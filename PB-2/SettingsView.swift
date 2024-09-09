import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var bankModel: BankModel
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var backupFileURL: URL?
    @State private var isPreparingBackup = false
    @State private var importResult: (success: Bool, message: String)?
    
    var body: some View {
        Form {
            Section(header: Text(NSLocalizedString("data_backup", comment: "Data Backup section header"))) {
                Button(NSLocalizedString("export_backup", comment: "Export backup button")) {
                    exportBackup()
                }
                
                Button(NSLocalizedString("import_backup", comment: "Import backup button")) {
                    isImporting = true
                }
            }
        }
        .navigationTitle(NSLocalizedString("settings", comment: "Settings view title"))
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importBackup(from: url)
            case .failure(let error):
                self.alertMessage = "文件选择失败: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
        .sheet(isPresented: $isExporting) {
            if let url = backupFileURL {
                DocumentPicker(url: url, isPresented: $isExporting)
                    .onAppear {
                        print("DocumentPicker 视图应该被加载，URL: \(url)")
                    }
            } else {
                Text("准备文件中...")
                    .onAppear {
                        print("显示 '准备文件中...' 文本")
                    }
            }
        }
        .onChange(of: isExporting) { newValue in
            print("isExporting 变为 \(newValue)")
        }
        .onAppear {
            print("SettingsView appeared")
            prepareBackupFile()
        }
    }
    
    private func exportBackup() {
        print("开始导出备份")
        if let url = backupFileURL {
            print("备份文件已存在，准备显示 DocumentPicker")
            self.isExporting = true
        } else {
            isPreparingBackup = true
            print("开始准备备份文件")
            bankModel.backupData { success, url, message in
                DispatchQueue.main.async {
                    self.isPreparingBackup = false
                    if success, let url = url {
                        self.backupFileURL = url
                        print("备份文件准备完成，设置 isExporting 为 true")
                        self.isExporting = true
                    } else {
                        self.alertMessage = message
                        self.showAlert = true
                        print("备份文件准备失败: \(message)")
                    }
                }
            }
        }
    }
    
    private func importBackup(from sourceURL: URL) {
        sourceURL.startAccessingSecurityScopedResource()
        defer { sourceURL.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: sourceURL)
            bankModel.restoreDataFromData(data) { success, message in
                DispatchQueue.main.async {
                    self.importResult = (success, message)
                    self.alertMessage = message
                    self.showAlert = true
                }
            }
        } catch {
            self.alertMessage = "导入失败: \(error.localizedDescription)"
            self.showAlert = true
        }
    }
    
    private func prepareBackupFile() {
        print("开始预备备份文件")
        bankModel.backupData { success, url, message in
            DispatchQueue.main.async {
                if success, let url = url {
                    self.backupFileURL = url
                    print("预备备份文件成功: \(url.path)")
                } else {
                    print("预备备份文件失败: \(message)")
                }
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let url: URL
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        print("DocumentPicker - makeUIViewController 被调用")
        let picker = UIDocumentPickerViewController(forExporting: [url])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        print("DocumentPicker - updateUIViewController 被调用")
    }
    
    func makeCoordinator() -> Coordinator {
        print("DocumentPicker - makeCoordinator 被调用")
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
            print("DocumentPicker - Coordinator 初始化")
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("文件已选择: \(urls)")
            parent.isPresented = false
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("文件选择已取消")
            parent.isPresented = false
        }
    }
}
