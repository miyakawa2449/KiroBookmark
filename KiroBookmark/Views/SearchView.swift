//
//  SearchView.swift
//  KiroBookmark
//
//  Unified search view for bookmarks, memos, and tags
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SearchViewModel()
    @State private var navigationPath = NavigationPath()
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                searchBar
                Divider()
                contentView
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle("検索")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                #endif
            }
            .navigationDestination(for: ArticleBookmark.self) { bookmark in
                if let urlString = bookmark.url, let url = URL(string: urlString) {
                    ArticleWebView(url: url, bookmark: bookmark)
                }
            }
            .onAppear {
                isSearchFieldFocused = true
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("記事、メモ、タグを検索", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFieldFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        viewModel.search()
                        if !viewModel.searchText.isEmpty {
                            viewModel.addToRecentSearches(viewModel.searchText)
                        }
                    }
                    .onChange(of: viewModel.searchText) { _, _ in
                        viewModel.search()
                    }

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.systemGray5)
            .cornerRadius(10)
        }
        .padding()
        .background(Color.systemBackground)
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.searchText.isEmpty {
            recentSearchesView
        } else if viewModel.isSearching {
            loadingView
        } else if viewModel.results.isEmpty {
            emptyResultsView
        } else {
            searchResultsList
        }
    }

    // MARK: - Recent Searches

    private var recentSearchesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !viewModel.recentSearches.isEmpty {
                    HStack {
                        Text("最近の検索")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("クリア") {
                            viewModel.clearRecentSearches()
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)

                    ForEach(viewModel.recentSearches, id: \.self) { query in
                        recentSearchRow(query)
                    }
                } else {
                    emptyRecentSearchesView
                }
            }
        }
    }

    private func recentSearchRow(_ query: String) -> some View {
        HStack {
            Button {
                viewModel.searchText = query
                viewModel.search()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.secondary)
                        .frame(width: 24)

                    Text(query)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.removeRecentSearch(query)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.trailing)
        }
        .background(Color.systemBackground)
    }

    private var emptyRecentSearchesView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("検索するキーワードを入力")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("記事タイトル、URL、メモ、タグを検索できます")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Text("検索中...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Empty Results

    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("「\(viewModel.searchText)」の検索結果はありません")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    // MARK: - Search Results

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                HStack {
                    Text("\(viewModel.results.count)件の結果")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                ForEach(viewModel.results) { result in
                    searchResultRow(result)
                }
            }
        }
    }

    private func searchResultRow(_ result: SearchResult) -> some View {
        VStack(spacing: 0) {
            Button {
                viewModel.addToRecentSearches(viewModel.searchText)
                navigationPath.append(result.bookmark)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(result.bookmark.title ?? "無題")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Match info
                    HStack(spacing: 4) {
                        Image(systemName: result.matchType.systemIcon)
                            .font(.caption2)
                        Text(result.matchType.displayName)
                            .font(.caption2)

                        if let matchedText = result.matchedText {
                            Text("・")
                                .font(.caption2)
                            Text(matchedText)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                    .foregroundColor(.blue)

                    // Domain and date
                    HStack {
                        if let domain = result.bookmark.domain {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                    .font(.caption2)
                                Text(domain)
                                    .font(.caption2)
                            }
                            .foregroundColor(.secondary)
                        }

                        Spacer()

                        if let date = result.bookmark.bookmarkedDate {
                            Text(date.relativeTimeString())
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.systemBackground)
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.leading)
        }
    }
}

// MARK: - Preview

#Preview {
    SearchView()
}
