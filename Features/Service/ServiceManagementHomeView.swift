import SwiftUI

struct ServiceManagementHomeView: View {
    @EnvironmentObject private var theme: ThemeManager

    private var menuItems: [ServiceManagementMenuItem] {
        ServiceManagementHomeViewDataBuilder.makeMenuItems()
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(ServiceManagementHomeViewDataBuilder.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, -14)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

            VStack(spacing: 16) {
                ForEach(menuItems) { item in
                    serviceTypeCard(for: item)
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(theme.current.primaryXLight.ignoresSafeArea())
        .navigationTitle("利用中のサービスを管理")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension ServiceManagementHomeView {
    @ViewBuilder
    func serviceTypeCard(for item: ServiceManagementMenuItem) -> some View {
        NavigationLink {
            ServiceListView(managementMode: true, serviceType: item.serviceType)
        } label: {
            VStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .fill(item.topColor)

                    Image(systemName: item.iconName)
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(item.iconColor)
                }
                .frame(height: 128)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                    Text(item.subtitle)
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
                    .stroke(item.borderColor, lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
