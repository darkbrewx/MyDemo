//
//  UIImage+ColorExtract_Improved.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/18.
//

import UIKit
import SwiftUI

// MARK: - Color Extraction Result
struct ColorExtractionResult {
    let colors: [UIColor]
    let progress: Double
    let iteration: Int
    let isComplete: Bool
    let stage: ExtractionStage
    let convergenceInfo: ConvergenceInfo?
}

enum ExtractionStage {
    case preprocessing
    case kmeans(iteration: Int, totalIterations: Int)
    case converged
    case completed
}

struct ConvergenceInfo {
    let convergedAt: Int
    let centerMovements: [CGFloat]
    let averageMovement: CGFloat
}

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension UIImage {
    var aspectRatio: CGFloat {
        return self.size.height / self.size.width
    }

    // Create a down sized image to speed up color extraction
    func downSized(width: CGFloat, height: CGFloat) async -> UIImage {
        let size = CGSize(width: width, height: height * aspectRatio)

        let renderer = UIGraphicsImageRenderer(size: size)
        let downSizedImage = renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
        return downSizedImage
    }

    // Get pixel data from CGImage
    private func getPixelData(cgImage: CGImage) async throws -> [PixelData] {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8

        // Allocate memory for pixel data
        guard let data = calloc(height * width, MemoryLayout<UInt32>.size) else {
            throw NSError(domain: "UIImageColorExtractionError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Memory allocation failed"])
        }

        defer { free(data) }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw NSError(domain: "UIImageColorExtractionError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGContext"])
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: height * width * bytesPerPixel)

        var pixelData = [PixelData]()
        for y in 0..<height {
            for x in 0..<width {
                let offset = ((width * y) + x) * bytesPerPixel
                let r = pixelBuffer[offset]
                let g = pixelBuffer[offset + 1]
                let b = pixelBuffer[offset + 2]
                pixelData.append(PixelData(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b)))
            }
        }
        return pixelData
    }

    // MARK: - Progressive Color Extraction
    
    // Progressive color extraction with real-time updates
    func extractColorsProgressive(colorCount: Int) -> AsyncThrowingStream<ColorExtractionResult, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard self.cgImage != nil else {
                        throw NSError(domain: "UIImageColorExtractionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
                    }
                    
                    // Report preprocessing stage
                    continuation.yield(ColorExtractionResult(
                        colors: [],
                        progress: 0.1,
                        iteration: 0,
                        isComplete: false,
                        stage: .preprocessing,
                        convergenceInfo: nil
                    ))
                    
                    let downSizedImage = await downSized(width: 100, height: 100)
                    guard let cgImage = downSizedImage.cgImage else {
                        throw NSError(domain: "UIImageColorExtractionError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage"])
                    }
                    
                    let pixelData = try await getPixelData(cgImage: cgImage)
                    
                    // Report preprocessing completion
                    continuation.yield(ColorExtractionResult(
                        colors: [],
                        progress: 0.2,
                        iteration: 0,
                        isComplete: false,
                        stage: .preprocessing,
                        convergenceInfo: nil
                    ))
                    
                    // Initialize clusters
                    var clusters = initializeClusters(pixels: pixelData, count: colorCount)
                    let maxIterations = 10
                    
                    var previousCenters = clusters.map { $0.center }
                    
                    for iteration in 0..<maxIterations {
                        // Check for cancellation
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }
                        
                        // Perform one iteration
                        clusters = await performKMeansIteration(pixels: pixelData, clusters: clusters)
                        
                        // Check for convergence and calculate movements
                        let currentCenters = clusters.map { $0.center }
                        let movements = zip(previousCenters, currentCenters).map { 
                            euclideanDistance(pixel1: $0, pixel2: $1) 
                        }
                        let averageMovement = movements.reduce(0, +) / CGFloat(movements.count)
                        let hasConverged = movements.allSatisfy { $0 <= 1.0 }
                        
                        // Convert to colors and yield result
                        let colors = clustersToColors(clusters)
                        let baseProgress = 0.2 + (0.8 * Double(iteration + 1) / Double(maxIterations))
                        let progress = hasConverged ? 1.0 : baseProgress
                        
                        let convergenceInfo = hasConverged ? ConvergenceInfo(
                            convergedAt: iteration + 1,
                            centerMovements: movements,
                            averageMovement: averageMovement
                        ) : nil
                        
                        continuation.yield(ColorExtractionResult(
                            colors: colors,
                            progress: progress,
                            iteration: iteration + 1,
                            isComplete: hasConverged || iteration == maxIterations - 1,
                            stage: hasConverged ? .converged : .kmeans(iteration: iteration + 1, totalIterations: maxIterations),
                            convergenceInfo: convergenceInfo
                        ))
                        
                        // Early termination if converged
                        if hasConverged {
                            break
                        }
                        
                        // Update previous centers for next iteration
                        previousCenters = clusters.map { $0.center }
                        
                        // Optional: yield after each update to show progress
                        await Task.yield()
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // Original synchronous method for compatibility
    func extractColors(colorCount: Int) async throws -> [UIColor] {
        guard self.cgImage != nil else {
            throw NSError(domain: "UIImageColorExtractionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }
        
        let downSizedImage = await downSized(width: 100, height: 100)
        guard let cgImage = downSizedImage.cgImage else {
            throw NSError(domain: "UIImageColorExtractionError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage"])
        }
        
        let pixelData = try await getPixelData(cgImage: cgImage)
        let clusters = await kMeansClustering(pixels: pixelData, colorCount: colorCount)
        
        return clustersToColors(clusters)
    }

    // MARK: - K-means Implementation

    // Initialize clusters using K-means++ algorithm for better convergence
    private func initializeClusters(pixels: [PixelData], count: Int) -> [Cluster] {
        guard !pixels.isEmpty && count > 0 else { return [] }
        
        var centers = [PixelData]()
        
        // Step 1: Choose first center randomly
        if let firstCenter = pixels.randomElement() {
            centers.append(firstCenter)
        }
        
        // Step 2: Choose remaining centers using K-means++ algorithm
        for _ in 1..<count {
            var distances = [CGFloat]()
            var totalDistance: CGFloat = 0
            
            // Calculate squared distances to nearest existing center
            for pixel in pixels {
                let minDistance = centers.map { euclideanDistance(pixel1: pixel, pixel2: $0) }.min() ?? 0
                let squaredDistance = minDistance * minDistance
                distances.append(squaredDistance)
                totalDistance += squaredDistance
            }
            
            // Choose next center based on probability proportional to squared distance
            let randomValue = CGFloat.random(in: 0...totalDistance)
            var cumulativeDistance: CGFloat = 0
            
            for (index, distance) in distances.enumerated() {
                cumulativeDistance += distance
                if cumulativeDistance >= randomValue {
                    centers.append(pixels[index])
                    break
                }
            }
        }
        
        return centers.map { Cluster(center: $0, points: []) }
    }
    
    // Convert clusters to UIColors
    private func clustersToColors(_ clusters: [Cluster]) -> [UIColor] {
        return clusters.map { cluster in
            let center = cluster.center
            return UIColor(
                red: center.red / 255.0,
                green: center.green / 255.0,
                blue: center.blue / 255.0,
                alpha: 1.0
            )
        }.sorted {
            var h1: CGFloat = 0, s1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            var h2: CGFloat = 0, s2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            $0.getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)
            $1.getHue(&h2, saturation: &s2, brightness: &b2, alpha: &a2)
            return h1 < h2
        }
    }
    
    // Perform single K-means iteration with parallel processing
    private func performKMeansIteration(pixels: [PixelData], clusters: [Cluster]) async -> [Cluster] {
        var newClusters = clusters.map { Cluster(center: $0.center, points: []) }
        
        // Assignment step: assign pixels to nearest cluster (parallel)
        await withTaskGroup(of: [(Int, [PixelData])].self) { group in
            let batchSize = max(pixels.count / ProcessInfo.processInfo.activeProcessorCount, 100)
            
            for batch in pixels.chunked(into: batchSize) {
                group.addTask {
                    var assignments: [Int: [PixelData]] = [:]
                    
                    for pixel in batch {
                        let closestIndex = self.findClosestCluster(pixel: pixel, clusters: clusters)
                        assignments[closestIndex, default: []].append(pixel)
                    }
                    
                    return assignments.map { ($0.key, $0.value) }
                }
            }
            
            // Collect results
            for await batchAssignments in group {
                for (index, pixels) in batchAssignments {
                    newClusters[index].points.append(contentsOf: pixels)
                }
            }
        }
        
        // Update step: recalculate cluster centers
        for i in 0..<newClusters.count {
            if !newClusters[i].points.isEmpty {
                let sum = newClusters[i].points.reduce(PixelData(red: 0, green: 0, blue: 0)) { result, pixel in
                    PixelData(
                        red: result.red + pixel.red,
                        green: result.green + pixel.green,
                        blue: result.blue + pixel.blue
                    )
                }
                let count = CGFloat(newClusters[i].points.count)
                newClusters[i].center = PixelData(
                    red: sum.red / count,
                    green: sum.green / count,
                    blue: sum.blue / count
                )
            }
        }
        
        return newClusters
    }
    
    // Find closest cluster for a pixel
    private func findClosestCluster(pixel: PixelData, clusters: [Cluster]) -> Int {
        var minDistance = CGFloat.greatestFiniteMagnitude
        var closestIndex = 0
        
        for (index, cluster) in clusters.enumerated() {
            let distance = euclideanDistance(pixel1: pixel, pixel2: cluster.center)
            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        }
        
        return closestIndex
    }
    
    // Check if algorithm has converged by comparing center movements
    private func checkConvergence(
        previousCenters: [PixelData],
        currentCenters: [PixelData],
        threshold: CGFloat
    ) -> Bool {
        guard previousCenters.count == currentCenters.count else { return false }
        
        for (prev, curr) in zip(previousCenters, currentCenters) {
            let distance = euclideanDistance(pixel1: prev, pixel2: curr)
            if distance > threshold {
                return false
            }
        }
        
        return true
    }

    // Original K-means method for compatibility
    private func kMeansClustering(pixels: [PixelData], colorCount: Int, maxIterations: Int = 10) async -> [Cluster] {
        var clusters = initializeClusters(pixels: pixels, count: colorCount)
        
        for _ in 0..<maxIterations {
            clusters = await performKMeansIteration(pixels: pixels, clusters: clusters)
            await Task.yield() // Allow cancellation
        }
        
        return clusters
    }

    // MARK: - Data Structures
    
    private struct PixelData {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
    }

    private struct Cluster {
        var center: PixelData
        var points: [PixelData]
    }

    // Calculate euclidean distance between two pixels
    private func euclideanDistance(pixel1: PixelData, pixel2: PixelData) -> CGFloat {
        let dr = pixel1.red - pixel2.red
        let dg = pixel1.green - pixel2.green
        let db = pixel1.blue - pixel2.blue
        return sqrt(dr * dr + dg * dg + db * db)
    }
}

