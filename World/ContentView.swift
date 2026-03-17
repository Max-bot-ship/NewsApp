//
//  ContentView.swift
//  World
//
//  Created by Skyler on 2/28/26.
//

import SwiftUI
import SwiftData
import SafariServices

struct BookmarkedArticle: Identifiable, Codable, Hashable {
    let url: String
    let title: String
    let source: String?
    let publishedAt: String?

    var id: String { url }

    init(article: Article) {
        url = article.url
        title = article.title
        publishedAt = article.publishedAt
        source = Self.sourceHost(from: article.url)
    }

    private static func sourceHost(from rawURL: String) -> String? {
        guard let host = URL(string: rawURL)?.host else { return nil }
        let cleaned = host.replacingOccurrences(of: "www.", with: "")
        return cleaned.isEmpty ? nil : cleaned.uppercased()
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var scrollOffset: CGFloat = 0
    @State private var refreshID = 0
    @State private var selectedFeed: FeedOption = .us
    @State private var isSidebarOpen = false
    @State private var bookmarkedArticles: [BookmarkedArticle] = []
    @State private var selectedBookmarkedArticle: BookmarkedArticle?
    

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Headings(
                    scrollOffset: $scrollOffset,
                    refreshID: refreshID,
                    selectedFeed: selectedFeed,
                    bookmarkedURLs: bookmarkedURLSet,
                    onToggleBookmark: toggleBookmark
                )
                    .padding(.top, contentTopPadding)
                    .padding(.horizontal, horizontalPadding)

                ZStack {
                    TopNavigationView(selectedFeed: selectedFeed, onSelectFeed: { feed in
                        selectedFeed = feed
                        refreshID += 1
                    })
                    .frame(maxWidth: topNavMaxWidth)
                    .frame(maxWidth: .infinity, alignment: .center)

                    HStack {
                        Spacer()
                        Button {
                            if isSidebarOpen {
                                closeSidebar()
                            } else {
                                openSidebar()
                            }
                        } label: {
                            HeaderSidebarView()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topHeaderPadding)

                if isSidebarOpen {
                    Color.black.opacity(0.24)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            closeSidebar()
                        }
                }

                HStack(spacing: 0) {
                    Spacer()
                    SlideOutSidebarView(
                        bookmarkedArticles: bookmarkedArticles,
                        onSelectArticle: { bookmarked in
                            selectedBookmarkedArticle = bookmarked
                            closeSidebar()
                        },
                        onClose: {
                            closeSidebar()
                        }
                    )
                    .frame(width: sidebarPanelWidth, alignment: .trailing)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .offset(x: isSidebarOpen ? 0 : sidebarPanelWidth + 24)
                }
                .ignoresSafeArea(edges: .vertical)
                .allowsHitTesting(isSidebarOpen)
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: isSidebarOpen)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                loadBookmarkedArticles()
            }
            .navigationDestination(item: $selectedBookmarkedArticle) { bookmarked in
                ArticleScreen(articleURL: bookmarked.url)
            }
        }
    }

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .compact ? 12 : 16
    }

    private var contentTopPadding: CGFloat {
        horizontalSizeClass == .compact ? 82 : 94
    }

    private var topNavMaxWidth: CGFloat {
        horizontalSizeClass == .compact ? 340 : 420
    }

    private var topHeaderPadding: CGFloat {
        horizontalSizeClass == .compact ? 2 : 6
    }

    private var sidebarPanelWidth: CGFloat {
        horizontalSizeClass == .compact ? 278 : 320
    }

    private var bookmarkedURLSet: Set<String> {
        Set(bookmarkedArticles.map(\.url))
    }

    private func openSidebar() {
        isSidebarOpen = true
    }

    private func closeSidebar() {
        isSidebarOpen = false
    }

    private func toggleBookmark(_ article: Article) {
        if let index = bookmarkedArticles.firstIndex(where: { $0.url == article.url }) {
            bookmarkedArticles.remove(at: index)
        } else {
            bookmarkedArticles.insert(BookmarkedArticle(article: article), at: 0)
        }
        saveBookmarkedArticles()
    }

    private func loadBookmarkedArticles() {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarksStorageKey) else { return }
        guard let decoded = try? JSONDecoder().decode([BookmarkedArticle].self, from: data) else { return }
        bookmarkedArticles = decoded
    }

    private func saveBookmarkedArticles() {
        guard let data = try? JSONEncoder().encode(bookmarkedArticles) else { return }
        UserDefaults.standard.set(data, forKey: Self.bookmarksStorageKey)
    }

    private static let bookmarksStorageKey = "world.bookmarked.articles"
}


