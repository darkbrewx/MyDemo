//
//  DownsizedImageViewDemo.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/13.
//

import SwiftUI

struct DownsizedImageViewDemo: View {
    let fileURL = URL(string: "https://github.com/darkbrewx/MyResources/blob/main/jpg/star-huge.jpg?raw=true")
    @State private var imageData: Data? = nil
    var body: some View {
        NavigationStack {
            VStack {
                // reminder: target size is pixel, not point.
                let pixelSize = CGSize(width: 450, height: 450)
                DownsizedImageView(image: UIImage(resource: .starHuge), pixelSize: pixelSize) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(.rect(cornerRadius: 10))
                }
                DownsizedImageView(imageURL: fileURL, pixelSize: pixelSize) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(.rect(cornerRadius: 10))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle("DownsizedImageViewDemo")
    }
}

#Preview {
    DownsizedImageViewDemo()
}
