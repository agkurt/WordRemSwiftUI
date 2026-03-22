import re

file_path = "WordRemSwiftUI.xcodeproj/project.pbxproj"
with open(file_path, 'r') as file:
    content = file.read()

# Replace Firebase SDK version 10.25.0 -> 11.0.0
content = content.replace("10.25.0", "11.0.0")

# Find and delete product references completely
# Usually they look like:  E8A83A492C1D41E700F9FDE6 /* FirebaseFirestoreSwift in Frameworks */ = {isa = PBXBuildFile; productRef = E8A83A482C1D41E700F9FDE6 /* FirebaseFirestoreSwift */; };
pattern = r"[A-F0-9]{24} \/\* (FirebaseFirestoreSwift|FirebaseRemoteConfigSwift|FirebaseDatabaseSwift).*?\n"
content = re.sub(pattern, "", content)

# Also remove references in PBXFrameworksBuildPhase
# Usually like: E8A83A492C1D41E700F9FDE6 /* FirebaseFirestoreSwift in Frameworks */,
pattern_phase = r"[A-F0-9]{24} \/\* (FirebaseFirestoreSwift|FirebaseRemoteConfigSwift|FirebaseDatabaseSwift).*?,\n"
content = re.sub(pattern_phase, "", content)

# And PBXNativeTarget dependencies
pattern_dep = r"[A-F0-9]{24} \/\* (FirebaseFirestoreSwift|FirebaseRemoteConfigSwift|FirebaseDatabaseSwift).*?,\n"
content = re.sub(pattern_dep, "", content)

with open(file_path, 'w') as file:
    file.write(content)
print("done")