func navbar() {
    
}

enum FeedOption: String, CaseIterable, Hashable {
    case us = "US"
    case tech = "Tech"
    case politics = "Politics"
    case nyctimes = "NY Times"
    case bbc = "BBC"
    case guardian = "Guardian"
}

private struct TopNavigationView: View {
    @Environment(\.colorScheme) private var colorScheme
    let selectedFeed: FeedOption
    let onSelectFeed: (FeedOption) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FeedOption.allCases, id: \.self) { feed in
                    Button {
                        onSelectFeed(feed)
                    } label: {
                        Text(feed.rawValue)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(feed == selectedFeed ? Color.white : unselectedTextColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(feed == selectedFeed ? Color.accentColor : unselectedPillColor)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 2)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(navGlassTint)
        )
        .glassEffect()
        .clipShape(RoundedRectangle(cornerRadius: 18
                                    , style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(glassBorderColor, lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.09), radius: 12, x: 0, y: 6)
    }

    private var navGlassTint: Color {
        colorScheme == .dark
            ? Color(red: 0.176, green: 0.176, blue: 0.176).opacity(0.76) // #2D2D2D
            : Color(red: 0.949020, green: 0.949020, blue: 0.968627).opacity(0.62) // #F2F2F7
    }

    private var glassBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.55)
    }

    private var unselectedPillColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06)
    }

    private var unselectedTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.85) : Color.black.opacity(0.70)
    }
}

private struct HeaderSidebarView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bookmark")
                .font(.system(size: 14, weight: .bold))

        }
        .foregroundStyle(iconColor)
        .frame(width: 42, height: 46)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(sidebarBackgroundColor)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(sidebarBackgroundColor)
                .frame(width: 10, height: 34)
                .offset(x: -5)
        }
        .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 5)
    }

    private var sidebarBackgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.176, green: 0.176, blue: 0.176) // #2D2D2D
            : Color(red: 0.949020, green: 0.949020, blue: 0.968627) // #F2F2F7
    }

    private var iconColor: Color {
        colorScheme == .dark ? .white : Color(.label)
    }
}

private struct SlideOutSidebarView: View {
    @Environment(\.colorScheme) private var colorScheme
    let bookmarkedArticles: [BookmarkedArticle]
    let onSelectArticle: (BookmarkedArticle) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Bookmarked")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(primaryTextColor)

                Spacer()

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(primaryTextColor)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(colorScheme == .dark ? 0.24 : 0.06), in: Circle())
                }
                .buttonStyle(.plain)
            }

            if bookmarkedArticles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No bookmarks yet")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(primaryTextColor)
                    Text("Long-press any article card and tap Bookmark.")
                        .font(.subheadline)
                        .foregroundStyle(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 12)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(bookmarkedArticles) { article in
                            Button {
                                onSelectArticle(article)
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.accentColor)
                                        .padding(.top, 3)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(article.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(primaryTextColor)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)

                                        if let source = article.source {
                                            Text(source)
                                                .font(.caption2.weight(.medium))
                                                .foregroundStyle(secondaryTextColor)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(rowBackground)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 62)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(sidebarBackgroundColor)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.black.opacity(colorScheme == .dark ? 0.34 : 0.08))
                .frame(width: 1)
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.12), radius: 14, x: -8, y: 0)
        .gesture(
            DragGesture(minimumDistance: 18)
                .onEnded { value in
                    if value.translation.width > 70 {
                        onClose()
                    }
                }
        )
    }

    private var sidebarBackgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.176, green: 0.176, blue: 0.176) // #2D2D2D
            : Color(red: 0.949020, green: 0.949020, blue: 0.968627) // #F2F2F7
    }

    private var rowBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(.label)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.72) : Color(.secondaryLabel)
    }

}

