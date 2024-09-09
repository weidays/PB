//
//  ContentView.swift
//  PB-2
//
//  Created by rf on 2024/9/8.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bankModel = BankModel()
    @State private var showingAddChild = false
    @State private var showingAllTransactions = false // 新增状态变量
    @State private var showingSettings = false
    
    let columns = [GridItem(.adaptive(minimum: 120))]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(bankModel.children) { child in
                        NavigationLink(destination: ChildDetailView(bankModel: bankModel, child: binding(for: child))) {
                            ChildProfileView(child: child)
                        }
                    }
                    
                    Button(action: { showingAddChild = true }) {
                        VStack(spacing: 4) {
                            Image(systemName: "person.badge.plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                            
                            Text(NSLocalizedString("add_account", comment: "Add account button"))
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)
                                .frame(height: 20)
                        }
                        .frame(width: 90, height: 110)
                        .padding(5)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("select_account", comment: "Select account title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(NSLocalizedString("all_transactions", comment: "All transactions button")) {
                            showingAllTransactions = true
                        }
                        Button(NSLocalizedString("settings", comment: "Settings button")) {
                            showingSettings = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .navigationBarItems(leading: EditButton().foregroundColor(.blue))
        }
        .sheet(isPresented: $showingAddChild) {
            AddChildView(bankModel: bankModel, isPresented: $showingAddChild)
        }
        .sheet(isPresented: $showingAllTransactions) {
            NavigationView {
                TransactionHistoryView(bankModel: bankModel)
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView(bankModel: bankModel)
            }
        }
    }
    
    private func binding(for child: Child) -> Binding<Child> {
        guard let childIndex = bankModel.children.firstIndex(where: { $0.id == child.id }) else {
            fatalError("无法找到子账户")   
        }
        return $bankModel.children[childIndex]
    }
}

struct ChildProfileView: View {
    let child: Child
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
            
            Text(child.name)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
                .frame(height: 20)
            
            Text(child.balance.isNaN ? "$0.00" : child.balance.asCurrencyString())
                .font(.system(size: 12))
                .lineLimit(1)
                .frame(height: 16)
        }
        .frame(width: 90, height: 110)
        .padding(5)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

struct AddChildView: View {
    @ObservedObject var bankModel: BankModel
    @Binding var isPresented: Bool
    @State private var newChildName = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField(NSLocalizedString("child_name", comment: "Child name field"), text: $newChildName)
                
                Button(NSLocalizedString("add", comment: "Add button")) {
                    if !newChildName.isEmpty {
                        bankModel.addChild(name: newChildName)
                        newChildName = ""
                        isPresented = false
                    }
                }
            }
            .navigationTitle(NSLocalizedString("add_child", comment: "Add child view title"))
            .navigationBarItems(trailing: Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                isPresented = false
            })
        }
    }
}

#Preview {
    ContentView()
}
