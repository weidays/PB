//
//  ContentView.swift
//  PB-2
//
//  Created by rf on 2024/9/8.
//

import SwiftUI

// 如果 AddChildView 在一个单独的文件中，可能需要添加以下导入
// import AddChildView

struct ContentView: View {
    @ObservedObject var bankModel: BankModel
    @State private var showingAddChildSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    if bankModel.children.isEmpty {
                        emptyStateView
                    } else {
                        childrenListView
                    }
                    
                    addChildButton
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("family_accounts", comment: "Family accounts title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(NSLocalizedString("settings", comment: "Settings button")) {
                        SettingsView(bankModel: bankModel)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddChildSheet) {
            AddChildView(bankModel: bankModel, isPresented: $showingAddChildSheet)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
            
            Text(NSLocalizedString("no_children_yet", comment: "No children yet"))
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(NSLocalizedString("add_child_prompt", comment: "Add child prompt"))
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    private var childrenListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach($bankModel.children) { $child in
                    NavigationLink(destination: ChildDetailView(bankModel: bankModel, child: $child)) {
                        ChildRowView(child: child)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var addChildButton: some View {
        Button(action: { showingAddChildSheet = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text(NSLocalizedString("add_child", comment: "Add child button"))
            }
            .font(.headline)
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
        }
    }
}

struct ChildRowView: View {
    let child: Child
    
    var body: some View {
        HStack(spacing: 16) {
            if let avatarImage = child.avatarImage {
                avatarImage
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


            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)
                
                Text(NSLocalizedString("current_balance", comment: "Current balance") + ": " + String(format: "$%.2f", child.balance))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(NSLocalizedString("short_term_wish", comment: "Short-term wish") + ": " + child.shortTermWish)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func genderSpecificAvatar(for child: Child) -> Image {
        if let avatarImage = child.avatarImage {
            return avatarImage
        } else {
            switch child.gender {
            case .male:
                return Image(systemName: "person.circle.fill")
            case .female:
                return Image(systemName: "person.crop.circle.fill")
            case .other:
                return Image(systemName: "person.fill.questionmark")
            }
        }
    }
}

#Preview {
    ContentView(bankModel: BankModel())
}
