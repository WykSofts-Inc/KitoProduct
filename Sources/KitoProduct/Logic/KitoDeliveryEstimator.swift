//
//  KitoDeliveryEstimator.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// Works out when an order arrives, counting only working days.
///
/// Orders placed before the cut-off on a working day are dispatched that day; later orders, and
/// orders at the weekend or on a holiday, are dispatched on the next working day. Delivery then
/// takes `minDays`–`maxDays` working days.
///
/// ```swift
/// let estimator = KitoDeliveryEstimator(minDays: 1, maxDays: 2, cutoffHour: 14)
/// let estimate = estimator.estimate(from: .now)
/// estimate.title          // "Get it Fri 25 – Mon 28 Sep"
/// estimate.countdown      // "Order within 3 h 12 min"
/// ```
public struct KitoDeliveryEstimator: Sendable {
    public var minDays: Int
    public var maxDays: Int
    /// The hour (0–23) after which an order is dispatched the next working day.
    public var cutoffHour: Int
    /// Days with no dispatch or delivery, as `Calendar` weekdays (1 is Sunday, 7 is Saturday).
    public var closedWeekdays: Set<Int>
    /// Public holidays and other closed dates.
    public var holidays: [Date]
    public var calendar: Calendar
    /// The language for day and month names. The default gives "Fri 25 Sep" on every device.
    public var locale: Locale

    public init(
        minDays: Int = 1,
        maxDays: Int? = nil,
        cutoffHour: Int = 14,
        closedWeekdays: Set<Int> = [1, 7],
        holidays: [Date] = [],
        calendar: Calendar = .current,
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) {
        self.minDays = max(minDays, 0)
        self.maxDays = max(maxDays ?? minDays, max(minDays, 0))
        self.cutoffHour = min(max(cutoffHour, 0), 24)
        self.closedWeekdays = closedWeekdays.count >= 7 ? [] : closedWeekdays
        self.holidays = holidays
        self.calendar = calendar
        self.locale = locale
    }

    /// Whether goods move on this day.
    public func isWorkingDay(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        guard !closedWeekdays.contains(weekday) else { return false }
        return !holidays.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    /// The day an order placed at `now` leaves the warehouse.
    public func dispatchDate(for now: Date) -> Date {
        let today = calendar.startOfDay(for: now)
        if isWorkingDay(today), calendar.component(.hour, from: now) < cutoffHour {
            return today
        }
        return nextWorkingDay(after: today)
    }

    /// The delivery window for an order placed at `now`.
    public func estimate(from now: Date) -> KitoDeliveryEstimate {
        let dispatch = dispatchDate(for: now)
        let earliest = adding(workingDays: minDays, to: dispatch)
        let latest = adding(workingDays: maxDays, to: dispatch)
        var remaining: TimeInterval?
        if calendar.isDate(dispatch, inSameDayAs: now),
           let cutoff = calendar.date(bySettingHour: cutoffHour, minute: 0, second: 0, of: now) {
            remaining = cutoff.timeIntervalSince(now)
        }
        return KitoDeliveryEstimate(orderDate: now, earliest: earliest, latest: latest,
                                    timeUntilCutoff: remaining, calendar: calendar, locale: locale)
    }

    /// `days` working days after `date` (the same day for 0).
    public func adding(workingDays days: Int, to date: Date) -> Date {
        var current = calendar.startOfDay(for: date)
        var left = days
        while left > 0 {
            current = nextWorkingDay(after: current)
            left -= 1
        }
        return current
    }

    private func nextWorkingDay(after date: Date) -> Date {
        var current = date
        // A year of closed days would mean the calendar is misconfigured; stop rather than spin.
        for _ in 0..<366 {
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { return current }
            current = next
            if isWorkingDay(current) { return current }
        }
        return current
    }
}

/// A delivery window with its wording.
public struct KitoDeliveryEstimate: Hashable, Sendable {
    public var orderDate: Date
    public var earliest: Date
    public var latest: Date
    /// Seconds left to order for today's dispatch, or `nil` when today's dispatch has gone.
    public var timeUntilCutoff: TimeInterval?
    public var calendar: Calendar
    public var locale: Locale

    public init(orderDate: Date, earliest: Date, latest: Date, timeUntilCutoff: TimeInterval? = nil,
                calendar: Calendar = .current, locale: Locale = Locale(identifier: "en_US_POSIX")) {
        self.orderDate = orderDate
        self.earliest = earliest
        self.latest = max(latest, earliest)
        self.timeUntilCutoff = timeUntilCutoff
        self.calendar = calendar
        self.locale = locale
    }

    /// "Get it today", "Get it tomorrow", "Get it by Fri 25 Sep" or "Get it Fri 25 – Mon 28 Sep".
    public var title: String {
        if calendar.isDate(earliest, inSameDayAs: latest) {
            if calendar.isDate(earliest, inSameDayAs: orderDate) { return "Get it today" }
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: orderDate)),
               calendar.isDate(earliest, inSameDayAs: tomorrow) {
                return "Get it tomorrow"
            }
            return "Get it by \(format(earliest, "EEE d MMM"))"
        }
        return "Get it \(rangeText)"
    }

    /// "Fri 25 – Mon 28 Sep", or "Wed 30 Sep – Fri 2 Oct" across months.
    public var rangeText: String {
        let sameMonth = calendar.isDate(earliest, equalTo: latest, toGranularity: .month)
        let start = format(earliest, sameMonth ? "EEE d" : "EEE d MMM")
        return "\(start) – \(format(latest, "EEE d MMM"))"
    }

    /// "Order within 3 h 12 min", or `nil` once today's dispatch has gone.
    public var countdown: String? {
        guard let seconds = timeUntilCutoff, seconds > 0 else { return nil }
        let minutes = Int((seconds / 60).rounded(.up))
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "Order within \(rest) min" }
        if rest == 0 { return "Order within \(hours) h" }
        return "Order within \(hours) h \(rest) min"
    }

    private func format(_ date: Date, _ template: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateFormat = template
        return formatter.string(from: date)
    }
}
