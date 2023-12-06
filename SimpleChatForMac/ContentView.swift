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
                                    withAnimation {
                                        vm.currentIndex = chatIndex
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
                            ForEach(vm.chats[vm.currentIndex].messages) { message in
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
                            proxy.scrollTo(vm.chats[vm.currentIndex].messages.last?.id, anchor: .bottom)
                        }
                        .onChange(of: vm.chats[vm.currentIndex].messages.count) { oldValue, newValue in
                            withAnimation {
                                proxy.scrollTo(vm.chats[vm.currentIndex].messages.last?.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                HStack {
                    TextField("发送消息", text: $inputText)
                        .onAppear {
                            inputText = vm.chats[vm.currentIndex].title
                        }
                        .onChange(of: vm.currentIndex) { oldValue, newValue in
                            inputText = vm.chats[vm.currentIndex].title
                        }
                    Button(action: {
                        if inputText.isEmpty { return }
                        vm.chats[vm.currentIndex].messages.append(Message(content: inputText))
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
            messages: (0..<30).map({ Message(content: "黄蓉\($0)") })
        ),
        Chat(
            title: "杨康",
            messages: (0..<40).map({ Message(content: "杨康\($0)") })
        ),
        Chat(
            title: "穆念慈",
            messages: (0..<50).map({ Message(content: "穆念慈\($0)") })
        ),
    ]
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
