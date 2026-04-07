import SwiftUI

struct ThemeSelectView: View {
    @EnvironmentObject private var theme: ThemeManager

    private var viewData: ThemeSelectViewData {
        ThemeSelectViewDataBuilder.build(currentThemeID: theme.current.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(viewData.items) { item in
                        Button {
                            theme.select(item.theme)
                        } label: {
                            HStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    ForEach(Array(item.previewColors.enumerated()), id: \.offset) { _, color in
                                        themeCircle(color)
                                    }
                                }

                                Text(item.theme.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(item.isSelected ? theme.current.primary : .gray)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(item.isSelected ? theme.current.primaryLight : Color(uiColor: .systemBackground))
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        item.isSelected ? theme.current.primary : .clear,
                                        lineWidth: 2
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 56)
            }
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.current.primary)
            .safeAreaInset(edge: .top) {
                Text("カラーテーマ")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 5)
                    .padding(.bottom, 8)
                    .background(theme.current.primaryXLight)
            }
        }
    }
}

private extension ThemeSelectView {
    func themeCircle(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 24, height: 24)
    }
}

#Preview {
    ThemeSelectView()
        .environmentObject(ThemeManager())
}
