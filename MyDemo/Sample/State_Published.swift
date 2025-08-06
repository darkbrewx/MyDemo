//
//  State_Published.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/06.
//

import SwiftUI
import Combine

class PublishedViewModel: ObservableObject {
    @Published var count = 0
    var count2 = 0
}


// published: will trigger view re-render even if the value is not changed
// state: will trigger view re-render only if the value is changed
struct State_Published: View {
    @StateObject var publishedViewModel = PublishedViewModel()
    @State var stateCount = 0
    var body: some View {
        VStack {
            Button("state\(publishedViewModel.count2)") {
                publishedViewModel.count2 += 1
                stateCount = stateCount
            }

            Button("pulished\(publishedViewModel.count2)") {
                publishedViewModel.count2 += 1
                publishedViewModel.count = publishedViewModel.count
            }

            Text("Count: \(publishedViewModel.count)")
            Text("Count: \(publishedViewModel.count2)")
        }
    }
}

#Preview {
    State_Published()
}
