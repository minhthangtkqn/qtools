//
//  QAChat.swift
//  qtool
//
//  Created by Hoang Minh Thang on 7/8/26.
//

import SwiftUI
import AVFoundation

// MARK: - Gemini response model

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

// MARK: - Network service

private class GeminiService {
    // Get a free key at https://aistudio.google.com/app/apikey
    // Set your key in Secrets.swift — never commit that file
    private let apiKey = Secrets.geminiAPIKey
    private let model = "gemini-3.6-flash"

    func send(prompt: String, imageData: Data?, audioData: Data?, history: [ChatMessage]) async throws -> String {
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
            if let data = msg.audioData {
                parts.append(["inlineData": ["mimeType": "audio/mp4", "data": data.base64EncodedString()]])
            }
            return ["role": msg.isUser ? "user" : "model", "parts": parts]
        }

        // Current user message
        var currentParts: [[String: Any]] = []
        if !prompt.isEmpty { currentParts.append(["text": prompt]) }
        if let data = imageData {
            currentParts.append(["inlineData": ["mimeType": "image/jpeg", "data": data.base64EncodedString()]])
        }
        if let data = audioData {
            currentParts.append(["inlineData": ["mimeType": "audio/mp4", "data": data.base64EncodedString()]])
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

// MARK: - Audio recorder

private class AudioRecorderHelper: ObservableObject {
    @Published var isRecording = false
    @Published var duration = 0

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var fileURL: URL?

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".m4a")
        fileURL = url
        recorder = try AVAudioRecorder(url: url, settings: [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ])
        recorder?.record()
        isRecording = true
        duration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.duration += 1
        }
    }

    /// Stops recording and returns the captured audio as Data.
    func stop() -> Data? {
        timer?.invalidate(); timer = nil
        recorder?.stop()
        isRecording = false
        return fileURL.flatMap { try? Data(contentsOf: $0) }
    }
}

// MARK: - Main view

struct QAChatView: View {
    @EnvironmentObject private var chatSession: ChatSession
    @StateObject private var mic = AudioRecorderHelper()
    @State private var inputText: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var stagedAudioData: Data? = nil
    @State private var showCamera: Bool = false
    @State private var showPhotoLibrary: Bool = false

    private let service = GeminiService()

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if chatSession.messages.isEmpty && !chatSession.isLoading {
                            Text("Ask me anything…")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)
                        }

                        ForEach(chatSession.messages) { msg in
                            MessageBubble(message: msg)
                        }

                        if chatSession.isLoading {
                            TypingIndicator()
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture { hideKeyboard() }
                .onChange(of: chatSession.messages.count) {
                    withAnimation { proxy.scrollTo("bottom") }
                }
                .onChange(of: chatSession.isLoading) {
                    withAnimation { proxy.scrollTo("bottom") }
                }
            }

            // Input area
            VStack(spacing: 10) {
                // Active recording bar
                if mic.isRecording {
                    RecordingBar(duration: mic.duration) {
                        if let data = mic.stop() { stagedAudioData = data }
                    }
                    .padding(.horizontal, 20)
                }

                // Staged audio chip
                if !mic.isRecording, let _ = stagedAudioData {
                    StagedAudioChip { stagedAudioData = nil }
                        .padding(.horizontal, 20)
                }

                // Staged image thumbnail
                if let selectedImage {
                    HStack {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(alignment: .topTrailing) {
                                Button { self.selectedImage = nil } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, Color.black.opacity(0.5))
                                }
                                .offset(x: 8, y: -8)
                            }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }

                // Pill-shaped input card
                HStack(alignment: .bottom, spacing: 10) {
                    // Attachment menu — replaces individual camera/photo buttons
                    Menu {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take a Photo", systemImage: "camera.fill")
                        }

                        Button {
                            showPhotoLibrary = true
                        } label: {
                            Label("Upload Image", systemImage: "photo.fill")
                        }

                        Button {
                            startRecording()
                        } label: {
                            Label("Record Audio", systemImage: "mic.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5), in: Circle())
                    }

                    TextField("Ask something…", text: $inputText, axis: .vertical)
                        .font(.body)
                        .lineLimit(1...6)
                        .disabled(chatSession.isLoading)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(canSend ? Color.blue : Color(.systemGray4), in: Circle())
                            .animation(.easeInOut(duration: 0.15), value: canSend)
                    }
                    .disabled(!canSend)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 28))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(.separator), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -3)
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePickerView(image: $selectedImage, sourceType: .camera)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoLibrary) {
            ImagePickerView(image: $selectedImage, sourceType: .photoLibrary)
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

    // Send allowed when there's content and not mid-recording or loading
    private var canSend: Bool {
        (!inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedImage != nil
            || stagedAudioData != nil)
            && !chatSession.isLoading && !mic.isRecording
    }

    private func startRecording() {
        stagedAudioData = nil   // discard any previous recording
        AVAudioApplication.requestRecordPermission { granted in
            guard granted else { return }
            DispatchQueue.main.async { try? self.mic.start() }
        }
    }

    private func sendMessage() {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty || selectedImage != nil || stagedAudioData != nil else { return }

        let imageData = selectedImage.flatMap { $0.jpegData(compressionQuality: 0.8) }
        let audioData = stagedAudioData
        let historyBeforeThisMessage = chatSession.messages

        inputText = ""
        selectedImage = nil
        stagedAudioData = nil
        chatSession.messages.append(ChatMessage(isUser: true, text: prompt, imageData: imageData, audioData: audioData))
        chatSession.isLoading = true

        Task {
            do {
                let reply = try await service.send(prompt: prompt, imageData: imageData, audioData: audioData, history: historyBeforeThisMessage)
                await MainActor.run {
                    chatSession.messages.append(ChatMessage(isUser: false, text: reply))
                    chatSession.isLoading = false
                }
            } catch {
                await MainActor.run {
                    chatSession.messages.append(ChatMessage(isUser: false, text: "Error: \(error.localizedDescription)"))
                    chatSession.isLoading = false
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

                if let _ = message.audioData {
                    Label("Voice message", systemImage: "waveform")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(message.isUser ? Color.blue : Color(.systemGray5))
                        .foregroundStyle(message.isUser ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(message.isUser ? Color.blue : Color(.systemGray5))
                        .foregroundStyle(message.isUser ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = message.text
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        } preview: {
                            Text(message.text)
                                .lineLimit(nil)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .foregroundStyle(message.isUser ? Color.white : Color.primary)
                                .background(message.isUser ? Color.blue : Color(.systemGray5))
                        }
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

// Unified image picker — handles both .camera and .photoLibrary
private struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) { self.parent = parent }

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

// Active recording indicator shown above the input card
private struct RecordingBar: View {
    let duration: Int
    let onStop: () -> Void
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .scaleEffect(pulsing ? 1.35 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulsing)
                .onAppear { pulsing = true }

            Text(formatted)
                .font(.body.monospacedDigit())

            Spacer()

            Button("Stop", action: onStop)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.red)
        }
    }

    private var formatted: String {
        String(format: "%d:%02d", duration / 60, duration % 60)
    }
}

// Chip shown after recording stops, before send
private struct StagedAudioChip: View {
    let onDiscard: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.system(size: 20))
                .foregroundStyle(.blue)

            Text("Voice message ready")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: onDiscard) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color(.systemGray2), Color(.systemGray5))
            }
        }
    }
}

#Preview {
    NavigationStack {
        QAChatView()
    }
    .environmentObject(ChatSession())
}
