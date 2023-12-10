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
    
    var body: some View {
        Text("设置界面")
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
                                .background(vm.selectedChat?.id == vm.chats[chatIndex].id ? Color.accentColor.opacity(0.1) : Color(.systemGray).opacity(0.1))
                                .id(vm.chats[chatIndex].id)
                                .overlay(alignment: .leading, content: {
                                    Rectangle()
                                        .fill(Color.accentColor)
                                        .frame(width: 4)
                                        .opacity(vm.selectedChat?.id == vm.chats[chatIndex].id ? 1 : 0)
                                })
                                .onTapGesture {
                                    vm.selectedChat = vm.chats[chatIndex]
                                    print("当前选中聊天ID：\(String(describing: vm.selectedChat?.id))")
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
                            proxy.scrollTo(vm.selectedChat?.id, anchor: .top)
                        }
                    }
                    .onChange(of: vm.chats.count) { oldValue, newValue in
                        if newValue > oldValue {
                            DispatchQueue.main.async {
                                proxy.scrollTo(vm.selectedChat?.id, anchor: .bottom)
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
    @State var inputText: String = ""
    @State var isTitleEditable: Bool = false
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题支持编辑
            if let index = vm.chats.firstIndex(where: { $0.id == vm.selectedChat?.id }) {
                EditableTextView(text: $vm.chats[index].title, isEditable: $isTitleEditable) {
                    isTitleEditable = false
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
                    .onChange(of: vm.getCurChatMessages().count) { _, _ in
                        DispatchQueue.main.async {
                            print("当前消息数量变化")
                            proxy.scrollTo(vm.getCurChatMessages().last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: vm.selectedChat?.id) { _, _ in
                        DispatchQueue.main.async {
                            print("当前选中索引变化")
                            proxy.scrollTo(vm.getCurChatMessages().last?.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    scrollViewProxy = proxy
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                // 工具栏
                HStack(spacing: 12) {
                    SFButtonView(imageSystemName: "mic") {
                        print("开始录音")
                    }
                    
                    SFButtonView(imageSystemName: "square.on.square") {
                        var textResult: String = ""
                        for message in vm.selectedChat?.messages ?? [] {
                            textResult += message.role == .assistant ? "\n\(message.content)\n\n" : "\(message.content)\n"
                        }
                        copyToClipboard(text: textResult)
                    }
                    
                    SFButtonView(imageSystemName: "arrow.up.to.line.compact") {
                        DispatchQueue.main.async {
                            withAnimation {
                                scrollViewProxy?.scrollTo(vm.getCurChatMessages().first?.id, anchor: .bottom)
                            }
                        }
                    }
                    
                    SFButtonView(imageSystemName: "arrow.down.to.line.compact") {
                        DispatchQueue.main.async {
                            withAnimation {
                                scrollViewProxy?.scrollTo(vm.getCurChatMessages().last?.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .padding(.leading, 10)
                
                // 发送消息
                HStack(spacing: 12) {
                    TextEditor(text: $inputText)
                        .textEditorStyle(.plain)
                        .font(.body)
                        .padding(6)
                        .frame(height: 80)
                        .background(Color(.systemGray).opacity(0.1))
                        .cornerRadius(10)
                    Button(action: {
                        if inputText.isEmpty {
                            print("消息不能为空")
                            return
                        }
                        //vm.sendMessage(inputText: inputText)
                        Task {
                            await vm.sendMessageAsync(messageText: inputText)
                        }
                    }, label: {
                        Text("发送")
                            .padding(.vertical, 3)
                    })
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
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
                    Button {
                        isEditable = true
                    } label: {
                        HStack(spacing: 0) {
                            Text(text)
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
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
    }
}

class ViewModel: ObservableObject {
    @Published var selectedChat: Chat? {
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
            print("保存当前所选聊天对象成功:\(String(describing: selectedChat?.id))")
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
    
    let apiService = ApiService()
    
    func getCurChatMessages() -> [Message] {
        if let index = chats.firstIndex(where: {$0.id == selectedChat?.id}) {
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
    
    func getCurChat() -> Chat? {
        if let index = chats.firstIndex(where: {$0.id == selectedChat?.id}) {
            return chats[index]
        } else {
            return nil
        }
    }
    
    // 模拟发送异步消息
    func sendMessageAsync(messageText: String) async {
        
        guard let chatIndex = chats.firstIndex(where: {$0.id == selectedChat?.id}) else {
            print("聊天对象不存在")
            return
        }
        
        await MainActor.run {
            self.chats[chatIndex].messages.append(Message(content: messageText, role: .user))
        }
        
        let result = await apiService.sendMessage(messageText: messageText)
        
        switch result {
        case .success(let reply):
            await MainActor.run {
                self.chats[chatIndex].messages.append(Message(content: reply, role: .assistant))
            }
        case .failure(let error):
            print(error.localizedDescription)
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
    let role: Role
}

enum Role: CaseIterable, Codable {
    case user
    case assistant
}

/// --------------------------------------------------------
/// 模拟API请求
/// --------------------------------------------------------

class ApiService {
    
    // 模拟回复消息
    func sendMessage(messageText: String) async -> Result<String, Error> {
        try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
        return .success("回复[\(messageText)]：\(Int.random(in: 0...999999))")
    }
}


/// --------------------------------------------------------


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
