//
//  DownsizedImageView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/12.
//

import SwiftUI

struct DownsizedImageView<Content: View>: View {
    @State private var image: UIImage?
    @State private var imageURL: URL?
    private var scale: CGFloat = UIScreen.main.scale
    // Target size in pixels
    private var pixelSize: CGSize

    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    @ViewBuilder var content: (Image) -> Content
    @State private var downsizedImageView: Image?
    var body: some View {
        ZStack {
            if let downsizedImageView {
                content(downsizedImageView)
            }
        }
        // SwiftUI's .task modifier provides structured concurrency with automatic cancellation
        // when the view disappears, eliminating the need for manual Task management
        .task {
            guard downsizedImageView == nil else { return }
            await createDownsizedImage()
        }
    }

    private func createDownsizedImage() async {
        if let image {
            await createDownsizedImageByUIImage(image)
        } else if let imageURL {
            await createDownsizedImageByImageIO(filePath: imageURL)
        }
    }

    private func createDownsizedImageByUIImage(_ image: UIImage?) async {
        guard let image else { return }

        // Force image processing to background thread to prevent main thread blocking
        let resizedImage = await Task.detached(priority: .userInitiated) {
            let aspectSize = image.size.aspectFit(pixelSize)
            
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            let render = UIGraphicsImageRenderer(size: aspectSize, format: format)
            return render.image { context in
                image.draw(in: .init(origin: .zero, size: aspectSize))
            }
        }.value
        
        // Cooperative cancellation check - allows task to be cancelled gracefully
        // when parent view is deallocated or task context is cancelled
        guard !Task.isCancelled else { return }
        
        await MainActor.run {
            downsizedImageView = .init(uiImage: resizedImage)
        }
    }

    private func createDownsizedImageByImageIO(filePath: URL?) async {
        guard let filePath else { return }
        if filePath.isFileURL {
            await createDownsizedImageFromFilePath(filePath: filePath)
        } else {
            await createDownsizedImageFromNetwork(url: filePath)
        }
    }

    private func createDownsizedImageFromFilePath(filePath: URL?) async {
        guard let filePath else { return }
        
        // Use CGImageSourceCreateWithURL to avoid loading original image into memory
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(filePath as CFURL, imageSourceOptions) else { return }
        
        await downsampleAndUpdate(imageSource)
    }
    
    private func createDownsizedImageFromNetwork(url: URL) async {
        guard let imageSource = await downloadAndCreateImageSource(url) else { return }
        await downsampleAndUpdate(imageSource)
    }
    
    // Data will be released when function returns
    private func downloadAndCreateImageSource(_ url: URL) async -> CGImageSource? {
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        
        // Check cancellation after network download to avoid unnecessary processing
        guard !Task.isCancelled else { return nil }
        
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        return CGImageSourceCreateWithData(data as CFData, imageSourceOptions)
    }
    
    private func downsampleAndUpdate(_ imageSource: CGImageSource) async {
        let maxDimensionInPixels = max(pixelSize.width, pixelSize.height)
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ]
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions as CFDictionary) else { return }
        
        // Final cancellation check before UI update to prevent stale results
        guard !Task.isCancelled else { return }
        
        await MainActor.run {
            downsizedImageView = Image(uiImage: UIImage(cgImage: downsampledImage))
        }
    }
}

extension DownsizedImageView {

    init(image: UIImage?, pixelSize: CGSize, scale: CGFloat = UIScreen.main.scale, @ViewBuilder content: @escaping (Image) -> Content) {
        self.image = image
        self.pixelSize = pixelSize
        self.scale = scale
        self.content = content
    }

    init(imageURL: URL?, pixelSize: CGSize, @ViewBuilder content: @escaping (Image) -> Content) {
        self.imageURL = imageURL
        self.pixelSize = pixelSize
        self.content = content
    }
}

extension CGSize {
    func aspectFit(_ to: CGSize) -> CGSize {
        let scaleX = to.width / self.width
        let scaleY = to.height / self.height
        let aspectRatio = min(scaleX, scaleY)
        return .init(width: aspectRatio * width, height: aspectRatio * height)
    }
}

