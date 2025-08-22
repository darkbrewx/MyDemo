//
//  MovableCardsView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/20.
//

import SwiftUI
import CoreData

struct MovableCardsView: View {
    // keep track of the categories fetched from Core Data
    @FetchRequest(
        entity: Category.entity(),
        // sort by dateCreated in ascending order
        sortDescriptors: [.init(keyPath: \Category.dateCreated, ascending: true)]
    ) private var categories: FetchedResults<Category>
    // get core data context from environment
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var dragProperties: DragProperties

    // Scroll Properties
    @State private var scrollPosition: ScrollPosition = .init()
    @State private var currentScrollOffset: CGFloat = .zero
    @State private var dragScrollOffset: CGFloat = .zero
    @GestureState private var isActive: Bool = false

    // Load more area
    @State private var scrollRect: CGRect = .zero
    @State private var loadMoreArea: CGRect = .zero

    var body: some View {
        ScrollView(.vertical) {
            DisclosureCategoryGroups
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        clearCategoryButton
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        createCategoryButton
                    }
                }
        }
        .background {
            loadMoreBanner
        }
        .scrollPosition($scrollPosition)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { newValue in
            scrollRect = newValue
        }
        .onScrollPhaseChange{ oldPhase, newPhase in
            // when in scrolling, disable the drag gesture
            dragProperties.isInScrolling = newPhase != .idle
        }
        .onScrollGeometryChange(for: CGFloat.self) { proxy in
            proxy.contentOffset.y + proxy.contentInsets.top
        } action: { oldValue, newValue in
            currentScrollOffset = newValue
        }
        .scrollDisabled(dragProperties.isShow)
        .contentShape(.rect)
        .onChange(of: isActive) { oldValue, newValue in
            if !newValue {
                dragScrollOffset = 0
            }
        }
        .onChange(of: dragProperties.dragLocation) { oldValue, newValue in
            if loadMoreArea.contains(newValue) {
                scrollPosition.scrollTo(y: currentScrollOffset + 20)
            }
        }
    }

    var DisclosureCategoryGroups: some View {
        VStack(spacing: 15) {
            ForEach(categories) { category in
                DisclosureCategoryGroup(category: category)
            }
        }
        .padding(15)
    }

    var createCategoryButton: some View {
        Button("", systemImage: "plus.circle.fill") {
            createCategory()
        }
    }

    var clearCategoryButton: some View {
        Button("", systemImage: "trash") {
            let _ = categories.map { category in
                context.delete(category)
            }
        }
    }

    var loadMoreBanner: some View {
        VStack {
            Spacer()
            Rectangle()
                .fill(Color.clear)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { newValue in
                    loadMoreArea = newValue
                }
        }
        .ignoresSafeArea()
    }

    func createCategory() {
        // adding some dummy data
        for index in 1...5 {
            // create a new category and card
            let category = Category(context: context)
            category.dateCreated = .init()
            let card = FlashCard(context: context)
            card.title = "card \(index)"
            card.category = category

            // save the context
            try? context.save()
        }
    }
}

#Preview {
    MovableCardsDemo()
        // inject the managed object context from the PersistenceController
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
