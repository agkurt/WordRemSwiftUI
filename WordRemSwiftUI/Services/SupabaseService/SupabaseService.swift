//
//  SupabaseService.swift
//  WordRemSwiftUI
//
//  Supabase client singleton.
//  Credentials are read from Config.plist — same pattern as APIKey.swift.
//

import Foundation
import Supabase

final class SupabaseService {

    // MARK: - Singleton
    static let shared = SupabaseService()

    // MARK: - Client
    let client: SupabaseClient

    // MARK: - Public URL (for Edge Functions etc.)
    private(set) var supabaseURLString: String = ""

    // MARK: - Initx4
    private init() {
        // Read from Config.plist — same approach as existing APIKey.swift
        guard
            let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
            let plist = NSDictionary(contentsOfFile: path),
            let urlString = plist["SUPABASE_URL"] as? String,
            let anonKey  = plist["SUPABASE_ANON_KEY"] as? String,
            let supabaseURL = URL(string: urlString),
            !urlString.hasPrefix("https://YOUR_PROJECT"),
            !anonKey.hasPrefix("YOUR_SUPABASE")
        else {
            fatalError("""
            ⚠️  Supabase credentials missing or still placeholder!
            Open WordRemSwiftUI/Config.plist and replace:
              SUPABASE_URL     → https://<your-ref>.supabase.co
              SUPABASE_ANON_KEY → eyJ...
            Get these from: Supabase Dashboard → Settings → API
            """)
        }

        supabaseURLString = urlString

        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    autoRefreshToken: true,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    // MARK: - Convenience
    var currentUserId: UUID? {
        client.auth.currentSession?.user.id
    }
}
