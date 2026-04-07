import SwiftUI
import SwiftData

struct GachaTemplateSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var entitlements: EntitlementManager
    @Query(sort: \Service.name) private var services: [Service]

    @State private var selectedServiceForSheet: Service?
    @State private var selectedTemplateForEdit: GachaTemplate?
    @State private var selectedTemplateForDelete: GachaTemplate?
    @State private var showAddSheet = false

    private let cardBackground = Color.white.opacity(0.86)
    private let cardBorder = Color(red: 188 / 255, green: 198 / 255, blue: 230 / 255).opacity(0.45)
    private let primaryText = Color(red: 33 / 255, green: 38 / 255, blue: 58 / 255)
    private let mutedText = Color(red: 86 / 255, green: 95 / 255, blue: 126 / 255).opacity(0.78)
    private let sectionText = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)

    private var viewData: GachaTemplateSettingsViewData {
        GachaTemplateSettingsViewDataBuilder.build(services: services)
    }

    var body: some View {
        NavigationStack {
            List {
                if viewData.isEmpty {
                    Section {
                        emptyState
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                } else {
                    ForEach(viewData.serviceRows) { row in
                        TemplateServiceSectionView(
                            service: row.service,
                            onAddTemplate: { addTemplate(for: row.service) },
                            onEditTemplate: { template in
                                selectedTemplateForEdit = template
                            },
                            onDeleteTemplate: { template in
                                selectedTemplateForDelete = template
                            },
                            cardBackground: cardBackground,
                            cardBorder: cardBorder,
                            primaryText: primaryText,
                            mutedText: mutedText,
                            sectionText: sectionText
                        )
                        .environmentObject(theme)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 56)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.current.primary)
            .environment(\.editMode, .constant(.active))
            .safeAreaInset(edge: .top) {
                Text("購入内容テンプレート")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 5)
                    .padding(.bottom, 8)
                    .background(theme.current.primaryXLight)
            }
            .sheet(isPresented: $showAddSheet) {
                AddGachaTemplateView(preselectedService: selectedServiceForSheet)
                    .environmentObject(theme)
                    .environmentObject(entitlements)
            }
            .sheet(item: $selectedTemplateForEdit) { template in
                EditGachaTemplateView(template: template)
                    .environmentObject(theme)
            }
            .alert(MessageCatalog.templateDeleteTitle, isPresented: deleteAlertBinding) {
                Button("キャンセル", role: .cancel) {
                    selectedTemplateForDelete = nil
                }
                Button("削除", role: .destructive) {
                    deleteSelectedTemplate()
                }
            } message: {
                Text(MessageCatalog.operationCannotBeUndone)
            }
        }
    }
}

private extension GachaTemplateSettingsView {
    func addTemplate(for service: Service) {
        selectedServiceForSheet = service
        showAddSheet = true
    }

    var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { selectedTemplateForDelete != nil },
            set: { newValue in
                if !newValue {
                    selectedTemplateForDelete = nil
                }
            }
        )
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.secondary)

            Text(viewData.emptyStateTitle)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(cardBorder, lineWidth: 0.8)
        }
        .cornerRadius(16)
    }

    func deleteSelectedTemplate() {
        guard let template = selectedTemplateForDelete else { return }
        template.service.gachaTemplates.removeAll { $0.persistentModelID == template.persistentModelID }
        modelContext.delete(template)

        for (index, item) in template.service.gachaTemplates.enumerated() {
            item.sortOrder = index
        }

        try? modelContext.save()
        selectedTemplateForDelete = nil
    }
}

private struct TemplateServiceSectionView: View {
    @Environment(\.editMode) private var editMode
    @EnvironmentObject private var theme: ThemeManager
    @Bindable var service: Service

    let onAddTemplate: () -> Void
    let onEditTemplate: (GachaTemplate) -> Void
    let onDeleteTemplate: (GachaTemplate) -> Void
    let cardBackground: Color
    let cardBorder: Color
    let primaryText: Color
    let mutedText: Color
    let sectionText: Color

    var body: some View {
        Section {
            if service.gachaTemplates.isEmpty {
                Text("テンプレートがまだありません。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                    .listRowBackground(cardBackground)
            } else {
                ForEach(service.gachaTemplates, id: \.persistentModelID) { template in
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.label)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(primaryText)

                            if let amount = template.amount {
                                Text(amount.formatted(.currency(code: "JPY")))
                                    .font(.caption)
                                    .foregroundStyle(mutedText)
                            }
                        }

                        Spacer()

                        Menu {
                            Button {
                                onEditTemplate(template)
                            } label: {
                                Label("編集", systemImage: "pencil")
                            }
                            .tint(.primary)

                            Button(role: .destructive) {
                                onDeleteTemplate(template)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                            .tint(.red)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .foregroundStyle(theme.current.primary)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(cardBackground)
                }
                .onMove(perform: moveTemplates)
            }
        } header: {
            HStack {
                Text(service.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(sectionText)
                    .textCase(.none)

                Spacer()

                Button("＋ 追加") {
                    onAddTemplate()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.current.primary)
                .textCase(.none)
            }
        }
        .onAppear {
            normalizeTemplateOrder()
        }
        .onChange(of: service.gachaTemplates.map(\.persistentModelID)) { _, _ in
            syncSortOrder()
        }
    }
}

private extension TemplateServiceSectionView {
    func moveTemplates(from source: IndexSet, to destination: Int) {
        service.gachaTemplates.move(fromOffsets: source, toOffset: destination)
        syncSortOrder()
    }

    func normalizeTemplateOrder() {
        let sorted = service.gachaTemplates.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.label < rhs.label
            }
            return lhs.sortOrder < rhs.sortOrder
        }

        guard sorted.map(\.persistentModelID) != service.gachaTemplates.map(\.persistentModelID) else {
            syncSortOrder()
            return
        }

        service.gachaTemplates = sorted
        syncSortOrder()
    }

    func syncSortOrder() {
        for (index, template) in service.gachaTemplates.enumerated() {
            template.sortOrder = index
        }
    }
}

private struct EditGachaTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager

    let template: GachaTemplate

    @State private var label: String = ""
    @State private var amountText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    inputCard(title: "テンプレート名") {
                        TextField("例：10連、単発、月パック", text: $label)
                            .textFieldStyle(.roundedBorder)
                    }

                    inputCard(title: "金額") {
                        TextField("任意", text: $amountText)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }

                    saveButton
                }
                .padding(20)
            }
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("テンプレート編集")
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.current.primary)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                label = template.label
                amountText = template.amount.map(String.init) ?? ""
            }
        }
    }
}

private extension EditGachaTemplateView {
    var saveButton: some View {
        Button {
            saveTemplate()
        } label: {
            Text("保存する")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [theme.current.primary, theme.current.primaryDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.4)
    }

    func inputCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 6)
        )
    }

    var amountValue: Int {
        ViewDataCommon.intValue(from: amountText)
    }

    var trimmedAmountText: String {
        amountText.trimmedText
    }

    var canSave: Bool {
        !label.isTrimmedEmpty &&
        (trimmedAmountText.isEmpty || amountValue > 0)
    }

    func saveTemplate() {
        guard canSave else { return }

        template.label = label.trimmedText
        template.amount = trimmedAmountText.isEmpty ? nil : amountValue

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Service.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    SampleDataFactory.makeServices().forEach {
        container.mainContext.insert($0)
    }

    return GachaTemplateSettingsView()
        .environmentObject(ThemeManager())
        .environmentObject(EntitlementManager())
        .modelContainer(container)
}
