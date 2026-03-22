require 'xcodeproj'

project_path = 'WordRemSwiftUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

view_group = project.main_group.find_subpath(File.join('WordRemSwiftUI', 'View'), false)
onboarding_group = view_group.children.find { |c| c.display_name == 'OnboardingFlow' || c.path == 'OnboardingFlow' }

if onboarding_group.nil?
  puts "OnboardingFlow group missing!"
  exit(1)
end

file_name = 'MascotAnimationView.swift'
file_ref = onboarding_group.files.find { |f| f.path == file_name }
if file_ref.nil?
  file_ref = onboarding_group.new_file(file_name)
  target.add_file_references([file_ref])
  puts "Added #{file_name} to target"
end

project.save
puts "Fixed Xcode project references 4 for MascotAnimationView."
