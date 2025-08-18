//
//  MMCQ_ColorExtractor.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/18.
//  
//  Implementation of Modified Median Cut Quantization (MMCQ) algorithm
//  for superior color extraction with deterministic results
//

import UIKit
import SwiftUI

// MARK: - MMCQ Result Structure
struct MMCQResult {
    let colors: [UIColor]
    let progress: Double
    let stage: MMCQStage
    let colorBoxCount: Int
    let isComplete: Bool
}

enum MMCQStage {
    case preprocessing
    case buildingHistogram
    case medianCut(iteration: Int, totalBoxes: Int)
    case extractingColors
    case completed
}

// MARK: - Core Data Structures
struct ColorBox {
    let rMin: Int, rMax: Int
    let gMin: Int, gMax: Int  
    let bMin: Int, bMax: Int
    private(set) var histogram: [ColorKey: Int]
    private(set) var volume: Int
    private(set) var population: Int
    
    init(rMin: Int, rMax: Int, gMin: Int, gMax: Int, bMin: Int, bMax: Int, histogram: [ColorKey: Int]) {
        self.rMin = rMin
        self.rMax = rMax
        self.gMin = gMin
        self.gMax = gMax
        self.bMin = bMin
        self.bMax = bMax
        self.histogram = histogram.filter { key, _ in
            key.r >= rMin && key.r <= rMax &&
            key.g >= gMin && key.g <= gMax &&
            key.b >= bMin && key.b <= bMax
        }
        self.volume = (rMax - rMin + 1) * (gMax - gMin + 1) * (bMax - bMin + 1)
        self.population = self.histogram.values.reduce(0, +)
    }
    
    // Calculate average color for this box
    var averageColor: UIColor {
        guard !histogram.isEmpty else {
            let midR = (rMin + rMax) / 2
            let midG = (gMin + gMax) / 2
            let midB = (bMin + bMax) / 2
            return UIColor(red: CGFloat(midR)/255.0, green: CGFloat(midG)/255.0, blue: CGFloat(midB)/255.0, alpha: 1.0)
        }
        
        var totalR = 0, totalG = 0, totalB = 0, totalCount = 0
        
        for (colorKey, count) in histogram {
            totalR += colorKey.r * count
            totalG += colorKey.g * count
            totalB += colorKey.b * count
            totalCount += count
        }
        
        guard totalCount > 0 else {
            return UIColor.black
        }
        
        return UIColor(
            red: CGFloat(totalR / totalCount) / 255.0,
            green: CGFloat(totalG / totalCount) / 255.0,
            blue: CGFloat(totalB / totalCount) / 255.0,
            alpha: 1.0
        )
    }
    
    // Find the dimension with largest range
    var longestDimension: ColorDimension {
        let rRange = rMax - rMin
        let gRange = gMax - gMin
        let bRange = bMax - bMin
        
        if rRange >= gRange && rRange >= bRange {
            return .red
        } else if gRange >= bRange {
            return .green
        } else {
            return .blue
        }
    }
    
    // Check if box can be split
    var canSplit: Bool {
        return population > 1 && (rMax > rMin || gMax > gMin || bMax > bMin)
    }
    
    // Split the box at median point
    func split() -> (ColorBox, ColorBox)? {
        guard canSplit else { return nil }
        
        let dimension = longestDimension
        let colors = histogram.keys.sorted { lhs, rhs in
            switch dimension {
            case .red: return lhs.r < rhs.r
            case .green: return lhs.g < rhs.g  
            case .blue: return lhs.b < rhs.b
            }
        }
        
        // Find median split point by population
        var totalCount = 0
        let targetCount = population / 2
        var splitValue = 0
        
        for colorKey in colors {
            totalCount += histogram[colorKey] ?? 0
            if totalCount >= targetCount {
                splitValue = switch dimension {
                case .red: colorKey.r
                case .green: colorKey.g
                case .blue: colorKey.b
                }
                break
            }
        }
        
        // Create two new boxes
        let (leftBox, rightBox) = switch dimension {
        case .red:
            (
                ColorBox(rMin: rMin, rMax: splitValue, gMin: gMin, gMax: gMax, bMin: bMin, bMax: bMax, histogram: histogram),
                ColorBox(rMin: splitValue + 1, rMax: rMax, gMin: gMin, gMax: gMax, bMin: bMin, bMax: bMax, histogram: histogram)
            )
        case .green:
            (
                ColorBox(rMin: rMin, rMax: rMax, gMin: gMin, gMax: splitValue, bMin: bMin, bMax: bMax, histogram: histogram),
                ColorBox(rMin: rMin, rMax: rMax, gMin: gMin + 1, gMax: gMax, bMin: bMin, bMax: bMax, histogram: histogram)
            )
        case .blue:
            (
                ColorBox(rMin: rMin, rMax: rMax, gMin: gMin, gMax: gMax, bMin: bMin, bMax: splitValue, histogram: histogram),
                ColorBox(rMin: rMin, rMax: rMax, gMin: gMin, gMax: gMax, bMin: splitValue + 1, bMax: bMax, histogram: histogram)
            )
        }
        
        // Only return if both boxes have population
        if leftBox.population > 0 && rightBox.population > 0 {
            return (leftBox, rightBox)
        }
        
        return nil
    }
}

