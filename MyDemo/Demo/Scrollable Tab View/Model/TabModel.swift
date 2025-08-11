//
//  TabModel.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/11.
//

import Foundation

enum Tabs: String, CaseIterable {
    case chats = "Chats"
    case calls = "Calls"
    case settings = "Settings"

    var systemImage: String {
        switch self {
        case .chats:
            return "bubble.left.and.bubble.right"
        case .calls:
            return "phone"
        case .settings:
            return "gear"
        }
    }
}
