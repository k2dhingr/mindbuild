//
//  ChatView.swift
//  MindfulHealth
//
//  Conversational AI health coaching interface
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var healthViewModel: HealthViewModel
    @EnvironmentObject var chatViewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Health Coach")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if healthViewModel.llmManager.isModelLoaded {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("AI Ready • On-Device")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white.opacity(0.7))
                        
                        Text("Loading AI Model...")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(chatViewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        if chatViewModel.isTyping {
                            TypingIndicator()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .onChange(of: chatViewModel.messages.count) { _ in
                    if let lastMessage = chatViewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Suggested questions (if chat is new)
            if chatViewModel.messages.count == 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(chatViewModel.getSuggestedQuestions(), id: \.self) { question in
                            Button {
                                chatViewModel.currentInput = question
                                Task {
                                    await chatViewModel.sendMessage()
                                }
                            } label: {
                                Text(question)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.12))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)
            }
            
            // Input area
            HStack(spacing: 12) {
                TextField("Ask about your health...", text: $chatViewModel.currentInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(24)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        Task {
                            // Configure chat with health context
                            if let baseline = healthViewModel.baseline,
                               let latestSummary = healthViewModel.healthDataManager.weeklyData.last {
                                let context = FeatureEngineering.generateLLMContext(
                                    baseline: baseline,
                                    current: latestSummary,
                                    anomalies: healthViewModel.anomalies,
                                    weeklyData: healthViewModel.healthDataManager.weeklyData
                                )
                                chatViewModel.configure(
                                    llmManager: healthViewModel.llmManager,
                                    healthContext: context
                                )
                            }
                            
                            await chatViewModel.sendMessage()
                        }
                    }
                
                Button {
                    Task {
                        // Configure chat with health context
                        if let baseline = healthViewModel.baseline,
                           let latestSummary = healthViewModel.healthDataManager.weeklyData.last {
                            let context = FeatureEngineering.generateLLMContext(
                                baseline: baseline,
                                current: latestSummary,
                                anomalies: healthViewModel.anomalies,
                                weeklyData: healthViewModel.healthDataManager.weeklyData
                            )
                            chatViewModel.configure(
                                llmManager: healthViewModel.llmManager,
                                healthContext: context
                            )
                        }
                        
                        await chatViewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .disabled(chatViewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(chatViewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.2))
        }
        .onAppear {
            // Configure chat on appear
            if let baseline = healthViewModel.baseline,
               let latestSummary = healthViewModel.healthDataManager.weeklyData.last {
                let context = FeatureEngineering.generateLLMContext(
                    baseline: baseline,
                    current: latestSummary,
                    anomalies: healthViewModel.anomalies,
                    weeklyData: healthViewModel.healthDataManager.weeklyData
                )
                chatViewModel.configure(
                    llmManager: healthViewModel.llmManager,
                    healthContext: context
                )
            }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 36)
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: animating ? -6 : 0)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.12))
            .cornerRadius(20)
            
            Spacer()
        }
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(HealthViewModel())
        .environmentObject(ChatViewModel())
        .background(AnimatedGradientView())
}
