//
//  FlashCardView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/20.
//

import SwiftUI

struct FlashCardView: View {
    var card: FlashCard
    var category: Category

    @EnvironmentObject private var dragProperties: DragProperties
    @Environment(\.managedObjectContext) private var context
    @GestureState private var isActive: Bool = false
    @State private var haptics: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let rect = proxy.frame(in: .global)
            let isSwappingInSameGroup = rect.contains(dragProperties.dragLocation) && dragProperties.destinationCategory == nil && dragProperties.sourceCard != card

            cardContent(rect: rect)
                .simultaneousGesture(dragProperties.isInScrolling ? nil : customGesture(rect: rect))
                .onChange(of: isSwappingInSameGroup) { oldValue, newValue in
                    // observe the swapping state, when changing to true, swap the cards
                    if newValue && dragProperties.sourceCategory == category {
                        dragProperties.swapCardsInSameGroup(card)
                    }
                }
        }
        .frame(height: 60)
        .opacity(dragProperties.sourceCard == card ? 0 : 1)
        .onChange(of: isActive) { oldValue, newValue in
            if newValue {
                haptics.toggle()
            }
        }
        .sensoryFeedback(.impact, trigger: haptics)
    }

    private func customGesture(rect: CGRect) -> some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            // make sure the minimum distance is 0, to keep sure the onEnded call back can be fired properly
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .updating($isActive) { value, state, _ in
                state = true
            }
            .onChanged { value in
                // handle second(DragGesture) gesture
                if case .second(_, let dragValue) = value {
                    handleGestureChange(dragValue, rect: rect)
                } else {
                    // otherwise fire the ended callback
                    handleGestureEnd()
                }
            }
            .onEnded { value in
                handleGestureEnd()
            }
    }

    private func handleGestureChange(_ gesture: DragGesture.Value?, rect: CGRect) {
        // Step 1: create a preview image of dragging view
        if dragProperties.previewImage == nil {
            dragProperties.isShow = true
            dragProperties.previewImage = createPreviewImage(rect: rect)
            dragProperties.sourceCard = card
            dragProperties.sourceCategory = category
            dragProperties.initialViewLocation = rect.origin
        }

        // update gesture value
        guard let gesture else { return }

        // update gesture state
        dragProperties.dragOffset = gesture.translation
        dragProperties.dragLocation = gesture.location

        // if card swapped, card's display order will be changed accordly, save the new location
        // if no swapping occurs, will equal to the initial view location
        dragProperties.updatedViewLocation = rect.origin
    }

    private func handleGestureEnd() {
        withAnimation(.easeInOut(duration: 0.25), completionCriteria: .logicallyComplete) {
            if dragProperties.destinationCategory != nil {
                // change the card to a new group
                dragProperties.changeGroup(context)
            } else {
                // if swapping occurs, update initial view location to new location
                // make overlay image can find the new location, or the animation will be incorrect
                if dragProperties.updatedViewLocation != .zero && dragProperties.initialViewLocation != dragProperties.updatedViewLocation {
                    dragProperties.initialViewLocation = dragProperties.updatedViewLocation
                }
                dragProperties.dragOffset = .zero
            }
        } completion: {
            // if cards swapped in the same group, save context when the drag ends
            if dragProperties.isCardsSwapped {
                try? context.save()
            }
            dragProperties.resetAllProperties()
        }
    }

    private func cardContent(rect: CGRect) -> some View {
        Text(card.title ?? "")
            .padding(.horizontal, 15)
            .frame(width: rect.width, height: rect.height, alignment: .leading)
            .background(Color.black.opacity(0.1), in: .rect(cornerRadius: 10))
    }

    private func createPreviewImage(rect: CGRect) -> UIImage? {
        // create a preview image for dragging effect
        let view = HStack {
            cardContent(rect: rect)
        }

        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale

        return renderer.uiImage
    }
}

#Preview {
    MovableCardsDemo()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
