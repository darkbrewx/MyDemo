//
//  DBSCANColorExtractor.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/18.
//  
//  DBSCAN + Visual Importance hybrid color extraction algorithm
//  Designed to preserve small-area high-contrast outlier colors while avoiding similar color redundancy
//

import UIKit
import SwiftUI

// MARK: - Enhanced LAB Color System
struct AdvancedLABColor {
    let L: Double  // Lightness (0-100)
    let A: Double  // Green-Red axis (-128 to +127)
    let B: Double  // Blue-Yellow axis (-128 to +127)
    let originalRGB: (r: Int, g: Int, b: Int)
    
    init(r: Int, g: Int, b: Int) {
        self.originalRGB = (r, g, b)
        
        // RGB to XYZ conversion
        let rNorm = Double(r) / 255.0
        let gNorm = Double(g) / 255.0
        let bNorm = Double(b) / 255.0
        
        // Gamma correction
        let rLinear = rNorm > 0.04045 ? pow((rNorm + 0.055) / 1.055, 2.4) : rNorm / 12.92
        let gLinear = gNorm > 0.04045 ? pow((gNorm + 0.055) / 1.055, 2.4) : gNorm / 12.92
        let bLinear = bNorm > 0.04045 ? pow((bNorm + 0.055) / 1.055, 2.4) : bNorm / 12.92
        
        // Convert to XYZ (D65 illuminant)
        let x = rLinear * 0.4124564 + gLinear * 0.3575761 + bLinear * 0.1804375
        let y = rLinear * 0.2126729 + gLinear * 0.7151522 + bLinear * 0.0721750
        let z = rLinear * 0.0193339 + gLinear * 0.1191920 + bLinear * 0.9503041
        
        // Normalize by D65 white point
        let xn = x / 0.95047
        let yn = y / 1.00000
        let zn = z / 1.08883
        
        // Convert XYZ to LAB
        let fx = xn > 0.008856 ? pow(xn, 1.0/3.0) : (7.787 * xn + 16.0/116.0)
        let fy = yn > 0.008856 ? pow(yn, 1.0/3.0) : (7.787 * yn + 16.0/116.0)
        let fz = zn > 0.008856 ? pow(zn, 1.0/3.0) : (7.787 * zn + 16.0/116.0)
        
        self.L = 116.0 * fy - 16.0
        self.A = 500.0 * (fx - fy)
        self.B = 200.0 * (fy - fz)
    }
    
    // Delta-E CIE76 distance
    func deltaE(_ other: AdvancedLABColor) -> Double {
        let deltaL = self.L - other.L
        let deltaA = self.A - other.A
        let deltaB = self.B - other.B
        return sqrt(deltaL * deltaL + deltaA * deltaA + deltaB * deltaB)
    }
    
    // Convert back to UIColor
    var uiColor: UIColor {
        let r = Double(originalRGB.r) / 255.0
        let g = Double(originalRGB.g) / 255.0
        let b = Double(originalRGB.b) / 255.0
        return UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
    }
    
    // Color properties for analysis
    var saturation: Double {
        return sqrt(A * A + B * B)
    }
    
    var lightness: Double {
        return L
    }
    
    var contrast: Double {
        // Distance from neutral gray (L=50, A=0, B=0)
        let neutralL = 50.0
        let deltaL = abs(L - neutralL) / 50.0  // Normalized lightness contrast
        let chromaContrast = saturation / 100.0  // Normalized chroma contrast
        return (deltaL + chromaContrast) / 2.0
    }
}

// MARK: - Color Point for DBSCAN
struct ColorPoint {
    let labColor: AdvancedLABColor
    let frequency: Int
    var clusterId: Int = -1  // -1 means unclassified, -2 means noise
    var isVisited: Bool = false
    var visualImportance: Double = 0.0
    
    init(r: Int, g: Int, b: Int, frequency: Int) {
        self.labColor = AdvancedLABColor(r: r, g: g, b: b)
        self.frequency = frequency
    }
    
