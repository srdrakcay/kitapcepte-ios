import Foundation

protocol APIClient: Sendable {
    func send<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T
}

struct APIConfig: Sendable {
    var timeout: TimeInterval = 20
    var maxRetries = 2
    var retryDelay: Duration = .milliseconds(300)
    var userAgent = "KitapCepte/1.0 (iOS)"
}

struct URLSessionAPIClient: APIClient {
    /// Yeniden denenebilir hata (ağ kopması, 5xx).
    private struct RetryableFailure: Error { let error: AppError }

    let session: URLSession
    var config = APIConfig()

    func send<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url else { throw AppError.unknown }
        var request = URLRequest(url: url, timeoutInterval: config.timeout)
        request.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var attempt = 0
        while true {
            do {
                let data = try await fetch(request)
                return try decode(T.self, from: data)
            } catch let failure as RetryableFailure {
                guard attempt < config.maxRetries else { throw failure.error }
                attempt += 1
                try await Task.sleep(for: config.retryDelay * attempt)
            }
        }
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw RetryableFailure(error: .network)
        }
        guard let http = response as? HTTPURLResponse else { throw AppError.unknown }
        switch http.statusCode {
        case 200..<300: return data
        case 404: throw AppError.notFound
        case 500..<600: throw RetryableFailure(error: .network)
        default: throw AppError.network
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw AppError.decoding
        }
    }
}
