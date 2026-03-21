//
//  ProfileViewModel.swift
//  WordRemSwiftUI
//
//  Rewritten to use Supabase Auth + Supabase Storage.
//  Firebase Auth / Firestore / Storage completely removed.
//

import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var username: String = ""
    @Published var email: String = ""
    @Published var imageURL: URL?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Fetch Profile
    func fetchUsernameInfo() async {
        do {
            guard let profile = try await SupabaseDataService.shared.fetchUserProfile() else { return }
            username = profile.username
            // Email comes from Supabase Auth session
            email = SupabaseService.shared.client.auth.currentSession?.user.email ?? ""
            if let urlStr = profile.avatarUrl, let url = URL(string: urlStr) {
                imageURL = url
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ fetchUsernameInfo: \(error)")
        }
    }

    // MARK: - Upload Profile Photo
    func uploadPhoto(image: UIImage) async {
        guard let uid = SupabaseService.shared.currentUserId else { return }
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        isLoading = true
        defer { isLoading = false }

        let fileName = "\(UUID().uuidString).jpg"
        let path = "\(uid.uuidString)/\(fileName)"

        do {
            // Upload to Supabase Storage bucket "profile-images"
            _ = try await SupabaseService.shared.client.storage
                .from("profile-images")
                .upload(path: path, file: data)

            // Get public URL
            let publicURL = try SupabaseService.shared.client.storage
                .from("profile-images")
                .getPublicURL(path: path)

            imageURL = publicURL

            // Save URL to users table
            struct AvatarUpdate: Encodable { let avatar_url: String }
            try await SupabaseService.shared.client
                .from("users")
                .update(AvatarUpdate(avatar_url: publicURL.absoluteString))
                .eq("id", value: uid.uuidString)
                .execute()

            print("✅ Profile photo uploaded: \(publicURL)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ uploadPhoto error: \(error)")
        }
    }
}
