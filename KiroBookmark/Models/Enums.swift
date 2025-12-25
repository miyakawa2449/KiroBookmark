//
//  Enums.swift
//  KiroBookmark
//
//  Shared enums for the application
//

import SwiftUI

// MARK: - MemoType

enum MemoType: String, CaseIterable, Codable {
    case idea = "idea"
    case thought = "thought"
    case todo = "todo"
    case quote = "quote"
    case other = "other"

    var displayName: String {
        switch self {
        case .idea: return "アイディア"
        case .thought: return "感想"
        case .todo: return "TODO"
        case .quote: return "引用"
        case .other: return "その他"
        }
    }

    var color: Color {
        switch self {
        case .idea: return .blue
        case .thought: return .green
        case .todo: return .orange
        case .quote: return .purple
        case .other: return .gray
        }
    }

    var systemIcon: String {
        switch self {
        case .idea: return "lightbulb"
        case .thought: return "text.bubble"
        case .todo: return "list.bullet"
        case .quote: return "quote.bubble"
        case .other: return "ellipsis"
        }
    }
}

// MARK: - ReadingStatus

enum ReadingStatus: String, CaseIterable, Codable {
    case unread = "unread"
    case read = "read"
    case favorite = "favorite"

    var displayName: String {
        switch self {
        case .unread: return "未読"
        case .read: return "既読"
        case .favorite: return "お気に入り"
        }
    }

    var color: Color {
        switch self {
        case .unread: return .gray
        case .read: return .green
        case .favorite: return .red
        }
    }

    var systemIcon: String {
        switch self {
        case .unread: return "circle"
        case .read: return "checkmark.circle"
        case .favorite: return "heart.fill"
        }
    }
}

// MARK: - MainTabType

enum MainTabType: String, CaseIterable, Codable {
    case newEntry = "newEntry"
    case bookmark = "bookmark"

    var displayName: String {
        switch self {
        case .newEntry: return "New Entry"
        case .bookmark: return "Bookmark"
        }
    }

    var systemIcon: String {
        switch self {
        case .newEntry: return "newspaper"
        case .bookmark: return "bookmark"
        }
    }
}

// MARK: - SideMenuItem

enum SideMenuItem: String, CaseIterable, Codable {
    case favorite = "favorite"
    case idea = "idea"
    case thought = "thought"
    case todo = "todo"
    case other = "other"

    var displayName: String {
        switch self {
        case .favorite: return "いいね"
        case .idea: return "アイディア"
        case .thought: return "感想"
        case .todo: return "TODO"
        case .other: return "その他"
        }
    }

    var systemIcon: String {
        switch self {
        case .favorite: return "heart.fill"
        case .idea: return "lightbulb"
        case .thought: return "text.bubble"
        case .todo: return "list.bullet"
        case .other: return "ellipsis"
        }
    }

    var color: Color {
        switch self {
        case .favorite: return .red
        case .idea: return .blue
        case .thought: return .green
        case .todo: return .orange
        case .other: return .gray
        }
    }

    var associatedMemoType: MemoType? {
        switch self {
        case .favorite: return nil
        case .idea: return .idea
        case .thought: return .thought
        case .todo: return .todo
        case .other: return .other
        }
    }
}
