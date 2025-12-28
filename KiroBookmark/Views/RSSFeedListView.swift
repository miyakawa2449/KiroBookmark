//
//  RSSFeedListView.swift
//  KiroBookmark
//
//  View for managing registered RSS feeds
//

import SwiftUI

struct RSSFeedListView: View {
    @StateObject private var viewModel = RSSFeedViewModel()
    @State private var selectedBlog: FavoriteBlog?

    var body: some View {
        List {
            // Blogs with RSS
            if !viewModel.blogsWithRSS.isEmpty {
                Section("RSSフィード登録済み") {
                    ForEach(viewModel.blogsWithRSS, id: \.id) { blog in
                        feedRow(blog, hasRSS: true)
                    }
                }
            }

            // Blogs without RSS
            if !viewModel.blogsWithoutRSS.isEmpty {
                Section("RSS未設定") {
                    ForEach(viewModel.blogsWithoutRSS, id: \.id) { blog in
                        feedRow(blog, hasRSS: false)
                    }
                }
            }

            // Empty state
            if viewModel.blogs.isEmpty && !viewModel.isLoading {
                Section {
                    emptyState
                }
            }
        }
        .navigationTitle("フィード管理")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            viewModel.loadBlogs()
        }
        .sheet(item: $selectedBlog) { blog in
            NavigationStack {
                RSSFeedDetailView(blog: blog, viewModel: viewModel)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }

    private func feedRow(_ blog: FavoriteBlog, hasRSS: Bool) -> some View {
        Button {
            selectedBlog = blog
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(blog.name ?? blog.domain ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(blog.domain ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if hasRSS, let rssURL = blog.rssURL {
                        Text(rssURL)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: hasRSS ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundColor(hasRSS ? .green : .blue)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("お気に入りブログがありません")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("記事をブックマークすると、そのブログが自動的に追加されます")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    NavigationStack {
        RSSFeedListView()
    }
}
