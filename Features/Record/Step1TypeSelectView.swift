import SwiftUI

struct Step1TypeSelectView: View {
    @Binding var path: NavigationPath

    @EnvironmentObject private var theme: ThemeManager

    private var options: [RecordTypeOption] {
        Step1TypeSelectViewDataBuilder.makeOptions(theme: theme.current)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(Step1TypeSelectViewDataBuilder.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, -14)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

            VStack(spacing: 16) {
                ForEach(options) { option in
                    typeCard(for: option) {
                        path.append(RecordStep.serviceSelect(serviceType: option.serviceType))
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(theme.current.primaryXLight.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension Step1TypeSelectView {
    func typeCard(
        for option: RecordTypeOption,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .fill(option.topColor)

                    Image(systemName: option.iconName)
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(option.iconColor)
                }
                .frame(height: 128)

                VStack(alignment: .leading, spacing: 6) {
                    Text(option.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                    Text(option.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(Color(.systemBackground))
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(option.borderColor, lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
