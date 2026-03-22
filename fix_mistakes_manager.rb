require 'xcodeproj'
project_path = 'WordRemSwiftUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath(File.join('WordRemSwiftUI', 'Services'), true)

# Remove the invalid one
invalid_refs = group.files.select { |f| f.path == 'WordRemSwiftUI/Services/MistakesManager.swift' }
invalid_refs.each do |ref|
    target.source_build_phase.files_references.delete(ref)
    ref.remove_from_project
end

# Add the correct one
file_path = 'MistakesManager.swift'
file_ref = group.new_reference(file_path)

target.add_file_references([file_ref])

project.save
