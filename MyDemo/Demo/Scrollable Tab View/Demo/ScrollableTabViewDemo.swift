//
//  ScrollableTabViewDemo.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/11.
//

import SwiftUI

struct ScrollableTabViewDemo: View {
    var body: some View {
        ScrollableTabView()
            .toolbarVisibility(.hidden, for: .navigationBar)
    }
}

#Preview {
    ScrollableTabViewDemo()
}
