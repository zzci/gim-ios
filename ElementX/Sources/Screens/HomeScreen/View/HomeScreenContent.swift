//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SentrySwiftUI
import SwiftUI

struct HomeScreenContent: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @ObservedObject var context: HomeScreenViewModel.Context
    let scrollViewAdapter: ScrollViewAdapter
    
    var body: some View {
        roomList
            .sentryTrace("\(Self.self)")
    }
    
    private var roomList: some View {
        GeometryReader { geometry in
            ScrollView {
                switch context.viewState.roomListMode {
                case .skeletons:
                    LazyVStack(spacing: 0) {
                        ForEach(context.viewState.visibleRooms, id: \.id) { room in
                            HomeScreenRoomCell(room: room, isSelected: false, mediaProvider: context.mediaProvider, action: context.send)
                                .redacted(reason: .placeholder)
                                .shimmer() // Putting this directly on the LazyVStack creates an accordion animation on iOS 16.
                        }
                    }
                    .disabled(true)
                    .accessibilityRepresentation {
                        Text(L10n.commonLoading)
                    }
                case .empty:
                    HomeScreenEmptyStateLayout(minHeight: geometry.size.height) {
                        topSection
                        
                        HomeScreenEmptyStateView(context: context)
                            .layoutPriority(1)
                    }
                case .rooms:
                    LazyVStack(spacing: 0) {
                        Section {
                            if !context.viewState.shouldShowEmptyFilterState {
                                HomeScreenRoomList(context: context)
                            }
                        } header: {
                            topSection
                        }
                    }
                    .isSearching($context.isSearchFieldFocused)
                    .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always))
                    .compoundSearchField()
                    .disableAutocorrection(true)
                }
            }
            .introspect(.scrollView, on: .supportedVersions) { scrollView in
                guard scrollView != scrollViewAdapter.scrollView else { return }
                scrollViewAdapter.scrollView = scrollView
            }
            .onReceive(scrollViewAdapter.didScroll) { _ in
                scheduleVisibleRangeUpdate()
            }
            .onReceive(scrollViewAdapter.isScrolling) { _ in
                scheduleVisibleRangeUpdate()
            }
            .onChange(of: context.searchQuery) {
                scheduleVisibleRangeUpdate()
            }
            .onChange(of: context.viewState.visibleRooms) {
                scheduleVisibleRangeUpdate()
            }
            .background {
                Button("") {
                    context.send(viewAction: .globalSearch)
                }
                .keyboardShortcut(KeyEquivalent("k"), modifiers: [.command])
            }
            .overlay {
                if context.viewState.shouldShowEmptyFilterState {
                    RoomListFiltersEmptyStateView(state: context.filtersState)
                        .background(.compound.bgCanvasDefault)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollDisabled(context.viewState.roomListMode == .skeletons)
            .scrollBounceBehavior(context.viewState.roomListMode == .empty ? .basedOnSize : .automatic)
            .animation(.elementDefault, value: context.viewState.roomListMode)
            .animation(.none, value: context.viewState.visibleRooms)
        }
    }
    
    @ViewBuilder
    private var topSection: some View {
        // An empty VStack causes glitches within the room list
        if context.viewState.shouldShowFilters || context.viewState.shouldShowBanner {
            VStack(spacing: 0) {
                if context.viewState.shouldShowFilters {
                    RoomListFiltersView(state: $context.filtersState)
                }
                
                if case let .show(state) = context.viewState.securityBannerMode {
                    HomeScreenRecoveryKeyConfirmationBanner(state: state, context: context)
                } else if context.viewState.shouldShowNewSoundBanner {
                    HomeScreenNewSoundBanner { context.send(viewAction: .dismissNewSoundBanner) }
                }
            }
            .background(Color.compound.bgCanvasDefault)
        }
    }
    
    @State private var visibleRangeUpdateTask: Task<Void, Never>?

    /// Debounces multiple visible range update requests. Cancels the previous pending
    /// computation and waits 500ms before executing, preventing redundant calls
    /// from rapid scroll/filter events while allowing the UI to settle.
    private func scheduleVisibleRangeUpdate() {
        visibleRangeUpdateTask?.cancel()
        visibleRangeUpdateTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            computeVisibleRange()
        }
    }

    private func computeVisibleRange() {
        guard let scrollView = scrollViewAdapter.scrollView,
              scrollViewAdapter.isScrolling.value == false, // Ignore while scrolling
              context.searchQuery.isEmpty == true, // Ignore while filtering
              context.viewState.visibleRooms.count > 0 else {
            return
        }
        
        guard scrollView.contentSize.height > scrollView.bounds.height else {
            return
        }
        
        let adjustedContentSize = max(scrollView.contentSize.height - scrollView.contentInset.top - scrollView.contentInset.bottom, scrollView.bounds.height)
        let cellHeight = adjustedContentSize / Double(context.viewState.visibleRooms.count)
        
        let firstIndex = Int(max(0.0, scrollView.contentOffset.y + scrollView.contentInset.top) / cellHeight)
        let lastIndex = Int(max(0.0, scrollView.contentOffset.y + scrollView.bounds.height) / cellHeight)
        
        // This will be deduped and throttled on the view model layer
        context.send(viewAction: .updateVisibleItemRange(firstIndex..<lastIndex))
    }
}
