//
//  TitleTextRenderer.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/17.
//

import SwiftUI

struct TitleTextRenderer: TextRenderer, Animatable {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
        // layout -> line -> runs = [runSlices]
        // get slices from layout
        let slices = layout.flatMap({ $0 }).flatMap({ $0 })

        for (index, slice) in slices.enumerated() {
            // calculate the progress for each slice
            let sliceProgressIndex = CGFloat(slices.count) * progress
            let sliceProgress = max(min(sliceProgressIndex / CGFloat(index + 1), 1), 0)

            ctx.addFilter(.blur(radius: 5 - (sliceProgress * 5)))
            ctx.opacity = sliceProgress
            ctx.translateBy(x: 0, y: 5 - (5 * sliceProgress))
            ctx.draw(slice, options: .disablesSubpixelQuantization)
        }
    }
}
