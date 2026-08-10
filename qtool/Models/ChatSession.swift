//
//  ChatSession.swift
//  qtool
//
//  Created by Hoang Minh Thang on 7/8/26.
//

import SwiftUI

// MARK: - Message model

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let imageData: Data?
    let audioData: Data?

    init(isUser: Bool, text: String, imageData: Data? = nil, audioData: Data? = nil) {
        self.isUser = isUser
        self.text = text
        self.imageData = imageData
        self.audioData = audioData
    }
}

// MARK: - Chat session (survives navigation, cleared on "Clear" or app close)

class ChatSession: ObservableObject {
    @Published var messages: [ChatMessage] = []
}
