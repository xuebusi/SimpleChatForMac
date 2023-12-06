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
                        vm.sendMessage(inputText: inputText)
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
    
    func getCurChatMessages() -> [Message] {
        return chats[currentIndex].messages
    }
    
    func getCurChat() -> Chat {
        return chats[currentIndex]
    }
    
    func sendMessage(inputText: String) {
        self.chats[self.currentIndex].messages.append(Message(content: inputText))
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
