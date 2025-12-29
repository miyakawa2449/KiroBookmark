//
//  BookmarkCardView.swift
//  KiroBookmark
//
//  Card view for displaying a bookmark
//

import SwiftUI
import CoreData

struct BookmarkCardView: View {
    let bookmark: ArticleBookmark
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            titleSection
            metadataSection
        }
        .padding(16)
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            domainLabel
            Spacer()
            favoriteButton
        }
    }

    private var domainLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "globe")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(bookmark.domain ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    private var favoriteButton: some View {
        Button(action: onFavoriteToggle) {
            Image(systemName: bookmark.isFavorite ? "heart.fill" : "heart")
                .foregroundColor(bookmark.isFavorite ? .red : .gray)
                .font(.system(size: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        Text(bookmark.title ?? "Untitled")
            .font(.headline)
            .foregroundColor(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        HStack(spacing: 12) {
            readingStatusBadge
            elapsedTimeLabel
            Spacer()
            memoCountBadge
        }
    }

    @ViewBuilder
    private var readingStatusBadge: some View {
        let status = ReadingStatus(rawValue: bookmark.readingStatus ?? "unread") ?? .unread
        HStack(spacing: 4) {
            Image(systemName: status.systemIcon)
                .font(.caption2)
            Text(status.displayName)
                .font(.caption2)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
    }

    private var elapsedTimeLabel: some View {
        Text(formatElapsedTime(from: bookmark.bookmarkedDate))
            .font(.caption)
            .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var memoCountBadge: some View {
        let count = (bookmark.memos as? Set<TweetMemo>)?.count ?? 0
        if count > 0 {
            HStack(spacing: 4) {
                Image(systemName: "note.text")
                    .font(.caption2)
                Text("\(count)")
                    .font(.caption2)
            }
            .foregroundColor(.blue)
        }
    }

    // MARK: - Time Formatting

    private func formatElapsedTime(from date: Date?) -> String {
        guard let date = date else { return "" }
        return date.relativeTimeString()
    }
}

// MARK: - Preview

#Preview {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext

    let bookmark = ArticleBookmark(context: context)
    bookmark.id = UUID()
    bookmark.title = "SwiftUIで美しいUIを作る方法"
    bookmark.url = "https://example.com/swiftui-beautiful-ui"
    bookmark.domain = "example.com"
    bookmark.bookmarkedDate = Date()
    bookmark.isFavorite = true
    bookmark.readingStatus = ReadingStatus.unread.rawValue

    return BookmarkCardView(
        bookmark: bookmark,
        onFavoriteToggle: {},
        onDelete: {}
    )
    .padding()
}