enum ColorDimension {
    case red, green, blue
}

struct ColorKey: Hashable {
    let r: Int
    let g: Int  
    let b: Int
    
    init(r: Int, g: Int, b: Int) {
        // Quantize to reduce color space (5 bits per channel)
        self.r = (r >> 3) << 3
        self.g = (g >> 3) << 3
        self.b = (b >> 3) << 3
    }
}

// MARK: - MMCQ Implementation
extension UIImage {
    
    // MARK: - Progressive MMCQ Extraction
    func extractColorsMMCQ(targetColors: Int = 5) -> AsyncThrowingStream<MMCQResult, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Stage 1: Preprocessing
                    continuation.yield(MMCQResult(
                        colors: [],
                        progress: 0.1,
                        stage: .preprocessing,
                        colorBoxCount: 0,
                        isComplete: false
                    ))
                    
                    guard self.cgImage != nil else {
                        throw NSError(domain: "MMCQError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
                    }
                    
                    let downSizedImage = await downSized(width: 150, height: 150)
                    guard let cgImage = downSizedImage.cgImage else {
                        throw NSError(domain: "MMCQError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage"])
                    }
                    
                    // Stage 2: Building histogram
                    continuation.yield(MMCQResult(
                        colors: [],
                        progress: 0.2,
                        stage: .buildingHistogram,
                        colorBoxCount: 0,
                        isComplete: false
                    ))
                    
                    let histogram = await buildColorHistogram(cgImage: cgImage)
                    
                    continuation.yield(MMCQResult(
                        colors: [],
                        progress: 0.3,
                        stage: .buildingHistogram,
                        colorBoxCount: 1,
                        isComplete: false
                    ))
                    
                    // Stage 3: MMCQ Algorithm
                    let colorBoxes = await performMMCQ(
                        histogram: histogram,
                        targetColors: targetColors,
                        progressCallback: { iteration, totalBoxes in
                            let progress = 0.3 + (0.6 * Double(totalBoxes) / Double(targetColors))
                            continuation.yield(MMCQResult(
                                colors: [],
                                progress: progress,
                                stage: .medianCut(iteration: iteration, totalBoxes: totalBoxes),
                                colorBoxCount: totalBoxes,
                                isComplete: false
                            ))
                        }
                    )
                    
                    // Stage 4: Extract final colors
                    continuation.yield(MMCQResult(
                        colors: [],
                        progress: 0.9,
                        stage: .extractingColors,
                        colorBoxCount: colorBoxes.count,
                        isComplete: false
                    ))
                    
                    let finalColors = colorBoxes
                        .sorted { $0.population > $1.population }
                        .map { $0.averageColor }
                    
                    // Stage 5: Complete
                    continuation.yield(MMCQResult(
                        colors: finalColors,
                        progress: 1.0,
                        stage: .completed,
                        colorBoxCount: colorBoxes.count,
                        isComplete: true
                    ))
                    
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Build Color Histogram
    private func buildColorHistogram(cgImage: CGImage) async -> [ColorKey: Int] {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        
        guard let data = calloc(height * width, MemoryLayout<UInt32>.size) else {
            return [:]
        }
        defer { free(data) }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return [:]
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: height * width * bytesPerPixel)
        
        var histogram: [ColorKey: Int] = [:]
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = ((width * y) + x) * bytesPerPixel
                let r = Int(pixelBuffer[offset])
                let g = Int(pixelBuffer[offset + 1])
                let b = Int(pixelBuffer[offset + 2])
                let alpha = Int(pixelBuffer[offset + 3])
                
                // Skip transparent pixels
                guard alpha > 125 else { continue }
                
