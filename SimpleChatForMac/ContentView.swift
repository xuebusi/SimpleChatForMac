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
    var body: some View {
        HStack {
            SidebarView()
                .padding()
                .frame(width: 200)
            
            Divider()
            
            DetailView()
                .frame(minWidth: 500)
        }
        .frame(minHeight: 460)
    }
}

// 侧边栏视图
struct SidebarView: View {
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
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
                                    DispatchQueue.main.async {
                                        vm.selectedChat = vm.chats[chatIndex]
                                        print("当前选中聊天ID：\(String(describing: vm.selectedChat?.id))")
                                    }
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
                Spacer()
                Button {
                    vm.chats.insert(Chat(title: "新的聊天", messages: []), at: 0)
                    vm.selectedChat = vm.chats[0]
                    vm.saveChats()
                } label: {
                    Text("新建聊天")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
            }
        }
    }
}

// 详情视图
struct DetailView: View {
    @EnvironmentObject var vm: ViewModel
    @State var inputText: String = ""
    @State var isTitleEditable: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题支持编辑
            if let index = vm.chats.firstIndex(where: { $0.id == vm.selectedChat?.id }) {
                EditableTextView(text: $vm.chats[index].title, isEditable: $isTitleEditable)
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
                                Text(message.content)
                                    .padding()
                                    .background(message.role == .user ? Color(.systemGray).opacity(0.1) : Color.accentColor.opacity(0.1))
                                    .cornerRadius(10)
                                    .id(message.id)
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
                .onTapGesture {
                    isTitleEditable = false
                }
            }
            
            // 发送消息
            HStack {
                TextField("发送消息", text: $inputText)
                    .onAppear {
                        inputText = vm.getCurChat()?.title ?? ""
                    }
                    .onChange(of: vm.selectedChat?.id) { oldValue, newValue in
                        inputText = vm.getCurChat()?.title ?? ""
                    }
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
                })
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

class ViewModel: ObservableObject {
    @Published var selectedChat: Chat? {
        didSet {
            saveSelectedChat()
        }
    }
    
    //    @Published var currentChatID: String? = UserDefaults.standard.string(forKey: "currentChatID") {
    //        didSet {
    //            UserDefaults.standard.set(currentChatID, forKey: "currentChatID")
    //            print("更新当前选中的聊天对象成功！\(String(describing: currentChatID))")
    //        }
    //    }
    
    @Published var chats: [Chat] = [] {
        didSet {
            saveChats()
        }
    }
    
    //    @Published var chats: [Chat] = [
    //        Chat(
    //            title: "郭靖",
    //            messages: (0..<1).map({ Message(content: "郭靖\($0)", role: .user) })
    //        ),
    //        Chat(
    //            title: "黄蓉",
    //            messages: (0..<1).map({ Message(content: "黄蓉\($0)", role: .user) })
    //        ),
    //        Chat(
    //            title: "杨康",
    //            messages: (0..<1).map({ Message(content: "杨康\($0)", role: .user) })
    //        ),
    //        Chat(
    //            title: "穆念慈",
    //            messages: (0..<1).map({ Message(content: "穆念慈\($0)", role: .user) })
    //        ),
    //    ]
    
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
