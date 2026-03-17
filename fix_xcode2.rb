require 'xcodeproj'

project_path = 'WordRemSwiftUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# 1. Clean up bad file references
def clean_refs(group)
  bad_files = []
  group.files.each do |f|
    if f.path && (f.path.include?('WelcomeView.swift') || f.path.include?('LanguageSelectionView.swift') || f.path.include?('ProficiencyView.swift') || f.path.include?('OnboardingLoadingView.swift'))
      bad_files << f
    end
  end
  bad_files.each { |f| f.remove_from_project }
  group.groups.each { |g| clean_refs(g) }
end

clean_refs(project.main_group)

# 2. Setup correct group
view_group = project.main_group.find_subpath(File.join('WordRemSwiftUI', 'View'), false)
old_onboarding = view_group.children.find { |c| c.display_name == 'OnboardingFlow' || c.path == 'OnboardingFlow' }
if old_onboarding
  old_onboarding.remove_from_project
end

onboarding_group = view_group.new_group('OnboardingFlow', 'OnboardingFlow')

# 3. Add files securely
['WelcomeView.swift', 'LanguageSelectionView.swift', 'ProficiencyView.swift', 'OnboardingLoadingView.swift'].each do |file_name|
  file_ref = onboarding_group.new_file(file_name)
  target.add_file_references([file_ref])
end

project.save
puts "Fixed Xcode project references 2."
