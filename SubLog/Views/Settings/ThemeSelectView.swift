import SwiftUI

struct ThemeSelectView: View {
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(ThemeManager.allThemes) { appTheme in
                        Button {
                            theme.select(appTheme)
                        } label: {
                            HStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    themeCircle(appTheme.primary)
                                    themeCircle(appTheme.primaryDark)
                                    themeCircle(appTheme.primaryMid)
                                    themeCircle(appTheme.primaryLight)
                                    themeCircle(appTheme.primaryXLight)
                                }

                                Text(appTheme.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: isSelected(appTheme) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected(appTheme) ? theme.current.primary : .gray)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(isSelected(appTheme) ? theme.current.primaryLight : Color(uiColor: .systemBackground))
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        isSelected(appTheme) ? theme.current.primary : .clear,
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
    func isSelected(_ appTheme: AppTheme) -> Bool {
        theme.current.id == appTheme.id
    }

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
