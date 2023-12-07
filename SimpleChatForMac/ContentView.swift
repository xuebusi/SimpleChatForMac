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
                                .background(vm.currentIndex == chatIndex ? Color.accentColor.opacity(0.1) : Color(.systemGray).opacity(0.1))
                                .overlay(alignment: .leading, content: {
                                    Rectangle()
                                        .fill(Color.accentColor)
                                        .frame(width: 4)
                                        .opacity(vm.currentIndex == chatIndex ? 1 : 0)
                                })
                                .onTapGesture {
                                    DispatchQueue.main.async {
                                        vm.currentIndex = chatIndex
                                        print("当前选中索引：\(vm.currentIndex)")
                                    }
                                }
                        }
                    }
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
                        .onChange(of: vm.currentIndex) { _, _ in
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
                            inputText = vm.getCurChat().title
                        }
                        .onChange(of: vm.currentIndex) { oldValue, newValue in
                            inputText = vm.getCurChat().title
                        }
                    Button(action: {
                        if inputText.isEmpty { return }
                        //vm.sendMessage(inputText: inputText)
                        Task {
                            await vm.sendMessageAsync(messageText: inputText, chatIndex: vm.currentIndex)
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
    @Published var currentIndex: Int = 0
    @Published var chats: [Chat] = [
        Chat(
            title: "郭靖",
            messages: (0..<20).map({ Message(content: "郭靖\($0)") })
        ),
        Chat(
            title: "黄蓉",
            messages: (0..<20).map({ Message(content: "黄蓉\($0)") })
        ),
        Chat(
            title: "杨康",
            messages: (0..<20).map({ Message(content: "杨康\($0)") })
        ),
        Chat(
            title: "穆念慈",
            messages: (0..<20).map({ Message(content: "穆念慈\($0)") })
        ),
    ]
    
    let apiService = ApiService()
    
    func getCurChatMessages() -> [Message] {
        return chats[currentIndex].messages
    }
    
    func getCurChat() -> Chat {
        return chats[currentIndex]
    }
    
    func sendMessage(inputText: String) {
        self.chats[self.currentIndex].messages.append(Message(content: inputText))
    }
    
    // 模拟发送异步消息
    func sendMessageAsync(messageText: String, chatIndex: Int) async {
        await MainActor.run {
            self.chats[chatIndex].messages.append(Message(content: messageText))
        }
        
        let result = await apiService.sendMessage(messageText: messageText)
        
        switch result {
        case .success(let reply):
            await MainActor.run {
                self.chats[chatIndex].messages.append(Message(content: reply))
            }
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}

struct Chat: Identifiable {
    let id: UUID = .init()
    let title: String
    var messages: [Message]
}

struct Message: Identifiable {
    let id: UUID = .init()
    let content: String
    let role: Role = Role.allCases.randomElement()!
}

enum Role: CaseIterable {
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
