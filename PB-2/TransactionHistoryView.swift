import SwiftUI

struct TransactionHistoryView: View {
    @ObservedObject var bankModel: BankModel
    var childId: UUID? // 新增可选参数
    
    var body: some View {
        List {
            ForEach(filteredTransactions.sorted(by: { $0.date > $1.date })) { transaction in
                TransactionRow(transaction: transaction, childName: childName(for: transaction.childId))
            }
        }
        .navigationTitle(childId == nil ? "所有交易记录" : "账户交易记录")
    }
    
    private var filteredTransactions: [Transaction] {
        if let childId = childId {
            return bankModel.getAllTransactions().filter { $0.childId == childId }
        } else {
            return bankModel.getAllTransactions()
        }
    }
    
    private func childName(for id: UUID) -> String {
        bankModel.children.first(where: { $0.id == id })?.name ?? "未知"
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let childName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(childName)
                    .font(.headline)
                Spacer()
                Text(amountText)
                    .foregroundColor(transaction.type == .deposit ? .green : .red)
            }
            Text(transaction.date, style: .date)
                .font(.subheadline)
            if !transaction.note.isEmpty {
                Text("备注: \(transaction.note)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var amountText: String {
        let prefix = transaction.type == .deposit ? "+" : "-"
        let amountString = transaction.amount.isNaN ? "$0.00" : transaction.amount.asCurrencyString()
        return "\(prefix)\(amountString)"
    }
}
