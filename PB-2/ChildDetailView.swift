import SwiftUI

struct ChildDetailView: View {
    @ObservedObject var bankModel: BankModel
    @Binding var child: Child
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var showingTransactionHistory = false
    @State private var isEditing = false
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var tempAvatarImage: Image?
    @State private var showImageCropper = false
    @State private var tempImage: UIImage?
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case amount
        case note
        case childName
        case shortTermWish
        case longTermWish
        case shortTermSavingsGoal
        case longTermSavingsGoal
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text(NSLocalizedString("basic_info", comment: "Basic information section"))) {
                    HStack {
                        if isEditing {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                avatarView
                            }
                        } else {
                            avatarView
                        }
                        VStack(alignment: .leading) {
                            if isEditing {
                                TextField(NSLocalizedString("child_name", comment: "Child name field"), text: $child.name)
                                    .focused($focusedField, equals: .childName)
                            } else {
                                Text(child.name)
                                    .font(.headline)
                            }
                            Text(NSLocalizedString("current_balance", comment: "Current balance") + ": \(child.balance.asCurrencyString())")
                            if !isEditing {
                                Text(NSLocalizedString("gender", comment: "Gender label") + ": " + genderString(child.gender))
                                Text(NSLocalizedString("birthday", comment: "Birthday label") + ": " + formatDate(child.birthday))
                            }
                        }
                    }
                    
                    if isEditing {
                        Picker(NSLocalizedString("gender", comment: "Gender picker"), selection: $child.gender) {
                            Text(NSLocalizedString("male", comment: "Male gender")).tag(Child.Gender.male)
                            Text(NSLocalizedString("female", comment: "Female gender")).tag(Child.Gender.female)
                            Text(NSLocalizedString("other", comment: "Other gender")).tag(Child.Gender.other)
                        }
                        DatePicker(NSLocalizedString("birthday", comment: "Birthday picker"), selection: $child.birthday, displayedComponents: .date)
                    } else {
                       
                    }
                }
                if !isEditing {
                    Section(header: Text(NSLocalizedString("transaction", comment: "Transaction section"))) {
                        TextField(NSLocalizedString("amount", comment: "Amount field"), text: $amount)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                        
                        TextField(NSLocalizedString("note", comment: "Note field"), text: $note)
                            .focused($focusedField, equals: .note)
                        
                        HStack {
                            Button(NSLocalizedString("deposit", comment: "Deposit button")) {
                                deposit()
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            
                            Button(NSLocalizedString("withdraw", comment: "Withdraw button")) {
                                withdraw()
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }

                Section(header: Text(NSLocalizedString("wishes_and_goals", comment: "Wishes and goals section"))) {
                    if isEditing {
                        TextField(NSLocalizedString("short_term_wish", comment: "Short-term wish field"), text: $child.shortTermWish)
                            .focused($focusedField, equals: .shortTermWish)
                        TextField(NSLocalizedString("long_term_wish", comment: "Long-term wish field"), text: $child.longTermWish)
                            .focused($focusedField, equals: .longTermWish)
                        TextField(NSLocalizedString("short_term_savings_goal", comment: "Short-term savings goal field"), value: $child.shortTermSavingsGoal, formatter: NumberFormatter())
                            .focused($focusedField, equals: .shortTermSavingsGoal)
                        TextField(NSLocalizedString("long_term_savings_goal", comment: "Long-term savings goal field"), value: $child.longTermSavingsGoal, formatter: NumberFormatter())
                            .focused($focusedField, equals: .longTermSavingsGoal)
                    } else {
                        Text(NSLocalizedString("short_term_wish", comment: "Short-term wish label") + ": " + child.shortTermWish)
                        Text(NSLocalizedString("long_term_wish", comment: "Long-term wish label") + ": " + child.longTermWish)
                        Text(NSLocalizedString("short_term_savings_goal", comment: "Short-term savings goal label") + ": \(child.shortTermSavingsGoal.asCurrencyString())")
                        Text(NSLocalizedString("long_term_savings_goal", comment: "Long-term savings goal label") + ": \(child.longTermSavingsGoal.asCurrencyString())")
                        
                    }
                }
                if !isEditing {
                    Button(NSLocalizedString("transaction_history", comment: "Transaction history button")) {
                        showingTransactionHistory = true
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(child.name + NSLocalizedString("'s Account", comment: "Account title"))
        .navigationBarItems(trailing: Button(isEditing ? NSLocalizedString("save", comment: "Save button") : NSLocalizedString("edit", comment: "Edit button")) {
            if isEditing {
                bankModel.updateChild(child)
            }
            isEditing.toggle()
        })
        .sheet(isPresented: $showingTransactionHistory) {
            TransactionHistoryView(bankModel: bankModel, childId: child.id)
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage)
        }
        .onChange(of: inputImage) { _ in
            if inputImage != nil {
                showImageCropper = true
            }
        }
        // .onTapGesture {
        //     focusedField = nil
        // }
    }
    
    private var avatarView: some View {
        AvatarPicker(avatarData: Binding(
            get: { child.avatarData },
            set: { newValue in
                var updatedChild = child
                updatedChild.avatarData = newValue
                child = updatedChild
            }
        ),isEditing: $isEditing)
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        showImageCropper = true
    }
    
    private func deposit() {
        guard let amount = Double(amount), amount > 0, !amount.isNaN, !amount.isInfinite else {
            // 显示错误消息
            return
        }
        if let index = bankModel.children.firstIndex(where: { $0.id == child.id }) {
            bankModel.addTransaction(to: index, amount: amount, type: .deposit, note: note)
            self.amount = ""
            self.note = ""
        }
    }
    
    private func withdraw() {
        guard let amount = Double(amount), amount > 0, !amount.isNaN, !amount.isInfinite, amount <= child.balance else {
            // 显示错误消息
            return
        }
        if let index = bankModel.children.firstIndex(where: { $0.id == child.id }) {
            bankModel.addTransaction(to: index, amount: amount, type: .withdraw, note: note)
            self.amount = ""
            self.note = ""
        }
    }
    
    private func genderString(_ gender: Child.Gender) -> String {
        switch gender {
        case .male:
            return NSLocalizedString("male", comment: "Male gender")
        case .female:
            return NSLocalizedString("female", comment: "Female gender")
        case .other:
            return NSLocalizedString("other", comment: "Other gender")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func saveChanges() {
        var updatedChild = child
        if let tempImage = tempImage {
            updatedChild.avatarData = tempImage.jpegData(compressionQuality: 0.8)
        }
        bankModel.updateChild(updatedChild)
        isEditing = false
        tempImage = nil
        inputImage = nil
        
        // 强制更新视图
        child = updatedChild
    }
}
