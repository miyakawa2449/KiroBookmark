//
//  RSSArticleCardView.swift
//  KiroBookmark
//
//  Card view for displaying RSS article in New Entry tab
//

import SwiftUI

struct RSSArticleCardView: View {
    let article: RSSArticle
    let onBookmark: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Blog info
            HStack {
                Text(article.blogName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if let dateString = article.formattedDate {
                    Text(dateString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Title
            Text(article.title)
                .font(.headline)
                .lineLimit(2)
                .foregroundColor(.primary)

            // Summary
            if let summary = article.summary {
                Text(stripHTML(summary))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Action row
            HStack {
                // Domain badge
                Text(article.blogDomain)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)

                Spacer()

                // Bookmark button
                Button(action: onBookmark) {
                    HStack(spacing: 4) {
                        Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                        Text(article.isBookmarked ? "追加済み" : "追加")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(article.isBookmarked ? Color.gray.opacity(0.2) : Color.blue)
                    .foregroundColor(article.isBookmarked ? .secondary : .white)
                    .cornerRadius(8)
                }
                .disabled(article.isBookmarked)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func stripHTML(_ string: String) -> String {
        string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

#Preview {
    VStack {
        RSSArticleCardView(
            article: RSSArticle(
                title: "SwiftUIで始めるiOSアプリ開発",
                url: URL(string: "https://example.com/article1")!,
                publishedDate: Date().addingTimeInterval(-3600),
                summary: "SwiftUIは宣言的UIフレームワークで、より少ないコードでより多くのことを実現できます。",
                blogDomain: "example.com",
                blogName: "Tech Blog",
                isBookmarked: false
            ),
            onBookmark: {}
        )

        RSSArticleCardView(
            article: RSSArticle(
                title: "既にブックマーク済みの記事",
                url: URL(string: "https://example.com/article2")!,
                publishedDate: Date().addingTimeInterval(-86400),
                summary: nil,
                blogDomain: "example.com",
                blogName: "Tech Blog",
                isBookmarked: true
            ),
            onBookmark: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