    // Calculate visual importance score
    mutating func calculateVisualImportance(among allPoints: [ColorPoint]) {
        // 1. Uniqueness score (50% weight) - minimum distance to other colors
        let distances = allPoints.compactMap { other in
            other.labColor.originalRGB != self.labColor.originalRGB ? self.labColor.deltaE(other.labColor) : nil
        }
        let minDistance = distances.min() ?? 0
        let uniquenessScore = min(minDistance / 30.0, 1.0)  // Normalize to 0-1
        
        // 2. Contrast score (30% weight) - visual prominence
        let contrastScore = labColor.contrast
        
        // 3. Saturation score (20% weight) - color vividness
        let saturationScore = min(labColor.saturation / 80.0, 1.0)
        
        // Minimal frequency influence (only as tie-breaker)
        let frequencyScore = log(Double(frequency + 1)) / 15.0  // Very low weight
        
        // Final visual importance: prioritize uniqueness and visual impact
        self.visualImportance = uniquenessScore * 0.5 + 
                                contrastScore * 0.3 + 
                                saturationScore * 0.2 + 
                                frequencyScore * 0.05  // Minimal frequency weight
    }
}

// MARK: - DBSCAN Cluster
struct DBSCANCluster {
    let id: Int
    var points: [ColorPoint]
    var isOutlier: Bool = false
    
    // Representative color for this cluster
    var representativeColor: UIColor {
        guard !points.isEmpty else { return UIColor.black }
        
        // Use the most visually important color as representative
        let bestPoint = points.max(by: { $0.visualImportance < $1.visualImportance })
        return bestPoint?.labColor.uiColor ?? UIColor.black
    }
    
    // Average color (fallback)
    var averageColor: UIColor {
        guard !points.isEmpty else { return UIColor.black }
        
        let totalFreq = points.reduce(0) { $0 + $1.frequency }
        var totalR = 0.0, totalG = 0.0, totalB = 0.0
        
        for point in points {
            let weight = Double(point.frequency)
            totalR += Double(point.labColor.originalRGB.r) * weight
            totalG += Double(point.labColor.originalRGB.g) * weight
            totalB += Double(point.labColor.originalRGB.b) * weight
        }
        
        return UIColor(
            red: CGFloat(totalR / Double(totalFreq)) / 255.0,
            green: CGFloat(totalG / Double(totalFreq)) / 255.0,
            blue: CGFloat(totalB / Double(totalFreq)) / 255.0,
            alpha: 1.0
        )
    }
}

// MARK: - DBSCAN Result Structure
struct DBSCANResult {
    let colors: [UIColor]
    let progress: Double
    let stage: DBSCANStage
    let clusterCount: Int
    let outlierCount: Int
    let isComplete: Bool
}

enum DBSCANStage {
    case preprocessing
    case buildingHistogram
    case dbscanning(clustersFound: Int, outliers: Int)
    case calculating_importance
    case selecting_colors
    case deduplicating
    case completed
}

// MARK: - DBSCAN Algorithm Implementation
extension UIImage {
    
    // MARK: - Main DBSCAN Color Extraction
    func extractColorsDBSCAN(targetColors: Int = 5, eps: Double = 15.0, minPoints: Int = 2) -> AsyncThrowingStream<DBSCANResult, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Stage 1: Preprocessing
                    continuation.yield(DBSCANResult(
                        colors: [], progress: 0.1, stage: .preprocessing, 
                        clusterCount: 0, outlierCount: 0, isComplete: false
                    ))
                    
                    guard let cgImage = self.cgImage else {
                        throw NSError(domain: "DBSCANError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
                    }
                    
                    let downSizedImage = await self.downSized(width: 150, height: 150)
                    guard let processedCGImage = downSizedImage.cgImage else {
                        throw NSError(domain: "DBSCANError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage"])
                    }
                    
                    // Stage 2: Building histogram
                    continuation.yield(DBSCANResult(
                        colors: [], progress: 0.2, stage: .buildingHistogram, 
                        clusterCount: 0, outlierCount: 0, isComplete: false
                    ))
                    
                    let colorPoints = await self.buildColorPoints(cgImage: processedCGImage)
                    
                    // Stage 3: DBSCAN clustering
                    let (clusters, noisePoints) = await self.performDBSCAN(
                        points: colorPoints, eps: eps, minPoints: minPoints
                    ) { clustersFound, outliers in
                        continuation.yield(DBSCANResult(
                            colors: [], progress: 0.3 + 0.3 * Double(clustersFound) / 10.0, 
                            stage: .dbscanning(clustersFound: clustersFound, outliers: outliers), 
                            clusterCount: clustersFound, outlierCount: outliers, isComplete: false
                        ))
                    }
                    
