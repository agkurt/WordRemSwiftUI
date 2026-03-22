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
    /// Kullanıcının seçtiği dil için henüz kurs yok
    @Published var noCoursesForLanguage = false

    /// True after the first successful load; prevents re-fetching on every tab switch.
    private(set) var hasInitiallyLoaded = false

    // MARK: - Load Courses (kullanıcının seçtiği dile göre filtreli)
    func loadCourses() async {
        isLoading = true
        noCoursesForLanguage = false
        errorMessage = nil
        do {

            // Onboarding'de kaydedilen hedef dil kodunu oku
            let targetLangCode = UserDefaults.standard.string(forKey: "selectedTargetLanguageCode")
            courses = try await SupabaseDataService.shared.fetchCourses(targetLangCode: targetLangCode)

            if courses.isEmpty && targetLangCode != nil {
                // Seçili dil için kurs yok — kullanıcıya bilgi ver
                noCoursesForLanguage = true
                isLoading = false
                return
            }

            // Seçili kurs yoksa ilkini seç
            if selectedCourse == nil { selectedCourse = courses.first }

            if let course = selectedCourse {
                try await loadPath(courseId: course.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        hasInitiallyLoaded = true
        isLoading = false
    }

    /// Dil değişince çağır — PathMapView'den kurs yeniden yüklensin
    func refreshForLanguage(_ langCode: String) async {
        selectedCourse = nil
        levelsWithProgress = []
        noCoursesForLanguage = false
        await loadCourses()
    }

    // MARK: - Load Path for a course
    func loadPath(courseId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        // Check if user is enrolled (has any unlocked level)
        let loaded = try await SupabaseDataService.shared.fetchLevelsWithProgress(courseId: courseId)

        // Hiç user_progress satırı yoksa → yeni kayıt, ilk leveli aç
        let hasAnyProgress = loaded.contains { $0.progress != nil }
        if !hasAnyProgress {
            let proficiency = UserDefaults.standard.integer(forKey: "selectedProficiencyLevel")
            try await SupabaseDataService.shared.enrollWithProficiency(
                courseId: courseId,
                proficiencyLevel: proficiency
            )
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
