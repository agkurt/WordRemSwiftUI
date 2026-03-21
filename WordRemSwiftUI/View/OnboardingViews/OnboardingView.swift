//
//  OnboardingView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 10.03.2026.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            LinearBackgroundView()
            
            VStack(spacing: 0) {
                // Progress Bar
                OnboardingProgressBar(currentPage: viewModel.currentPage, totalPages: 3)
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                // Content
                TabView(selection: $viewModel.currentPage) {
                    // Page 1: Age Range
                    AgeSelectionPage(selectedAge: $viewModel.selectedAge)
                        .tag(0)
                    
                    // Page 2: Native Language
                    NativeLanguagePage(selectedLanguage: $viewModel.nativeLanguage)
                        .tag(1)
                    
                    // Page 3: Target Language
                    TargetLanguagePage(selectedLanguage: $viewModel.targetLanguage)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    if viewModel.currentPage > 0 {
                        Button(action: { viewModel.previousPage() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.custom("Feather-Bold", size: 16))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.Colors.cardBackground)
                            )
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    Button(action: {
                        if viewModel.currentPage == 2 {
                            viewModel.completeOnboarding()
                            dismiss()
                        } else {
                            viewModel.nextPage()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(viewModel.currentPage == 2 ? "Get Started" : "Continue")
                            Image(systemName: viewModel.currentPage == 2 ? "checkmark" : "chevron.right")
                        }
                        .font(.custom("Feather-Bold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: viewModel.canProceed() ? [Color(hex: "#f97316"), Color(hex: "#ea580c")] : [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(
                            color: viewModel.canProceed() ? Color(hex: "#f97316").opacity(0.4) : .clear,
                            radius: 12,
                            y: 6
                        )
                    }
                    .disabled(!viewModel.canProceed())
                }
                .padding(.horizontal)
                .padding(.vertical, 24)
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Progress Bar
struct OnboardingProgressBar: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? AppTheme.Colors.primaryOrange : AppTheme.Colors.inputBorder)
                    .frame(height: 4)
                    .frame(maxWidth: index == currentPage ? 40 : 20)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Page 1: Age Selection
struct AgeSelectionPage: View {
    @Binding var selectedAge: AgeRange?
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("👋")
                    .font(.system(size: 80))
                
                Text("Welcome to WordRem!")
                    .font(.custom("Feather-Bold", size: 32))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Let's personalize your learning experience")
                    .font(.custom("Feather-Bold", size: 16))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                Text("What's your age range?")
                    .font(.custom("Feather-Bold", size: 18))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                VStack(spacing: 12) {
                    ForEach(AgeRange.allCases, id: \.self) { age in
                        AgeRangeButton(age: age, isSelected: selectedAge == age) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedAge = age
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct AgeRangeButton: View {
    let age: AgeRange
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(age.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(age.rawValue)
                        .font(.custom("Feather-Bold", size: 16))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(age.description)
                        .font(.custom("Feather-Bold", size: 13))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.Colors.primaryOrange)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? AppTheme.Colors.primaryOrange : AppTheme.Colors.inputBorder, lineWidth: 2)
                    )
                    .shadow(
                        color: isSelected ? AppTheme.Colors.primaryOrange.opacity(0.3) : AppTheme.Shadows.softColor,
                        radius: isSelected ? 12 : 4,
                        y: isSelected ? 6 : 2
                    )
            )
        }
    }
}

// MARK: - Page 2: Native Language
struct NativeLanguagePage: View {
    @Binding var selectedLanguage: Language?
    @State private var searchText = ""
    
