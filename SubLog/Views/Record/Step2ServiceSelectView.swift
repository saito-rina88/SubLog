import SwiftUI
import SwiftData

struct Step2ServiceSelectView: View {
    let serviceType: ServiceType
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var entitlements: EntitlementManager
    @Query private var allServices: [Service]
    @EnvironmentObject private var theme: ThemeManager

    @State private var searchText = ""
    @State private var showAddService = false
    @State private var isManagingServices = false
    @State private var serviceToEdit: Service?
    @State private var serviceToDelete: Service?
    @State private var showPremiumSheet = false

    private let premiumCard = Color.white.opacity(0.86)
    private let premiumBorder = Color(red: 188 / 255, green: 198 / 255, blue: 230 / 255).opacity(0.45)
    private let primaryText = Color(red: 33 / 255, green: 38 / 255, blue: 58 / 255)
    private let mutedText = Color(red: 86 / 255, green: 95 / 255, blue: 126 / 255).opacity(0.78)
    private let sectionText = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
    private let searchTint = Color(red: 121 / 255, green: 130 / 255, blue: 162 / 255).opacity(0.7)

    private var viewData: Step2ServiceSelectViewData {
        Step2ServiceSelectViewDataBuilder.build(
            allServices: allServices,
            serviceType: serviceType,
            searchText: searchText,
            isPremium: entitlements.isPremium
        )
    }

    var body: some View {
        content
        .background(
            LinearGradient(
                colors: [
                    theme.current.primaryXLight,
                    theme.current.primaryLight.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 56)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddService) {
            AddServiceView(serviceType: serviceType)
        }
        .sheet(item: $serviceToEdit) { service in
            EditServiceView(service: service, fixedServiceType: serviceType)
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
        .onAppear {
            normalizeServiceOrderIfNeeded()
        }
        .onChange(of: searchText) { _, newValue in
            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                isManagingServices = false
            }
        }
    }
}

private extension Step2ServiceSelectView {
    @ViewBuilder
    var content: some View {
        if isManagingServices {
            reorderableContent
        } else {
            standardContent
        }
    }

    var standardContent: some View {
        ScrollView {
            headerAndActions

            VStack(spacing: 16) {
                ForEach(viewData.filteredServices) { service in
                    serviceCard(service)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    var reorderableContent: some View {
        VStack(spacing: 0) {
            headerAndActions

            List {
                ForEach(viewData.filteredServices) { service in
                    serviceCard(service)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .onMove(perform: moveServices)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .environment(\.editMode, .constant(.active))
        }
    }

    var headerAndActions: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("サービスを選択")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 5)
                .padding(.horizontal, 20)
                .padding(.bottom, 0)

            searchBar

            HStack(alignment: .center, spacing: 12) {
                Text("利用中のサービス")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(sectionText)

                Spacer()

                manageServiceButton
                addServiceButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 0)
        .padding(.bottom, 20)
    }

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
                .stroke(premiumBorder, lineWidth: 0.8)
        }
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 16, y: 8)
    }

    func serviceCard(_ service: Service) -> some View {
        Button {
            guard !isManagingServices else { return }
            let step: RecordStep = serviceType == .subscription
                ? .subscDetail(serviceID: service.persistentModelID)
                : .gameDetail(serviceID: service.persistentModelID)
            path.append(step)
        } label: {
            HStack(spacing: 14) {
                ServiceIconView(service: service, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(primaryText)
                }

                Spacer(minLength: 12)

                if isManagingServices {
                    Menu {
                        Button {
                            serviceToEdit = service
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            serviceToDelete = service
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(theme.current.primary)
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(searchTint)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(premiumCard)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(premiumBorder, lineWidth: 0.8)
            }
            .cornerRadius(16)
            .shadow(color: theme.current.primary.opacity(0.08), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
    }

    var manageServiceButton: some View {
        Button {
            isManagingServices.toggle()
        } label: {
            Text(isManagingServices ? "完了" : "編集")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isManagingServices ? .blue : theme.current.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(premiumCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(premiumBorder, lineWidth: 0.8)
                }
                .cornerRadius(12)
                .shadow(color: theme.current.primary.opacity(0.08), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    var addServiceButton: some View {
        Button {
            if viewData.canAddService {
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
            .background(premiumCard)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(premiumBorder, lineWidth: 0.8)
            }
            .cornerRadius(12)
            .shadow(color: theme.current.primary.opacity(0.12), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    func deleteSelectedService() {
        guard let serviceToDelete else { return }
        serviceToDelete.isArchived = true
        for subscription in serviceToDelete.subscriptions where subscription.isActive {
            subscription.isActive = false
            subscription.canceledDate = subscription.canceledDate ?? .now
        }
        reindexServices()
        try? modelContext.save()
        self.serviceToDelete = nil
    }

    var canReorderServices: Bool {
        viewData.canReorderServices
    }

    func moveServices(from source: IndexSet, to destination: Int) {
        var reordered = viewData.filteredServices
        reordered.move(fromOffsets: source, toOffset: destination)

        for (index, service) in reordered.enumerated() {
            service.sortOrder = index
        }

        try? modelContext.save()
    }

    func reindexServices() {
        for (index, service) in viewData.filteredServices.enumerated() {
            service.sortOrder = index
        }
    }

    func normalizeServiceOrderIfNeeded() {
        let services = viewData.filteredServices
        let needsNormalization = Step2ServiceSelectViewDataBuilder.needsOrderNormalization(services: services)

        guard needsNormalization else { return }

        for (index, service) in services.enumerated() {
            service.sortOrder = index
        }

        try? modelContext.save()
    }
}
