//
//  PaywallViewDemo.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/12/11.
//

import SwiftUI

struct PaywallViewDemo: View {
    var body: some View {
        NavigationStack {
            PaywallView()
                .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    PaywallViewDemo()
}
