//
//  MemoCardView.swift
//  KiroBookmark
//
//  Card view for displaying a memo with type indicator
//

import SwiftUI
import CoreData

struct MemoCardView: View {
    let memo: TweetMemo
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var memoType: MemoType {
        MemoType(rawValue: memo.memoType ?? "") ?? .other
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerSection
            contentSection
            if memo.isQuote {
                quoteSection
            }
            footerSection
        }
        .padding(12)
        .background(Color.systemBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(memoType.color.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            memoTypeBadge
            Spacer()
            menuButton
        }
    }

    private var memoTypeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: memoType.systemIcon)
                .font(.caption)
            Text(memoType.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(memoType.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(memoType.color.opacity(0.1))
        .cornerRadius(8)
    }

    private var menuButton: some View {
        Menu {
            Button(action: onEdit) {
                Label("編集", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("削除", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        Text(memo.content ?? "")
            .font(.body)
            .foregroundColor(.primary)
            .lineLimit(5)
            .multilineTextAlignment(.leading)
    }

    // MARK: - Quote Section

    private var quoteSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let selectedText = memo.selectedText, !selectedText.isEmpty {
                Text("「\(selectedText)」")
                    .font(.callout)
                    .italic()
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .padding(.leading, 8)
                    .overlay(
                        Rectangle()
                            .fill(Color.purple.opacity(0.5))
                            .frame(width: 2),
                        alignment: .leading
                    )
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack {
            timestampLabel
            Spacer()
            if memo.isQuote {
                quoteBadge
            }
        }
    }

    private var timestampLabel: some View {
        Text(formatDate(memo.createdDate))
            .font(.caption2)
            .foregroundColor(.secondary)
    }

    private var quoteBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "quote.bubble")
                .font(.caption2)
            Text("引用")
                .font(.caption2)
        }
        .foregroundColor(.purple)
    }

    // MARK: - Date Formatting

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }

        let elapsed = Date().timeIntervalSince(date)
        let hours = Int(elapsed / 3600)
        let days = Int(elapsed / 86400)

        if hours < 1 {
            return "たった今"
        } else if hours < 24 {
            return "\(hours)時間前"
        } else if days < 7 {
            return "\(days)日前"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview

#Preview {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext

    let memo = TweetMemo(context: context)
    memo.id = UUID()
    memo.content = "SwiftUIのViewは100行以下に保つべき。これはMVVMパターンを守るための基本原則。"
    memo.memoType = MemoType.idea.rawValue
    memo.createdDate = Date()
    memo.updatedDate = Date()
    memo.isQuote = false

    return MemoCardView(
        memo: memo,
        onEdit: {},
        onDelete: {}
    )
    .padding()
}
