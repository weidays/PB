import Foundation
import SwiftUI

struct Transaction: Codable, Identifiable {
    let id: UUID
    let childId: UUID
    let amount: Double
    let date: Date
    let type: TransactionType
    let note: String  // 新增备注字段
    
    enum TransactionType: String, Codable {
        case deposit
        case withdraw
    }
}

struct Child: Identifiable, Codable {
    let id: UUID
    var name: String
    var balance: Double
    var avatarData: Data?
    var transactions: [Transaction]
    var gender: Gender
    var birthday: Date
    var shortTermWish: String
    var longTermWish: String
    var shortTermSavingsGoal: Double
    var longTermSavingsGoal: Double
    
    enum Gender: String, Codable {
        case male, female, other
    }
    
    var avatarImage: Image? {
        if let data = avatarData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
}

class BankModel: ObservableObject {
    @Published var children: [Child] = []
    let interestRate: Double = 0.05
    
    init() {
        loadData()
        print("BankModel initialized with \(children.count) children")
    }
    func addChild(name: String){
        let newChild = Child(
            id: UUID(),
            name: name,
            balance: 0,
            avatarData: nil,
            transactions: [],
            gender: .other,
            birthday: Date(),
            shortTermWish: "",
            longTermWish: "",
            shortTermSavingsGoal: 0,
            longTermSavingsGoal: 0
        )
        children.append(newChild)
        saveData()
    }

    func addChild(name: String, gender: Child.Gender, birthday: Date, shortTermWish: String, longTermWish: String, shortTermSavingsGoal: Double, longTermSavingsGoal: Double, avatarData: Data?) {
        let newChild = Child(
            id: UUID(),
            name: name,
            balance: 0,
            avatarData: avatarData,
            transactions: [],
            gender: gender,
            birthday: birthday,
            shortTermWish: shortTermWish,
            longTermWish: longTermWish,
            shortTermSavingsGoal: shortTermSavingsGoal,
            longTermSavingsGoal: longTermSavingsGoal
        )
        children.append(newChild)
        saveData()
    }
    
    func addTransaction(to childIndex: Int, amount: Double, type: Transaction.TransactionType, note: String) {
        guard !amount.isNaN && !amount.isInfinite else {
            print("Invalid amount: \(amount)")
            return
        }
        
        let transaction = Transaction(id: UUID(), childId: children[childIndex].id, amount: amount, date: Date(), type: type, note: note)
        children[childIndex].transactions.append(transaction)
        
        switch type {
        case .deposit:
            children[childIndex].balance += amount
        case .withdraw:
            children[childIndex].balance -= amount
        }
        
        // 确保余额不会变成 NaN
        if children[childIndex].balance.isNaN {
            children[childIndex].balance = 0
        }
        
        saveData()
    }
    
    func updateChild(_ updatedChild: Child) {
        if let index = children.firstIndex(where: { $0.id == updatedChild.id }) {
            children[index] = updatedChild
            saveData()
            
            // 通知观察者数据已更改
            objectWillChange.send()
        }
    }
    
    func getAllTransactions() -> [Transaction] {
        return children.flatMap { $0.transactions }
    }
    
    func deleteChild(at offsets: IndexSet) {
        children.remove(atOffsets: offsets)
        saveData()
    }
    
    private func saveData() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(children)
            let url = getDocumentsDirectory().appendingPathComponent("bankData.json")
            try data.write(to: url, options: .atomicWrite)
            print("数据成功保存到: \(url.path)")
        } catch {
            print("保存数据时出错: \(error.localizedDescription)")
        }
    }
    
    private func loadData() {
        let fileURL = getDocumentsDirectory().appendingPathComponent("bankData.json")
        
        if let data = try? Data(contentsOf: fileURL) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                children = try decoder.decode([Child].self, from: data)
            } catch {
                print("无法加载数据: \(error.localizedDescription)")
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func backupData(completion: @escaping (Bool, URL?, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard !self.children.isEmpty else {
                    print("没有数据可以备份")
                    DispatchQueue.main.async {
                        completion(false, nil, NSLocalizedString("backup_failed", comment: "Backup failed message"))
                    }
                    return
                }
                
                let data = try JSONEncoder().encode(self.children)
                let fileManager = FileManager.default
                let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let backupURL = documentsURL.appendingPathComponent("bankDataBackup.json")
                
                print("尝试写入文件到: \(backupURL.path)")
                try data.write(to: backupURL, options: .atomic)
                
                print("文件成功创建于: \(backupURL.path)")
                DispatchQueue.main.async {
                    completion(true, backupURL, NSLocalizedString("backup_successful", comment: "Backup successful message"))
                }
            } catch {
                print("备份数据时出错: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, nil, NSLocalizedString("backup_failed", comment: "Backup failed message"))
                }
            }
        }
    }
    
    func restoreData(from url: URL, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: url)
                print("成功读取文件数据，大小：\(data.count) 字节")
                
                let decodedChildren = try JSONDecoder().decode([Child].self, from: data)
                print("成功解码数据，包含 \(decodedChildren.count) 个子账户")
                
                DispatchQueue.main.async {
                    self.children = decodedChildren
                    self.objectWillChange.send()
                    self.saveData()
                    print("数据已恢复并保存")
                    completion(true, "恢复成功，共恢复 \(decodedChildren.count) 个子账户")
                }
            } catch {
                print("恢复数据时出错: \(error)")
                DispatchQueue.main.async {
                    completion(false, "恢复失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func restoreDataFromData(_ data: Data, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let decodedChildren = try JSONDecoder().decode([Child].self, from: data)
                DispatchQueue.main.async {
                    self.children = decodedChildren
                    self.objectWillChange.send()
                    self.saveData()
                    completion(true, NSLocalizedString("restore_successful", comment: "Restore successful message"))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, NSLocalizedString("restore_failed", comment: "Restore failed message"))
                }
            }
        }
    }
}
