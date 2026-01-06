//
//  DomainEditSheet.swift
//  KiroBookmark
//
//  Sheet for editing domain display name
//

import SwiftUI

struct DomainEditSheet: View {
    let domain: String
    let currentName: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(domain)
                        .foregroundColor(.secondary)
                } header: {
                    Text("ドメイン")
                }

                Section {
                    TextField("表示名", text: $editedName)
                } header: {
                    Text("表示名")
                } footer: {
                    Text("サイドメニューに表示される名前を設定できます")
                }
            }
            .navigationTitle("ドメイン名を編集")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(editedName)
                        dismiss()
                    }
                    .disabled(editedName.isEmpty)
                }
            }
            .onAppear {
                editedName = currentName
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    DomainEditSheet(
        domain: "example.com",
        currentName: "Example Blog",
        onSave: { _ in }
    )
}
