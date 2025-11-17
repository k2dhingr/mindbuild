//
//  LLMManager.swift
//  MindfulHealth
//
//  Manages on-device AI inference with ExecuTorch + Gemma 3n-E2B
//  ARM-optimized for efficient mobile execution
//

import Foundation
// Note: ExecuTorch will be added via Swift Package Manager
// Uncomment these once you add the package:
// import executorch
// import ExecuTorchLLM

class LLMManager: ObservableObject {
    
    // Published properties for UI updates
    @Published var isModelLoaded = false
    @Published var isGenerating = false
    @Published var lastInferenceTime: Double = 0 // milliseconds
    
    // Model placeholder (will be ExecuTorch runner)
    // private var modelRunner: LLMRunner?
    
    // System prompt for health coaching
    private let systemPrompt = """
    You are a compassionate health and wellness coach. Your role is to:
    1. Analyze health metrics with empathy and understanding
    2. Provide actionable, science-based advice
    3. Suggest mind-body interventions (meditation, breathing exercises, sleep hygiene)
    4. Never diagnose medical conditions - suggest consulting healthcare professionals when appropriate
    5. Focus on holistic wellness: physical activity, sleep, stress management, and mental health
    6. Keep responses concise (2-3 sentences max) and encouraging
    7. Use simple, accessible language
    
    When you see concerning patterns (e.g., consistently poor sleep + elevated resting HR + low HRV), 
    gently suggest both lifestyle interventions AND recommend speaking with a healthcare provider.
    """
    
    init() {
        // Model initialization will happen here
        Task {
            await loadModel()
        }
    }
    
    // MARK: - Load Model
    func loadModel() async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // TODO: Implement ExecuTorch model loading
        // For now, using placeholder
        
        /*
         Actual implementation will look like:
         
         guard let modelPath = Bundle.main.path(forResource: "gemma3n", ofType: "pte") else {
             print("❌ Model file not found")
             return
         }
         
         do {
             modelRunner = try LLMRunner(modelPath: modelPath)
             
             DispatchQueue.main.async {
                 self.isModelLoaded = true
                 let loadTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                 print("✅ Model loaded in \(Int(loadTime))ms")
             }
         } catch {
             print("❌ Failed to load model: \(error)")
         }
         */
        
        // Placeholder for development
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate 1s load time
        
