import re

file_path = "WordRemSwiftUI.xcodeproj/project.pbxproj"
with open(file_path, "r") as file:
    content = file.read()

uuid_file_ref = "FBA999999999999999999991"
uuid_build_file = "FBA999999999999999999992"

if "EventManager.swift" not in content:
    build_file_str = fix_pbxproj{uuid_build_file} /* EventManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {uuid_file_ref} /* EventManager.swift */; }};\n"
    content = re.sub(r"(\/\* End PBXBuildFile section \*\/)", build_file_str + r"\1", content)
    
    file_ref_str = f"{uuid_file_ref} /* EventManager.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = EventManager.swift; sourceTree = \"<group>\"; }};\n"
    content = re.sub(r"(\/\* End PBXFileReference section \*\/)", file_ref_str + r"\1", content)
    
    sources_str = f"{uuid_build_file} /* EventManager.swift in Sources */,\n"
    content = re.sub(r"(isa = PBXSourcesBuildPhase;nbdstbuildActionMask = [\d]+;nbdstfiles = \(\n)", r"\1" + sources_str, content, count=1)
    
    group_pattern = r"(path = FirebaseService;nbdstsourceTree = \"<group>\";nbdstchildren = \(\n)"
    content = re.sub(group_pattern, r"\1" + f"{uuid_file_ref} /* EventManager.swift */,\n", content)

with open(file_path, "w") as file:
    file.write(content)
print("Updated successfully")
