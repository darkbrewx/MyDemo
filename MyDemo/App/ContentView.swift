//
//  ContentView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/04.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Task Manager", destination: TaskManagerView())
                NavigationLink("WaterfallGridDemo", destination: WaterfallGridDemo())
                NavigationLink("ExpandableHeaderDemo", destination: ExpandableHeaderDemo())
                NavigationLink("ScrollableTabViewDemo", destination: ScrollableTabViewDemo())
                NavigationLink("DownsizedImageViewDemo", destination: DownsizedImageViewDemo())
                NavigationLink("InfiniteScrollViewDemo", destination: InfiniteScrollViewDemo())
                NavigationLink("PaywallDemo", destination: PaywallViewDemo())
            }
        }
    }
}

#Preview {
    ContentView()
}
