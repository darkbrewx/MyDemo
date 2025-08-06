//
//  ContentView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/04.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
//        Home()
//        SwiftUIView()
//        TaskManagerView()
        NavigationStack {
            List {
                NavigationLink("Task Manager", destination: TaskManagerView())
            }
        }
    }
}

#Preview {
    ContentView()
}
