//
//  DragProperties.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/20.
//

import Foundation
import UIKit
import CoreData

class DragProperties: ObservableObject {
    // MARK: Drag Preview Properties
    @Published var isShow: Bool = false
    // create a card's screen shot image, to achieve the drag preview
    @Published var previewImage: UIImage?
    @Published var initialViewLocation: CGPoint = .zero
    // when swapping cards, need to update the view location to make gesture ending animation smooth
    @Published var updatedViewLocation: CGPoint = .zero

    // MARK: Drag Gesture Properties
    @Published var dragOffset: CGSize = .zero
    @Published var dragLocation: CGPoint = .zero

    // MARK: Grouping And Section RE-Ordering
    @Published var sourceCard: FlashCard?
    @Published var sourceCategory: Category?
    @Published var destinationCategory: Category?
    @Published var isCardsSwapped: Bool = false

    @Published var isInScrolling: Bool = false

    func changeGroup(_ context: NSManagedObjectContext) {
        guard let sourceCard, let destinationCategory else { return }
        // move the card to the new category, and update its order
        let sourceCardOrder = sourceCard.order
        sourceCard.order = Int32(destinationCategory.cards?.count ?? 0)
        sourceCard.category = destinationCategory
        // update the souce category's cards' order, due to a card is removed
        let _ = sourceCategory?.cards?.map { card in
            if let card = card as? FlashCard, card.order > sourceCardOrder {
                card.order -= 1
            }
        }
        // save the changing
        try? context.save()
        // reset the drag properties
        resetAllProperties()
    }

    // Swap cards' order in the same category
    func swapCardsInSameGroup(_ destinationCard: FlashCard) {
        guard let sourceCard else { return }
        let sourceOrder = sourceCard.order
        let destinationOrder = destinationCard.order

        sourceCard.order = destinationOrder
        destinationCard.order = sourceOrder
        isCardsSwapped = true
    }

    // Reset's all properties
    func resetAllProperties() {
        print("reset")
        isShow = false
        previewImage = nil
        initialViewLocation = .zero
        updatedViewLocation = .zero
        dragOffset = .zero
        dragLocation = .zero
        sourceCard = nil
        sourceCategory = nil
        destinationCategory = nil
        isCardsSwapped = false
    }
}
