//
//  QAChat.swift
//  qtool
//
//  Created by Hoang Minh Thang on 7/8/26.
//

import SwiftUI
import PhotosUI

// MARK: - Response model

private struct GeminiResponse: Decodable {
    let candidates: [Candidate]

    struct Candidate: Decodable {
        let content: Content
    }
    struct Content: Decodable {
        let parts: [Part]
    }
    struct Part: Decodable {
        let text: String
    }
}

// MARK: - Chat session (survives navigation, cleared on "Clear" or app close)

class ChatSession: ObservableObject {
    @Published var messages: [ChatMessage] = []
}

// MARK: - Message model

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let imageData: Data?

    init(isUser: Bool, text: String, imageData: Data? = nil) {
        self.isUser = isUser
        self.text = text
        self.imageData = imageData
    }
}

// MARK: - Network service

private class GeminiService {
    // Get a free key at https://aistudio.google.com/app/apikey
    // Set your key in Secrets.swift — never commit that file
    private let apiKey = Secrets.geminiAPIKey
    private let model = "gemini-3.6-flash"

    func send(prompt: String, imageData: Data?, history: [ChatMessage]) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build multi-turn conversation history
        var contents: [[String: Any]] = history.map { msg in
            var parts: [[String: Any]] = []
            if !msg.text.isEmpty { parts.append(["text": msg.text]) }
            if let data = msg.imageData {
                parts.append(["inlineData": ["mimeType": "image/jpeg", "data": data.base64EncodedString()]])
            }
            return ["role": msg.isUser ? "user" : "model", "parts": parts]
        }

        // Current user message
        var currentParts: [[String: Any]] = []
        if !prompt.isEmpty { currentParts.append(["text": prompt]) }
        if let data = imageData {
            currentParts.append(["inlineData": ["mimeType": "image/jpeg", "data": data.base64EncodedString()]])
        }
        contents.append(["role": "user", "parts": currentParts])

        request.httpBody = try JSONSerialization.data(withJSONObject: ["contents": contents])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "(empty body)"
            throw NSError(domain: "GeminiError", code: status,
                          userInfo: [NSLocalizedDescriptionKey: "[\(status)] \(body)"])
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        return decoded.candidates.first?.content.parts.first?.text ?? "No response."
    }
}

// MARK: - Main view

struct QAChatView: View {
    @EnvironmentObject private var chatSession: ChatSession
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var showCamera: Bool = false

    private let service = GeminiService()

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if chatSession.messages.isEmpty && !isLoading {
                            Text("Ask me anything…")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)
                        }

                        ForEach(chatSession.messages) { msg in
                            MessageBubble(message: msg)
                        }

                        if isLoading {
                            TypingIndicator()
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture { hideKeyboard() }
                .onChange(of: chatSession.messages.count) { _ in
                    withAnimation { proxy.scrollTo("bottom") }
                }
                .onChange(of: isLoading) { _ in
                    withAnimation { proxy.scrollTo("bottom") }
                }
            }

            Divider()

            VStack(spacing: 8) {
                // Image thumbnail — shown when an image is staged
                if let selectedImage {
                    HStack(alignment: .top, spacing: 8) {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button {
                            self.selectedImage = nil
                            self.photoPickerItem = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.gray)
                                .font(.system(size: 18))
                        }

                        Spacer()
                    }
                }

                HStack(alignment: .bottom, spacing: 12) {
                    // Camera button
                    Button {
                        showCamera = true
                    } label: {
                        Image(systemName: "camera")
                            .font(.system(size: 24))
                            .foregroundStyle(.blue)
                    }

                    // Photo library picker
                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundStyle(.blue)
                    }
                    .onChange(of: photoPickerItem) { item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self) {
                                selectedImage = UIImage(data: data)
                            }
                        }
                    }

                    TextField("Ask something…", text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .disabled(isLoading)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(canSend ? .blue : .gray)
                    }
                    .disabled(!canSend)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
                .ignoresSafeArea()
        }
        .navigationTitle("AI Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !chatSession.messages.isEmpty {
                    Button("Clear") {
                        chatSession.messages = []
                    }
                }
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // Send is allowed if there's text OR an image (or both)
    private var canSend: Bool {
        (!inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil) && !isLoading
    }

    private func sendMessage() {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty || selectedImage != nil else { return }

        let imageData = selectedImage.flatMap { $0.jpegData(compressionQuality: 0.8) }
        let historyBeforeThisMessage = chatSession.messages

        inputText = ""
        selectedImage = nil
        photoPickerItem = nil
        chatSession.messages.append(ChatMessage(isUser: true, text: prompt, imageData: imageData))
        isLoading = true

        Task {
            do {
                let reply = try await service.send(prompt: prompt, imageData: imageData, history: historyBeforeThisMessage)
                await MainActor.run {
                    chatSession.messages.append(ChatMessage(isUser: false, text: reply))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    chatSession.messages.append(ChatMessage(isUser: false, text: "Error: \(error.localizedDescription)"))
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Subviews

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                if let data = message.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(message.isUser ? Color.blue : Color(.systemGray5))
                        .foregroundStyle(message.isUser ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

private struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(.systemGray3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { animating = true }
    }
}

private struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        QAChatView()
    }
    .environmentObject(ChatSession())
}
