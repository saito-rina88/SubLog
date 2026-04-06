import SwiftUI
import SwiftData

struct ServiceListView: View {
    @EnvironmentObject private var entitlements: EntitlementManager
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Service.name) private var services: [Service]
    @State private var showAddService = false
    @State private var selectedServiceType: ServiceType
    @State private var searchText = ""
    @State private var serviceToEdit: Service?
    @State private var serviceToDelete: Service?
    @State private var showPremiumSheet = false

    let managementMode: Bool
    let serviceType: ServiceType?

    private let cardBackground = Color.white.opacity(0.86)
    private let cardBorder = Color(red: 188 / 255, green: 198 / 255, blue: 230 / 255).opacity(0.45)
    private let primaryText = Color(red: 33 / 255, green: 38 / 255, blue: 58 / 255)
    private let mutedText = Color(red: 86 / 255, green: 95 / 255, blue: 126 / 255).opacity(0.78)
    private let sectionText = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
    private let searchTint = Color(red: 121 / 255, green: 130 / 255, blue: 162 / 255).opacity(0.7)

    init(managementMode: Bool = false, serviceType: ServiceType? = nil) {
        self.managementMode = managementMode
        self.serviceType = serviceType
        _selectedServiceType = State(initialValue: serviceType ?? .subscription)
    }

    var body: some View {
        NavigationStack {
            content
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.current.primary)
            .scrollContentBackground(.hidden)
            .sheet(isPresented: $showAddService) {
                AddServiceView(serviceType: currentServiceType)
            }
            .sheet(item: $serviceToEdit) { service in
                EditServiceView(service: service, fixedServiceType: service.serviceType)
            }
            .sheet(isPresented: $showPremiumSheet) {
                SubscriptionManagementView(displayMode: .serviceLimitReached)
            }
            .alert("サービスを削除しますか？", isPresented: deleteAlertBinding) {
                Button("キャンセル", role: .cancel) {
                    serviceToDelete = nil
                }
                Button("削除", role: .destructive) {
                    deleteSelectedService()
                }
            } message: {
                Text("支払い履歴は残り、サービス一覧からのみ外れます。サブスクは停止扱いになります。")
            }
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .onAppear {
                normalizeServiceOrderIfNeeded(for: currentServiceType)
            }
            .onChange(of: selectedServiceType) { _, newValue in
                normalizeServiceOrderIfNeeded(for: newValue)
            }
        }
    }
}

