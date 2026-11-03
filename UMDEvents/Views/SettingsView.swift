import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var showAddSource = false

    private let intervals: [(TimeInterval, LocalizedStringKey)] = [
        (1800, "Every 30 minutes"),
        (3600, "Every hour"),
        (7200, "Every 2 hours"),
        (14400, "Every 4 hours"),
    ]

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section("Apple Intelligence") {
                    AIStatusBanner(status: Summarizer.status)
                }

                Section {
                    ForEach(FeedCategory.allCases) { category in
                        Toggle(isOn: notifyBinding(category)) {
                            Label { Text(category.title) } icon: { Image(systemName: category.symbol) }
                        }
                    }
                    Picker("Check for Updates", selection: $settings.refreshInterval) {
                        ForEach(intervals, id: \.0) { interval, label in
                            Text(label).tag(interval)
                        }
                    }
                    Button("Send Test Notification") {
                        Task { await Notifier.sendTest() }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("iOS decides exactly when background refresh runs, based on how often you use the app.")
                }

                ForEach(FeedCategory.allCases) { category in
                    Section {
                        ForEach(settings.allSources.filter { $0.category == category }) { source in
                            Toggle(isOn: enabledBinding(source)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(source.name)
                                    Text(source.url.host() ?? source.url.absoluteString)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions {
                                if source.isCustom {
                                    Button("Delete", systemImage: "trash", role: .destructive) { remove(source) }
                                }
                            }
                        }
                    } header: {
                        Text(category.title)
                    }
                }

                Section {
                    Button("Add Custom Feed", systemImage: "plus") { showAddSource = true }
                } footer: {
                    Text("Supports RSS, Atom and iCalendar (.ics) feeds. Swipe left on a custom feed to delete it.")
                }

                Section("Status") {
                    LabeledContent("Last Refresh") {
                        if let last = environment.lastRefresh {
                            Text(last, format: .relative(presentation: .named))
                        } else {
                            Text("Never")
                        }
                    }
                    ForEach(environment.lastFailures.sorted(by: { $0.key < $1.key }), id: \.key) { name, error in
                        LabeledContent(name) {
                            Text(error).foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddSource) { AddSourceView() }
        }
    }

    private func notifyBinding(_ category: FeedCategory) -> Binding<Bool> {
        Binding {
            settings.notifyCategories.contains(category)
        } set: { on in
            if on { settings.notifyCategories.insert(category) } else { settings.notifyCategories.remove(category) }
        }
    }

    private func enabledBinding(_ source: FeedSource) -> Binding<Bool> {
        Binding { settings.isEnabled(source) } set: { settings.setEnabled(source, $0) }
    }

    private func remove(_ source: FeedSource) {
        settings.customSources.removeAll { $0.id == source.id }
        settings.disabledSourceIDs.remove(source.id)
        settings.knownSourceIDs.remove(source.id)
        environment.deleteArticles(fromSource: source.id)
    }
}

struct AddSourceView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    enum Kind: String, CaseIterable, Identifiable {
        case rss, ical
        var id: String { rawValue }
        var title: LocalizedStringResource {
            switch self {
            case .rss: "RSS / Atom"
            case .ical: "iCalendar (.ics)"
            }
        }
    }

    @State private var name = ""
    @State private var urlText = ""
    @State private var kind: Kind = .rss
    @State private var category: FeedCategory = .department

    private var url: URL? {
        var text = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.lowercased().hasPrefix("webcal://") { text = "https://" + text.dropFirst("webcal://".count) }
        guard let url = URL(string: text), let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https", url.host() != nil else { return nil }
        return url
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Feed URL", text: $urlText)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Picker("Type", selection: $kind) {
                    ForEach(Kind.allCases) { Text($0.title).tag($0) }
                }
                Picker("Category", selection: $category) {
                    ForEach(FeedCategory.allCases) { Text($0.title).tag($0) }
                }
            }
            .navigationTitle("Add Custom Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || url == nil)
                }
            }
        }
    }

    private func add() {
        guard let url else { return }
        settings.customSources.append(FeedSource(
            id: "custom-\(UUID().uuidString)",
            name: name.trimmingCharacters(in: .whitespaces),
            url: url,
            kind: kind == .rss ? .rss : .ical,
            category: category,
            isCustom: true))
        dismiss()
    }
}
