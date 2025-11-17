//
//  ChatViewModel.swift
//  MindfulHealth
//
//  Manages chat conversation with on-device AI
//

import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var isTyping = false
    
    // Reference to LLM manager (will be injected)
    private var llmManager: LLMManager?
    private var healthContext: String = ""
    
    init() {
        // Add welcome message
        messages.append(ChatMessage(
            content: "Hi! I'm your personal health coach. I can help you understand your health patterns and suggest ways to improve your wellbeing. What would you like to know?",
            isUser: false,
            timestamp: Date(),
            healthContext: nil
        ))
    }
    
    // MARK: - Configure Dependencies
    func configure(llmManager: LLMManager, healthContext: String) {
        self.llmManager = llmManager
        self.healthContext = healthContext
    }
    
    // MARK: - Send Message
    func sendMessage() async {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = currentInput
        currentInput = ""
        
        // Add user message
        messages.append(ChatMessage(
            content: userMessage,
            isUser: true,
            timestamp: Date(),
            healthContext: nil
        ))
        
        // Show typing indicator
        isTyping = true
        
        // Generate response
        guard let llmManager = llmManager else {
            let errorMessage = ChatMessage(
                content: "AI model not ready. Please wait a moment and try again.",
                isUser: false,
                timestamp: Date(),
                healthContext: nil
            )
            messages.append(errorMessage)
            isTyping = false
            return
        }
        
        let response = await llmManager.generateChatResponse(
            conversationHistory: messages,
            healthContext: healthContext
        )
        
        // Add AI response
        messages.append(ChatMessage(
            content: response,
            isUser: false,
            timestamp: Date(),
            healthContext: nil
        ))
        
        isTyping = false
    }
    
    // MARK: - Suggested Questions
    func getSuggestedQuestions() -> [String] {
        return [
            "How can I improve my sleep?",
            "Why is my HRV lower than usual?",
            "What should I focus on today?",
            "Am I getting enough activity?"
        ]
    }
    
    // MARK: - Clear Chat
    func clearChat() {
        messages = [messages[0]] // Keep welcome message
    }
}
