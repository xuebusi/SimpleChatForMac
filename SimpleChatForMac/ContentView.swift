//
//  ContentView.swift
//  SimpleChatForMac
//
//  Created by shiyanjun on 2023/12/6.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
            .environmentObject(ViewModel())
    }
}

#Preview {
    ContentView()
}


struct HomeView: View {
    @State private var settingsActive: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            if settingsActive {
                SettingsView(settingsActive: $settingsActive)
                    .frame(minWidth: 700)
            } else {
                SidebarView(settingsActive: $settingsActive)
                    .frame(width: 200)
                
                Divider()
                
                DetailView()
                    .frame(minWidth: 500)
            }
        }
        .frame(minHeight: 460)
    }
}

struct SettingsView: View {
    @Binding var settingsActive: Bool
    @State var apiKey: String = UserDefaults.standard.string(forKey: "apiKey") ?? ""
    @State var tipMessage: String = ""
    @State var isSuccess: Bool = false
    
    var body: some View {
        VStack {
            GeometryReader { reader in
                let size = reader.size
                Form {
                    Section {
                        HStack {
                            TextField("", text: $apiKey)
                                .frame(height: 36)
                            
                            Button {
                                UserDefaults.standard.set(apiKey, forKey: "apiKey")
                                let apiKey = UserDefaults.standard.string(forKey: "apiKey")
                                tipMessage = "保存API密钥成功"
                                print("保存API密钥成功:apiKey=\(apiKey ?? "")")
                            } label: {
                                Text("保存")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.accentColor)
                        }
                    } header: {
                        Label("API Key", systemImage: "key.fill")
                    } footer: {
                        HStack {
                            Text("您可以在 https://openai.com 免费申请API Key")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                            if !tipMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(tipMessage)
                                    .padding(6)
                                    .font(.body)
                                    .foregroundStyle(Color.green)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(6)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                            withAnimation {
                                                tipMessage = ""
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding()
                .frame(minWidth: 300)
                .frame(width: size.width * 0.8)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            SFButtonView(imageSystemName: "xmark") {
                settingsActive = false
            }
            .padding()
        }
    }
}

// 侧边栏视图
struct SidebarView: View {
    @EnvironmentObject var vm: ViewModel
    @Binding var settingsActive: Bool
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(vm.chats.indices, id: \.self) { chatIndex in
                            Text("\(vm.chats[chatIndex].title)(\(vm.chats[chatIndex].messages.count)条)")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(vm.selectedChat.id == vm.chats[chatIndex].id ? Color.accentColor.opacity(0.1) : Color(.systemGray).opacity(0.1))
                                .id(vm.chats[chatIndex].id)
                                .overlay(alignment: .leading, content: {
                                    Rectangle()
                                        .fill(Color.accentColor)
                                        .frame(width: 4)
                                        .opacity(vm.selectedChat.id == vm.chats[chatIndex].id ? 1 : 0)
                                })
                                .onTapGesture {
                                    vm.selectedChat = vm.chats[chatIndex]
                                    print("当前选中聊天ID：\(String(describing: vm.selectedChat.id))")
                                }
                                .contextMenu {
                                    VStack {
                                        Button {
                                            withAnimation {
                                                vm.removeChat(chat: vm.chats[chatIndex])
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                                Text("删除")
                                            }
                                        }
                                    }
                                }
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.async {
                            proxy.scrollTo(vm.selectedChat.id, anchor: .top)
                        }
                    }
                    .onChange(of: vm.chats.count) { oldValue, newValue in
                        if newValue > oldValue {
                            DispatchQueue.main.async {
                                proxy.scrollTo(vm.selectedChat.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            HStack {
                SFButtonView(imageSystemName: "gearshape.fill") {
                    settingsActive = true
                }
                
                Spacer()
                Button {
                    vm.chats.insert(Chat(title: "新的聊天", messages: []), at: 0)
                    vm.selectedChat = vm.chats[0]
                    vm.saveChats()
                } label: {
                    Text("新建聊天")
                        .padding(.vertical, 3)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

// 详情视图
struct DetailView: View {
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题支持编辑
            if let index = vm.chats.firstIndex(where: { $0.id == vm.selectedChat.id }) {
                EditableTextView(text: $vm.chats[index].title, isEditable: $vm.isTitleEditable) {
                    vm.isTitleEditable = false
                    if vm.chats[index].title.isEmpty {
                        vm.chats[index].title = "新的聊天"
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 3)
                Divider()
            }
            // 聊天记录
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .trailing, spacing: 20) {
                        ForEach(vm.getCurChatMessages()) { message in
                            HStack {
                                if message.role == .user {
                                    Spacer()
                                }
                                VStack(alignment: message.role == .user ? .trailing : .leading) {
                                    Text(dateFormat(date: message.createTime))
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                        .padding(message.role == .user ? .trailing : .leading, 10)
                                    Text(message.content)
                                        .padding()
                                        .background(message.role == .user ? Color(.systemGray).opacity(0.1) : Color.accentColor.opacity(0.1))
                                        .cornerRadius(10)
                                        .id(message.id)
                                        .contextMenu {
                                            VStack {
                                                Button {
                                                    copyToClipboard(text: "\(message.content)")
                                                } label: {
                                                    HStack {
                                                        Image(systemName: "square.on.square")
                                                            .foregroundColor(.red)
                                                        Text("复制")
                                                    }
                                                }
                                                
                                                Divider()
                                                
                                                Button {
                                                    withAnimation {
                                                        vm.removeMessage(chatId: vm.selectedChat.id, messageId: message.id)
                                                    }
                                                } label: {
                                                    HStack {
                                                        Image(systemName: "trash")
                                                            .foregroundColor(.red)
                                                        Text("删除")
                                                    }
                                                }
                                            }
                                        }
                                }
                                if message.role == .assistant {
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .onAppear {
                        DispatchQueue.main.async {
                            proxy.scrollTo(vm.getCurChatMessages().last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: vm.getCurChatMessages().count) { oldValue, newValue in
                        DispatchQueue.main.async {
                            if newValue > oldValue {
                                print("当前消息数量变化")
                                proxy.scrollTo(vm.getCurChatMessages().last?.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: vm.selectedChat.id) { _, _ in
                        DispatchQueue.main.async {
                            print("当前选中索引变化")
                            proxy.scrollTo(vm.getCurChatMessages().last?.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    vm.scrollViewProxy = proxy
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                // 工具栏
                HStack(spacing: 12) {
                    SFButtonView(imageSystemName: "mic") {
                        print("开始录音")
                    }
                    // 复制聊天记录
                    SFButtonView(imageSystemName: "square.on.square") {
                        var textResult: String = ""
                        for message in vm.selectedChat.messages {
                            textResult += message.role == .assistant ? "\n\(message.content)\n\n" : "\(message.content)\n"
                        }
                        copyToClipboard(text: textResult)
                    }
                    // 滚动到顶部
                    SFButtonView(imageSystemName: "arrow.up.to.line.compact") {
                        DispatchQueue.main.async {
                            withAnimation {
                                vm.scrollViewProxy?.scrollTo(vm.getCurChatMessages().first?.id, anchor: .bottom)
                            }
                        }
                    }
                    // 滚动到底部
                    SFButtonView(imageSystemName: "arrow.down.to.line.compact") {
                        DispatchQueue.main.async {
                            withAnimation {
                                vm.scrollViewProxy?.scrollTo(vm.getCurChatMessages().last?.id, anchor: .bottom)
                            }
                        }
                    }
                    
                    if vm.showErrorMessage {
                        Text(vm.errorMessage ?? "")
                            .font(.body)
                            .foregroundStyle(Color(.systemRed))
                            .padding(6)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(6)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                    withAnimation {
                                        vm.showErrorMessage = false
                                    }
                                }
                            }
                    }
                }
                .padding(.leading, 10)
                
                // 发送消息
                HStack(spacing: 12) {
                    TextEditor(text: $vm.inputText)
                        .textEditorStyle(.plain)
                        .font(.body)
                        .padding(6)
                        .frame(height: 80)
                        .background(Color(.systemGray).opacity(0.1))
                        .cornerRadius(10)
                    Button(action: {
                        Task {
                            vm.sendMessage()
                        }
                    }, label: {
                        Text("发送")
                            .padding(.vertical, 3)
                    })
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
                    .disabled(vm.isReceiving)
                }
            }
            .padding([.horizontal, .bottom])
            .padding(.top, 10)
        }
    }
}

struct EditableTextView: View {
    @Binding var text: String
    @Binding var isEditable: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            ZStack {
                if isEditable {
                    TextField(text, text: $text)
                        .padding(.vertical, 10)
                } else {
                    HStack {
                        Text(text)
                        SFButtonView(imageSystemName: "square.and.pencil") {
                            isEditable = true
                        }
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .font(.system(.headline))
            
            if isEditable {
                Button(action: {
                    action()
                }, label: {
                    Text("确定")
                })
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
            }
        }
    }
}

struct SFButtonView: View {
    let imageSystemName: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: imageSystemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(6)
                .frame(width: 26, height: 26)
                .background(Color(.systemGray).opacity(0.1))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            if isHovered {
                // 鼠标悬停时更改指针形状
                NSCursor.pointingHand.set()
            } else {
                // 恢复默认指针形状
                NSCursor.arrow.set()
            }
        }
    }
}

class ViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var isTitleEditable: Bool = false
    @Published var scrollViewProxy: ScrollViewProxy? = nil
    
    @Published var isReceiving: Bool = false
    @Published var showErrorMessage: Bool = false
    @Published var errorMessage: String?
    
    private let openAIService = OpenAIService()
    
    @Published var selectedChat: Chat = Chat(
        title: "新的聊天",
        messages: [Message(content: "你是一个万能助理，可以帮我解决各种问题。请始终使用简体中文回答我。", role: .system)]
    ) {
        didSet {
            saveSelectedChat()
        }
    }
    
    @Published var chats: [Chat] = [] {
        didSet {
            saveChats()
        }
    }
    
    init() {
        loadChats()
        loadSelectedChat()
        
        //        clearData()
    }
    
    private func clearData() {
        UserDefaults.standard.removeObject(forKey: "chats")
        UserDefaults.standard.removeObject(forKey: "apiKey")
    }
    
    func loadSelectedChat() {
        if let data = UserDefaults.standard.data(forKey: "selectedChat"),
           let decodedData = try? JSONDecoder().decode(Chat.self, from: data) {
            selectedChat = decodedData
        }
    }
    
    func saveSelectedChat() {
        if let encodedData = try? JSONEncoder().encode(selectedChat) {
            UserDefaults.standard.setValue(encodedData, forKey: "selectedChat")
            print("保存当前所选聊天对象成功:\(String(describing: selectedChat.id))")
        }
    }
    
    func loadChats() {
        if let data = UserDefaults.standard.data(forKey: "chats"),
           let decodedData = try? JSONDecoder().decode([Chat].self, from: data) {
            chats = decodedData
        }
    }
    
    func saveChats() {
        if let encodedData = try? JSONEncoder().encode(chats) {
            UserDefaults.standard.setValue(encodedData, forKey: "chats")
            print("保存聊天记录成功!")
        }
    }
    
    func getCurChatMessages() -> [Message] {
        if let index = chats.firstIndex(where: {$0.id == selectedChat.id}) {
            return chats[index].messages
        } else {
            return []
        }
    }
    
    // 删除聊天
    func removeChat(chat: Chat) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats.remove(at: index)
            saveChats()
        }
    }
    
    // 删除消息
    func removeMessage(chatId: String, messageId: String) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            if let messageIndex = chats[index].messages.firstIndex(where: { $0.id == messageId }) {
                chats[index].messages.remove(at: messageIndex)
            }
        }
    }
    
    // 发送消息
    func sendMessage() {
        if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("消息不能为空")
            errorMessage = "消息不能为空"
            showErrorMessage = true
            return
        }
        
        guard let index = chats.firstIndex(where: {$0.id == selectedChat.id}) else {
            print("聊天对象不存在")
            errorMessage = "聊天对象不存在"
            showErrorMessage = true
            return
        }
        
        let newMessage = Message(content: inputText, role: .user)
        chats[index].messages.append(newMessage)
        inputText = ""
        isReceiving = true
        
        guard let apiKey = UserDefaults.standard.string(forKey: "apiKey") else {
            print("请先设置API秘钥！")
            errorMessage = "请先设置API秘钥！"
            showErrorMessage = true
            isReceiving = false
            return
        }
        
        if apiKey.isEmpty {
            print("请先设置API秘钥！")
            errorMessage = "请先配置API密钥！"
            showErrorMessage = true
            isReceiving = false
            return
        }
        
        Task {
            let result = await openAIService.sendMessage(messages: chats[index].messages, apiKey: apiKey)
            switch (result) {
            case .success(let response):
                guard let receivedOpenAIMessage = response.choices.first?.message else {
                    print("没有收到消息")
                    errorMessage = "没有收到消息"
                    showErrorMessage = true
                    isReceiving = false
                    return
                }
                let receiveMessage = Message(content: receivedOpenAIMessage.content, role: receivedOpenAIMessage.role)
                
                await MainActor.run {
                    chats[index].messages.append(receiveMessage)
                    isReceiving = false
                }
            case .failure(CustomError.error_info(let errorMsg)):
                await MainActor.run {
                    isReceiving = false
                    errorMessage = errorMsg
                    showErrorMessage = true
                }
            case .failure(let error):
                await MainActor.run {
                    print(error.localizedDescription)
                    isReceiving = false
                    errorMessage = "网络错误，请检查网络连接！"
                    showErrorMessage = true
                }
            }
        }
    }
    
    
    
    
}

struct Chat: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var messages: [Message]
}

struct Message: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var createTime: Date = .init()
    let content: String
    let role: SenderRole
}

// 日期格式化
public func dateFormat(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
    return formatter.string(from: date)
}

// 将文本复制到剪贴板
func copyToClipboard(text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.writeObjects([text as NSPasteboardWriting])
}
