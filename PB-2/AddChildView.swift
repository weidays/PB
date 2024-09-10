import SwiftUI

struct AddChildView: View {
    @ObservedObject var bankModel: BankModel
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var gender = Child.Gender.other
    @State private var birthday = Date()
    @State private var shortTermWish = ""
    @State private var longTermWish = ""
    @State private var shortTermSavingsGoal = ""
    @State private var longTermSavingsGoal = ""
    @State private var avatarImage: UIImage?
    @State private var showingImagePicker = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("basic_info", comment: "Basic information section"))) {
                    avatarView
                    TextField(NSLocalizedString("child_name", comment: "Child name field"), text: $name)
                    Picker(NSLocalizedString("gender", comment: "Gender picker"), selection: $gender) {
                        Text(NSLocalizedString("male", comment: "Male gender")).tag(Child.Gender.male)
                        Text(NSLocalizedString("female", comment: "Female gender")).tag(Child.Gender.female)
                        Text(NSLocalizedString("other", comment: "Other gender")).tag(Child.Gender.other)
                    }
                    DatePicker(NSLocalizedString("birthday", comment: "Birthday picker"), selection: $birthday, displayedComponents: .date)
                }
                
                Section(header: Text(NSLocalizedString("wishes_and_goals", comment: "Wishes and goals section"))) {
                    TextField(NSLocalizedString("short_term_wish", comment: "Short-term wish field"), text: $shortTermWish)
                    TextField(NSLocalizedString("long_term_wish", comment: "Long-term wish field"), text: $longTermWish)
                    TextField(NSLocalizedString("short_term_savings_goal", comment: "Short-term savings goal field"), text: $shortTermSavingsGoal)
                        .keyboardType(.decimalPad)
                    TextField(NSLocalizedString("long_term_savings_goal", comment: "Long-term savings goal field"), text: $longTermSavingsGoal)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(NSLocalizedString("add_child", comment: "Add child view title"))
            .navigationBarItems(
                leading: Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                    isPresented = false
                },
                trailing: Button(NSLocalizedString("save", comment: "Save button")) {
                    addChild()
                    isPresented = false
                }
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $avatarImage)
        }
    }
    
    private var avatarView: some View {
        Button(action: {
            showingImagePicker = true
        }) {
            if let avatarImage = avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                genderSpecificAvatar(for: gender)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            }
        }
    }
    
    private func genderSpecificAvatar(for gender: Child.Gender) -> Image {
        switch gender {
        case .male:
            return Image(systemName: "person.circle.fill")
        case .female:
            return Image(systemName: "person.crop.circle.fill")
        case .other:
            return Image(systemName: "person.fill.questionmark")
        }
    }
    
    private func addChild() {
        let avatarData = avatarImage?.jpegData(compressionQuality: 0.8)
        bankModel.addChild(
            name: name,
            gender: gender,
            birthday: birthday,
            shortTermWish: shortTermWish,
            longTermWish: longTermWish,
            shortTermSavingsGoal: Double(shortTermSavingsGoal) ?? 0,
            longTermSavingsGoal: Double(longTermSavingsGoal) ?? 0,
            avatarData: avatarData
        )
    }
}
