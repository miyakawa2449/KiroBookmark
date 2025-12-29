//
//  ArticleWebView.swift
//  KiroBookmark
//
//  WebView for displaying articles with text selection support
//

import SwiftUI
import WebKit

struct ArticleWebView: View {
    @StateObject private var viewModel = ArticleWebViewModel()
    @Environment(\.dismiss) private var dismiss

    let url: URL
    let bookmark: ArticleBookmark?
    let onBookmarkCreated: ((ArticleBookmark) -> Void)?

    init(url: URL, bookmark: ArticleBookmark? = nil, onBookmarkCreated: ((ArticleBookmark) -> Void)? = nil) {
        self.url = url
        self.bookmark = bookmark
        self.onBookmarkCreated = onBookmarkCreated
    }

    var body: some View {
        VStack(spacing: 0) {
            // WebView with overlays
            ZStack {
                webViewContent
                overlayContent
            }

            // Task 2: Article Preview UI Improvement - Action Toolbar
            #if os(iOS)
            actionToolbar
            #endif
        }
        .navigationTitle(viewModel.pageTitle ?? "記事")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            toolbarContent
        }
        .onAppear {
            if let bookmark = bookmark {
                viewModel.configure(bookmark: bookmark)
            } else {
                viewModel.configure(url: url)
            }
        }
        .sheet(isPresented: $viewModel.showingQuoteMemoSheet) {
            quoteMemoSheet
        }
        .sheet(isPresented: $viewModel.showingMemoSheet) {
            if let bookmark = bookmark {
                // Task 3: 事前選択対応
                AddMemoSheet(
                    bookmark: bookmark,
                    preselectedType: viewModel.preselectedMemoType,
                    onDismiss: {
                        viewModel.showingMemoSheet = false
                        viewModel.preselectedMemoType = nil
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showingDetailView) {
            if let bookmark = bookmark {
                NavigationStack {
                    ArticleDetailView(bookmark: bookmark, onUpdate: {})
                }
            }
        }
    }

    // MARK: - WebView Content

    private var webViewContent: some View {
        WebViewRepresentable(
            url: url,
            viewModel: viewModel
        )
    }

    // MARK: - Overlay Content

    private var overlayContent: some View {
        ZStack {
            // Loading indicator
            if viewModel.isLoading {
                loadingOverlay
            }

            // Error message
            if let errorMessage = viewModel.errorMessage {
                errorOverlay(message: errorMessage)
            }

            // Text selection action button
            if viewModel.selectedText != nil {
                textSelectionButton
            }

            // Bookmark registration button
            if viewModel.showBookmarkButton {
                bookmarkButton
            }
        }
    }

    private var loadingOverlay: some View {
        VStack {
            ProgressView(value: viewModel.loadingProgress)
                .progressViewStyle(.linear)
                .padding(.horizontal)
            Spacer()
        }
    }

    private func errorOverlay(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("再読み込み") {
                // Reload will be triggered by WebViewRepresentable
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.systemBackground.opacity(0.9))
    }

    // MARK: - Text Selection Button

    private var textSelectionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    viewModel.showQuoteMemoSheet()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "quote.bubble.fill")
                        Text("引用メモを作成")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .cornerRadius(24)
                    .shadow(radius: 4)
                }
                .padding(.trailing, 16)
            }
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: viewModel.selectedText != nil)
    }

    // MARK: - Bookmark Button

    private var bookmarkButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    registerBookmark()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bookmark.fill")
                        Text("ブックマーク登録")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(24)
                    .shadow(radius: 4)
                }
                .padding(.trailing, 16)
            }
            .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: viewModel.showBookmarkButton)
    }

    // MARK: - Quote Memo Sheet

    private var quoteMemoSheet: some View {
        QuoteMemoSheet(
            selectedText: viewModel.selectedText ?? "",
            sourceURL: url,
            bookmark: viewModel.getBookmark(),
            onSave: { content, memoType in
                do {
                    _ = try viewModel.createQuoteMemo(content: content, memoType: memoType)
                } catch {
                    // Handle error
                }
            },
            onCancel: {
                viewModel.showingQuoteMemoSheet = false
            }
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .navigationBarTrailing) {
            navigationButtons
        }
        ToolbarItem(placement: .bottomBar) {
            bottomToolbar
        }
        #else
        ToolbarItem(placement: .automatic) {
            navigationButtons
        }
        #endif
    }

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            Button {
                // Go back - handled by WebViewRepresentable
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!viewModel.canGoBack)

            Button {
                // Go forward - handled by WebViewRepresentable
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!viewModel.canGoForward)
        }
    }

    private var bottomToolbar: some View {
        HStack {
            // Bookmark status indicator
            if viewModel.isBookmarked {
                Label("ブックマーク済み", systemImage: "bookmark.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            Spacer()

            // Share button
            if let url = viewModel.currentURL {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    // MARK: - Action Toolbar (Task 2: Article Preview UI Improvement)

    #if os(iOS)
    private var actionToolbar: some View {
        HStack(spacing: 0) {
            // メモボタン
            ActionToolbarButton(
                icon: "square.and.pencil",
                label: "メモ",
                action: { viewModel.openMemoSheet() }
            )

            toolbarDivider

            // TODOボタン
            ActionToolbarButton(
                icon: "checkmark.circle",
                label: "TODO",
                action: { viewModel.addQuickTodo() }
            )

            toolbarDivider

            // お気に入りボタン
            ActionToolbarButton(
                icon: viewModel.isFavorite ? "heart.fill" : "heart",
                label: "お気に入り",
                isActive: viewModel.isFavorite,
                activeColor: .red,
                action: { viewModel.toggleFavorite() }
            )

            toolbarDivider

            // 詳細ボタン
            ActionToolbarButton(
                icon: "info.circle",
                label: "詳細",
                action: { viewModel.showingDetailView = true }
            )
        }
        .frame(height: 64)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }

    private var toolbarDivider: some View {
        Divider()
            .frame(height: 24)
    }
    #endif

    // MARK: - Actions

    private func registerBookmark() {
        do {
            if let newBookmark = try viewModel.registerBookmark() {
                onBookmarkCreated?(newBookmark)
            }
        } catch {
            // Handle error
        }
    }
}

// MARK: - WebViewRepresentable

#if os(iOS)
struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    let viewModel: ArticleWebViewModel

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // Enable JavaScript for text selection
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        // Add script for text selection detection
        let selectionScript = WKUserScript(
            source: textSelectionScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        configuration.userContentController.addUserScript(selectionScript)
        configuration.userContentController.add(context.coordinator, name: "textSelection")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.delegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only load if URL has changed
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Text Selection Script

    private var textSelectionScript: String {
        """
        document.addEventListener('selectionchange', function() {
            var selection = window.getSelection();
            var text = selection.toString();
            window.webkit.messageHandlers.textSelection.postMessage(text);
        });
        """
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, UIScrollViewDelegate {
        let viewModel: ArticleWebViewModel
        private var isUserScrolling = false

        init(viewModel: ArticleWebViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                viewModel.updateLoadingState(true)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                viewModel.updateLoadingState(false)
                viewModel.updateCurrentURL(webView.url)
                viewModel.updatePageTitle(webView.title)
                viewModel.updateNavigationState(
                    canGoBack: webView.canGoBack,
                    canGoForward: webView.canGoForward
                )
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                viewModel.setError("ページの読み込みに失敗しました")
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                viewModel.setError("ページの読み込みに失敗しました")
            }
        }

        // MARK: - WKScriptMessageHandler

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "textSelection", let text = message.body as? String {
                Task { @MainActor in
                    viewModel.handleTextSelection(text)
                }
            }
        }

        // MARK: - UIScrollViewDelegate

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isUserScrolling = true
            Task { @MainActor in
                viewModel.handleScrollStart()
            }
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                scrollDidEnd()
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            scrollDidEnd()
        }

        private func scrollDidEnd() {
            isUserScrolling = false
            Task { @MainActor in
                viewModel.handleScrollEnd()
            }
        }
    }
}
#else
// macOS implementation
struct WebViewRepresentable: NSViewRepresentable {
    let url: URL
    let viewModel: ArticleWebViewModel

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // Enable JavaScript for text selection
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        // Add script for text selection detection
        let selectionScript = WKUserScript(
            source: textSelectionScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        configuration.userContentController.addUserScript(selectionScript)
        configuration.userContentController.add(context.coordinator, name: "textSelection")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Only load if URL has changed
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Text Selection Script

    private var textSelectionScript: String {
        """
        document.addEventListener('selectionchange', function() {
            var selection = window.getSelection();
            var text = selection.toString();
            window.webkit.messageHandlers.textSelection.postMessage(text);
        });
        """
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let viewModel: ArticleWebViewModel

        init(viewModel: ArticleWebViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                viewModel.updateLoadingState(true)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                viewModel.updateLoadingState(false)
                viewModel.updateCurrentURL(webView.url)
                viewModel.updatePageTitle(webView.title)
                viewModel.updateNavigationState(
                    canGoBack: webView.canGoBack,
                    canGoForward: webView.canGoForward
                )
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                viewModel.setError("ページの読み込みに失敗しました")
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                viewModel.setError("ページの読み込みに失敗しました")
            }
        }

        // MARK: - WKScriptMessageHandler

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "textSelection", let text = message.body as? String {
                Task { @MainActor in
                    viewModel.handleTextSelection(text)
                }
            }
        }
    }
}
#endif

// MARK: - Action Toolbar Button Component (Task 2: Article Preview UI Improvement)

#if os(iOS)
struct ActionToolbarButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    var activeColor: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isActive ? activeColor : .primary)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(isActive ? activeColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint("タップして\(label)を実行")
    }
}
#endif

// MARK: - Preview

#Preview {
    NavigationStack {
        ArticleWebView(
            url: URL(string: "https://example.com")!,
            bookmark: nil
        )
    }
}
