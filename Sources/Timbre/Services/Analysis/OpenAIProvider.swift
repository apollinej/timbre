import Foundation

struct OpenAIProvider: AnalysisProvider {
    let name = "openai-gpt-4o"

    private let model = "gpt-4o"
    private let temperature = 0.3
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    func analyze(
        transcript: String,
        task: AnalysisTask
    ) async throws -> AnalysisResult {
        guard let apiKey = KeychainService.read(key: "openai-api-key"),
              !apiKey.isEmpty
        else {
            throw AnalysisError.noAPIKey
        }

        let body = ChatRequest(
            model: model,
            messages: [
                ChatMessage(role: "system", content: task.systemPrompt),
                ChatMessage(role: "user", content: transcript),
            ],
            temperature: temperature
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 120

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AnalysisError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AnalysisError.invalidResponse(0)
        }
        guard http.statusCode == 200 else {
            throw AnalysisError.invalidResponse(http.statusCode)
        }

        let decoded: ChatResponse
        do {
            decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            throw AnalysisError.decodingFailed(error.localizedDescription)
        }

        guard let text = decoded.choices.first?.message.content else {
            throw AnalysisError.decodingFailed("empty response")
        }

        return AnalysisResult(text: text, task: task)
    }
}

// MARK: - OpenAI API types

private struct ChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: ChatMessage
    }
}
