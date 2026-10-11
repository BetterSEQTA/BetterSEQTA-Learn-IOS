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
                        LearnCourseDetailView(
                            subject: subject,
                            courses: viewModel.courses(for: subject)
                        )
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
    let courses: [Course]

    var body: some View {
        Group {
            if courses.isEmpty {
                LearnEmptyState(
                    title: "No course items",
                    message: "SEQTA did not return course modules for \(subject.code)."
                )
            } else {
                List(courses) { course in
                    LearnGlassCard {
                        Text(course.title)
                            .foregroundStyle(LearnTheme.Colors.primaryText)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background { LearnScreenBackground() }
        .learnShellNavigationDepth(1)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            LearnInlineNavBar(title: subject.code) {
                LearnCopyMorphIconButton(
                    text: "\(subject.code)\n\(subject.title)",
                    accessibilityLabel: "Copy subject details"
                )
            }
        }
    }
}
