//
//  ExpandableHeaderView.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/08.
//

import SwiftUI

struct ExpandableHeaderDemo: View {
    @Environment(\.dismiss) private var dismiss
    @Namespace private var header
    var body: some View {
        NavigationStack {
            VStack {
                ExpadableHeader {
                    Image(systemName: "chevron.left")
                        .onTapGesture {
                            dismiss()
                        }
                        .font(.title3)
                } trailing: {
                    Image(systemName: "airpods.max")
                        .font(.title3)
                } header: { isExpanded in
                    HeaderView(isHeaderExpanded: isExpanded)
                } expandedContent: { isExpanded in
                    expandedHeaderContentView(isHeaderExpanded: isExpanded)
                }
                .toolbarVisibility(.hidden, for: .navigationBar)
                Spacer()
            }
        }
    }

    @ViewBuilder
    func expandedHeaderContentView(isHeaderExpanded: Binding<Bool>) -> some View
    {
        VStack(spacing: 12) {
            CustomButton(imageName: "message", title: "Message")
            CustomButton(imageName: "phone", title: "Call")
            CustomButton(imageName: "video", title: "Video Call")
            CustomButton(imageName: "bell", title: "Notifications")
            CustomButton(imageName: "gear", title: "Settings")
            CustomButton(
                imageName: "person.crop.circle.badge.checkmark",
                title: "Add Members"
            )
            Divider()
            CustomButton(imageName: "ellipsis", title: "More")
            CustomButton(imageName: "arrow.down.circle", title: "Download")
        }
    }
}

struct HeaderView: View {
    @Binding var isHeaderExpanded: Bool
    @Namespace var header

    var body: some View {
        HStack(spacing: 10) {
            if !isHeaderExpanded {
                ZStack {
                    Image(systemName: "number")
                        .fontWeight(.semibold)
                        .matchedGeometryEffect(id: "#Icon", in: header)
                }
                .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    if isHeaderExpanded {
                        Image(systemName: "number")
                            .fontWeight(.semibold)
                            .matchedGeometryEffect(
                                id: "#Icon",
                                in: header
                            )
                            .scaleEffect(0.8)
                    }
                    Text("General")
                }
                Text("36 Members - 4 Online")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 50)
    }
}

struct CustomButton: View {
    var imageName: String
    var title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: imageName)
                    .frame(width: 25)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 5)
            .foregroundStyle(Color.primary)
        }
    }
}

#Preview {
    ExpandableHeaderDemo()
}
