//
//  SimpleSmartColorExtractor.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/18.
//  
//  Simple but smart color extraction that preserves unique small-area colors
//  while avoiding similar color redundancy
//

import UIKit
import SwiftUI

// MARK: - Simple LAB Color
struct SimpleLABColor {
    let L: Double
    let A: Double
    let B: Double
    let originalRGB: (r: Int, g: Int, b: Int)
    
    init(r: Int, g: Int, b: Int) {
        self.originalRGB = (r, g, b)
        
        // Simplified RGB to LAB conversion
        let rNorm = Double(r) / 255.0
        let gNorm = Double(g) / 255.0
        let bNorm = Double(b) / 255.0
        
        // Gamma correction
        let rLinear = rNorm > 0.04045 ? pow((rNorm + 0.055) / 1.055, 2.4) : rNorm / 12.92
        let gLinear = gNorm > 0.04045 ? pow((gNorm + 0.055) / 1.055, 2.4) : gNorm / 12.92
        let bLinear = bNorm > 0.04045 ? pow((bNorm + 0.055) / 1.055, 2.4) : bNorm / 12.92
        
        // XYZ
        let x = rLinear * 0.4124564 + gLinear * 0.3575761 + bLinear * 0.1804375
        let y = rLinear * 0.2126729 + gLinear * 0.7151522 + bLinear * 0.0721750
        let z = rLinear * 0.0193339 + gLinear * 0.1191920 + bLinear * 0.9503041
        
        // D65 normalization
        let xn = x / 0.95047
        let yn = y / 1.00000
        let zn = z / 1.08883
        
        // LAB
        let fx = xn > 0.008856 ? pow(xn, 1.0/3.0) : (7.787 * xn + 16.0/116.0)
        let fy = yn > 0.008856 ? pow(yn, 1.0/3.0) : (7.787 * yn + 16.0/116.0)
        let fz = zn > 0.008856 ? pow(zn, 1.0/3.0) : (7.787 * zn + 16.0/116.0)
        
        self.L = 116.0 * fy - 16.0
        self.A = 500.0 * (fx - fy)
        self.B = 200.0 * (fy - fz)
    }
    
    func deltaE(_ other: SimpleLABColor) -> Double {
        let deltaL = self.L - other.L
        let deltaA = self.A - other.A
        let deltaB = self.B - other.B
        return sqrt(deltaL * deltaL + deltaA * deltaA + deltaB * deltaB)
    }
    
    var uiColor: UIColor {
        return UIColor(
            red: CGFloat(originalRGB.r) / 255.0,
            green: CGFloat(originalRGB.g) / 255.0,
            blue: CGFloat(originalRGB.b) / 255.0,
            alpha: 1.0
        )
    }
    
    // Calculate visual distinctiveness
    var contrast: Double {
        return abs(L - 50) / 50.0 + sqrt(A * A + B * B) / 80.0
    }
}

// MARK: - Smart Color Point
struct SmartColorPoint {
    let labColor: SimpleLABColor
    let frequency: Int
    var uniquenessScore: Double = 0.0
    var finalScore: Double = 0.0
    
    init(r: Int, g: Int, b: Int, frequency: Int) {
        self.labColor = SimpleLABColor(r: r, g: g, b: b)
        self.frequency = frequency
    }
    
    mutating func calculateScores(among allColors: [SmartColorPoint]) {
        // Calculate uniqueness: minimum distance to any other color
        let distances = allColors.compactMap { other in
            other.labColor.originalRGB != self.labColor.originalRGB ? 
                self.labColor.deltaE(other.labColor) : nil
        }
        
        self.uniquenessScore = distances.min() ?? 100.0
        
        // Final score: heavily weight uniqueness, moderate frequency, add visual contrast
        let normalizedUniqueness = min(uniquenessScore / 30.0, 1.0)
        let normalizedFrequency = log(Double(frequency + 1)) / 12.0
        let contrastScore = labColor.contrast
        
        // 60% uniqueness + 15% frequency + 25% contrast
        self.finalScore = normalizedUniqueness * 0.6 + 
                         normalizedFrequency * 0.15 + 
                         contrastScore * 0.25
    }
}

// MARK: - Simple Smart Result
struct SimpleSmartResult {
    let colors: [UIColor]
    let progress: Double
    let stage: SimpleSmartStage
    let uniqueColorsFound: Int
    let totalColorsProcessed: Int
    let isComplete: Bool
}

