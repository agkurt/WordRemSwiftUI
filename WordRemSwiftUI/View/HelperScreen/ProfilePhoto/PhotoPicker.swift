//
//  PhotoPicker.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 30.04.2024.
//

import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
   class Coordinator: NSObject, PHPickerViewControllerDelegate {
       var parent:PhotoPicker // Reference to the parent PhotoPicker struct
       
       init(parent: PhotoPicker) {
           self.parent = parent
       }
       
       // This delegate method is called when an image is selected
       func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
           if let result = results.first{
               result .itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                   if let uiImage = object as? UIImage {
                       DispatchQueue.main.async {
                           self.parent.selectedImage = uiImage // Assign the selected image to the parent's `selectedImage` property
                           
                       }
                   }
               }
           }
           picker.dismiss(animated: true,completion: nil) // Dismiss the photo picker
            
       }
   }
   
   @Binding var selectedImage: UIImage?  // Binding to hold the selected image
   
   // This method creates a Coordinator instance which handles the delegation of PHPickerViewController
   func makeCoordinator() -> Coordinator {
       Coordinator(parent: self)
        
   }
   
   // This method creates a PHPickerViewController instance with specified configurations
   func makeUIViewController(context: Context) -> PHPickerViewController {
       var configuration = PHPickerConfiguration()
       
       configuration.selectionLimit = 1// Limiting selection to one image
       configuration .filter = .images // Filtering for images only
       let picker = PHPickerViewController(configuration: configuration)
       picker.delegate = context.coordinator // Set the delegate to handle photo picker events
       return picker

   }
   
   // This method is used to update the PHPickerViewController when SwiftUI view updates, but not used in this example
   func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
}


