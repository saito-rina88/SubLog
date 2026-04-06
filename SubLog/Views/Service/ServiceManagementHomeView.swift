import SwiftUI

struct ServiceManagementHomeView: View {
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("管理するサービスを選択")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, -14)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

            VStack(spacing: 16) {
                serviceTypeCard(
                    title: "定期支払い",
                    subtitle: "サブスク系サービスを追加・編集・削除",
                    iconName: "calendar.badge.clock",
                    topColor: Color(red: 0.84, green: 0.96, blue: 0.80),
                    iconColor: Color(red: 0.29, green: 0.56, blue: 0.46),
                    destination: ServiceListView(managementMode: true, serviceType: .subscription)
                )

                serviceTypeCard(
                    title: "単発支払い",
                    subtitle: "都度課金サービスを追加・編集・削除",
                    iconName: "creditcard.fill",
                    topColor: Color(red: 0.77, green: 0.97, blue: 0.92),
                    iconColor: Color(red: 0.26, green: 0.59, blue: 0.53),
                    destination: ServiceListView(managementMode: true, serviceType: .game)
                )
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
    func serviceTypeCard<Destination: View>(
        title: String,
        subtitle: String,
        iconName: String,
        topColor: Color,
        iconColor: Color,
        destination: Destination
    ) -> some View {
        NavigationLink {
            destination
        } label: {
            VStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .fill(topColor)

                    Image(systemName: iconName)
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                .frame(height: 128)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
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
                    .stroke(topColor, lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
