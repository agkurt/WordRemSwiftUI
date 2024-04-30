//
//  ProfileImageCam.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 30.04.2024.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import FirebaseStorage

struct ProfileImageCam: View {
    
    @State private var image: UIImage?
    @State private var isConfirmationDialogPresented: Bool = false
    @State private var isImagePickerPresented: Bool = false
    @State private var sourceType: SourceType = .camera
    @State private var viewModel = ProfileViewModel()
    
    var body: some View {
        ZStack {
            if let image = image {
                CircularImageView(image: image)
            } else {
                PlaceholderView()
            }
        }
        .onTapGesture {
            isConfirmationDialogPresented = true
        }
        .confirmationDialog("Choose an option", isPresented: $isConfirmationDialogPresented) {
            Button("Camera") {
                sourceType = .camera
                isImagePickerPresented = true
            }
            Button("Photo Library") {
                sourceType = .photoLibrary
                isImagePickerPresented = true
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            if sourceType == .camera {
                ImagePicker(isPresented: $isImagePickerPresented, image: $image, sourceType: .camera)
            } else {
                PhotoPicker(selectedImage: $image)
            }
        }
        .onChange(of: image) { newImage, _ in
            if let selectedImage = newImage {
                Task {
                  await viewModel.uploadPhoto(image: selectedImage)
                }
            }
        }
    }

}

struct CircularImageView: View {
    var image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .resizable().scaledToFill()
            .frame(width: 200, height: 200)
            .clipShape(Circle())
    }
}

struct PlaceholderView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 5)
                .foregroundColor(.gray)
                .frame(width: 200, height: 200)
            Image(systemName: "plus")
                .font(.system(size: 50))
                .foregroundColor(.gray)
        }
    }
}


