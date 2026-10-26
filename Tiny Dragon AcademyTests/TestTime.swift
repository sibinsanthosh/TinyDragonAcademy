//
//  TestTime.swift
//  Tiny Dragon AcademyTests
//
//  Fixed dates and a UTC calendar so life-simulation tests are deterministic.
//

import Foundation

enum TestTime {
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// 2026-01-`day` `hour`:`minute` UTC.
    static func date(day: Int, hour: Int, minute: Int = 0) -> Date {
        utc.date(from: DateComponents(year: 2026, month: 1, day: day, hour: hour, minute: minute))!
    }
}