                let colorKey = ColorKey(r: r, g: g, b: b)
                histogram[colorKey, default: 0] += 1
            }
            
            // Yield control periodically
            if y % 10 == 0 {
                await Task.yield()
            }
        }
        
        return histogram
    }
    
    // MARK: - MMCQ Core Algorithm
    private func performMMCQ(
        histogram: [ColorKey: Int],
        targetColors: Int,
        progressCallback: @escaping (Int, Int) -> Void
    ) async -> [ColorBox] {
        
        // Create initial box containing all colors
        let allColors = histogram.keys
        guard !allColors.isEmpty else { return [] }
        
        let rRange = (allColors.map(\.r).min()!, allColors.map(\.r).max()!)
        let gRange = (allColors.map(\.g).min()!, allColors.map(\.g).max()!)
        let bRange = (allColors.map(\.b).min()!, allColors.map(\.b).max()!)
        
        let initialBox = ColorBox(
            rMin: rRange.0, rMax: rRange.1,
            gMin: gRange.0, gMax: gRange.1,
            bMin: bRange.0, bMax: bRange.1,
            histogram: histogram
        )
        
        var colorBoxes = [initialBox]
        var iteration = 0
        
        // Split boxes until we reach target color count
        while colorBoxes.count < targetColors {
            iteration += 1
            
            // Find the box with largest population * volume that can be split
            let boxToSplit = colorBoxes
                .enumerated()
                .compactMap { index, box in
                    box.canSplit ? (index, box, box.population * box.volume) : nil
                }
                .max { $0.2 < $1.2 }
            
            guard let (boxIndex, box, _) = boxToSplit,
                  let (leftBox, rightBox) = box.split() else {
                break // No more boxes can be split
            }
            
            // Replace the original box with the two new boxes
            colorBoxes.remove(at: boxIndex)
            colorBoxes.append(leftBox)
            colorBoxes.append(rightBox)
            
            // Report progress
            await MainActor.run {
                progressCallback(iteration, colorBoxes.count)
            }
            
            // Yield control
            await Task.yield()
        }
        
        return colorBoxes.filter { $0.population > 0 }
    }
}

// MARK: - MMCQ Demo View
@MainActor
class MMCQViewModel: ObservableObject {
    @Published var colors: [UIColor] = []
    @Published var progress: Double = 0
    @Published var isExtracting = false
    @Published var currentStage: MMCQStage = .preprocessing
    @Published var colorBoxCount = 0
    @Published var statusMessage = ""
    
    func extractColors(from image: UIImage, targetColors: Int = 5) {
        Task {
            isExtracting = true
            colors = []
            progress = 0
            colorBoxCount = 0
            
            do {
                for try await result in image.extractColorsMMCQ(targetColors: targetColors) {
                    colors = result.colors
                    progress = result.progress
                    currentStage = result.stage
                    colorBoxCount = result.colorBoxCount
                    
                    // Update status message
                    switch result.stage {
                    case .preprocessing:
                        statusMessage = "Preparing image..."
                    case .buildingHistogram:
                        statusMessage = "Building color histogram..."
                    case .medianCut(let iteration, let totalBoxes):
                        statusMessage = "Median cut: \(totalBoxes) color regions"
                    case .extractingColors:
                        statusMessage = "Extracting final colors..."
                    case .completed:
                        statusMessage = "MMCQ extraction complete!"
                    }
                    
                    if result.isComplete {
                        isExtracting = false
                        break
                    }
                }
            } catch {
                print("MMCQ extraction failed: \(error)")
                statusMessage = "Extraction failed"
                isExtracting = false
            }
        }
    }
}

struct MMCQColorExtractor: View {
    @StateObject private var viewModel = MMCQViewModel()
    @State private var targetColors: Double = 5
    
    var body: some View {
        VStack(spacing: 20) {
            Text("MMCQ Color Extractor")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
            
            Text("Deterministic • Superior Quality • No Random Results")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Image(.reflect)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
            
            if viewModel.isExtracting {
                VStack(spacing: 12) {
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text(viewModel.statusMessage)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(viewModel.progress * 100))% • \(viewModel.colorBoxCount) regions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.3), value: viewModel.statusMessage)
            }
            
            if !viewModel.colors.isEmpty {
                VStack(spacing: 15) {
                    Text("Extracted Colors")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 15) {
                        ForEach(Array(viewModel.colors.enumerated()), id: \.offset) { index, color in
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 50, height: 50)
                                    .shadow(radius: 3)
                                
                                Text("#\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(.primary)
                                
                                Text(color.toHexString())
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.colors.count)
            }
            
            VStack(spacing: 15) {
                HStack {
                    Text("Target Colors: \(Int(targetColors))")
                        .font(.subheadline)
                    Spacer()
                }
                
                Slider(value: $targetColors, in: 2...8, step: 1)
                    .disabled(viewModel.isExtracting)
                
                Button(action: {
                    let image = UIImage(resource: .reflect)
                    viewModel.extractColors(from: image, targetColors: Int(targetColors))
                }) {
                    HStack {
                        if viewModel.isExtracting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(viewModel.isExtracting ? "Extracting..." : "Extract Colors (MMCQ)")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.isExtracting ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isExtracting)
            }
        }
        .padding()
        .onAppear {
            let image = UIImage(resource: .reflect)
            viewModel.extractColors(from: image, targetColors: Int(targetColors))
        }
    }
}

#Preview {
    MMCQColorExtractor()
}