                    // Stage 4: Calculate visual importance
                    continuation.yield(DBSCANResult(
                        colors: [], progress: 0.7, stage: .calculating_importance, 
                        clusterCount: clusters.count, outlierCount: noisePoints.count, isComplete: false
                    ))
                    
                    let finalColors = await self.selectFinalColors(
                        clusters: clusters, noisePoints: noisePoints, targetColors: targetColors
                    )
                    
                    // Stage 5: Deduplication
                    continuation.yield(DBSCANResult(
                        colors: [], progress: 0.9, stage: .deduplicating, 
                        clusterCount: clusters.count, outlierCount: noisePoints.count, isComplete: false
                    ))
                    
                    let deduplicatedColors = await self.deduplicateColors(finalColors)
                    
                    // Stage 6: Complete
                    continuation.yield(DBSCANResult(
                        colors: deduplicatedColors, progress: 1.0, stage: .completed, 
                        clusterCount: clusters.count, outlierCount: noisePoints.count, isComplete: true
                    ))
                    
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Build Color Points from Image
    private func buildColorPoints(cgImage: CGImage) async -> [ColorPoint] {
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
                
                // Skip transparent pixels
                guard alpha > 125 else { continue }
                
                // Quantize colors to reduce noise (3 bits per channel)
                let qR = (r >> 5) << 5
                let qG = (g >> 5) << 5
                let qB = (b >> 5) << 5
                
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
        
        // Convert to ColorPoints and filter out very rare colors
        let minFrequency = max(1, colorHistogram.values.map { $0.count }.max()! / 200)
        var colorPoints = colorHistogram.values
            .filter { $0.count >= minFrequency }
            .map { ColorPoint(r: $0.r, g: $0.g, b: $0.b, frequency: $0.count) }
        
        // Calculate visual importance for all points
        for i in 0..<colorPoints.count {
            colorPoints[i].calculateVisualImportance(among: colorPoints)
        }
        
        return colorPoints
    }
    
    // MARK: - DBSCAN Clustering Algorithm
    private func performDBSCAN(
        points: [ColorPoint], 
        eps: Double, 
        minPoints: Int,
        progressCallback: @escaping (Int, Int) -> Void
    ) async -> ([DBSCANCluster], [ColorPoint]) {
        
        var workingPoints = points
        var clusters: [DBSCANCluster] = []
        var currentClusterId = 0
        
        for i in 0..<workingPoints.count {
            if workingPoints[i].isVisited { continue }
            
            workingPoints[i].isVisited = true
            let neighbors = await regionQuery(points: workingPoints, pointIndex: i, eps: eps)
            
            if neighbors.count < minPoints {
                workingPoints[i].clusterId = -2  // Mark as noise
            } else {
                // Create new cluster
                let cluster = DBSCANCluster(id: currentClusterId, points: [])
                clusters.append(cluster)
                
                await expandCluster(
                    points: &workingPoints, pointIndex: i, neighbors: neighbors,
                    clusterId: currentClusterId, eps: eps, minPoints: minPoints
                )
                
                currentClusterId += 1
            }
            
            // Report progress periodically
            if i % max(1, workingPoints.count / 20) == 0 {
                let noiseCount = workingPoints.filter { $0.clusterId == -2 }.count
                await MainActor.run {
                    progressCallback(clusters.count, noiseCount)
                }
            }
            
            await Task.yield()
        }
        
        // Group points into clusters
        var finalClusters: [DBSCANCluster] = []
        for clusterId in 0..<currentClusterId {
            let clusterPoints = workingPoints.filter { $0.clusterId == clusterId }
            if !clusterPoints.isEmpty {
                finalClusters.append(DBSCANCluster(id: clusterId, points: clusterPoints))
            }
        }
        
        let noisePoints = workingPoints.filter { $0.clusterId == -2 }
        
        return (finalClusters, noisePoints)
    }
    
