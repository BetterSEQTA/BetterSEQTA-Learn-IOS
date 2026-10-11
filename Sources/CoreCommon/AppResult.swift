import Foundation

public enum AppResult<T>: Sendable where T: Sendable {
    case success(T)
    case failure(AppError)
}

public enum AppError: Error, Sendable, Equatable {
    case network(message: String)
    case auth(message: String)
    case sessionExpired
    case unknown(message: String)
}

extension AppError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .network(let message):
            return message
        case .auth(let message):
            return message
        case .sessionExpired:
            return "Session expired"
        case .unknown(let message):
            return message
        }
    }
}

extension AppResult {
    public var value: T? {
        if case let .success(value) = self { return value }
        return nil
    }

    public func map<U>(_ transform: (T) -> U) -> AppResult<U> where U: Sendable {
        switch self {
        case let .success(value):
            return .success(transform(value))
        case let .failure(error):
            return .failure(error)
        }
    }
}
