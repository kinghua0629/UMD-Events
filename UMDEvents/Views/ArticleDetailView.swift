import SafariServices
import SwiftData
import SwiftUI
import Translation

struct ArticleDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    @Query private var results: [Article]
    @State private var isSummarizing = false
    @State private var showSafari = false
    @State private var canTranslate = false
    @State private var showTranslation = true
    @State private var isTranslating = false
    @State private var translationFailed = false
    @State private var translationConfig: TranslationSession.Configuration?

    init(articleID: String) {
        _results = Query(filter: #Predicate<Article> { $0.id == articleID })
    }

    var body: some View {
        if let article = results.first {
            content(article)
        } else {
            ContentUnavailableView("Story Not Found", systemImage: "doc.questionmark")
        }
    }

    private func content(_ article: Article) -> some View {
        let translated = article.hasTranslation(for: TranslationSupport.targetKey) && showTranslation
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.sourceName.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                    Text(translated ? article.translatedTitle ?? article.title : article.title)
                        .font(.title2.bold())
                    if canTranslate {
                        TranslateButton(article: article, showTranslation: $showTranslation,
                                        isTranslating: isTranslating, failed: translationFailed) {
                            startTranslation()
                        }
                    }
                    if article.category != .events, !article.dateIsEstimated {
                        Text(article.published, format: .dateTime.year().month().day().hour().minute())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let start = article.eventStart {
                    EventInfo(start: start, end: article.eventEnd, location: article.location)
                }

                SummaryCard(article: article, isSummarizing: isSummarizing, showTranslation: translated)

                if let url = article.link {
                    Button {
                        showSafari = true
                    } label: {
                        Label("Read Full Article", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .sheet(isPresented: $showSafari) {
                        SafariView(url: url).ignoresSafeArea()
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let url = article.link {
                ToolbarItem(placement: .topBarTrailing) { ShareLink(item: url) }
            }
        }
        .translationTask(translationConfig) { session in
            await translate(article, using: session)
        }
        .task(id: article.id) {
            article.isRead = true
            if TranslationSupport.isNeeded {
                #if targetEnvironment(simulator)
                // The Simulator reports every pair as unsupported; show the button anyway for UI work.
                canTranslate = true
                #else
                canTranslate = await TranslationSupport.isSupported()
                #endif
            }
            guard !article.hasAISummary, article.summaryAttempts < 2, Summarizer.isAvailable else { return }
            isSummarizing = true
            await environment.summarize(article)
            isSummarizing = false
        }
    }

    private func startTranslation() {
        translationFailed = false
        isTranslating = true
        if translationConfig == nil {
            translationConfig = TranslationSupport.configuration()
        } else {
            translationConfig?.invalidate()   // re-runs .translationTask
        }
    }

    /// Translates the original title and summary. The first time, the system may ask the
    /// user to download the language; everything then runs on device.
    private func translate(_ article: Article, using session: TranslationSession) async {
        defer { isTranslating = false }
        var requests = [TranslationSession.Request(sourceText: article.title, clientIdentifier: "title")]
        if !article.fallbackSummary.isEmpty {
            requests.append(TranslationSession.Request(sourceText: article.fallbackSummary, clientIdentifier: "summary"))
        }
        do {
            let responses = try await session.translations(from: requests)
            let byID = Dictionary(responses.compactMap { r in r.clientIdentifier.map { ($0, r.targetText) } },
                                  uniquingKeysWith: { first, _ in first })
            article.apply(translatedTitle: byID["title"], summary: byID["summary"],
                          language: TranslationSupport.targetKey)
            showTranslation = true
        } catch {
            translationFailed = true
        }
    }
}

private struct TranslateButton: View {
    let article: Article
    @Binding var showTranslation: Bool
    let isTranslating: Bool
    let failed: Bool
    let translate: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if isTranslating {
                ProgressView().controlSize(.small)
                Text("Translating…").foregroundStyle(.secondary)
            } else if article.hasTranslation(for: TranslationSupport.targetKey) {
                Button(showTranslation ? "Show Original" : "Show Translation", systemImage: "translate") {
                    showTranslation.toggle()
                }
            } else {
                Button("Translate", systemImage: "translate", action: translate)
            }
            if failed {
                Text("Translation failed. Try again later.").foregroundStyle(.red)
            }
        }
        .font(.subheadline)
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.small)
    }
}

private struct EventInfo: View {
    let start: Date
    let end: Date?
    let location: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                if let end {
                    Text(start..<max(end, start), format: .interval.weekday().month().day().hour().minute())
                } else {
                    Text(start, format: .dateTime.weekday().month().day().hour().minute())
                }
            } icon: {
                Image(systemName: "calendar")
            }
            if let location {
                Label(location, systemImage: "mappin.and.ellipse")
            }
        }
        .font(.subheadline)
    }
}

private struct SummaryCard: View {
    let article: Article
    let isSummarizing: Bool
    var showTranslation = false

    private var originalSummary: String {
        if showTranslation, let translated = article.translatedSummary { return translated }
        return article.fallbackSummary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if article.hasAISummary {
                Label("Apple Intelligence Summary", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.purple)
            } else {
                Label("Original Summary", systemImage: "text.alignleft")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if isSummarizing {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Summarizing on device…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let headline = article.aiHeadline {
                Text(headline).font(.headline)
            }

            if let summary = article.aiSummary {
                Text(summary)
            } else if !originalSummary.isEmpty {
                Text(originalSummary)
            } else if !isSummarizing {
                Text("No summary available.").foregroundStyle(.secondary)
            }

            if !article.aiKeyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(article.aiKeyPoints, id: \.self) { point in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "circle.fill").font(.system(size: 5))
                            Text(point)
                        }
                    }
                }
                .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .animation(.default, value: article.hasAISummary)
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
