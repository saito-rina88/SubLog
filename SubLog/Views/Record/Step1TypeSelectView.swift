import SwiftUI

struct Step1TypeSelectView: View {
    @Binding var path: NavigationPath

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("支払いタイプを選択")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, -14)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

            VStack(spacing: 16) {
                typeCard(
                    title: "定期支払い",
                    subtitle: "月額・年額などの定期支払い",
                    iconKey: "subscription"
                ) {
                    path.append(RecordStep.serviceSelect(serviceType: .subscription))
                }

                typeCard(
                    title: "単発支払い",
                    subtitle: "都度の支払い（買い切り・アイテム購入など）",
                    iconKey: "oneTime"
                ) {
                    path.append(RecordStep.serviceSelect(serviceType: .game))
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
        title: String,
        subtitle: String,
        iconKey: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .fill(cardTopBackground(for: iconKey))

                    cardIcon(for: iconKey)
                        .foregroundStyle(cardIconColor(for: iconKey))
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
                    .stroke(cardBorderColor(for: iconKey), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func cardIcon(for iconKey: String) -> some View {
        switch iconKey {
        case "subscription":
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 42, weight: .medium))
        case "oneTime":
            Image(systemName: "creditcard.fill")
                .font(.system(size: 42, weight: .medium))
        default:
            EmptyView()
        }
    }

    func cardTopBackground(for iconKey: String) -> Color {
        if theme.current.id == "green" {
            switch iconKey {
            case "subscription":
                return Color(red: 0.86, green: 0.95, blue: 0.72)
            case "oneTime":
                return Color(red: 0.84, green: 0.96, blue: 0.80)
            default:
                return Color(.secondarySystemBackground)
            }
        }

        if theme.current.id == "purple" {
            switch iconKey {
            case "subscription":
                return Color(red: 0.92, green: 0.93, blue: 0.99)
            case "oneTime":
                return Color(red: 0.92, green: 0.88, blue: 0.98)
            default:
                return Color(.secondarySystemBackground)
            }
        }

        if theme.current.id == "blue" {
            switch iconKey {
            case "subscription":
                return Color(red: 0.88, green: 0.95, blue: 0.99)
            case "oneTime":
                return Color(red: 0.88, green: 0.92, blue: 0.99)
            default:
                return Color(.secondarySystemBackground)
            }
        }

        if theme.current.id == "pink" || theme.current.id == "orange" {
            switch iconKey {
            case "subscription":
                return theme.current.id == "orange"
                    ? Color(red: 0.99, green: 0.95, blue: 0.77)
                    : Color(red: 0.99, green: 0.91, blue: 0.87)
            case "oneTime":
                return theme.current.id == "orange"
                    ? Color(red: 0.99, green: 0.91, blue: 0.82)
                    : Color(red: 0.98, green: 0.88, blue: 0.92)
            default:
                return Color(.secondarySystemBackground)
            }
        }

        switch iconKey {
        case "subscription":
            return Color(red: 0.84, green: 0.96, blue: 0.80)
        case "oneTime":
            return Color(red: 0.77, green: 0.97, blue: 0.92)
        default:
            return Color(.secondarySystemBackground)
        }
    }

    func cardIconColor(for iconKey: String) -> Color {
        if theme.current.id == "green" {
            switch iconKey {
            case "subscription":
                return Color(red: 0.41, green: 0.62, blue: 0.18)
            case "oneTime":
                return Color(red: 0.29, green: 0.56, blue: 0.46)
            default:
                return theme.current.primary
            }
        }

        if theme.current.id == "purple" {
            switch iconKey {
            case "subscription":
                return Color(red: 0.43, green: 0.49, blue: 0.79)
            case "oneTime":
                return Color(red: 0.50, green: 0.31, blue: 0.72)
            default:
                return theme.current.primary
            }
        }

        if theme.current.id == "blue" {
            switch iconKey {
            case "subscription":
                return Color(red: 0.31, green: 0.67, blue: 0.84)
            case "oneTime":
                return Color(red: 0.28, green: 0.48, blue: 0.86)
            default:
                return theme.current.primary
            }
        }

        if theme.current.id == "pink" || theme.current.id == "orange" {
            switch iconKey {
            case "subscription":
                return theme.current.id == "orange"
                    ? Color(red: 0.78, green: 0.60, blue: 0.14)
                    : Color(red: 0.82, green: 0.47, blue: 0.38)
            case "oneTime":
                return theme.current.id == "orange"
                    ? Color(red: 0.86, green: 0.48, blue: 0.18)
                    : Color(red: 0.82, green: 0.36, blue: 0.54)
            default:
                return theme.current.primary
            }
        }

        switch iconKey {
        case "subscription":
            return Color(red: 0.29, green: 0.56, blue: 0.46)
        case "oneTime":
            return Color(red: 0.26, green: 0.59, blue: 0.53)
        default:
            return theme.current.primary
        }
    }

    func cardBorderColor(for iconKey: String) -> Color {
        if theme.current.id == "mint" {
            switch iconKey {
            case "subscription":
                return Color(red: 0.78, green: 0.91, blue: 0.72)
            case "oneTime":
                return Color(red: 0.70, green: 0.90, blue: 0.84)
            default:
                return Color.clear
            }
        }

        if theme.current.id == "green" {
            switch iconKey {
            case "subscription":
                return Color(red: 0.79, green: 0.89, blue: 0.56)
            case "oneTime":
                return Color(red: 0.76, green: 0.90, blue: 0.72)
            default:
                return Color.clear
            }
        }

        if theme.current.id == "purple" {
            switch iconKey {
            case "subscription":
                return Color(red: 0.82, green: 0.86, blue: 0.97)
            case "oneTime":
                return Color(red: 0.84, green: 0.78, blue: 0.95)
            default:
                return Color.clear
            }
        }

        if theme.current.id == "blue" {
            switch iconKey {
            case "subscription":
                return Color(red: 0.76, green: 0.88, blue: 0.96)
            case "oneTime":
                return Color(red: 0.76, green: 0.84, blue: 0.97)
            default:
                return Color.clear
            }
        }

        if theme.current.id == "pink" || theme.current.id == "orange" {
            switch iconKey {
            case "subscription":
                return theme.current.id == "orange"
                    ? Color(red: 0.95, green: 0.88, blue: 0.62)
                    : Color(red: 0.96, green: 0.84, blue: 0.78)
            case "oneTime":
                return theme.current.id == "orange"
                    ? Color(red: 0.96, green: 0.83, blue: 0.69)
                    : Color(red: 0.95, green: 0.80, blue: 0.87)
            default:
                return Color.clear
            }
        }

        switch iconKey {
        case "subscription":
            return Color(red: 0.84, green: 0.96, blue: 0.80)
        case "oneTime":
            return Color(red: 0.77, green: 0.97, blue: 0.92)
        default:
            return Color.clear
        }
    }
}
