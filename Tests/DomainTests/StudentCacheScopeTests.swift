import Domain
import XCTest

final class StudentCacheScopeTests: XCTestCase {
    func testScopeSeparatesSchools() {
        let user = SessionData(
            baseUrl: "https://school-a.example.com/seqta/",
            jsessionId: "abc",
            storedUsername: "alice",
            userId: 42
        )
        let otherSchool = SessionData(
            baseUrl: "https://school-b.example.com",
            jsessionId: "abc",
            storedUsername: "alice",
            userId: 42
        )
        XCTAssertNotEqual(
            StudentCacheScope.storageScope(for: user),
            StudentCacheScope.storageScope(for: otherSchool)
        )
    }

    func testScopeSeparatesAccountsAtSameSchool() {
        let school = "https://school.example.com"
        let alice = SessionData(baseUrl: school, jsessionId: "1", userId: 1)
        let bob = SessionData(baseUrl: school, jsessionId: "2", userId: 2)
        XCTAssertNotEqual(
            StudentCacheScope.storageScope(for: alice),
            StudentCacheScope.storageScope(for: bob)
        )
    }

    func testSchoolKeyNormalizesTrailingSlashAndScheme() {
        let a = StudentCacheScope.normalizedSchoolKey(baseUrl: "https://school.example.com/seqta/")
        let b = StudentCacheScope.normalizedSchoolKey(baseUrl: "https://school.example.com")
        XCTAssertEqual(a, b)
        XCTAssertEqual(a, "school.example.com")
    }
}
