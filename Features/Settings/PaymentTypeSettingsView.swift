import SwiftUI
import SwiftData
import CoreGraphics

struct PaymentTypeSettingsView: View {
    var isSheet: Bool = false

    @Query(sort: \PaymentCustomType.sortOrder) private var customTypes: [PaymentCustomType]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager

    @State private var showAddSheet = false
    @State private var editingType: PaymentCustomType? = nil
    @State private var newTypeName = ""
    @State private var deleteTarget: PaymentCustomType? = nil
    @State private var showDeleteConfirm = false

    private var viewData: PaymentTypeSettingsViewData {
        PaymentTypeSettingsViewDataBuilder.build(customTypes: customTypes)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                List {
                    ForEach(viewData.rows) { row in
                        HStack(spacing: 12) {
                            Text(row.displayName)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingType = row.type
                                }

                            Button {
                                deleteTarget = row.type
                                showDeleteConfirm = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red.opacity(0.8))
                                    .font(.subheadline)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                        .moveDisabled(false)
                    }
                    .onMove { from, to in
                        var reordered = customTypes
                        reordered.move(fromOffsets: from, toOffset: to)
                        for (index, type) in reordered.enumerated() {
                            type.sortOrder = index
                        }
                        try? modelContext.save()
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: 56)
                }
                HStack {
                    Spacer()

                    Button {
                        newTypeName = ""
                        showAddSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("タイプを追加")
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(theme.current.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(theme.current.primaryXLight)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 0)
                }
                .listStyle(.insetGrouped)
                .environment(\.editMode, .constant(.active))
                .frame(height: viewData.listHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color(.systemGroupedBackground))
            .navigationTitle("課金タイプ管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.current.primary)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            typeSheet(title: "タイプを追加", name: $newTypeName) {
                let maxOrder = customTypes.map(\.sortOrder).max() ?? -1
                modelContext.insert(
                    PaymentCustomType(name: newTypeName, sortOrder: maxOrder + 1)
                )
                try? modelContext.save()
            }
        }
        .sheet(item: $editingType) { type in
            let binding = Binding(
                get: { type.name },
                set: { type.name = $0 }
            )
            typeSheet(title: "タイプを編集", name: binding) {
                try? modelContext.save()
            }
        }
        .confirmationDialog(
            "「\(deleteTarget?.name ?? "")」を削除しますか？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                if let target = deleteTarget {
                    modelContext.delete(target)
                    try? modelContext.save()
                    deleteTarget = nil
                }
            }
            Button("キャンセル", role: .cancel) {
                deleteTarget = nil
            }
        }
    }
}

private extension PaymentTypeSettingsView {
    func typeSheet(
        title: String,
        name: Binding<String>,
        onSave: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 14)

            ZStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    Button("キャンセル") {
                        showAddSheet = false
                        editingType = nil
                    }
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button("保存") {
                        let trimmed = PaymentTypeSettingsViewDataBuilder.normalizedName(name.wrappedValue)
                        guard PaymentTypeSettingsViewDataBuilder.canSave(name: trimmed) else { return }
                        name.wrappedValue = trimmed
                        onSave()
                        showAddSheet = false
                        editingType = nil
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(theme.current.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            TextField("タイプ名を入力", text: name)
                .padding(14)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 20)

            Spacer()
        }
        .presentationDetents([.height(200)])
        .presentationBackground(Color(.systemBackground))
    }
}

#Preview {
    let schema = Schema([
        PaymentCustomType.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let context = container.mainContext

    ["ガチャ", "アイテム購入", "パス更新"].enumerated().forEach { index, name in
        context.insert(PaymentCustomType(name: name, sortOrder: index))
    }

    return NavigationStack {
        PaymentTypeSettingsView(isSheet: false)
    }
    .modelContainer(container)
    .environmentObject(ThemeManager())
}
