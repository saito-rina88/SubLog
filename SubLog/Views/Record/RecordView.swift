import SwiftUI

struct RecordView: View {
    @State private var flowState = RecordFlowState()

    var body: some View {
        NavigationStack(path: $flowState.path) {
            Step1TypeSelectView(path: $flowState.path)
                .navigationDestination(for: RecordStep.self) { step in
                    RecordFlowDestinationBuilder.destination(for: step, path: $flowState.path)
                }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 56)
        }
    }
}
