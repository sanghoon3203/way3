//
//  APIResponse.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 2024-12-26.
//  표준화된 API 응답 처리를 위한 구조체들
//

import Foundation

// MARK: - Standard API Response
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let timestamp: String?
    let statusCode: Int?
    let message: String?
    let data: T?
    let meta: ResponseMeta?
    let error: APIError?

    // 성공 응답 여부 확인
    var isSuccess: Bool {
        return success && error == nil
    }

    // 실제 데이터 안전하게 가져오기
    func getData() -> T? {
        guard isSuccess else { return nil }
        return data
    }

    // 에러 메시지 가져오기
    func getErrorMessage() -> String {
        if let error = error {
            return error.message
        }
        return message ?? "Unknown error occurred"
    }
}

// MARK: - API Error Structure
struct APIError: Codable {
    let code: String
    let message: String
    let details: [String: AnyCodable]?
    let validationErrors: [ValidationError]?

    // 사용자 친화적 메시지 생성
    var userFriendlyMessage: String {
        switch code {
        case "UNAUTHORIZED":
            return "로그인이 필요합니다"
        case "FORBIDDEN":
            return "접근 권한이 없습니다"
        case "NOT_FOUND":
            return "요청하신 정보를 찾을 수 없습니다"
        case "VALIDATION_ERROR":
            return "입력 정보를 확인해주세요"
        case "INSUFFICIENT_FUNDS":
            return "자금이 부족합니다"
        case "INVENTORY_FULL":
            return "인벤토리가 가득 찼습니다"
        case "ITEM_NOT_AVAILABLE":
            return "아이템을 구매할 수 없습니다"
        case "LEVEL_TOO_LOW":
            return "레벨이 부족합니다"
        case "LICENSE_REQUIRED":
            return "상급 라이센스가 필요합니다"
        case "DATABASE_ERROR":
            return "서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요"
        case "RATE_LIMITED":
            return "요청이 너무 많습니다. 잠시 후 다시 시도해주세요"
        default:
            return message
        }
    }

    // 에러 타입별 색상 (UI에서 사용)
    var errorType: ErrorType {
        switch code {
        case "UNAUTHORIZED", "FORBIDDEN":
            return .authentication
        case "VALIDATION_ERROR":
            return .validation
        case "INSUFFICIENT_FUNDS", "INVENTORY_FULL", "ITEM_NOT_AVAILABLE", "LEVEL_TOO_LOW", "LICENSE_REQUIRED":
            return .gameplay
        case "DATABASE_ERROR", "INTERNAL_ERROR":
            return .system
        case "RATE_LIMITED":
            return .rateLimit
        default:
            return .general
        }
    }

    enum ErrorType {
        case authentication
        case validation
        case gameplay
        case system
        case rateLimit
        case general

        var systemImageName: String {
            switch self {
            case .authentication:
                return "person.fill.xmark"
            case .validation:
                return "exclamationmark.triangle"
            case .gameplay:
                return "gamecontroller.fill"
            case .system:
                return "server.rack"
            case .rateLimit:
                return "clock.fill"
            case .general:
                return "exclamationmark.circle"
            }
        }
    }
}

// MARK: - Validation Error
struct ValidationError: Codable {
    let field: String?
    let message: String
    let value: AnyCodable?

    private enum CodingKeys: String, CodingKey {
        case field = "param"
        case message = "msg"
        case value
    }
}

// MARK: - Response Meta (for pagination, etc.)
struct ResponseMeta: Codable {
    let pagination: PaginationMeta?

    struct PaginationMeta: Codable {
        let total: Int
        let page: Int
        let limit: Int
        let totalPages: Int
        let hasNextPage: Bool
        let hasPreviousPage: Bool
        let nextPage: Int?
        let previousPage: Int?
    }
}

// MARK: - Any Codable Support
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
            value = dictionaryValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictionaryValue as [String: Any]:
            try container.encode(dictionaryValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Specific Response Types
typealias EmptyResponse = APIResponse<EmptyData>
typealias StringResponse = APIResponse<String>
typealias IntResponse = APIResponse<Int>
typealias BoolResponse = APIResponse<Bool>

struct EmptyData: Codable {
    // 빈 응답 데이터용
}

// MARK: - Network Error Definition
enum NetworkError: Error {
    case noNetwork
    case unauthorized
    case serverError(String)
    case invalidRequest
    case notFound
    case badRequest
    case rateLimited
    case timeout
    case custom(String)
    case unknown(String)

    var code: String {
        switch self {
        case .noNetwork: return "NO_NETWORK"
        case .unauthorized: return "UNAUTHORIZED"
        case .serverError: return "SERVER_ERROR"
        case .invalidRequest: return "INVALID_REQUEST"
        case .notFound: return "NOT_FOUND"
        case .badRequest: return "BAD_REQUEST"
        case .rateLimited: return "RATE_LIMITED"
        case .timeout: return "TIMEOUT"
        case .custom(let code): return code
        case .unknown: return "UNKNOWN"
        }
    }
}

// MARK: - Network Error Extension
extension NetworkError {
    // API 응답에서 NetworkError 생성
    static func fromAPIError(_ apiError: APIError, statusCode: Int = 400) -> NetworkError {
        switch apiError.code {
        case "UNAUTHORIZED":
            return .unauthorized
        case "NOT_FOUND":
            return .notFound
        case "VALIDATION_ERROR":
            return .badRequest
        case "RATE_LIMITED":
            return .rateLimited
        case "DATABASE_ERROR", "INTERNAL_ERROR":
            return .serverError(apiError.userFriendlyMessage)
        default:
            return .custom(apiError.userFriendlyMessage)
        }
    }
}

// MARK: - Result Extension for API Response
extension Result where Success: Codable, Failure == NetworkError {
    // APIResponse에서 Result로 변환
    static func fromAPIResponse<T: Codable>(_ response: APIResponse<T>) -> Result<T, NetworkError> {
        if response.isSuccess, let data = response.data {
            return .success(data)
        } else if let apiError = response.error {
            return .failure(NetworkError.fromAPIError(apiError, statusCode: response.statusCode ?? 400))
        } else {
            return .failure(.custom("Unknown API error"))
        }
    }
}
