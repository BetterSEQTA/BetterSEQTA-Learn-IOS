import Foundation

public typealias JSONObject = [String: Any]

public enum JSONObjectHelpers {
    public static func object(from data: Data) throws -> Any {
        try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    public static func seqtaPayload(from data: Data) throws -> Any? {
        let root = try object(from: data)
        return unwrapSeqtaValue(root)
    }

    /// Unwraps `payload` keys and JSON-encoded string layers (DesQTA / Android `unwrapPayload`).
    public static func unwrapSeqtaValue(_ value: Any?) -> Any? {
        var current = value
        for _ in 0 ..< 6 {
            if let string = current as? String,
               let data = string.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) {
                current = parsed
                continue
            }
            if let dict = current as? JSONObject {
                if let inner = dict["payload"] {
                    current = inner
                    continue
                }
            }
            break
        }
        return current
    }

    static func string(_ object: JSONObject, keys: String...) -> String? {
        for key in keys {
            if let value = object[key] as? String, !value.isEmpty { return value }
            if let value = object[key] as? NSNumber {
                return value.stringValue
            }
        }
        return nil
    }

    static func int(_ object: JSONObject, keys: String...) -> Int? {
        for key in keys {
            if let value = object[key] as? Int { return value }
            if let value = object[key] as? NSNumber { return value.intValue }
            if let value = object[key] as? String, let parsed = Int(value) { return parsed }
        }
        return nil
    }

    static func bool(_ object: JSONObject, key: String) -> Bool? {
        if let value = object[key] as? Bool { return value }
        if let value = object[key] as? NSNumber { return value.boolValue }
        if let value = object[key] as? String {
            if value == "1" || value.lowercased() == "true" { return true }
            if value == "0" || value.lowercased() == "false" { return false }
        }
        return nil
    }

    static func array(_ object: JSONObject, keys: String...) -> [JSONObject]? {
        for key in keys {
            if let arr = object[key] as? [JSONObject] { return arr }
            if let arr = object[key] as? [Any] {
                return arr.compactMap { $0 as? JSONObject }
            }
        }
        return nil
    }

    static func nestedObject(_ object: JSONObject, keys: String...) -> JSONObject? {
        for key in keys {
            if let nested = object[key] as? JSONObject { return nested }
        }
        return nil
    }

    static func isActiveFolder(_ object: JSONObject) -> Bool {
        guard let active = object["active"] else { return false }
        if let flag = active as? Bool { return flag }
        if let number = active as? NSNumber { return number.intValue != 0 }
        if let text = active as? String {
            return text == "1" || text.lowercased() == "true"
        }
        return false
    }
}
