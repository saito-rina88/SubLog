import PhotosUI
import SwiftUI
import SwiftData

struct AddServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.displayScale) private var displayScale
    @EnvironmentObject private var theme: ThemeManager
    @Query private var services: [Service]

    private let fixedServiceType: ServiceType?

    @State private var name = ""
    @State private var serviceType: ServiceType = .game
    @State private var photoItem: PhotosPickerItem?
    @State private var iconData: Data?
    @State private var presetIconCategory: Category?
    @State private var showIconSourceDialog = false
    @State private var showPhotoPicker = false
    @State private var showPresetIconSheet = false

    private var viewData: AddServiceViewData {
        AddServiceViewDataBuilder.build(
            services: services,
            name: name,
            serviceType: serviceType,
            presetIconCategory: presetIconCategory,
            iconData: iconData
        )
    }

    init(serviceType: ServiceType? = nil) {
        self.fixedServiceType = serviceType
        _serviceType = State(initialValue: serviceType ?? .game)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    iconSelectionCard
                    inputCard(title: "サービス名") {
                        TextField("サービス名", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    if fixedServiceType == nil {
                        inputCard(title: "サービス種類") {
                            Picker("サービス種類", selection: $serviceType) {
                                ForEach(ServiceType.allCases, id: \.self) { serviceType in
                                    Text(serviceType.displayName).tag(serviceType)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    saveButton
                }
                .padding(20)
            }
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("サービス追加")
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.current.primary)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .task(id: photoItem) {
                guard let photoItem else { return }
                presetIconCategory = nil
                let loadedData = try? await photoItem.loadTransferable(type: Data.self)
                iconData = loadedData.flatMap(squareCroppedIconData(from:))
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
            .confirmationDialog("アイコンを選択", isPresented: $showIconSourceDialog, titleVisibility: .visible) {
                Button("写真をアップロード") {
                    showPhotoPicker = true
                }
                Button("既存アイコンから選択") {
                    showPresetIconSheet = true
                }
                Button("キャンセル", role: .cancel) {}
            }
            .sheet(isPresented: $showPresetIconSheet) {
                presetIconPickerSheet
            }
        }
    }
}

private extension AddServiceView {
    var iconSelectionCard: some View {
        inputCard(title: "アイコン") {
            VStack(spacing: 12) {
                Button {
                    showIconSourceDialog = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(theme.current.primaryLight)
                            .frame(width: 80, height: 80)

                        if let iconData, let uiImage = UIImage(data: iconData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        } else {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundStyle(theme.current.primary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Text(viewData.iconButtonTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if iconData != nil {
                    Button("画像を削除", role: .destructive) {
                        photoItem = nil
                        iconData = nil
                        presetIconCategory = nil
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    var presetIconPickerSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 16) {
                    ForEach(Category.allCases, id: \.self) { category in
                        presetIconButton(for: category)
                    }
                }
                .padding(20)
            }
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("アイコンを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        showPresetIconSheet = false
                    }
                }
            }
        }
    }

    var saveButton: some View {
        Button {
            saveService()
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

    func saveService() {
        let service = Service(
            name: viewData.trimmedName,
            category: viewData.selectedCategory,
            serviceType: serviceType,
            sortOrder: viewData.nextSortOrder,
            icon: iconData,
            createdAt: .now
        )
        service.subscriptions = []
        service.payments = []
        if serviceType == .game {
            service.gachaTemplates = AddServiceViewDataBuilder.defaultGameTemplates.enumerated().map { index, template in
                GachaTemplate(
                    label: template.label,
                    amount: template.amount,
                    service: service,
                    sortOrder: index
                )
            }
        } else {
            service.gachaTemplates = []
        }

        modelContext.insert(service)
        dismiss()
    }

    func presetIconButton(for category: Category) -> some View {
        Button {
            photoItem = nil
            presetIconCategory = category
            iconData = generatedDefaultIconData(for: category)
            showPresetIconSheet = false
        } label: {
            VStack(spacing: 6) {
                Image(systemName: category.sfSymbol)
                    .font(.title3)
                    .foregroundStyle(category.tintColor)
                    .frame(width: 52, height: 52)
                    .background(category.tintColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                presetIconCategory == category ? theme.current.primary : Color.clear,
                                lineWidth: 2
                            )
                    }

                Text(category.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    func generatedDefaultIconData(for category: Category) -> Data? {
        let iconView = ZStack {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(category.tintColor.opacity(0.15))

            Image(systemName: category.sfSymbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(category.tintColor)
                .frame(
                    width: category.generatedSymbolFrame.width,
                    height: category.generatedSymbolFrame.height
                )
                .offset(y: category.generatedSymbolYOffset)
        }
        .frame(width: 160, height: 160)

        let renderer = ImageRenderer(content: iconView)
        renderer.scale = displayScale
        return renderer.uiImage?.pngData()
    }

    func squareCroppedIconData(from data: Data) -> Data? {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            return data
        }

        let side = min(cgImage.width, cgImage.height)
        let cropRect = CGRect(
            x: (cgImage.width - side) / 2,
            y: (cgImage.height - side) / 2,
            width: side,
            height: side
        )

        guard let cropped = cgImage.cropping(to: cropRect) else {
            return data
        }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512))
        return renderer.pngData { _ in
            UIImage(cgImage: cropped).draw(in: CGRect(x: 0, y: 0, width: 512, height: 512))
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Service.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    return AddServiceView()
        .environmentObject(ThemeManager())
        .modelContainer(container)
}
