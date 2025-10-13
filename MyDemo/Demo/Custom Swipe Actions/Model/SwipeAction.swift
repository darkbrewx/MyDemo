//
//  SwipeAction.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/10/13.
//

import Foundation
import SwiftUI

struct SwipeAction: Identifiable {
    private(set) var id: UUID = .init()
    var tint: Color
    var icon: String
    var iconFont: Font = .title
    var iconTint: Color = .white
    var isEnabled: Bool = true
    var action: () -> Void
}

enum SwipeDirection {
    case leading
    case trailing

    var alignment: Alignment {
        switch self {
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }
}

@resultBuilder
struct ActionBuilder {
    static func buildBlock(_ components: SwipeAction...) -> [SwipeAction] {
        return components
    }
}
