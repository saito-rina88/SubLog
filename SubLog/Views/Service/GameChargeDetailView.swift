import SwiftUI
import SwiftData

private enum PaymentField: Identifiable {
    case amount
    case type
    case date
    case memo

    var id: Self { self }
}

struct GameChargeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager

    let payment: Payment

    @State private var editingField: PaymentField?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    paymentInfoCard
                }
                .padding(.vertical, 20)
            }
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.current.primary)
            .sheet(item: $editingField) { field in
                EditPaymentFieldView(payment: payment, field: field)
            }
        }
    }
}

private extension GameChargeDetailView {
    var headerCard: some View {
        HStack(spacing: 14) {
            ServiceIconView(service: payment.service, size: 44)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color(.systemBackground))
                )
            Text(payment.service.name)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(theme.current.primaryDeep)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(theme.current.primaryMid.opacity(0.15))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    var paymentInfoCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            infoButtonRow(label: "金額", value: "¥\(payment.amount.formatted())", field: .amount)
            Divider()
            infoButtonRow(
                label: "購入内容",
                value: payment.type.replacingOccurrences(of: "、", with: "\n"),
                field: .type
            )
            Divider()
            infoButtonRow(label: "日付", value: dateString(payment.date), field: .date)

            if let memo = payment.memo, !memo.isEmpty {
                Divider()
                infoButtonRow(label: "メモ", value: memo, field: .memo)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    func infoButtonRow(label: String, value: String, field: PaymentField) -> some View {
        Button {
            editingField = field
        } label: {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .fontWeight(.medium)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
        }
        .foregroundStyle(.primary)
        .buttonStyle(.plain)
    }

    func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

private struct EditPaymentFieldView: View {
    let payment: Payment
    let field: PaymentField

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager

    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var memo: String = ""
    @State private var selectedTemplateIDs: Set<PersistentIdentifier> = []
    @State private var templateQuantities: [PersistentIdentifier: Int] = [:]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                Spacer()
            }
            .padding(.top, 10)
            .padding(.bottom, 14)

            ZStack {
                Text(fieldTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("保存") { save() }
                        .fontWeight(.bold)
                        .foregroundStyle(theme.current.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            inputView
                .padding(.horizontal, 20)

            Spacer()
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationBackground(Color(.systemBackground))
        .presentationDragIndicator(.hidden)
        .tint(theme.current.primary)
        .onAppear { loadCurrentValue() }
    }
}

private extension EditPaymentFieldView {
    var sortedTemplates: [GachaTemplate] {
        payment.service.gachaTemplates.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.label < rhs.label
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    @ViewBuilder
    var inputView: some View {
        switch field {
        case .amount:
            HStack(spacing: 4) {
                Text("¥")
                    .font(.body)
                    .foregroundStyle(.secondary)
                TextField("0", text: $amount)
                    .font(.body)
                    .keyboardType(.numberPad)
            }
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(10)

        case .type:
            if sortedTemplates.isEmpty {
                Text("このサービスにはテンプレートがありません。設定から追加してください。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(sortedTemplates, id: \.persistentModelID) { template in
                            templateSelectionRow(for: template)
                        }
                    }
                }
            }

        case .date:
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .environment(\.calendar, mondayFirstCalendar)
                .accentColor(theme.current.primary)
                .frame(maxWidth: .infinity)

        case .memo:
            ZStack(alignment: .topLeading) {
                TextEditor(text: $memo)
                    .font(.body)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                if memo.isEmpty {
                    Text("メモを入力（任意）")
                        .foregroundStyle(.tertiary)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    var fieldTitle: String {
        switch field {
        case .amount: return "金額"
        case .type: return "購入内容"
        case .date: return "日付"
        case .memo: return "メモ"
        }
    }

    var sheetHeight: CGFloat {
        switch field {
        case .amount:
            return 180
        case .type:
            return 420
        case .date:
            return 440
        case .memo:
            return 300
        }
    }

    func loadCurrentValue() {
        amount = String(payment.amount)
        date = payment.date
        memo = payment.memo ?? ""
        loadSelectedTemplates()
    }

    func save() {
        switch field {
        case .amount:
            if let value = Int(amount) {
                payment.amount = value
            }
        case .type:
            let normalized = purchaseSummary
            if !normalized.isEmpty {
                payment.type = normalized
                if calculatedAmount > 0 {
                    payment.amount = calculatedAmount
                }
            }
        case .date:
            payment.date = date
        case .memo:
            payment.memo = memo.isEmpty ? nil : memo
        }
        try? modelContext.save()
        dismiss()
    }

    var mondayFirstCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.firstWeekday = 2
        return calendar
    }

    var purchaseSummary: String {
        sortedTemplates
            .filter { selectedTemplateIDs.contains($0.persistentModelID) }
            .map { template in
                let quantity = templateQuantities[template.persistentModelID, default: 1]
                return quantity > 1 ? "\(template.label) ×\(quantity)" : template.label
            }
            .joined(separator: "、")
    }

    var calculatedAmount: Int {
        sortedTemplates.reduce(0) { result, template in
            guard selectedTemplateIDs.contains(template.persistentModelID) else { return result }
            let quantity = templateQuantities[template.persistentModelID, default: 1]
            return result + (template.amount ?? 0) * quantity
        }
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
    }

    func loadSelectedTemplates() {
        selectedTemplateIDs = []
        templateQuantities = [:]

        let items = payment.type
            .split(separator: "、")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for item in items {
            let components = item.components(separatedBy: " ×")
            let label = components.first ?? item
            let quantity = components.count > 1 ? max(Int(components[1]) ?? 1, 1) : 1

            guard let template = sortedTemplates.first(where: { $0.label == label }) else { continue }
            selectedTemplateIDs.insert(template.persistentModelID)
            templateQuantities[template.persistentModelID] = quantity
        }
    }
}

#Preview {
    let schema = Schema([
        Service.self,
        Subscription.self,
        Payment.self,
        GachaTemplate.self,
        PaymentCustomType.self
    ])
    let container = try! ModelContainer(
        for: schema,
        configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    )
    let services = SampleDataFactory.makeServices()
    services.forEach {
        container.mainContext.insert($0)
    }
    SampleDataFactory.insertDefaultPaymentCustomTypesIfNeeded(into: container.mainContext)
    let payment = services.first { $0.serviceType == .game }!.payments.first!

    return GameChargeDetailView(payment: payment)
        .environmentObject(ThemeManager())
        .modelContainer(container)
}
