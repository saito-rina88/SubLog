import SwiftUI
import SwiftData

enum RecordStep: Hashable {
    case serviceSelect(serviceType: ServiceType)
    case subscDetail(serviceID: PersistentIdentifier)
    case gameDetail(serviceID: PersistentIdentifier)
}

struct RecordView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Step1TypeSelectView(path: $path)
                .navigationDestination(for: RecordStep.self) { step in
                    switch step {
                    case .serviceSelect(let type):
                        Step2ServiceSelectView(serviceType: type, path: $path)
                    case .subscDetail(let id):
                        Step3aSubscDetailView(serviceID: id, path: $path)
                    case .gameDetail(let id):
                        Step3bGameDetailView(serviceID: id, path: $path)
                    }
                }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 56)
        }
    }
}
