import PhotosUI
import SwiftUI
import SwiftData

struct EditServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager

    let service: Service
    private let fixedServiceType: ServiceType?

    @State private var name: String
    @State private var category: Category
    @State private var serviceType: ServiceType
    @State private var photoItem: PhotosPickerItem?
    @State private var iconData: Data?
    @State private var presetIconCategory: Category?
    @State private var showIconSourceDialog = false
    @State private var showPhotoPicker = false
    @State private var showPresetIconSheet = false

    init(service: Service, fixedServiceType: ServiceType? = nil) {
        self.service = service
        self.fixedServiceType = fixedServiceType
        _name = State(initialValue: service.name)
        _category = State(initialValue: service.category)
        _serviceType = State(initialValue: fixedServiceType ?? service.serviceType)
        _iconData = State(initialValue: service.icon)
        _presetIconCategory = State(initialValue: service.icon == nil ? service.category : nil)
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
                        inputCard(title: "カテゴリ") {
                            Picker("カテゴリ", selection: $category) {
                                ForEach(Category.allCases, id: \.self) { category in
                                    Text(category.displayName).tag(category)
                                }
                            }
                        }
                    }

                    if fixedServiceType == nil {
                        inputCard(title: "サービス種類") {
                            Picker("サービス種類", selection: $serviceType) {
                                ForEach(ServiceType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
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
            .navigationTitle("サービスを編集")
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

private extension EditServiceView {
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
                            Image(systemName: selectedCategory.sfSymbol)
                                .font(.title2)
                                .foregroundStyle(selectedCategory.tintColor)
                        }
                    }
                }
                .buttonStyle(.plain)

                Text("タップして変更")
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
            save()
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
        .disabled(trimmedName.isEmpty)
        .opacity(trimmedName.isEmpty ? 0.4 : 1)
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

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func save() {
        guard !trimmedName.isEmpty else { return }

        service.name = trimmedName
        service.category = selectedCategory
        service.serviceType = serviceType
        service.icon = iconData

        try? modelContext.save()
        dismiss()
    }

    var selectedCategory: Category {
        if let presetIconCategory {
            return presetIconCategory
        }
        return category
    }

    func presetIconButton(for category: Category) -> some View {
        Button {
            photoItem = nil
            presetIconCategory = category
            self.category = category
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
        renderer.scale = UIScreen.main.scale
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
    let services = SampleDataFactory.makeServices()
    services.forEach {
        container.mainContext.insert($0)
    }

    return EditServiceView(service: services.first!)
        .environmentObject(ThemeManager())
        .environmentObject(EntitlementManager())
        .environmentObject(NotificationManager())
        .modelContainer(container)
}
