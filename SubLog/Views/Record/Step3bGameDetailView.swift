import SwiftUI
import SwiftData

struct Step3bGameDetailView: View {
    let serviceID: PersistentIdentifier
    @Binding var path: NavigationPath

    @Query private var allServices: [Service]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var entitlements: EntitlementManager

    @State private var amount: String = ""
    @State private var selectedTemplateIDs: Set<PersistentIdentifier> = []
    @State private var templateQuantities: [PersistentIdentifier: Int] = [:]
    @State private var date: Date = Date()
    @State private var memo: String = ""
    @State private var showTemplateSettings = false

    private var viewData: Step3bGameDetailViewData {
        Step3bGameDetailViewDataBuilder.build(
            allServices: allServices,
            serviceID: serviceID,
            selectedTemplateIDs: selectedTemplateIDs,
            templateQuantities: templateQuantities,
            amountText: amount
        )
    }

    var body: some View {
        Form {
            Section {
                Text("支払い情報を入力")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)
                    .padding(.bottom, -10)
                    .listRowBackground(Color.clear)
            }

            Section("金額") {
                HStack(spacing: 8) {
                    Text("¥")
                        .foregroundStyle(.secondary)
                    TextField("0", text: $amount)
                        .keyboardType(.numberPad)
                }
            }

            Section {
                if viewData.sortedTemplates.isEmpty {
                    Text("このサービスにはテンプレートがありません。設定から追加してください。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewData.sortedTemplates, id: \.persistentModelID) { template in
                        templateSelectionRow(for: template)
                    }
                }
            } header: {
                HStack {
                    Text("購入内容（任意）")
                    Spacer()
                    Button {
                        showTemplateSettings = true
                    } label: {
                        Text("テンプレート編集")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.current.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.86))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color(red: 188 / 255, green: 198 / 255, blue: 230 / 255).opacity(0.45),
                                        lineWidth: 0.8
                                    )
                            }
                            .cornerRadius(12)
                            .shadow(color: theme.current.primary.opacity(0.08), radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)
                    .textCase(.none)
                }
            } footer: {
                if viewData.hasSelectedTemplateWithoutAmount {
                    Text("金額未設定の購入内容を選択しています。必要に応じて金額を手入力してください。")
                }
            }

            Section("支払日") {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    .environment(\.calendar, mondayFirstCalendar)
                    .tint(theme.current.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("メモ") {
                ZStack(alignment: .topLeading) {
                    if memo.isEmpty {
                        Text("メモ")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }

                    TextEditor(text: $memo)
                        .frame(minHeight: 60)
                        .scrollContentBackground(.hidden)
                }
            }

            Section {
                Button("記録する") {
                    save()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .listRowBackground(theme.current.primary)
                .disabled(!viewData.canSave)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 56)
        }
        .padding(.top, -60)
        .scrollContentBackground(.hidden)
        .background(theme.current.primaryXLight)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            syncSelectedTemplates()
            applySelectedTemplateAmounts()
        }
        .onChange(of: viewData.sortedTemplates.map(\.persistentModelID)) { _, _ in
            syncSelectedTemplates()
        }
        .sheet(isPresented: $showTemplateSettings) {
            NavigationStack {
                GachaTemplateSettingsView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("閉じる") {
                                showTemplateSettings = false
                            }
                        }
                    }
            }
            .environmentObject(theme)
            .environmentObject(entitlements)
        }
    }
}

private extension Step3bGameDetailView {
    var service: Service? {
        viewData.service
    }

    var sortedTemplates: [GachaTemplate] {
        viewData.sortedTemplates
    }

    var selectedTemplates: [GachaTemplate] {
        viewData.selectedTemplates
    }

    var amountValue: Int {
        viewData.amountValue
    }

    var mondayFirstCalendar: Calendar {
        Step3bGameDetailViewDataBuilder.mondayFirstCalendar
    }

    func templateSelectionRow(for template: GachaTemplate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                toggleTemplateSelection(template)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: selectedTemplateIDs.contains(template.persistentModelID) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selectedTemplateIDs.contains(template.persistentModelID) ? theme.current.primary : .secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.label)
                            .foregroundStyle(.primary)

                        if let templateAmount = template.amount {
                            Text("¥\(templateAmount.formatted())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if selectedTemplateIDs.contains(template.persistentModelID) {
                        Text("×\(templateQuantities[template.persistentModelID, default: 1])")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.current.primary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if selectedTemplateIDs.contains(template.persistentModelID) {
                HStack {
                    Text("購入数")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Stepper(value: quantityBinding(for: template), in: 1...99) {
                        Text("\(templateQuantities[template.persistentModelID, default: 1])")
                            .foregroundStyle(theme.current.primary)
                            .fontWeight(.medium)
                    }
                    .labelsHidden()
                    .onChange(of: templateQuantities[template.persistentModelID, default: 1]) { _, _ in
                        applySelectedTemplateAmounts()
                    }
                }
                .padding(.leading, 34)
            }
        }
        .padding(.vertical, 4)
    }

    func quantityBinding(for template: GachaTemplate) -> Binding<Int> {
        Binding(
            get: { templateQuantities[template.persistentModelID, default: 1] },
            set: { newValue in
                templateQuantities[template.persistentModelID] = max(newValue, 1)
            }
        )
    }

    func toggleTemplateSelection(_ template: GachaTemplate) {
        let templateID = template.persistentModelID

        if selectedTemplateIDs.contains(templateID) {
            selectedTemplateIDs.remove(templateID)
            templateQuantities.removeValue(forKey: templateID)
        } else {
            selectedTemplateIDs.insert(templateID)
            templateQuantities[templateID] = max(templateQuantities[templateID] ?? 1, 1)
        }

        applySelectedTemplateAmounts()
    }

    func save() {
        guard let service, amountValue > 0 else { return }

        let payment = Payment(
            date: date,
            amount: amountValue,
            type: purchaseSummary,
            service: service,
            memo: memo.trimmedNilIfEmpty
        )
        modelContext.insert(payment)
        service.payments.append(payment)
        try? modelContext.save()
        path = NavigationPath()
        dismiss()
    }

    var purchaseSummary: String {
        viewData.purchaseSummary
    }

    func syncSelectedTemplates() {
        let syncedSelection = Step3bGameDetailViewDataBuilder.syncedSelection(
            sortedTemplates: sortedTemplates,
            selectedTemplateIDs: selectedTemplateIDs,
            templateQuantities: templateQuantities
        )
        selectedTemplateIDs = syncedSelection.selectedTemplateIDs
        templateQuantities = syncedSelection.templateQuantities

        if selectedTemplateIDs.isEmpty {
            amount = ""
            return
        }

        applySelectedTemplateAmounts()
    }

    func applySelectedTemplateAmounts() {
        guard !selectedTemplates.isEmpty else {
            amount = ""
            return
        }

        let total = Step3bGameDetailViewDataBuilder.selectedTemplateTotal(
            selectedTemplates: selectedTemplates,
            templateQuantities: templateQuantities
        )

        if total > 0 {
            amount = String(total)
        } else {
            amount = ""
        }
    }
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
