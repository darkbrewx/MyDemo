//
//  MovableCardsDemo.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/20.
//

import SwiftUI
import CoreData

struct MovableCardsDemo: View {
    @StateObject private var dragProperties: DragProperties = DragProperties()
    var body: some View {
        NavigationStack {
            MovableCardsView()
                .navigationTitle("Flash Cards")
                .navigationBarTitleDisplayMode(.inline)
        }
        .overlay(alignment: .topLeading) {
            // when in the drag state, and the preview image is set, show the preview image
            if let previewImage = dragProperties.previewImage, dragProperties.isShow {
                Image(uiImage: previewImage)
                    .opacity(0.8)
                    // postion: initial position + offset
                    .offset(x: dragProperties.initialViewLocation.x, y: dragProperties.initialViewLocation.y)
                    .offset(dragProperties.dragOffset)
                    .ignoresSafeArea()
            }
        }
        .environmentObject(dragProperties)
    }
}

#Preview {
    MovableCardsDemo()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
