import Domain
import Foundation

public extension SessionData {
    var resolvedUserId: Int? {
        userId ?? extractUserIdFromJwt(jsessionId)
    }
}
