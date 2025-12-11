//
//  ScreenshotView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/12/11.
//

import SwiftUI

struct ScreenshotView: View {
    var content: [ImageResource] = []
    var offset: CGFloat = 0
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 10) {
                ForEach(content.indices, id: \.self) { index in
                    Image(content[index])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .offset(y: offset)
        }
        .scrollDisabled(true)
        .scrollIndicators(.hidden)
        .rotationEffect(Angle(degrees: -30), anchor: .bottom)
        // Disable clipping to show content outside bounds
        .scrollClipDisabled()
    }
}

#Preview {
    ScreenshotView()
}