private extension ServiceListView {
    var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { serviceToDelete != nil },
            set: { newValue in
                if !newValue {
                    serviceToDelete = nil
                }
            }
        )
    }

    @ViewBuilder
    var content: some View {
        if managementMode {
            managementContent
        } else if services.isEmpty {
            emptyState
        } else {
            serviceList
        }
    }

    var currentServiceType: ServiceType {
        serviceType ?? selectedServiceType
    }

    var filteredServices: [Service] {
        services
            .filter { $0.serviceType == currentServiceType && !$0.isArchived }
            .filter {
                searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { lhs, rhs in
                if managementMode {
                    if lhs.sortOrder == rhs.sortOrder {
                        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                    }
                    return lhs.sortOrder < rhs.sortOrder
                }

                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    var navigationTitle: String {
        managementMode ? "" : "サービス"
    }

    var managementContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("サービス一覧")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 5)
                .padding(.horizontal, 20)
                .padding(.bottom, 0)

            serviceTypeSegment
                .padding(.horizontal, 20)

            searchBar
                .padding(.horizontal, 20)

            HStack(alignment: .center, spacing: 12) {
                Text(currentServiceType == .subscription ? "定期支払いのサービス" : "単発支払いのサービス")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(sectionText)

                Spacer()

                addServiceButton
            }
            .padding(.horizontal, 20)

            if filteredServices.isEmpty {
                managementEmptyState
                    .padding(.horizontal, 20)
                Spacer(minLength: 0)
            } else {
                List {
                    ForEach(filteredServices, id: \.persistentModelID) { service in
                        managementServiceCard(service)
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .moveDisabled(!canReorderServices)
                    }
                    .onMove(perform: moveServices)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background {
                    SwiftUI.Color.clear
                }
                .environment(\.editMode, .constant(.active))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    var serviceList: some View {
        List {
            ForEach(filteredServices, id: \.persistentModelID) { service in
                NavigationLink {
                    destination(for: service)
                } label: {
                    serviceRow(for: service)
                }
            }
        }
    }

    var serviceTypeSegment: some View {
        Picker("サービス種別", selection: $selectedServiceType) {
            Text("定期支払い").tag(ServiceType.subscription)
            Text("単発支払い").tag(ServiceType.game)
        }
        .pickerStyle(.segmented)
        .tint(theme.current.primary)
    }

    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(searchTint)

            TextField(
                "",
                text: $searchText,
                prompt: Text("サービスを検索").foregroundStyle(searchTint)
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(primaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.92))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(cardBorder, lineWidth: 0.8)
        }
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 16, y: 8)
    }

    var addServiceButton: some View {
        Button {
            if entitlements.canAddService(currentCount: services.filter { !$0.isArchived }.count) {
                showAddService = true
            } else {
                showPremiumSheet = true
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(theme.current.primary)
                Text("追加")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.current.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(cardBorder, lineWidth: 0.8)
            }
            .cornerRadius(12)
            .shadow(color: theme.current.primary.opacity(0.12), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    func managementServiceCard(_ service: Service) -> some View {
        HStack(spacing: 14) {
            ServiceIconView(service: service, size: 44)

            Text(service.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(primaryText)

            Spacer(minLength: 12)

            Menu {
                Button {
                    serviceToEdit = service
                } label: {
                    Label("編集", systemImage: "pencil")
                }
                .tint(.primary)

                Button(role: .destructive) {
                    serviceToDelete = service
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
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(cardBorder, lineWidth: 0.8)
        }
        .cornerRadius(16)
        .shadow(color: theme.current.primary.opacity(0.08), radius: 18, y: 10)
    }

    var managementEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.secondary)

            Text(emptyStateTitle)
                .font(.headline)
                .multilineTextAlignment(.center)

            Button("＋ サービスを追加") {
                showAddService = true
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.current.primary)
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

    func deleteSelectedService() {
        guard let serviceToDelete else { return }
        let deletedType = serviceToDelete.serviceType
        serviceToDelete.isArchived = true
        for subscription in serviceToDelete.subscriptions where subscription.isActive {
            subscription.isActive = false
            subscription.canceledDate = subscription.canceledDate ?? .now
        }
        reindexServices(for: deletedType)
        try? modelContext.save()
        self.serviceToDelete = nil
    }

    var canReorderServices: Bool {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !filteredServices.isEmpty
    }

    func moveServices(from source: IndexSet, to destination: Int) {
        var reordered = filteredServices
        reordered.move(fromOffsets: source, toOffset: destination)

        for (index, service) in reordered.enumerated() {
            service.sortOrder = index
        }

        try? modelContext.save()
    }

    func reindexServices(for type: ServiceType) {
        let typedServices = services
            .filter { $0.serviceType == type && !$0.isArchived }
            .sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
                return lhs.sortOrder < rhs.sortOrder
            }

        for (index, service) in typedServices.enumerated() {
            service.sortOrder = index
        }
    }

    func normalizeServiceOrderIfNeeded(for type: ServiceType) {
        let typedServices = services
            .filter { $0.serviceType == type && !$0.isArchived }
            .sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
                return lhs.sortOrder < rhs.sortOrder
            }

        let needsNormalization = typedServices.enumerated().contains { index, service in
            service.sortOrder != index
        }

        guard needsNormalization else { return }

        for (index, service) in typedServices.enumerated() {
            service.sortOrder = index
        }

        try? modelContext.save()
    }
}

private extension ServiceListView {
    func serviceRow(for service: Service) -> some View {
        HStack(spacing: 12) {
            ServiceIconView(service: service, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(service.name)
                    .font(.headline)
                Text(service.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(totalAmount(for: service), format: .currency(code: "JPY"))
                .font(.headline)
                .foregroundStyle(theme.current.primary)
        }
        .padding(.vertical, 4)
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.secondary)

            Text(emptyStateTitle)
                .font(.headline)
                .multilineTextAlignment(.center)

            Button("＋ サービスを追加") {
                showAddService = true
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.current.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    var emptyStateTitle: String {
        switch currentServiceType {
        case .subscription:
            return "まだ定期支払いのサービスが登録されていません"
        case .game:
            return "まだ単発支払いのサービスが登録されていません"
        }
    }

    func totalAmount(for service: Service) -> Int {
        service.payments.reduce(0) { $0 + $1.amount }
    }

    @ViewBuilder
    func destination(for service: Service) -> some View {
        switch service.serviceType {
        case .game:
            if let payment = service.payments.sorted(by: { $0.date > $1.date }).first {
                GameChargeDetailView(payment: payment)
            } else {
                ServiceDetailView(service: service)
            }
        case .subscription:
            if let subscription = service.subscriptions.first {
                SubscriptionDetailView(subscription: subscription, service: service)
            } else {
                ServiceDetailView(service: service)
            }
        }
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

    return ServiceListView()
        .environmentObject(ThemeManager())
        .modelContainer(container)
}
