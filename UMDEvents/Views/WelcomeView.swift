import SwiftUI

struct WelcomeView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text("Welcome to UMD Events")
                        .font(.largeTitle.bold())
                    Text("Choose what interests you. Personalize your All feed and change your choices anytime in Settings.")
                        .foregroundStyle(.secondary)
                    InterestPicker()
                    Button {
                        settings.hasCompletedWelcome = true
                    } label: {
                        Text("Get Started")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(settings.interests.isEmpty)
                    Button("Explore Everything") {
                        settings.interests = Set(FeedCategory.allCases)
                        settings.hasCompletedWelcome = true
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(28)
            }
        }
        .interactiveDismissDisabled()
    }
}

struct InterestPicker: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        ForEach(FeedCategory.allCases) { category in
            Toggle(isOn: Binding {
                settings.interests.contains(category)
            } set: { selected in
                if selected { settings.interests.insert(category) }
                else { settings.interests.remove(category) }
            }) {
                Label { Text(category.title) } icon: { Image(systemName: category.symbol) }
            }
            .padding(.vertical, 6)
        }
    }
}