        DispatchQueue.main.async {
            self.isModelLoaded = true
            let loadTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            print("✅ [PLACEHOLDER] Model loaded in \(Int(loadTime))ms")
        }
    }
    
    // MARK: - Generate Health Insight
    func generateHealthInsight(
        healthContext: String,
        userQuestion: String? = nil
    ) async -> String {
        guard isModelLoaded else {
            return "AI model is still loading. Please wait a moment..."
        }
        
        DispatchQueue.main.async {
            self.isGenerating = true
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Build the prompt
        var prompt = systemPrompt + "\n\n"
        prompt += healthContext + "\n\n"
        
        if let question = userQuestion {
            prompt += "User Question: \(question)\n\n"
        } else {
            prompt += "Based on this health data, provide a brief insight and one actionable suggestion:\n"
        }
        
        // TODO: Actual ExecuTorch inference
        /*
         do {
             let response = try await modelRunner?.generate(
                 prompt: prompt,
                 maxTokens: 150,
                 temperature: 0.7
             )
             
             let inferenceTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
             
             DispatchQueue.main.async {
                 self.isGenerating = false
                 self.lastInferenceTime = inferenceTime
             }
             
             return response ?? "Unable to generate response"
         } catch {
             print("❌ Inference error: \(error)")
             return "I'm having trouble processing that right now. Please try again."
         }
         */
        
        // Placeholder response (rule-based logic for demo)
        let response = generatePlaceholderResponse(context: healthContext, question: userQuestion)
        
        try? await Task.sleep(nanoseconds: 500_000_000) // Simulate 500ms inference
        
        let inferenceTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        DispatchQueue.main.async {
            self.isGenerating = false
            self.lastInferenceTime = inferenceTime
        }
        
        return response
    }
    
    // MARK: - Placeholder Response Generator (for demo without actual model)
    private func generatePlaceholderResponse(context: String, question: String?) -> String {
        // Parse context to detect patterns
        let lowerContext = context.lowercased()
        
        // Detect specific patterns
        let hasSleepIssue = lowerContext.contains("sleep") && (lowerContext.contains("decreased") || lowerContext.contains("declining"))
        let hasHRVIssue = lowerContext.contains("hrv") && lowerContext.contains("decreased")
        let hasStepsIssue = lowerContext.contains("steps") && lowerContext.contains("decreased")
        let hasRestingHRIssue = lowerContext.contains("resting heart rate") && lowerContext.contains("increased")
        
        // Multi-factor pattern: stress/illness indicator
        if (hasSleepIssue && hasHRVIssue) || (hasHRVIssue && hasRestingHRIssue) {
            return """
            I notice your body is showing signs of stress or possible illness onset - low HRV combined with \
            \(hasSleepIssue ? "poor sleep" : "elevated resting heart rate"). \
            I'd recommend: (1) Try a 10-minute guided meditation tonight to help your nervous system recover, \
            (2) Aim for 8 hours of sleep, and (3) if these patterns continue for 2-3 more days, consider \
            checking in with your doctor.
            """
        }
        
        // Sleep-specific advice
        if hasSleepIssue {
            return """
            Your sleep has been below your baseline recently. This can affect everything from recovery to mood. \
            Try this tonight: dim lights 1 hour before bed, avoid screens 30 minutes before sleep, and keep your \
            room cool (65-68°F). Even small improvements in sleep hygiene can make a big difference.
            """
        }
        
        // HRV-specific (stress indicator)
        if hasHRVIssue {
            return """
            Your heart rate variability is lower than usual, which often indicates your body is under stress or \
            not recovering well. Consider trying a 5-minute box breathing exercise (4 seconds in, 4 hold, 4 out, 4 hold). \
            Also, prioritize sleep tonight - HRV typically improves with quality rest.
            """
        }
        
        // Activity-specific
        if hasStepsIssue {
            return """
            Your activity level has dropped this week. Even light movement can boost mood and energy. \
            Try this: take a 10-minute walk outside today, ideally in morning sunlight. It's a small step \
            that can help reset both your activity patterns and your circadian rhythm.
            """
        }
        
        // Positive/neutral response
        if lowerContext.contains("improving") || lowerContext.contains("increased") && !hasRestingHRIssue {
            return """
            Your metrics are looking good! Your consistency is paying off. To keep this momentum, \
            focus on maintaining your sleep schedule and staying active. Small, sustainable habits \
            create lasting results.
            """
        }
        
        // Default response
        return """
        Your health metrics look relatively stable. Keep focusing on the fundamentals: \
        7-9 hours of sleep, 30 minutes of movement daily, and stress management through \
        breathwork or meditation. These simple practices have the biggest impact.
        """
    }
    
    // MARK: - Chat Response
    func generateChatResponse(
        conversationHistory: [ChatMessage],
        healthContext: String
    ) async -> String {
        // Build conversation context
        var prompt = systemPrompt + "\n\n"
        prompt += "### Current Health Context:\n"
        prompt += healthContext + "\n\n"
        prompt += "### Conversation History:\n"
        
        for message in conversationHistory.suffix(5) { // Last 5 messages for context
            let role = message.isUser ? "User" : "Assistant"
            prompt += "\(role): \(message.content)\n"
        }
        
        prompt += "\nAssistant:"
        
        return await generateHealthInsight(healthContext: healthContext, userQuestion: conversationHistory.last?.content)
    }
}

// MARK: - Model Configuration
struct ModelConfig {
    static let maxTokens = 200
    static let temperature: Float = 0.7
    static let topP: Float = 0.9
    
    // ARM-optimized settings
    static let useXNNPACK = true // ARM CPU acceleration
    static let quantization = "4bit" // Memory efficiency
}
