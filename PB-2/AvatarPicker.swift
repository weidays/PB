import SwiftUI

struct AvatarPicker: View {
    @Binding var avatarData: Data?
    @Binding var isEditing: Bool
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    
    var body: some View {
        VStack {
            if let avatarData = avatarData, let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }
            
            if isEditing {
                Button(NSLocalizedString("choose_photo", comment: "Choose photo button")) {
                    showImagePicker = true
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $inputImage)
        }
        .onChange(of: inputImage) { newImage in
            if let newImage = newImage {
                print("新照片已选择")
                self.avatarData = newImage.jpegData(compressionQuality: 0.8)
            }
        }
    }
}
