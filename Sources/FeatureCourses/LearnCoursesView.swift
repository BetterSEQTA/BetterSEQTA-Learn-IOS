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
                    LearnLoadingState()
                } else if let error = viewModel.errorMessage, viewModel.subjects.isEmpty {
                    LearnErrorBanner(message: error) {
                        Task { await viewModel.load() }
                    }
                } else if viewModel.subjects.isEmpty {
                    LearnEmptyState(title: "No subjects", message: "Your subject list is empty.")
                } else {
                    List(viewModel.subjects) { subject in
                        NavigationLink(value: subject) {
                            LearnSubjectRow(subject: subject)
                        }
                        .listRowBackground(Color.clear)
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
            .background(LearnTheme.Colors.background)
            .navigationTitle("Courses")
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }
}

private struct LearnSubjectRow: View {
    let subject: Subject

    var body: some View {
        LearnGlassCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.code)
                    .font(.headline)
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                Text(subject.title)
                    .font(.subheadline)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
            }
        }
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
        .background(LearnTheme.Colors.background)
        .navigationTitle(subject.code)
    }
}
