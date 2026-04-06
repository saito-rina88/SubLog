import SwiftUI
import SwiftData

struct ServiceIconView: View {
    let service: Service
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let iconData = service.icon, let uiImage = UIImage(data: iconData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: size * 0.25,
                        style: .continuous
                    )
                    .fill(service.category.tintColor.opacity(0.14))

                    Image(systemName: service.category.sfSymbol)
                        .resizable()
                        .scaledToFit()
                        .padding(size * 0.18)
                        .foregroundStyle(service.category.tintColor)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(
            RoundedRectangle(
                cornerRadius: size * 0.25,
                style: .continuous
            )
        )
    }
}

#Preview {
    VStack {
        ServiceIconView(service: SampleDataFactory.makeServices()[0])
        ServiceIconView(service: SampleDataFactory.makeServices()[1], size: 60)
    }
    .environmentObject(ThemeManager())
    .modelContainer(
        try! ModelContainer(
            for: Service.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    )
}