// MARK: - Progressive Color Extractor View

@MainActor
class ColorExtractorViewModel: ObservableObject {
    @Published var colors: [UIColor] = []
    @Published var progress: Double = 0
    @Published var isExtracting = false
    @Published var currentIteration = 0
    @Published var currentStage: ExtractionStage = .preprocessing
    @Published var convergenceInfo: ConvergenceInfo?
    @Published var statusMessage = ""
    
    func extractColors(from image: UIImage) {
        Task {
            isExtracting = true
            colors = []
            progress = 0
            currentIteration = 0
            convergenceInfo = nil
            
            do {
                for try await result in image.extractColorsProgressive(colorCount: 5) {
                    colors = result.colors
                    progress = result.progress
                    currentIteration = result.iteration
                    currentStage = result.stage
                    convergenceInfo = result.convergenceInfo
                    
                    // Update status message based on stage
                    switch result.stage {
                    case .preprocessing:
                        statusMessage = "Processing image..."
                    case .kmeans(let iter, let total):
                        statusMessage = "Clustering iteration \(iter)/\(total)"
                    case .converged:
                        statusMessage = "Converged early!"
                    case .completed:
                        statusMessage = "Extraction complete"
                    }
                    
                    if result.isComplete {
                        isExtracting = false
                        break
                    }
                }
            } catch {
                print("Color extraction failed: \(error)")
                statusMessage = "Extraction failed"
                isExtracting = false
            }
        }
    }
}

