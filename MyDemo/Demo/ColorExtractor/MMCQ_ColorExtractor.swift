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

// MARK: - LAB Color Space Support
struct LABColor {
    let L: Double  // Lightness (0-100)
    let A: Double  // Green-Red axis (-128 to +127)
    let B: Double  // Blue-Yellow axis (-128 to +127)
    
    init(L: Double, A: Double, B: Double) {
        self.L = L
        self.A = A
        self.B = B
    }
    
    // Convert from RGB to LAB
    init(red: Int, green: Int, blue: Int) {
        // First convert RGB to XYZ
        let r = Double(red) / 255.0
        let g = Double(green) / 255.0
        let b = Double(blue) / 255.0
        
        // Gamma correction
        let rLinear = r > 0.04045 ? pow((r + 0.055) / 1.055, 2.4) : r / 12.92
        let gLinear = g > 0.04045 ? pow((g + 0.055) / 1.055, 2.4) : g / 12.92
        let bLinear = b > 0.04045 ? pow((b + 0.055) / 1.055, 2.4) : b / 12.92
        
        // Convert to XYZ (D65 illuminant)
        let x = rLinear * 0.4124564 + gLinear * 0.3575761 + bLinear * 0.1804375
        let y = rLinear * 0.2126729 + gLinear * 0.7151522 + bLinear * 0.0721750
        let z = rLinear * 0.0193339 + gLinear * 0.1191920 + bLinear * 0.9503041
        
        // Normalize by reference white (D65)
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
    
    // Calculate Delta-E (CIE76) - perceptual color difference
    func deltaE(_ other: LABColor) -> Double {
        let deltaL = self.L - other.L
        let deltaA = self.A - other.A
        let deltaB = self.B - other.B
        return sqrt(deltaL * deltaL + deltaA * deltaA + deltaB * deltaB)
    }
    
    // Convert back to UIColor
    var uiColor: UIColor {
        // Convert LAB to XYZ
        let fy = (L + 16.0) / 116.0
        let fx = A / 500.0 + fy
        let fz = fy - B / 200.0
        
        let x = fx > 0.206897 ? pow(fx, 3) : (fx - 16.0/116.0) / 7.787
        let y = fy > 0.206897 ? pow(fy, 3) : (fy - 16.0/116.0) / 7.787
        let z = fz > 0.206897 ? pow(fz, 3) : (fz - 16.0/116.0) / 7.787
        
        // Denormalize
        let xDenorm = x * 0.95047
        let yDenorm = y * 1.00000
        let zDenorm = z * 1.08883
        
        // Convert XYZ to RGB
        let r = xDenorm * 3.2404542 + yDenorm * -1.5371385 + zDenorm * -0.4985314
        let g = xDenorm * -0.9692660 + yDenorm * 1.8760108 + zDenorm * 0.0415560
        let b = xDenorm * 0.0556434 + yDenorm * -0.2040259 + zDenorm * 1.0572252
        
        // Gamma correction and clamping
        let rGamma = max(0, min(1, r > 0.0031308 ? 1.055 * pow(r, 1.0/2.4) - 0.055 : 12.92 * r))
        let gGamma = max(0, min(1, g > 0.0031308 ? 1.055 * pow(g, 1.0/2.4) - 0.055 : 12.92 * g))
        let bGamma = max(0, min(1, b > 0.0031308 ? 1.055 * pow(b, 1.0/2.4) - 0.055 : 12.92 * b))
        
        return UIColor(red: CGFloat(rGamma), green: CGFloat(gGamma), blue: CGFloat(bGamma), alpha: 1.0)
    }
}

// MARK: - Enhanced Color Structures
struct EnhancedColor {
    let uiColor: UIColor
    let labColor: LABColor
    let frequency: Int
    var uniqueness: Double = 0.0
    var visualImportance: Double = 0.0
    