enum SimpleSmartStage {
    case extracting
    case scoring
    case selecting
    case deduplicating
    case completed
}

// MARK: - Simple Smart Algorithm
extension UIImage {
    
    func extractColorsSimpleSmart(targetColors: Int = 5) -> AsyncThrowingStream<SimpleSmartResult, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Stage 1: Extract and build histogram
                    continuation.yield(SimpleSmartResult(
                        colors: [], progress: 0.2, stage: .extracting,
                        uniqueColorsFound: 0, totalColorsProcessed: 0, isComplete: false
                    ))
                    
                    guard let cgImage = self.cgImage else {
                        throw NSError(domain: "SimpleSmartError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
                    }
                    
                    let downSizedImage = await self.downSized(width: 150, height: 150)
                    guard let processedImage = downSizedImage.cgImage else {
                        throw NSError(domain: "SimpleSmartError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
                    }
                    
                    let colorPoints = await self.extractColorPoints(from: processedImage)
                    print("Extracted \(colorPoints.count) unique color points")
                    
                    // Stage 2: Calculate scores
                    continuation.yield(SimpleSmartResult(
                        colors: [], progress: 0.4, stage: .scoring,
                        uniqueColorsFound: colorPoints.count, totalColorsProcessed: colorPoints.count, isComplete: false
                    ))
                    
                    var scoredColors = colorPoints
                    for i in 0..<scoredColors.count {
                        scoredColors[i].calculateScores(among: scoredColors)
                    }
                    
                    // Stage 3: Smart selection
                    continuation.yield(SimpleSmartResult(
                        colors: [], progress: 0.6, stage: .selecting,
                        uniqueColorsFound: scoredColors.count, totalColorsProcessed: scoredColors.count, isComplete: false
                    ))
                    
                    let selectedColors = await self.smartSelectColors(scoredColors, targetCount: targetColors)
                    
                    // Stage 4: Final deduplication
                    continuation.yield(SimpleSmartResult(
                        colors: [], progress: 0.8, stage: .deduplicating,
                        uniqueColorsFound: selectedColors.count, totalColorsProcessed: scoredColors.count, isComplete: false
                    ))
                    
                    let finalColors = await self.finalDeduplication(selectedColors)
                    
                    // Complete
                    continuation.yield(SimpleSmartResult(
                        colors: finalColors, progress: 1.0, stage: .completed,
                        uniqueColorsFound: finalColors.count, totalColorsProcessed: scoredColors.count, isComplete: true
                    ))
                    
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Extract Color Points
    private func extractColorPoints(from cgImage: CGImage) async -> [SmartColorPoint] {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        
        guard let data = calloc(height * width, MemoryLayout<UInt32>.size) else {
            return []
        }
        defer { free(data) }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: data, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: colorSpace, bitmapInfo: bitmapInfo
        ) else {
            return []
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: height * width * bytesPerPixel)
        
        var colorHistogram: [String: (r: Int, g: Int, b: Int, count: Int)] = [:]
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = ((width * y) + x) * bytesPerPixel
                let r = Int(pixelBuffer[offset])
                let g = Int(pixelBuffer[offset + 1])
                let b = Int(pixelBuffer[offset + 2])
                let alpha = Int(pixelBuffer[offset + 3])
                
                guard alpha > 125 else { continue }
                
                // Light quantization to reduce noise but preserve uniqueness
                let qR = (r >> 2) << 2  // 6 bits per channel instead of 3
                let qG = (g >> 2) << 2
                let qB = (b >> 2) << 2
                
                let key = "\(qR),\(qG),\(qB)"
                if let existing = colorHistogram[key] {
                    colorHistogram[key] = (qR, qG, qB, existing.count + 1)
                } else {
                    colorHistogram[key] = (qR, qG, qB, 1)
                }
            }
            
            if y % 10 == 0 {
                await Task.yield()
            }
        }
        
