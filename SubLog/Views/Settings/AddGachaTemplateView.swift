import SwiftUI
import SwiftData

struct AddGachaTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager
    @Query private var services: [Service]

    @State private var selectedServiceID: PersistentIdentifier?
    @State private var label = ""
    @State private var amountText = ""

    private let preselectedService: Service?

    private var viewData: AddGachaTemplateViewData {
        AddGachaTemplateViewDataBuilder.build(
            services: services,
            selectedServiceID: selectedServiceID,
            label: label,
            amountText: amountText
        )
    }

    init(preselectedService: Service? = nil) {
        self.preselectedService = preselectedService
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    inputCard(title: "サービス") {
                        Text(viewData.selectedService?.name ?? "未選択")
                            .foregroundStyle(viewData.selectedService == nil ? .secondary : .primary)
                    }

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
            .navigationTitle("テンプレート追加")
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
                if selectedServiceID == nil {
                    selectedServiceID = preselectedService?.persistentModelID ?? viewData.gameServices.first?.persistentModelID
                }
            }
        }
    }
}

private extension AddGachaTemplateView {
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
        .disabled(!viewData.canSave)
        .opacity(viewData.canSave ? 1 : 0.4)
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

    func saveTemplate() {
        guard let selectedService = viewData.selectedService, viewData.canSave else {
            return
        }

        let sortOrder = (selectedService.gachaTemplates.map(\.sortOrder).max() ?? -1) + 1
        let template = GachaTemplate(
            label: viewData.trimmedLabel,
            amount: viewData.trimmedAmountText.isEmpty ? nil : viewData.amountValue,
            service: selectedService,
            sortOrder: sortOrder
        )

        selectedService.gachaTemplates.append(template)
        modelContext.insert(template)
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

    return AddGachaTemplateView()
        .environmentObject(ThemeManager())
        .modelContainer(container)
}
