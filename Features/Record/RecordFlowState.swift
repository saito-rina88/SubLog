import SwiftUI
import SwiftData

enum RecordStep: Hashable {
    case serviceSelect(serviceType: ServiceType)
    case subscDetail(serviceID: PersistentIdentifier)
    case gameDetail(serviceID: PersistentIdentifier)
}

struct RecordFlowState {
    var path = NavigationPath()
}

enum RecordFlowDestinationBuilder {
    @ViewBuilder
    static func destination(for step: RecordStep, path: Binding<NavigationPath>) -> some View {
        switch step {
        case .serviceSelect(let serviceType):
            Step2ServiceSelectView(serviceType: serviceType, path: path)
        case .subscDetail(let serviceID):
            Step3aSubscDetailView(serviceID: serviceID, path: path)
        case .gameDetail(let serviceID):
            Step3bGameDetailView(serviceID: serviceID, path: path)
        }
    }
}
