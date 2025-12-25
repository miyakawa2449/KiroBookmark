//
//  ArticleCardView.swift
//  KiroBookmark
//
//  Unified card view for displaying articles
//

import SwiftUI
import CoreData

struct ArticleCardView: View {
    let bookmark: ArticleBookmark
    let onFavoriteTap: () -> Void
    let onCardTap: () -> Void

    var body: some View {
        Button(action: onCardTap) {
            VStack(alignment: .leading, spacing: 12) {
                headerSection
                titleSection
                footerSection
            }
            .padding(16)
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            // Domain
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(bookmark.domain ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Favorite button
            Button(action: onFavoriteTap) {
                Image(systemName: bookmark.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16))
                    .foregroundColor(bookmark.isFavorite ? .red : .secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(bookmark.title ?? "無題")
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Memo type badges
            if let memoTypes = getMemoTypes(), !memoTypes.isEmpty {
                memoTypeBadges(memoTypes)
            }
        }
    }

    private func getMemoTypes() -> [MemoType]? {
        guard let memos = bookmark.memos as? Set<TweetMemo> else { return nil }
        let types = Set(memos.compactMap { MemoType(rawValue: $0.memoType ?? "") })
        return Array(types).sorted { $0.rawValue < $1.rawValue }
    }

    private func memoTypeBadges(_ types: [MemoType]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(types, id: \.self) { memoType in
                    memoTypeBadge(memoType)
                }
            }
        }
    }

    private func memoTypeBadge(_ memoType: MemoType) -> some View {
        HStack(spacing: 4) {
            Image(systemName: memoType.systemIcon)
                .font(.system(size: 10))
            Text(memoType.displayName)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(memoType.color.opacity(0.15))
        .foregroundColor(memoType.color)
        .cornerRadius(8)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack {
            // Date
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(formatDate(bookmark.bookmarkedDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Memo count
            if let memoCount = getMemoCount(), memoCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(memoCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Tag count
            if let tagCount = getTagCount(), tagCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "tag")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(tagCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "今日 \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if days < 7 {
                return "\(days)日前"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d"
                return formatter.string(from: date)
            }
        }
    }

    private func getMemoCount() -> Int? {
        return (bookmark.memos as? Set<TweetMemo>)?.count
    }

    private func getTagCount() -> Int? {
        return (bookmark.tags as? Set<Tag>)?.count
    }
}

// MARK: - Compact Card Variant

struct ArticleCardCompactView: View {
    let bookmark: ArticleBookmark
    let onCardTap: () -> Void

    var body: some View {
        Button(action: onCardTap) {
            HStack(spacing: 12) {
                // Icon
                VStack {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(bookmark.title ?? "無題")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(bookmark.domain ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.systemBackground)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext

    let bookmark = ArticleBookmark(context: context)
    bookmark.id = UUID()
    bookmark.title = "SwiftUIで作る美しいUIデザイン - 実践テクニック集"
    bookmark.url = "https://example.com/article"
    bookmark.domain = "example.com"
    bookmark.bookmarkedDate = Date()
    bookmark.isFavorite = true

    return VStack(spacing: 16) {
        ArticleCardView(
            bookmark: bookmark,
            onFavoriteTap: {},
            onCardTap: {}
        )

        ArticleCardCompactView(
            bookmark: bookmark,
            onCardTap: {}
        )
    }
    .padding()
    .background(Color.systemGroupedBackground)
}
