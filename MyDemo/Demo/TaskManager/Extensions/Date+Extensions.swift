//
//  Date+Extensions.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/04.
//

import Foundation

extension Date {
    static var currentWeek: [Day] {
        // get current week calendar
        let calendar = Calendar.current
        // found the current week's start date
        guard let firestWeekDay = calendar.dateInterval(of: .weekOfMonth, for: .now)?.start else {
            return []
        }
        var week: [Day] = []
        for index in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: index, to: firestWeekDay) {
                // add each day of the current week to the array
                week.append(.init(date: day))
            }
        }
        return week
    }

    // convert date to string with specific format
    func string(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format

        return formatter.string(from: self)
    }

    func isSameDay(as date: Date?) -> Bool {
        guard let date else { return false }
        return Calendar.current.isDate(self, inSameDayAs: date)
    }

    struct Day: Identifiable {
        var id: String = UUID().uuidString
        var date: Date
    }
}
