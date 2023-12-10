//
//  EditableTextView.swift
//  SimpleChatForMac
//
//  Created by shiyanjun on 2023/12/9.
//

import SwiftUI

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

#Preview {
    EditableTextView(text: .constant("Hello, World!"), isEditable: .constant(false)) {
        
    }
        .frame(width: 300, height: 200)
}
