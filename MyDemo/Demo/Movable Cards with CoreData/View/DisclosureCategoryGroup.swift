//
//  CustomDisclosureGroup.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/20.
//

import SwiftUI

struct DisclosureCategoryGroup: View {
    init(category: Category) {
        self.category = category

        // create a sort descriptor to sort flash cards by their order
        let descriptor = [
            NSSortDescriptor(keyPath: \FlashCard.order, ascending: true)
        ]
        // filter by the given category
        let predicate = NSPredicate(format: "category == %@", category)
        _cards = .init(
            entity: FlashCard.entity(),
            sortDescriptors: descriptor,
            predicate: predicate,
            animation: .easeInOut(duration: 0.15)
        )
    }
    var category: Category
    @FetchRequest private var cards: FetchedResults<FlashCard>
    @State private var isExpanded: Bool = true
    @State private var gestureRect: CGRect = .zero
    @EnvironmentObject private var dragProperties: DragProperties

    var body: some View {
        // detect if the drag gesture is going to drop on this group
        let isDropping = gestureRect.contains(dragProperties.dragLocation) && dragProperties.isShow && dragProperties.sourceCategory != category
        VStack(alignment: .leading, spacing: 10) {
            groupHeader
            if isExpanded {
                groupContent()
                    .transition(.blurReplace)
            }
        }
        .padding(15)
        .padding(.vertical, isExpanded ? 0 : 5)
        .animation(.easeInOut(duration: 0.2)) { content in
            content
                .background(isDropping ? Color.blue.opacity(0.1) : Color .gray.opacity(0.1))
        }
        .clipShape(.rect(cornerRadius: 10))
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.snappy) {
                isExpanded.toggle()
            }
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { newValue in
            gestureRect = newValue
        }
        .onChange(of: isDropping) { oldValue, newValue in
            // save the current category to the drag properties when dropping
            dragProperties.destinationCategory = newValue ? category : nil
        }
    }

    var groupHeader: some View {
        HStack {
            Text(category.title ?? "New Folder")
            Spacer(minLength: 0)
            Image(systemName: "chevron.down")
                .rotationEffect(Angle(degrees: isExpanded ? 0 : 180))
        }
        .font(.callout)
        .fontWeight(.semibold)
        .foregroundStyle(.mainBackground1)
    }

    @ViewBuilder
    func groupContent() -> some View {
        if cards.isEmpty {
            Text("No Flash Cards have been\nadded to this category")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
        } else {
            ForEach(cards) { card in
                FlashCardView(card: card, category: category)
            }
        }
    }

}

#Preview {
    MovableCardsDemo()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}