    // MARK: - DBSCAN Helper Methods
    private func regionQuery(points: [ColorPoint], pointIndex: Int, eps: Double) async -> [Int] {
        var neighbors: [Int] = []
        let queryPoint = points[pointIndex]
        
        for (index, point) in points.enumerated() {
            if queryPoint.labColor.deltaE(point.labColor) <= eps {
                neighbors.append(index)
            }
        }
        
        return neighbors
    }
    
    private func expandCluster(
        points: inout [ColorPoint], pointIndex: Int, neighbors: [Int],
        clusterId: Int, eps: Double, minPoints: Int
    ) async {
        
        points[pointIndex].clusterId = clusterId
        var neighborsList = neighbors
        var i = 0
        
        while i < neighborsList.count {
            let neighborIndex = neighborsList[i]
            
            if !points[neighborIndex].isVisited {
                points[neighborIndex].isVisited = true
                let newNeighbors = await regionQuery(points: points, pointIndex: neighborIndex, eps: eps)
                
                if newNeighbors.count >= minPoints {
                    neighborsList.append(contentsOf: newNeighbors)
                }
            }
            
            if points[neighborIndex].clusterId == -1 || points[neighborIndex].clusterId == -2 {
                points[neighborIndex].clusterId = clusterId
            }
            
            i += 1
            
            if i % 50 == 0 {
                await Task.yield()
            }
        }
    }
    
    // MARK: - Final Color Selection
    private func selectFinalColors(
        clusters: [DBSCANCluster], 
        noisePoints: [ColorPoint], 
        targetColors: Int
    ) async -> [UIColor] {
        
        print("Starting color selection: \(clusters.count) clusters, \(noisePoints.count) noise points, target: \(targetColors)")
        
        var selectedColors: [UIColor] = []
        
        // Step 1: Select outlier colors (30-40% of target)
        let outlierTarget = max(1, Int(Double(targetColors) * 0.35))
        let sortedOutliers = noisePoints
            .sorted { $0.visualImportance > $1.visualImportance }
            .prefix(outlierTarget)
        
        print("Targeting \(outlierTarget) outliers from \(noisePoints.count) noise points")
        for outlier in sortedOutliers {
            let color = outlier.labColor.uiColor
            selectedColors.append(color)
            print("Added outlier: RGB(\(outlier.labColor.originalRGB.r), \(outlier.labColor.originalRGB.g), \(outlier.labColor.originalRGB.b)) importance: \(String(format: "%.3f", outlier.visualImportance))")
        }
        
        print("Selected \(selectedColors.count) outlier colors")
        
        // Step 2: Select cluster representatives
        let remainingTarget = targetColors - selectedColors.count
        print("Need \(remainingTarget) more colors from \(clusters.count) clusters")
        
        if remainingTarget > 0 && !clusters.isEmpty {
            let sortedClusters = clusters.sorted { cluster1, cluster2 in
                let maxImportance1 = cluster1.points.max(by: { $0.visualImportance < $1.visualImportance })?.visualImportance ?? 0
                let maxImportance2 = cluster2.points.max(by: { $0.visualImportance < $1.visualImportance })?.visualImportance ?? 0
                return maxImportance1 > maxImportance2
            }
            
            for (index, cluster) in sortedClusters.enumerated() {
                if selectedColors.count >= targetColors { break }
                
                let color = cluster.representativeColor
                selectedColors.append(color)
                let bestPoint = cluster.points.max(by: { $0.visualImportance < $1.visualImportance })
                print("Added cluster \(index): RGB(\(bestPoint?.labColor.originalRGB.r ?? 0), \(bestPoint?.labColor.originalRGB.g ?? 0), \(bestPoint?.labColor.originalRGB.b ?? 0)) importance: \(String(format: "%.3f", bestPoint?.visualImportance ?? 0))")
            }
        }
        
        print("Total selected colors before deduplication: \(selectedColors.count)")
        return selectedColors
    }
    