    init(r: Int, g: Int, b: Int, frequency: Int) {
        self.uiColor = UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1.0)
        self.labColor = LABColor(red: r, green: g, blue: b)
        self.frequency = frequency
    }
    
    // Calculate uniqueness based on distance to other colors
    mutating func calculateUniqueness(among colors: [EnhancedColor]) {
        let distances = colors.compactMap { other in
            other.uiColor != self.uiColor ? self.labColor.deltaE(other.labColor) : nil
        }
        self.uniqueness = distances.isEmpty ? 0 : distances.min() ?? 0
    }
    
    // Calculate visual importance (frequency + uniqueness + contrast)
    mutating func calculateVisualImportance() {
        let frequencyScore = log(Double(frequency + 1)) / 10.0  // Normalized frequency
        let uniquenessScore = min(uniqueness / 30.0, 1.0)       // More sensitive to uniqueness
        let lightnessBonus = abs(labColor.L - 50) / 50.0        // Contrast from neutral gray
        let saturationBonus = abs(labColor.A) + abs(labColor.B)  // Color saturation
        let normalizedSaturation = min(saturationBonus / 100.0, 1.0)
        
        // Reduce frequency weight, increase uniqueness weight
        self.visualImportance = frequencyScore * 0.2 + uniquenessScore * 0.5 + lightnessBonus * 0.15 + normalizedSaturation * 0.15
    }
}

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
    case detectingOutliers
    case mergingColors
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
                    
                    // Stage 3: Enhanced MMCQ Algorithm
                    let finalColors = await performEnhancedMMCQ(
                        histogram: histogram,
                        targetColors: targetColors,
                        progressCallback: { iteration, totalBoxes in
                            let progress: Double
                            let stage: MMCQStage
                            
                            if iteration == 0 && totalBoxes == 0 {
                                // Outlier detection phase
                                progress = 0.7
                                stage = .detectingOutliers
                            } else if iteration == -1 {
                                // Merging phase
                                progress = 0.8
                                stage = .mergingColors
                            } else {
                                // Regular median cut
                                progress = 0.3 + (0.4 * Double(totalBoxes) / Double(targetColors))
                                stage = .medianCut(iteration: iteration, totalBoxes: totalBoxes)
                            }
                            
                            continuation.yield(MMCQResult(
                                colors: [],
                                progress: progress,
                                stage: stage,
                                colorBoxCount: totalBoxes,
                                isComplete: false
                            ))
                        }
                    )
                    
                    // Stage 4: Final processing
                    continuation.yield(MMCQResult(
                        colors: finalColors,
                        progress: 0.9,
                        stage: .extractingColors,
                        colorBoxCount: finalColors.count,
                        isComplete: false
                    ))
                    
                    // Stage 5: Complete
                    continuation.yield(MMCQResult(
                        colors: finalColors,
                        progress: 1.0,
                        stage: .completed,
                        colorBoxCount: finalColors.count,
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
    
    // MARK: - Intelligent Color Processing
    
    // Smart color merging using LAB color space
    private func mergeColors(_ colors: [EnhancedColor], threshold: Double = 10.0) -> [EnhancedColor] {
        var mergedColors = [EnhancedColor]()
        var processedIndices = Set<Int>()
        
        for (i, color) in colors.enumerated() {
            if processedIndices.contains(i) { continue }
            
            var mergeGroup = [color]
            processedIndices.insert(i)
            
            // Find similar colors to merge
            for (j, otherColor) in colors.enumerated() {
                if i != j && !processedIndices.contains(j) {
                    let deltaE = color.labColor.deltaE(otherColor.labColor)
                    if deltaE < threshold {
                        mergeGroup.append(otherColor)
                        processedIndices.insert(j)
                    }
                }
            }
            
            // Create merged color
            if mergeGroup.count == 1 {
                mergedColors.append(mergeGroup[0])
            } else {
                let mergedColor = createMergedColor(from: mergeGroup)
                mergedColors.append(mergedColor)
            }
        }
        
        return mergedColors
    }
    
    // Create a merged color from multiple similar colors
    private func createMergedColor(from colors: [EnhancedColor]) -> EnhancedColor {
        let totalFrequency = colors.reduce(0) { $0 + $1.frequency }
        
        // Weighted average in LAB space
        var totalL: Double = 0, totalA: Double = 0, totalB: Double = 0
        var totalWeight = 0
        
        for color in colors {
            let weight = color.frequency
            totalL += color.labColor.L * Double(weight)
            totalA += color.labColor.A * Double(weight)
            totalB += color.labColor.B * Double(weight)
            totalWeight += weight
        }
        
        let avgL = totalL / Double(totalWeight)
        let avgA = totalA / Double(totalWeight)
        let avgB = totalB / Double(totalWeight)
        
        let mergedLab = LABColor(L: avgL, A: avgA, B: avgB)
        let mergedUIColor = mergedLab.uiColor
        
        // Extract RGB components
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        mergedUIColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return EnhancedColor(
            r: Int(r * 255),
            g: Int(g * 255),
            b: Int(b * 255),
            frequency: totalFrequency
        )
    }
    
    // Detect outlier colors that should be preserved
    private func detectOutlierColors(_ colors: [EnhancedColor]) -> [EnhancedColor] {
        guard colors.count > 3 else { return colors }
        
        var outliers = [EnhancedColor]()
        
        // Sort by uniqueness (visual distinctiveness) instead of frequency
        for color in colors {
            // Calculate minimum distance to all other colors
            let distances = colors.compactMap { other in
                other.uiColor != color.uiColor ? color.labColor.deltaE(other.labColor) : nil
            }
            
            guard let minDistance = distances.min() else { continue }
            
            // If this color is visually distinct, it's an outlier worth keeping
            // Lower threshold = more outliers detected
            if minDistance > 10.0 {
                outliers.append(color)
            }
        }
        
        // Sort outliers by their uniqueness (most unique first)
        return outliers.sorted { color1, color2 in
            let dist1 = colors.compactMap { other in
                other.uiColor != color1.uiColor ? color1.labColor.deltaE(other.labColor) : nil
            }.min() ?? 0
            
            let dist2 = colors.compactMap { other in
                other.uiColor != color2.uiColor ? color2.labColor.deltaE(other.labColor) : nil  
            }.min() ?? 0
            
            return dist1 > dist2
        }
    }
    
    // Enhanced MMCQ with dual-phase extraction
    private func performEnhancedMMCQ(
        histogram: [ColorKey: Int],
        targetColors: Int,
        progressCallback: @escaping (Int, Int) -> Void
    ) async -> [UIColor] {
        
        // Convert all colors to enhanced format
        let allColors = histogram.map { (key, frequency) in
            EnhancedColor(r: key.r, g: key.g, b: key.b, frequency: frequency)
        }
        
        // Phase 1: Find the most unique/distinct colors first (outliers)
        // Report outlier detection phase
        await MainActor.run {
            progressCallback(0, 0)  // Special signal for outlier detection
        }
        
        let outliers = detectOutlierColors(allColors)
        var finalColorSet = [EnhancedColor]()
        
        // Add the most unique colors first (up to half of target)
        let outlierCount = min(outliers.count, targetColors / 2)
        finalColorSet.append(contentsOf: outliers.prefix(outlierCount))
        
        // Phase 2: Use MMCQ for remaining dominant colors
        let remainingTarget = targetColors - finalColorSet.count
        if remainingTarget > 0 {
            let dominantBoxes = await performMMCQ(
                histogram: histogram,
                targetColors: remainingTarget + 2, // Extract a few extra
                progressCallback: progressCallback
            )
            
            // Convert to enhanced colors
            let dominantColors = dominantBoxes.compactMap { box -> EnhancedColor? in
                guard !box.histogram.isEmpty else { return nil }
                
                // Use average color of the box
                var totalR = 0, totalG = 0, totalB = 0, totalCount = 0
                for (colorKey, count) in box.histogram {
                    totalR += colorKey.r * count
                    totalG += colorKey.g * count
                    totalB += colorKey.b * count
                    totalCount += count
                }
                
                guard totalCount > 0 else { return nil }
                
                return EnhancedColor(
                    r: totalR / totalCount,
                    g: totalG / totalCount,
                    b: totalB / totalCount,
                    frequency: totalCount
                )
            }
            
            // Add dominant colors that are different from outliers
            for dominant in dominantColors {
                let minDistance = finalColorSet.map {
                    dominant.labColor.deltaE($0.labColor)
                }.min() ?? Double.infinity
                
                if minDistance > 10.0 { // Not too similar to existing colors
                    finalColorSet.append(dominant)
                    if finalColorSet.count >= targetColors { break }
                }
            }
        }
        
        // Phase 3: Calculate uniqueness and importance for all colors
        var enhancedColors = finalColorSet
        for i in 0..<enhancedColors.count {
            enhancedColors[i].calculateUniqueness(among: enhancedColors)
            enhancedColors[i].calculateVisualImportance()
        }
        
        // Report merging phase  
        await MainActor.run {
            progressCallback(-1, 0)  // Special signal for merging
        }
        
        // Phase 4: Merge similar colors
        // Use a more conservative threshold to avoid over-merging
        print("Before merging: \(enhancedColors.count) colors")
        let mergedColors = mergeColors(enhancedColors, threshold: 8.0)
        print("After merging: \(mergedColors.count) colors")
        
        // Phase 5: Sort by visual importance and return top colors
        var finalColors = mergedColors
            .sorted { $0.visualImportance > $1.visualImportance }
            .prefix(targetColors)
            .map { $0.uiColor }
        print("Final colors count: \(finalColors.count)")
        
        // Ensure we have at least the requested number of colors
        // If not enough after merging, add back some original colors
        if finalColors.count < targetColors {
            let additionalColors = allColors
                .sorted { $0.frequency > $1.frequency }
                .compactMap { enhancedColor -> UIColor? in
                    let isUnique = finalColors.allSatisfy { existingColor in
                        enhancedColor.labColor.deltaE(LABColor(red: Int(existingColor.cgColor.components?[0] ?? 0 * 255), 
                                                             green: Int(existingColor.cgColor.components?[1] ?? 0 * 255), 
                                                             blue: Int(existingColor.cgColor.components?[2] ?? 0 * 255))) > 8.0
                    }
                    return isUnique ? enhancedColor.uiColor : nil
                }
                .prefix(targetColors - finalColors.count)
            
            finalColors.append(contentsOf: additionalColors)
        }
        
        return Array(finalColors)
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
            let currentIteration = iteration
            let currentBoxCount = colorBoxes.count
            await MainActor.run {
                progressCallback(currentIteration, currentBoxCount)
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
                    case .medianCut(_, let totalBoxes):
                        statusMessage = "Median cut: \(totalBoxes) color regions"
                    case .detectingOutliers:
                        statusMessage = "Detecting unique outlier colors..."
                    case .mergingColors:
                        statusMessage = "Merging similar colors (LAB ΔE<12)..."
                    case .extractingColors:
                        statusMessage = "Ranking by visual importance..."
                    case .completed:
                        statusMessage = "Enhanced MMCQ complete!"
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
            Text("Enhanced MMCQ Extractor")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
            
            VStack(spacing: 4) {
                Text("✓ LAB Color Space • ✓ Delta-E Merging • ✓ Outlier Detection")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("Solves: Similar Colors & Missing Outliers")
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
                        case .medianCut(_, let totalBoxes):
                            Text("\(totalBoxes) regions")
                                .font(.caption)
                                .foregroundColor(.blue)
                        case .detectingOutliers:
                            Text("Finding outliers")
                                .font(.caption)
                                .foregroundColor(.orange)
                        case .mergingColors:
                            Text("LAB ΔE merging")
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
