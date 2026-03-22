require 'xcodeproj'

project_path = 'WordRemSwiftUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# 1. Clean up bad file references
def clean_refs(group)
  bad_files = []
  group.files.each do |f|
    if ['WelcomeView.swift', 'LanguageSelectionView.swift', 'ProficiencyView.swift', 'OnboardingLoadingView.swift'].include?(f.path)
      bad_files << f
    end
  end
  bad_files.each { |f| f.remove_from_project }
  group.groups.each { |g| clean_refs(g) }
end

clean_refs(project.main_group)

# 2. Setup correct group
view_group = project.main_group.find_subpath(File.join('WordRemSwiftUI', 'View'), false)
onboarding_group = view_group.children.find { |c| c.display_name == 'OnboardingFlow' }
if onboarding_group.nil?
  onboarding_group = view_group.new_group('OnboardingFlow', 'OnboardingFlow')
end

# 3. Add files securely
['WelcomeView.swift', 'LanguageSelectionView.swift', 'ProficiencyView.swift', 'OnboardingLoadingView.swift'].each do |file_name|
  file_ref = onboarding_group.new_file(file_name)
  target.add_file_references([file_ref])
end

project.save
puts "Fixed Xcode project references."
