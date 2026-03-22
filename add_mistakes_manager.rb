require 'xcodeproj'
project_path = 'WordRemSwiftUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath(File.join('WordRemSwiftUI', 'Services'), true)

file_path = 'WordRemSwiftUI/Services/MistakesManager.swift'
file_ref = group.new_reference(file_path)

target.add_file_references([file_ref])

project.save
