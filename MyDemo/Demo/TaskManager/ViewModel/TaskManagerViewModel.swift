//
//  TaskManagerViewModel.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/05.
//

import Foundation

class TaskManagerViewModel: ObservableObject {
    @Published var currentWeek: [Date.Day] = Date.currentWeek
    @Published var selectedDate: Date?
    @Published var isEmptyDay: Bool = false
}