    private var filteredLanguages: [Language] {
        if searchText.isEmpty {
            return [.english, .turkish, .spanish, .french, .german, .italian, .portuguese, .russian, .japanese, .korean, .chinese, .arabic]
        }
        return Language.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("🌍")
                    .font(.system(size: 60))
                
                Text("What's your native language?")
                    .font(.custom("Feather-Bold", size: 26))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("This will be your translation source")
                    .font(.custom("Feather-Bold", size: 15))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                TextField("Search language...", text: $searchText)
                    .font(.custom("Feather-Bold", size: 16))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .autocapitalization(.none)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.Colors.cardBackground)
                    .shadow(color: AppTheme.Shadows.softColor, radius: 4, y: 2)
            )
            .padding(.horizontal)
            
            // Language Grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredLanguages, id: \.self) { language in
                        LanguageCardButton(language: language, isSelected: selectedLanguage == language) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedLanguage = language
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Page 3: Target Language
struct TargetLanguagePage: View {
    @Binding var selectedLanguage: Language?
    @State private var searchText = ""
    
    private var filteredLanguages: [Language] {
        if searchText.isEmpty {
            return [.english, .turkish, .spanish, .french, .german, .italian, .portuguese, .russian, .japanese, .korean, .chinese, .arabic]
        }
        return Language.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("🎯")
                    .font(.system(size: 60))
                
                Text("Which language do you want to learn?")
                    .font(.custom("Feather-Bold", size: 26))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("This will be your learning target")
                    .font(.custom("Feather-Bold", size: 15))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                TextField("Search language...", text: $searchText)
                    .font(.custom("Feather-Bold", size: 16))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .autocapitalization(.none)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.Colors.cardBackground)
                    .shadow(color: AppTheme.Shadows.softColor, radius: 4, y: 2)
            )
            .padding(.horizontal)
            
            // Language Grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredLanguages, id: \.self) { language in
                        LanguageCardButton(language: language, isSelected: selectedLanguage == language) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedLanguage = language
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Language Card Button
struct LanguageCardButton: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(language.flag)
                    .font(.system(size: 40))
                
                Text(language.shortName)
                    .font(.custom("Feather-Bold", size: 16))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.Colors.primaryOrange)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? AppTheme.Colors.primaryOrange : AppTheme.Colors.inputBorder, lineWidth: 2)
                    )
                    .shadow(
                        color: isSelected ? AppTheme.Colors.primaryOrange.opacity(0.3) : AppTheme.Shadows.softColor,
                        radius: isSelected ? 12 : 4,
                        y: isSelected ? 6 : 2
                    )
            )
        }
    }
}

// MARK: - Age Range Enum
enum AgeRange: String, CaseIterable {
    case young = "Under 18"
    case adult = "18 - 35"
    case mature = "36 - 50"
    case senior = "50+"
    
    var emoji: String {
        switch self {
        case .young: return "🧒"
        case .adult: return "👨‍💼"
        case .mature: return "👨‍🎓"
        case .senior: return "👴"
        }
    }
    
    var description: String {
        switch self {
        case .young: return "Student or teenager"
        case .adult: return "Young professional"
        case .mature: return "Experienced learner"
        case .senior: return "Senior learner"
        }
    }
}

// MARK: - ViewModel
@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    @Published var selectedAge: AgeRange?
    @Published var nativeLanguage: Language?
    @Published var targetLanguage: Language?
    
    func nextPage() {
        withAnimation(.spring(response: 0.3)) {
            currentPage += 1
        }
    }
    
    func previousPage() {
        withAnimation(.spring(response: 0.3)) {
            currentPage -= 1
        }
    }
    
    func canProceed() -> Bool {
        switch currentPage {
        case 0: return selectedAge != nil
        case 1: return nativeLanguage != nil
        case 2: return targetLanguage != nil
        default: return false
        }
    }
    
    func completeOnboarding() {
        // Save to UserDefaults
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(selectedAge?.rawValue, forKey: "userAgeRange")
        UserDefaults.standard.set(nativeLanguage?.code, forKey: "userNativeLanguage")
        UserDefaults.standard.set(targetLanguage?.code, forKey: "userTargetLanguage")
        
        print("✅ Onboarding completed!")
        print("Age: \(selectedAge?.rawValue ?? "N/A")")
        print("Native: \(nativeLanguage?.rawValue ?? "N/A")")
        print("Target: \(targetLanguage?.rawValue ?? "N/A")")
    }
}

#Preview {
    OnboardingView()
}
