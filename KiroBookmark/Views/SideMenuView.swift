//
//  SideMenuView.swift
//  KiroBookmark
//
//  Side menu for memo type filtering
//

import SwiftUI

struct SideMenuView: View {
    @ObservedObject var viewModel: HomeViewModel
    let onSettingsTap: () -> Void
    @State private var domainToEdit: String?

    // MARK: - Constants

    private static let menuWidth: CGFloat = 280

    var body: some View {
        HStack(spacing: 0) {
            // Menu Content
            VStack(alignment: .leading, spacing: 0) {
                menuHeader
                Divider()
                ScrollView {
                    VStack(spacing: 0) {
                        menuItems
                        if !viewModel.domainList.isEmpty {
                            Divider().padding(.vertical, 8)
                            domainSection
                        }
                    }
                }
                Spacer()
                Divider()
                settingsButton
            }
            .frame(width: Self.menuWidth)
            .background(Color.systemBackground)

            // Dimmed background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.closeSideMenu()
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: $domainToEdit) { domain in
            DomainEditSheet(
                domain: domain,
                currentName: viewModel.domainList.first { $0.domain == domain }?.displayName ?? domain,
                onSave: { newName in
                    viewModel.updateDomainDisplayName(domain, name: newName)
                }
            )
        }
    }

    // MARK: - Menu Header

    private var menuHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("KiroBookmark")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.closeSideMenu()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            Text("メモ種類別フィルター")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Menu Items

    private var menuItems: some View {
        VStack(spacing: 4) {
            ForEach(viewModel.visibleMenuItems, id: \.self) { item in
                menuItemRow(item)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Domain Section

    private var domainSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            domainSectionHeader
            ForEach(viewModel.domainList, id: \.domain) { item in
                domainItemRow(item)
            }
        }
        .padding(.vertical, 8)
    }

    private var domainSectionHeader: some View {
        Text("ドメイン別")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.horizontal, 24)
            .padding(.bottom, 4)
    }

    private func domainItemRow(_ item: (domain: String, displayName: String, count: Int)) -> some View {
        let isSelected = viewModel.selectedDomain == item.domain

        return Button {
            viewModel.selectDomain(item.domain)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 24)

                Text(item.displayName)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)

                Spacer()

                Text("\(item.count)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isSelected ? Color.white.opacity(0.2) : Color.systemGray5)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .contextMenu {
            Button {
                domainToEdit = item.domain
            } label: {
                Label("表示名を編集", systemImage: "pencil")
            }
        }
    }

    private func menuItemRow(_ item: SideMenuItem) -> some View {
        let isSelected = viewModel.selectedMenuItem == item
        let count = viewModel.getMenuItemCount(item)
        let isEmpty = count == 0

        return Button {
            viewModel.selectMenuItem(item)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.systemIcon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : item.color)
                    .frame(width: 24)

                Text(item.displayName)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : (isEmpty ? .secondary : .primary))

                Spacer()

                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        isSelected ? Color.white.opacity(0.2) : Color.systemGray5
                    )
                    .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? item.color : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .opacity(isEmpty ? 0.6 : 1.0)
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        Button {
            onSettingsTap()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                Text("設定")
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}

// MARK: - String Identifiable Extension

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Preview

#Preview {
    SideMenuView(
        viewModel: HomeViewModel(),
        onSettingsTap: {}
    )
}
