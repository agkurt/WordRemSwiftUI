//
//  ImagePicker.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 30.04.2024.
//

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
   @Binding var isPresented: Bool
   @Binding var image: UIImage?
   var sourceType: UIImagePickerController.SourceType
   
   func makeCoordinator() -> Coordinator {
       Coordinator(parent: self)
   }
   
   // This method creates a UIImagePickerController instance and sets its delegate and source type
   func makeUIViewController(context: Context) -> UIImagePickerController {
       let picker = UIImagePickerController()
       picker.delegate = context.coordinator  // Set the delegate to handle image picker events
       picker.sourceType = sourceType // Set the source type (camera or photo library)
        return picker
   }
   
   // This method is used to update the UIImagePickerController when SwiftUI view updates, but not used in this example
   func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
   
   // Coordinator class to handle the delegate methods of UIImagePickerController
   class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
       var parent:ImagePicker  // Reference to the parent ImagePicker struct
       init(parent: ImagePicker) {
           self.parent = parent
       }
        
       
       // This delegate method is called when an image is selected
       func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
           if let uiImage = info[.originalImage] as? UIImage {// Retrieve the selected image
               parent.image = uiImage
           }
           parent.isPresented = false// Dismiss the image picker
       }
       
       // This delegate method is called when the image picker is cancelled
       func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
           parent.isPresented = false // Dismiss the image picker
       }
   }
}
