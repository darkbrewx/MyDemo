//
//  ImageData.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/06.
//

import Foundation

struct ImageData: Identifiable {
    let id: UUID
    let url: URL
    var caption: String = "Beautiful Image 🌟"
    let aspectRatio: CGFloat
}

extension ImageData {
    static var mock: [ImageData] {
        (1...30).map { index in
            let width = CGFloat.random(in: 200...400)
            let height = CGFloat.random(in: 150...600)
            return ImageData(
                id: UUID(),
//                url: URL(string: "https://picsum.photos/\(Int(width))/\(Int(height))")!,
                url: URL(string: "https://github.com/onevcat/Flower-Data-Set/raw/master/rose/rose-\(Int.random(in: 1...500)).jpg")!,
                caption: randomCaption(),
                aspectRatio: width / height
            )
        }
    }

    private static func randomCaption() -> String {
        let captions = [
            "Stunning View 🌄",
            "Nature's Beauty 🌿",
            "City Lights 🌆",
            "Ocean Waves 🌊",
            "Mountain Peaks 🏔️",
            "Serene Landscape 🌅",
            "Urban Jungle 🌃",
            "Golden Hour Glow 🌇",
            "Tranquil Waters 🌊"
        ]
        return captions.randomElement() ?? "Beautiful Image 🌟"
    }
}

