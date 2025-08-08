//
//  ExpadableHeader.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/08.
//

import SwiftUI

struct ExpadableHeader<
    LeadingView: View,
    TrailingView: View,
    Header: View,
    ExpandedContent: View
>: View {
    @ViewBuilder var leading: () -> LeadingView
    @ViewBuilder var trailing: () -> TrailingView
    @ViewBuilder var header: (Binding<Bool>) -> Header
    @ViewBuilder var expandedContent: (Binding<Bool>) -> ExpandedContent

    var body: some View {
        VStack {
            expandableHeader
        }
    }

    var expandableHeader: some View {
        HStack(spacing: 10) {
            leading()
            UnExpandedHeaderView { isExpanded in
                header(isExpanded)
            } expandedContent: { isExpanded in
                expandedContent(isExpanded)
            }
            trailing()
        }
        .padding(15)
    }
}

#Preview {
    ExpadableHeader {
        Image(systemName: "chevron.left")
            .font(.title3)
    } trailing: {
        Image(systemName: "airpods.max")
            .font(.title3)
    } header: { isExpanded in
        HeaderView(isHeaderExpanded: isExpanded)
    } expandedContent: { isExpanded in
        Text("Content")
    }
}
