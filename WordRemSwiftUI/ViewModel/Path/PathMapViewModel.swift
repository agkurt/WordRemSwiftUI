//
//  PathMapViewModel.swift
//  WordRemSwiftUI
//
//  ViewModel for the Path (gamified level map) screen.
//

import SwiftUI

@MainActor
final class PathMapViewModel: ObservableObject {

    // MARK: - Published
    @Published var levelsWithProgress: [SBLevelWithProgress] = []
    @Published var courses: [SBCourse] = []
    @Published var selectedCourse: SBCourse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userProfile: SBUser?

    // MARK: - Load Courses
    func loadCourses() async {
        isLoading = true
        do {
            courses = try await SupabaseDataService.shared.fetchCourses()
            if selectedCourse == nil { selectedCourse = courses.first }
            if let course = selectedCourse {
                try await loadPath(courseId: course.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Load Path for a course
    func loadPath(courseId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        // Check if user is enrolled (has any unlocked level)
        let loaded = try await SupabaseDataService.shared.fetchLevelsWithProgress(courseId: courseId)

        // If no progress at all → auto-enroll (unlock level 1)
        if loaded.allSatisfy({ $0.status == .locked }) {
            try await SupabaseDataService.shared.enrollInCourse(courseId: courseId)
            levelsWithProgress = try await SupabaseDataService.shared.fetchLevelsWithProgress(courseId: courseId)
        } else {
            levelsWithProgress = loaded
        }
    }

    // MARK: - Switch course
    func selectCourse(_ course: SBCourse) {
        selectedCourse = course
        Task {
            try? await loadPath(courseId: course.id)
        }
    }

    // MARK: - Load user profile (XP, streak)
    func loadUserProfile() async {
        userProfile = try? await SupabaseDataService.shared.fetchUserProfile()
    }

    // MARK: - Computed helpers
    var totalXP: Int { userProfile?.totalXp ?? 0 }
    var streakDays: Int { userProfile?.streakDays ?? 0 }

    var completedCount: Int {
        levelsWithProgress.filter { $0.status == .completed }.count
    }

    var courseProgress: Double {
        guard !levelsWithProgress.isEmpty else { return 0 }
        return Double(completedCount) / Double(levelsWithProgress.count)
    }
}
