//
//  RSSFeedDetailView.swift
//  KiroBookmark
//
//  Detail view for managing a single RSS feed with manual URL input
//

import SwiftUI

struct RSSFeedDetailView: View {
    let blog: FavoriteBlog
    @ObservedObject var viewModel: RSSFeedViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            // Blog Info Section
            Section("ブログ情報") {
                LabeledContent("名前", value: blog.name ?? "Unknown")
                LabeledContent("ドメイン", value: blog.domain ?? "Unknown")
            }

            // Current RSS Section
            if let rssURL = blog.rssURL, !rssURL.isEmpty {
                Section("現在のRSSフィード") {
                    Text(rssURL)
                        .font(.caption)
                        .foregroundColor(.blue)

                    Button(role: .destructive) {
                        Task {
                            await viewModel.clearRSSURL(for: blog)
                            dismiss()
                        }
                    } label: {
                        Label("RSSフィードを解除", systemImage: "trash")
                    }
                }
            }

            // Manual RSS Input Section
            Section {
                TextField("RSS URL", text: $viewModel.manualRSSURL)
                    .textContentType(.URL)
                    #if os(iOS)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    #endif
                    .autocorrectionDisabled()

                // Validation result
                if let result = viewModel.rssValidationResult {
                    validationResultView(result)
                }

                // Validate button
                Button {
                    Task {
                        await viewModel.validateManualRSSURL()
                    }
                } label: {
                    HStack {
                        if viewModel.isValidatingRSS {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("検証")
                    }
                }
                .disabled(viewModel.manualRSSURL.isEmpty || viewModel.isValidatingRSS)

            } header: {
                Text("手動でRSS URLを設定")
            } footer: {
                Text("RSSフィードのURLを直接入力できます。検証後に保存してください。")
            }

            // Save button
            if case .valid = viewModel.rssValidationResult {
                Section {
                    Button {
                        Task {
                            if await viewModel.saveManualRSSURL(for: blog) {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("保存")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            // Delete blog section
            Section {
                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteBlog(blog)
                        dismiss()
                    }
                } label: {
                    Label("このブログを削除", systemImage: "trash")
                }
            }
        }
        .navigationTitle("フィード設定")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    viewModel.resetManualInput()
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.resetManualInput()
        }
    }

    @ViewBuilder
    private func validationResultView(_ result: RSSFeedViewModel.RSSValidationResult) -> some View {
        switch result {
        case .valid(let title):
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                VStack(alignment: .leading) {
                    Text("有効なフィード")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(title)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

        case .invalid(let message):
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    NavigationStack {
        Text("RSSFeedDetailView Preview")
            .font(.headline)
    }
}
