//
//  DateExtensions.swift
//  KiroBookmark
//
//  Relative time formatting extensions
//

import Foundation

extension Date {
    /// Returns a relative time string for display
    /// Examples: "たった今", "5分前", "2時間前", "昨日", "3日前", "2024/12/25"
    func relativeTimeString() -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.second, .minute, .hour, .day], from: self, to: now)

        // Future dates or invalid
        guard let days = components.day, days >= 0,
              let hours = components.hour, hours >= 0,
              let minutes = components.minute, minutes >= 0,
              let seconds = components.second, seconds >= 0 else {
            return formatAbsoluteDate()
        }

        // Just now (within 1 minute)
        if days == 0 && hours == 0 && minutes == 0 {
            return "たった今"
        }

        // Minutes ago (within 1 hour)
        if days == 0 && hours == 0 {
            return "\(minutes)分前"
        }

        // Hours ago (within 24 hours)
        if days == 0 {
            return "\(hours)時間前"
        }

        // Yesterday
        if days == 1 {
            return "昨日"
        }

        // Days ago (within 7 days)
        if days < 7 {
            return "\(days)日前"
        }

        // Older: show absolute date
        return formatAbsoluteDate()
    }

    /// Returns a short relative time string for compact display
    /// Examples: "今", "5分", "2時間", "昨日", "3日", "12/25"
    func relativeTimeShort() -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.second, .minute, .hour, .day], from: self, to: now)

        guard let days = components.day, days >= 0,
              let hours = components.hour, hours >= 0,
              let minutes = components.minute, minutes >= 0 else {
            return formatShortDate()
        }

        // Just now
        if days == 0 && hours == 0 && minutes == 0 {
            return "今"
        }

        // Minutes
        if days == 0 && hours == 0 {
            return "\(minutes)分"
        }

        // Hours
        if days == 0 {
            return "\(hours)時間"
        }

        // Yesterday
        if days == 1 {
            return "昨日"
        }

        // Days (within 7 days)
        if days < 7 {
            return "\(days)日"
        }

        // Older
        return formatShortDate()
    }

    // MARK: - Private Helpers

    private func formatAbsoluteDate() -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDate(self, equalTo: Date(), toGranularity: .year) {
            // Same year: "12/25 15:30"
            formatter.dateFormat = "M/d HH:mm"
        } else {
            // Different year: "2024/12/25"
            formatter.dateFormat = "yyyy/M/d"
        }

        return formatter.string(from: self)
    }

    private func formatShortDate() -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDate(self, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "M/d"
        } else {
            formatter.dateFormat = "yyyy/M/d"
        }

        return formatter.string(from: self)
    }
}
