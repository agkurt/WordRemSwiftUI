require 'xcodeproj'

project_path = 'WordRemSwiftUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find or create group
main_group = project.main_group.find_subpath(File.join('WordRemSwiftUI', 'View', 'OnboardingFlow'), true)

# Target
target = project.targets.first

# Add files
files_to_add = [
  'WordRemSwiftUI/View/OnboardingFlow/WelcomeView.swift',
  'WordRemSwiftUI/View/OnboardingFlow/LanguageSelectionView.swift',
  'WordRemSwiftUI/View/OnboardingFlow/ProficiencyView.swift',
  'WordRemSwiftUI/View/OnboardingFlow/OnboardingLoadingView.swift'
]

files_to_add.each do |file_path|
  file_ref = main_group.new_reference(File.basename(file_path))
  target.add_file_references([file_ref])
end

project.save
puts "Files added to Xcode project."