struct ProgressiveColorExtractor: View {
    @StateObject private var viewModel = ColorExtractorViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(.reflect)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
            
            if viewModel.isExtracting {
                VStack(spacing: 12) {
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text(viewModel.statusMessage)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(viewModel.progress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let convergenceInfo = viewModel.convergenceInfo {
                        VStack(spacing: 4) {
                            Text("✓ Converged at iteration \(convergenceInfo.convergedAt)")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text("Average movement: \(String(format: "%.2f", convergenceInfo.averageMovement))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.3), value: viewModel.statusMessage)
            }
            
            if !viewModel.colors.isEmpty {
                HStack(spacing: 15) {
                    ForEach(viewModel.colors, id: \.self) { color in
                        VStack {
                            Rectangle()
                                .fill(Color(color))
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                            
                            Text(color.toHexString())
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.colors.count)
            }
            
            Button(action: {
                let image = UIImage(resource: .reflect)
                viewModel.extractColors(from: image)
            }) {
                Text(viewModel.isExtracting ? "Extracting..." : "Extract Colors")
                    .foregroundColor(.white)
                    .padding()
                    .background(viewModel.isExtracting ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(viewModel.isExtracting)
        }
        .padding()
        .onAppear {
            let image = UIImage(resource: .reflect)
            viewModel.extractColors(from: image)
        }
    }
}

extension UIColor {
    func toHexString() -> String {
        var rFloat: CGFloat = 0
        var gFloat: CGFloat = 0
        var bFloat: CGFloat = 0
        var aFloat: CGFloat = 0

        self.getRed(&rFloat, green: &gFloat, blue: &bFloat, alpha: &aFloat)
        let rInt = Int(rFloat * 255)
        let gInt = Int(gFloat * 255)
        let bInt = Int(bFloat * 255)

        return String(format: "#%02x%02x%02x", rInt, gInt, bInt)
    }
}

#Preview {
    ProgressiveColorExtractor()
}