        // Convert to color points - keep ALL colors, even rare ones
        return colorHistogram.values.map { 
            SmartColorPoint(r: $0.r, g: $0.g, b: $0.b, frequency: $0.count) 
        }
    }
    
    // MARK: - Smart Color Selection
    private func smartSelectColors(_ colors: [SmartColorPoint], targetCount: Int) async -> [UIColor] {
        
        // Sort by final score (uniqueness + contrast + minimal frequency)
        let sortedColors = colors.sorted { $0.finalScore > $1.finalScore }
        
        var selectedColors: [UIColor] = []
        
        // Method: Select colors ensuring they are visually distinct
        for color in sortedColors {
            if selectedColors.count >= targetCount { break }
            
            // Check if this color is too similar to already selected colors
            let isTooSimilar = selectedColors.contains { selectedColor in
                // Extract RGB from selected color
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                selectedColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                
                let selectedLAB = SimpleLABColor(r: Int(r * 255), g: Int(g * 255), b: Int(b * 255))
                return color.labColor.deltaE(selectedLAB) < 12.0  // Similarity threshold
            }
            
            if !isTooSimilar {
                selectedColors.append(color.labColor.uiColor)
            }
        }
        
        return selectedColors
    }
    
    // MARK: - Final Deduplication
    private func finalDeduplication(_ colors: [UIColor]) async -> [UIColor] {
        if colors.count <= 1 { return colors }
        
        var finalColors: [UIColor] = []
        
        for color in colors {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            let colorLAB = SimpleLABColor(r: Int(r * 255), g: Int(g * 255), b: Int(b * 255))
            
            let isUnique = finalColors.allSatisfy { existingColor in
                var er: CGFloat = 0, eg: CGFloat = 0, eb: CGFloat = 0, ea: CGFloat = 0
                existingColor.getRed(&er, green: &eg, blue: &eb, alpha: &ea)
                let existingLAB = SimpleLABColor(r: Int(er * 255), g: Int(eg * 255), b: Int(eb * 255))
                return colorLAB.deltaE(existingLAB) >= 10.0
            }
            
            if isUnique {
                finalColors.append(color)
            }
        }
        
        return finalColors
    }
}

// MARK: - Simple Smart ViewModel
@MainActor
class SimpleSmartViewModel: ObservableObject {
    @Published var colors: [UIColor] = []
    @Published var progress: Double = 0
    @Published var isExtracting = false
    @Published var currentStage: SimpleSmartStage = .extracting
    @Published var uniqueColorsFound = 0
    @Published var totalColorsProcessed = 0
    @Published var statusMessage = ""
    
    func extractColors(from image: UIImage, targetColors: Int = 5) {
        Task {
            isExtracting = true
            colors = []
            progress = 0
            uniqueColorsFound = 0
            totalColorsProcessed = 0
            
            do {
                for try await result in image.extractColorsSimpleSmart(targetColors: targetColors) {
                    colors = result.colors
                    progress = result.progress
                    currentStage = result.stage
                    uniqueColorsFound = result.uniqueColorsFound
                    totalColorsProcessed = result.totalColorsProcessed
                    
                    switch result.stage {
                    case .extracting:
                        statusMessage = "提取颜色中..."
                    case .scoring:
                        statusMessage = "计算独特性得分..."
                    case .selecting:
                        statusMessage = "智能选择颜色..."
                    case .deduplicating:
                        statusMessage = "去除相似颜色..."
                    case .completed:
                        statusMessage = "提取完成!"
                    }
                    
                    if result.isComplete {
                        isExtracting = false
                        break
                    }
                }
            } catch {
                print("Simple smart extraction failed: \(error)")
                statusMessage = "提取失败"
                isExtracting = false
            }
        }
    }
}

// MARK: - Simple Smart Demo View
struct SimpleSmartColorExtractor: View {
    @StateObject private var viewModel = SimpleSmartViewModel()
    @State private var targetColors: Double = 5
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Simple Smart Extractor")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
            
            VStack(spacing: 4) {
                Text("✓ 独特性优先 • ✓ 避免相似颜色 • ✓ 保留小面积色彩")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("简单但有效的算法")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
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
                    
                    HStack {
                        Text("\(Int(viewModel.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("处理了 \(viewModel.totalColorsProcessed) 种颜色")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
            }
            
            if !viewModel.colors.isEmpty {
                VStack(spacing: 15) {
                    Text("提取的颜色")
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
                    Text("目标颜色数: \(Int(targetColors))")
                        .font(.subheadline)
                    Spacer()
                }
                
                Slider(value: $targetColors, in: 3...8, step: 1)
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
                        Text(viewModel.isExtracting ? "提取中..." : "开始提取颜色")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.isExtracting ? Color.gray : Color.green)
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

//// MARK: - UIColor Extension
//extension UIColor {
//    func toHexString() -> String {
//        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
//        self.getRed(&r, green: &g, blue: &b, alpha: &a)
//        return String(format: "#%02x%02x%02x", Int(r * 255), Int(g * 255), Int(b * 255))
//    }
//}

#Preview {
    SimpleSmartColorExtractor()
}
