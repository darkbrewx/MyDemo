//
//  UIImage+ColorExtract.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/18.
//

import UIKit
import SwiftUI

extension UIImage {
    var aspectRatio: CGFloat {
        return self.size.height / self.size.width
    }

    // create a down sized image to speed up color extraction
    func downSized(width: CGFloat, height: CGFloat) async -> UIImage {
        let size = CGSize(width: width, height: height * aspectRatio)

        let renderer = UIGraphicsImageRenderer(size: size)
        let downSizedImage = renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
        return downSizedImage
    }

    // get pixel data from CGImage
    private func getPixelData(cgImage: CGImage) async throws -> [PixelData] {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8

        // allocate memory for pixel data
        // size = height * width * bytesPerPixel(32 bits / 1 pixel)
        guard let data = calloc(height * width, MemoryLayout<UInt32>.size) else {
            throw NSError(domain: "UIImageColorExtractionError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Memory allocation failed"])
        }

        // ensure memory is freed after use
        defer { free(data) }

        // create a bitmap graphics context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        // create CGContext, and save pixel data in data we just allocated
        guard let contenxt = CGContext(
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

        // draw the image into the context
        contenxt.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        // binding the data to UInt8 type, to access pixel data
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

    func extractColors(colorCount: Int) async throws -> [UIColor] {
        guard self.cgImage != nil else {
            throw NSError(domain: "UIImageColorExtractionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }
        // get down sized image, or it will cost too much time
        let downSizedImage = await downSized(width: 100, height: 100)

        guard let cgImage = downSizedImage.cgImage else {
            throw NSError(domain: "UIImageColorExtractionError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage"])
        }

        // get pixel data from CGImage
        let pixelData = try await getPixelData(cgImage: cgImage)

        let clusters = await kMeansClustering(pixels: pixelData, colorCount: colorCount)
        let colors = clusters.map { cluster in
            let center = cluster.center
            return UIColor(
                red: center.red / 255.0,
                green: center.green / 255.0,
                blue: center.blue / 255.0,
                alpha: 1.0
            )
        }

        return colors.sorted {
            var h1: CGFloat = 0, s1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            var h2: CGFloat = 0, s2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            $0.getHue(&h1, saturation: &s1, brightness: &b1, alpha: &a1)
            $1.getHue(&h2, saturation: &s2, brightness: &b2, alpha: &a2)
            return h1 < h2
        }
    }

    private struct PixelData {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
    }

    private struct Cluster {
        var center: PixelData
        var points: [PixelData]
    }

    private func kMeansClustering(
        pixels: [PixelData],
        colorCount: Int,
        maxIterations: Int = 10) async -> [Cluster]
    {
        print("pixels count: \(pixels.count)")
        var clusters = [Cluster]()
        // create colorCount number of clusters
        for _ in 0..<colorCount {
            // randomly select a pixel as the initial cluster center
            if let randomPixel = pixels.randomElement() {
                clusters.append(Cluster(center: randomPixel, points: []))
            }
        }

        // perform k-means clustering
        for _ in 0..<maxIterations {
            // clear points in each cluster before each iteration
            for clusterIndex in 0 ..< clusters.count {
                clusters[clusterIndex].points.removeAll()
            }

            // find the closest cluster center for each pixel
            // closest: most similar color(R, G, B) as cluster center
            for pixel in pixels {
                // get a greatest finite float number as initial distance
                var minDistance = CGFloat.greatestFiniteMagnitude
                // find the closest cluster center
                var closestClusterIndex = 0
                // iterate the clusters to find the closest cluster center
                for (index, cluster) in clusters.enumerated() {
                    // calculate the distance between the pixel and the cluster center
                    let distance = euclideanDistance(pixel1: pixel, pixel2: cluster.center)
                    // save the closest cluster index
                    if distance < minDistance {
                        minDistance = distance
                        closestClusterIndex = index
                    }
                }
                // add the every pixel to the closest cluster
                clusters[closestClusterIndex].points.append(pixel)
            }

            for clusterIndex in 0 ..< clusters.count {
                let cluster = clusters[clusterIndex]
                if cluster.points.isEmpty { continue }
                // unfold the points, and calculate calculate sum(R, G, B) for each cluster
                let sum = cluster.points.reduce(
                    PixelData(red: 0, green: 0, blue: 0)
                ) { (result, pixel) in
                    return PixelData(
                        red: result.red + pixel.red,
                        green: result.green + pixel.green,
                        blue: result.blue + pixel.blue
                    )
                }
                // calculate the average color for the cluster center as the extracted color
                let count = CGFloat(cluster.points.count)
                clusters[clusterIndex].center = PixelData(
                    red: sum.red / count,
                    green: sum.green / count,
                    blue: sum.blue / count
                )
            }
        }
        return clusters
    }

    private func euclideanDistance(pixel1: PixelData, pixel2: PixelData) -> CGFloat {
        let dr = pixel1.red - pixel2.red
        let dg = pixel1.green - pixel2.green
        let db = pixel1.blue - pixel2.blue
        return sqrt(dr * dr + dg * dg + db * db)
    }
}


struct ColorExtractor: View {
    @State private var colors: [UIColor] = []
    var body: some View {
        VStack {
            Image(.reflect)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .onAppear {
                    print("Extracting colors...")
                    Task {
                        let uiimage = UIImage(resource: .reflect)
                        colors = try! await uiimage.extractColors(colorCount: 5)
                    }
                }
            if !colors.isEmpty {
                HStack {
                    ForEach(colors, id: \.self) { color in
                        let hexString = color.toHexString()
                        VStack {
                            Rectangle()
                                .fill(Color(color))
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)
                            Text(hexString)
                        }
                    }
                }
            }
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
    ColorExtractor()
}