struct Headings: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var scrollOffset: CGFloat
    let refreshID: Int
    let selectedFeed: FeedOption
    let bookmarkedURLs: Set<String>
    let onToggleBookmark: (Article) -> Void
    @State private var articles: [Article] = []
    @State private var trendingArticles: [Article] = []
    let uservice = us()
    let trendingService = trending()
    let bbcService = bbc()
    let guardianService = guardian()
    let politicsService = politics()
    let techService = tech()
    let nyctimesService = nyctimes()
    var body: some View {
        let fadeProgress = min(max(-scrollOffset / 90, 0), 1)
        let fadeProgressDouble = Double(fadeProgress)
        let titleScale = 1 - (0.28 * fadeProgress)

        ScrollView(.vertical, showsIndicators: false) {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("headingsScroll")).minY)
            }
            .frame(height: 0)

            VStack(spacing: 10) {
                ZStack {
                    Text("World News")
                        .font(.system(size: titleSize, weight: .bold, design: .default))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .scaleEffect(titleScale, anchor: .top)

                    HStack {
                        Spacer()
                        Text(Date(), style: .date)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .opacity(1 - fadeProgressDouble)
            }
            .padding(.top, topHeaderPadding)
            .padding(.bottom, 10)

            Text("Top Stories")
                .font(.title2.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)

            VStack(spacing: 14) {
                ForEach(trendingArticles.prefix(2)) { article in
                    NavigationLink {
                        ArticleScreen(articleURL: article.url)
                    } label: {
                        TrendingCard(article: article)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            onToggleBookmark(article)
                        } label: {
                            Label(
                                bookmarkedURLs.contains(article.url) ? "Remove Bookmark" : "Bookmark",
                                systemImage: bookmarkedURLs.contains(article.url) ? "bookmark.slash" : "bookmark"
                            )
                        }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 14)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(articles) { article in
                    NavigationLink {
                        ArticleScreen(articleURL: article.url)
                    } label: {
                        HeadingCard(article: article, feed: selectedFeed)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            onToggleBookmark(article)
                        } label: {
                            Label(
                                bookmarkedURLs.contains(article.url) ? "Remove Bookmark" : "Bookmark",
                                systemImage: bookmarkedURLs.contains(article.url) ? "bookmark.slash" : "bookmark"
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .coordinateSpace(name: "headingsScroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
        .task(id: "\(selectedFeed.rawValue)-\(refreshID)") {
            await loadSelectedFeed()
        }
        .task {
            await loadTrendingIfNeeded()
        }
    }

    private var titleSize: CGFloat {
        horizontalSizeClass == .compact ? 30 : 34
    }

    private var topHeaderPadding: CGFloat {
        horizontalSizeClass == .compact ? 2 : 6
    }

    private var columns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible(), spacing: 12)]
        }
        return [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private func loadSelectedFeed() async {
        do {
            let fetchedArticles = try await fetchArticles(for: selectedFeed)
            guard !Task.isCancelled else { return }
            articles = Array(fetchedArticles.prefix(10))
        } catch is CancellationError {
            return
        } catch {
            print("Error fetching articles: \(error)")
        }
    }

    private func loadTrendingIfNeeded() async {
        guard trendingArticles.isEmpty else { return }

        do {
            let fetchedTrending = try await trendingService.fetchArticles()
            guard !Task.isCancelled else { return }
            trendingArticles = Array(fetchedTrending.prefix(2))
        } catch is CancellationError {
            return
        } catch {
            print("Error fetching trending articles: \(error)")
        }
    }

    private func fetchArticles(for feed: FeedOption) async throws -> [Article] {
        switch feed {
        case .us:
            return try await
                uservice.fetchArticles()
        case .bbc:
            return try await bbcService.fetchArticles()
        case .tech:
            return try await techService.fetchArticles()
        case .politics:
            return try await politicsService.fetchArticles()
        case .nyctimes:
            return try await nyctimesService.fetchArticles()
        case .guardian:
            return try await guardianService.fetchArticles()
        }
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
struct TrendingCard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    let article: Article

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = articleImageURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    LinearGradient(
                        colors: [Color(.systemGray5), Color(.systemGray4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            } else {
                LinearGradient(
                    colors: [Color(red: 0.80, green: 0.24, blue: 0.18), Color(red: 0.45, green: 0.08, blue: 0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: "flame.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white.opacity(0.90))
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.70)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Label("Trending", systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.35), in: Capsule())

                Text(article.title)
                    .font(.system(size: titleSize, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom,80)

                if let sourceHost {
                    Text(sourceHost.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.86))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 56)
            .offset(y: -18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.22), radius: 14, x: 0, y: 8)
    }

    private var articleImageURL: URL? {
        guard let imageUrl = article.imageUrl else { return nil }
        return URL(string: imageUrl)
    }

    private var sourceHost: String? {
        guard let url = URL(string: article.url), let host = url.host else { return nil }
        let cleanedHost = host.replacingOccurrences(of: "www.", with: "")
        return cleanedHost.isEmpty ? nil : cleanedHost
    }

    private var titleSize: CGFloat {
        horizontalSizeClass == .compact ? 22 : 26
    }

    private var cardHeight: CGFloat {
        horizontalSizeClass == .compact ? 290 : 340
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.35)
    }
}

struct HeadingCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let article: Article
    let feed: FeedOption

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroSection

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    Label("Top Story", systemImage: "bolt.fill")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(Color.accentColor)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())

                    Spacer()

                    if let sourceHost {
                        Text(sourceHost.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(tertiaryCardTextColor)
                            .lineLimit(1)
                    }
                }

                Text(article.title)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundStyle(primaryCardTextColor)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(1.2)
                    .lineLimit(2)

                if let summaryText {
                    Text(summaryText)
                        .font(.caption)
                        .foregroundStyle(secondaryCardTextColor)
                        .lineSpacing(1)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    if let publishedDateText {
                        Label(publishedDateText, systemImage: "clock")
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(tertiaryCardTextColor)
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(secondaryCardTextColor)
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 4)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = articleImageURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 148)
                        .clipped()
                } placeholder: {
                    LinearGradient(
                        colors: [Color(.systemGray5), Color(.systemGray4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 148)
                }
            } else {
                LinearGradient(
                    colors: [Color(red: 0.17, green: 0.28, blue: 0.46), Color(red: 0.09, green: 0.15, blue: 0.24)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(maxWidth: .infinity)
                .frame(height: 148)

                Image(systemName: "newspaper.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white.opacity(0.86))
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.62)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 92)

            HStack(spacing: 8) {
                Image(systemName: "globe.americas.fill")
                    .font(.caption)
                Text(feed.rawValue)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.35), in: Capsule())
            .padding(12)
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "arrow.up.forward.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
                .padding(10)
        }
    }

    private var articleImageURL: URL? {
        guard let imageUrl = article.imageUrl else { return nil }
        return URL(string: imageUrl)
    }

    private var cardBackgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.172549, green: 0.172549, blue: 0.180392) // #2C2C2E
            : Color(red: 0.949020, green: 0.949020, blue: 0.968627) // #F2F2F7
    }

    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    private var primaryCardTextColor: Color {
        colorScheme == .dark ? .white : Color(.label)
    }

    private var secondaryCardTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.72) : Color(.secondaryLabel)
    }

    private var tertiaryCardTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.55) : Color(.tertiaryLabel)
    }

    private var sourceHost: String? {
        guard let url = URL(string: article.url), let host = url.host else { return nil }
        let cleanedHost = host.replacingOccurrences(of: "www.", with: "")
        return cleanedHost.isEmpty ? nil : cleanedHost
    }

    private var summaryText: String? {
        guard let description = article.description?.trimmingCharacters(in: .whitespacesAndNewlines),
              !description.isEmpty,
              description != "[Removed]" else {
            return nil
        }

        return description.replacingOccurrences(of: "\n", with: " ")
    }

    private var publishedDateText: String? {
        guard let publishedAt = article.publishedAt,
              let date = Self.isoDateFormatterWithFractional.date(from: publishedAt) ?? Self.isoDateFormatter.date(from: publishedAt) else {
            return nil
        }
        return Self.displayDateFormatter.string(from: date)
    }

    private static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let isoDateFormatterWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        return SFSafariViewController(url: url, configuration: config)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct ArticleScreen: View {
    let articleURL: String

    var body: some View {
        if let url = URL(string: articleURL) {
            SafariView(url: url)
                .ignoresSafeArea()
        } else {
            ContentUnavailableView(
                "Article Unavailable",
                systemImage: "newspaper.fill",
                description: Text("The article URL is invalid.")
            )
        }
    }
}

#Preview {
    ContentView()
}