    // MARK: - Color Deduplication
    private func deduplicateColors(_ colors: [UIColor]) async -> [UIColor] {
        var deduplicatedColors: [UIColor] = []
        
        print("Input colors for deduplication: \(colors.count)")
        
        for color in colors {
            // Fix: Proper RGB extraction from UIColor
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            
            let colorLAB = AdvancedLABColor(
                r: Int(r * 255),
                g: Int(g * 255),
                b: Int(b * 255)
            )
            
            let isSimilar = deduplicatedColors.contains { existingColor in
                var er: CGFloat = 0, eg: CGFloat = 0, eb: CGFloat = 0, ea: CGFloat = 0
                existingColor.getRed(&er, green: &eg, blue: &eb, alpha: &ea)
                
                let existingLAB = AdvancedLABColor(
                    r: Int(er * 255),
                    g: Int(eg * 255),
                    b: Int(eb * 255)
                )
                return colorLAB.deltaE(existingLAB) < 8.0  // Threshold for similarity
            }
            
            if !isSimilar {
                deduplicatedColors.append(color)
                print("Added unique color: RGB(\(Int(r*255)), \(Int(g*255)), \(Int(b*255)))")
            } else {
                print("Rejected similar color: RGB(\(Int(r*255)), \(Int(g*255)), \(Int(b*255)))")
            }
        }
        
        print("After deduplication: \(deduplicatedColors.count) colors")
        return deduplicatedColors
    }
}

// MARK: - DBSCAN Demo ViewModel
@MainActor
class DBSCANViewModel: ObservableObject {
    @Published var colors: [UIColor] = []
    @Published var progress: Double = 0
    @Published var isExtracting = false
    @Published var currentStage: DBSCANStage = .preprocessing
    @Published var clusterCount = 0
    @Published var outlierCount = 0
    @Published var statusMessage = ""
    
    func extractColors(from image: UIImage, targetColors: Int = 5) {
        Task {
            isExtracting = true
            colors = []
            progress = 0
            clusterCount = 0
            outlierCount = 0
            
            do {
                for try await result in image.extractColorsDBSCAN(targetColors: targetColors) {
                    colors = result.colors
                    progress = result.progress
                    currentStage = result.stage
                    clusterCount = result.clusterCount
                    outlierCount = result.outlierCount
                    
                    switch result.stage {
                    case .preprocessing:
                        statusMessage = "Preprocessing image..."
                    case .buildingHistogram:
                        statusMessage = "Building color histogram..."
                    case .dbscanning(let clusters, let outliers):
                        statusMessage = "DBSCAN: \(clusters) clusters, \(outliers) outliers"
                    case .calculating_importance:
                        statusMessage = "Calculating visual importance..."
                    case .selecting_colors:
                        statusMessage = "Selecting final colors..."
                    case .deduplicating:
                        statusMessage = "Removing similar colors (ΔE<8)..."
                    case .completed:
                        statusMessage = "DBSCAN extraction complete!"
                    }
                    
                    if result.isComplete {
                        isExtracting = false
                        break
                    }
                }
            } catch {
                print("DBSCAN extraction failed: \(error)")
                statusMessage = "Extraction failed"
                isExtracting = false
            }
        }
    }
}

// MARK: - DBSCAN Demo View
struct DBSCANColorExtractor: View {
    @StateObject private var viewModel = DBSCANViewModel()
    @State private var targetColors: Double = 5
    
    var body: some View {
        VStack(spacing: 20) {
            Text("DBSCAN Color Extractor")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
            
            VStack(spacing: 4) {
                Text("✓ Outlier Protection • ✓ Visual Importance • ✓ No Area Bias")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("Preserves Small High-Contrast Colors")
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
                        
                        switch viewModel.currentStage {
                        case .dbscanning(let clusters, let outliers):
                            Text("\(clusters) clusters, \(outliers) outliers")
                                .font(.caption)
                                .foregroundColor(.blue)
                        case .calculating_importance:
                            Text("Uniqueness + Contrast + Saturation")
                                .font(.caption)
                                .foregroundColor(.orange)
                        case .deduplicating:
                            Text("ΔE < 8.0 threshold")
                                .font(.caption)
                                .foregroundColor(.purple)
                        default:
                            Text("Processing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
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
                        Text(viewModel.isExtracting ? "Extracting..." : "Extract Colors (DBSCAN)")
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
            let image = UIImage(resource: .glass)
            viewModel.extractColors(from: image, targetColors: Int(targetColors))
        }
    }
}

#Preview {
    DBSCANColorExtractor()
}
