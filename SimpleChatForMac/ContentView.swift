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
    }
}

#Preview {
    ContentView()
}


struct HomeView: View {
    @StateObject var vm = ViewModel()
    @State var inputText: String = ""
    
    var body: some View {
        HStack {
            VStack {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(vm.chats.indices, id: \.self) { chatIndex in
                            Text("\(vm.chats[chatIndex].title)(\(vm.chats[chatIndex].messages.count)条)")
                                .padding(.vertical)
                                .frame(maxWidth: .infinity)
                                .background(vm.currentChatID == vm.chats[chatIndex].id ? Color.accentColor.opacity(0.1) : Color(.systemGray).opacity(0.1))
                                .overlay(alignment: .leading, content: {
                                    Rectangle()
                                        .fill(Color.accentColor)
                                        .frame(width: 4)
                                        .opacity(vm.currentChatID == vm.chats[chatIndex].id ? 1 : 0)
                                })
                                .onTapGesture {
                                    DispatchQueue.main.async {
                                        vm.currentChatID = vm.chats[chatIndex].id
                                        print("当前选中聊天ID：\(String(describing: vm.currentChatID))")
                                    }
                                }
                        }
                    }
                    .onAppear {
                        print("\(String(describing: vm.currentChatID))")
                    }
                }
                
                HStack {
                    Spacer()
                    Button {
                        vm.chats.append(Chat(title: "新的聊天", messages: []))
                        vm.saveChats()
                    } label: {
                        Text("新建聊天")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
                }
            }
            .padding()
            .frame(width: 200)
            
            Divider()
            
            VStack(spacing: 0) {
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
                        .onChange(of: vm.currentChatID) { _, _ in
                            DispatchQueue.main.async {
                                print("当前选中索引变化")
                                proxy.scrollTo(vm.getCurChatMessages().last?.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                HStack {
                    TextField("发送消息", text: $inputText)
                        .onAppear {
                            inputText = vm.getCurChat()?.title ?? ""
                        }
                        .onChange(of: vm.currentChatID) { oldValue, newValue in
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
            .frame(minWidth: 500)
        }
        .frame(minHeight: 460)
    }
}

class ViewModel: ObservableObject {
    @Published var currentChatID: String? = UserDefaults.standard.string(forKey: "currentChatID") {
        didSet {
            UserDefaults.standard.set(currentChatID, forKey: "currentChatID")
            print("更新当前选中的聊天对象成功！\(String(describing: currentChatID))")
        }
    }
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
            print("保存聊天记录成功:\(chats)")
        }
    }
    
    let apiService = ApiService()
    
    func getCurChatMessages() -> [Message] {
        if let index = chats.firstIndex(where: {$0.id == currentChatID}) {
            return chats[index].messages
        } else {
            return []
        }
    }
    
    func getCurChat() -> Chat? {
        if let index = chats.firstIndex(where: {$0.id == currentChatID}) {
            return chats[index]
        } else {
            return nil
        }
    }
    
    // 模拟发送异步消息
    func sendMessageAsync(messageText: String) async {
        
        guard let chatIndex = chats.firstIndex(where: {$0.id == currentChatID}) else {
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

struct Chat: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var messages: [Message]
}

struct Message: Identifiable, Codable {
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
