import CoreDesign
import Domain
import SwiftUI

public struct LearnCoursesView: View {
    @State private var viewModel: LearnCoursesViewModel

    public init(viewModel: LearnCoursesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LearnLoadingState(preset: .list(rows: 8))
                } else if let error = viewModel.errorMessage, viewModel.subjects.isEmpty {
                    LearnErrorBanner(message: error) {
                        Task { await viewModel.load() }
                    }
                } else if viewModel.subjects.isEmpty {
                    LearnEmptyState(title: "No subjects", message: "Your subject list is empty.")
                } else {
                    List {
                        ForEach(Array(viewModel.subjects.enumerated()), id: \.element.id) { index, subject in
                            NavigationLink(value: subject) {
                                LearnSubjectRow(subject: subject)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .learnListEntrance(index: index)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .navigationDestination(for: Subject.self) { subject in
                        LearnCourseDetailView(subject: subject, viewModel: viewModel)
                    }
                }
            }
            .background { LearnScreenBackground() }
            .learnShellNavigationDepth(0)
            .navigationBarHidden(true)
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }
}

private struct LearnSubjectRow: View {
    let subject: Subject

    var body: some View {
        LearnListRow(
            accent: LearnSubjectColour.parse(subject.code),
            title: subject.title,
            subtitle: subject.code,
            showsChevron: true
        )
    }
}

private struct LearnCourseDetailView: View {
    let subject: Subject
    let viewModel: LearnCoursesViewModel

    @State private var content: CourseContent?
    @State private var isLoading = true
    @State private var loadFailed = false

    var body: some View {
        Group {
            if isLoading {
                LearnLoadingState(preset: .detailBody)
            } else if let content {
                LearnCourseContentScreen(subject: subject, content: content, viewModel: viewModel)
            } else {
                LearnEmptyState(
                    title: "Could not load course",
                    message: loadFailed
                        ? "SEQTA did not return course content for \(subject.title). Try again later."
                        : "This subject is missing programme or class identifiers required by SEQTA."
                )
            }
        }
        .background { LearnScreenBackground() }
        .learnShellNavigationDepth(1)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            LearnInlineNavBar(title: subject.title)
        }
        .task {
            if let cached = viewModel.cachedCourse(for: subject) {
                content = cached
                isLoading = false
                return
            }
            isLoading = true
            loadFailed = false
            let loaded = await viewModel.loadCourse(for: subject)
            content = loaded
            loadFailed = loaded == nil && subject.programme != nil && subject.metaclass != nil
            isLoading = false
        }
    }
}
