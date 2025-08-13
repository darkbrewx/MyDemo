//
//  CardModel.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/12.
//

import Foundation

struct Card: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var imageName: String
}

let cards = [
    Card(imageName: "fuji"),
    Card(imageName: "skytree"),
    Card(imageName: "chamizu"),
    Card(imageName: "gyoen"),
    Card(imageName: "star"),
]

