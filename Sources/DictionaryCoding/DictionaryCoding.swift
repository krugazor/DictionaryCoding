// Crafted by Nicolas Zinovieff
// Inspired by JSONEncoder.swift -- https://swift.org/LICENSE.txt
// CC BY-SA 1.0 -- https://creativecommons.org/licenses/by-sa/1.0/

import Foundation

public class DictionaryCodingError: Error {
  public let reason: String
  public init(_ msg: String = "Unspecified error") {
    reason = msg
  }
}

public enum CoderResult {
  case dictionary([String: Any?])
  case array([Any?])
  case single(Any)
  case `nil`
}

public class DictionaryCoding {
  public init() {} // to work outside of module

  public func encode<T: Encodable>(_ value: T) throws -> CoderResult {
    let encoder = _DictionaryEncoder()
    try value.encode(to: encoder)
    guard let container = encoder.popEncoded() else { throw DictionaryCodingError("Nothing could be encoded, despite having no prior exception") }

    switch container {
    case .keyed(let dct):
      return .dictionary(dct.unwrapped)
    case .unkeyed(let arr):
      return .array(arr.unwrapped)
    case .single(let val):
      return .single(val)
    case .nil:
      return .nil
    }
  }

  public func decode<T: Decodable>(_ type: T.Type, from data: Any?) throws -> T {
    let decoder = _DictionaryDecoder(storage: [_DictionaryDecoder.wrapper(for: data)])
    return try decoder.decode(type)
  }
}

// MARK: Keys
struct _DKey: CodingKey {
  public var stringValue: String
  public var intValue: Int?

  public init?(stringValue: String) {
    self.stringValue = stringValue
    self.intValue = nil
  }

  public init?(intValue: Int) {
    self.stringValue = "\(intValue)"
    self.intValue = intValue
  }

  public init(stringValue: String, intValue: Int?) {
    self.stringValue = stringValue
    self.intValue = intValue
  }

  init(index: Int) {
    self.stringValue = "Index \(index)"
    self.intValue = index
  }

  static let `super` = _DKey(stringValue: "super")!
}

// MARK: Encoding
class _DictionaryEncoder: Encoder {
  enum ContainerKind {
    case keyed(DictionaryWrapper)
    case unkeyed(ArrayWrapper)
    case single(Any)
    case `nil`
  }

  public var codingPath: [CodingKey]
  public var userInfo: [CodingUserInfoKey: Any] = [:]

  var storage = [ContainerKind]()

  init(codingPath: [CodingKey] = []) {
    self.codingPath = codingPath
  }

  func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
    let lstorage = DictionaryWrapper()
    storage.append(.keyed(lstorage))
    let container = _DictionaryKeyedEncodingContainer<Key>(encoder: self, codingPath: self.codingPath, storage: lstorage)
    return KeyedEncodingContainer(container)
  }

  func unkeyedContainer() -> UnkeyedEncodingContainer {
    let lstorage = ArrayWrapper()
    storage.append(.unkeyed(lstorage))
    let container = _DictionaryUnkeyedEncodingContainer(encoder: self, codingPath: self.codingPath, storage: lstorage)
    return container
  }

  func singleValueContainer() -> SingleValueEncodingContainer {
    return self
  }

  func popEncoded() -> ContainerKind? {
    return storage.removeLast()
  }
}

class _DictionaryContainerAlias: _DictionaryEncoder {
  private enum AliasType {
    case array(ArrayWrapper, Int)
    case dictionary(DictionaryWrapper, String)
  }

  private let encoder: _DictionaryEncoder
  private let alias: AliasType

  init(encoder: _DictionaryEncoder, index: Int, storage: ArrayWrapper) {
    self.encoder = encoder
    self.alias = .array(storage, index)
    super.init(codingPath: encoder.codingPath)
    self.codingPath.append(_DKey(index: index))
  }

  init(encoder: _DictionaryEncoder, key: CodingKey, storage: DictionaryWrapper) {
    self.encoder = encoder
    self.alias = .dictionary(storage, key.stringValue)
    super.init(codingPath: encoder.codingPath)
    self.codingPath.append(key)
  }

  deinit {
    let value: Any
    switch self.storage.count {
    case 0: value = [String: Any?]()
    case 1:
      value = self.storage.removeLast()

    default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
    }

    switch self.alias {
    case .array(let array, let index):
      array.insert(value, at: index)

    case .dictionary(let dictionary, let key):
      dictionary[key] = value
    }
  }
}

extension _DictionaryEncoder: SingleValueEncodingContainer {
  func encodeNil() throws {
    self.storage.append(.nil)
  }

  func encode(_ value: Bool) throws {
    self.storage.append(.single(value))
  }

  func encode(_ value: String) throws {
    self.storage.append(.single(value))
  }

  func encode(_ value: Double) throws {
    self.storage.append(.single(value))
  }

  func encode(_ value: Float) throws {
    self.storage.append(.single(value))
  }

  func encode(_ value: Int) throws {
    self.storage.append(.single(value))
  }

  func encode(_ value: Int8) throws {
    self.storage.append(.single(value))
  }

  func encode(_ value: Int16) throws {
    self.storage.append(.single(value))
  }

  func encode(_ value: Int32) throws {
    self.storage.append(.single(value))
  }

  func encode(_ value: Int64) throws {
    self.storage.append(.single(value))
  }

  func encode(_ value: UInt) throws {
    self.storage.append(.single(value))
  }

  func encode(_ value: UInt8) throws {
    self.storage.append(.single(value))
  }

  func encode(_ value: UInt16) throws {
    self.storage.append(.single(value))
  }

  func encode(_ value: UInt32) throws {
    self.storage.append(.single(value))
  }

  func encode(_ value: UInt64) throws {
    self.storage.append(.single(value))
  }

  func encode<T>(_ value: T) throws where T: Encodable {
    // self.storage.append(.single(value))
    let type = Swift.type(of: value)
    if type == Date.self || type == NSDate.self
        || type == Data.self || type == NSData.self
        || type == URL.self || type == NSURL.self
        || type == Decimal.self || type == NSDecimalNumber.self {
      self.storage.append(.single(value))
      return
    }
    try value.encode(to: self)
  }
}

struct _DictionaryKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
  typealias Key = K

  private let encoder: _DictionaryEncoder // attached encoder
  private var storage: DictionaryWrapper
  private(set) public var codingPath: [CodingKey]

  init(encoder: _DictionaryEncoder, codingPath: [CodingKey], storage: DictionaryWrapper) {
    self.encoder = encoder
    self.codingPath = codingPath
    self.storage = storage
  }

  mutating func encodeNil(forKey key: K) throws {
    storage[key.stringValue] = nil
  }

  mutating func encode(_ value: Bool, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode(_ value: String, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode(_ value: Double, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode(_ value: Float, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode(_ value: Int, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode(_ value: Int8, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode(_ value: Int16, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode(_ value: Int32, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode(_ value: Int64, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode(_ value: UInt, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode(_ value: UInt8, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode(_ value: UInt16, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode(_ value: UInt32, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode(_ value: UInt64, forKey key: K) throws {
    storage[key.stringValue] = value
  }

  mutating func encode<T>(_ value: T, forKey key: K) throws where T: Encodable {
    // special types
    let type = Swift.type(of: value)
    if type == Date.self || type == NSDate.self
        || type == Data.self || type == NSData.self
        || type == URL.self || type == NSURL.self
        || type == Decimal.self || type == NSDecimalNumber.self {
      storage[key.stringValue] = value
      return
    }

    // other types
    try value.encode(to: self.encoder)
    if let popped = self.encoder.popEncoded() {
      switch popped {
      case .keyed(let dct):
        storage[key.stringValue] = dct.unwrapped
      case .unkeyed(let arr):
        storage[key.stringValue] = arr.unwrapped
      case .single(let val):
        storage[key.stringValue] = val
      case .nil:
        storage[key.stringValue] = nil
      }
    } else {
      throw DictionaryCodingError("Trying to pop past last encoded")
    }
  }

  mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
    let dictionary = DictionaryWrapper()
    storage[key.stringValue] = dictionary
    codingPath.append(key)

    let container = _DictionaryKeyedEncodingContainer<NestedKey>(encoder: self.encoder, codingPath: self.codingPath, storage: dictionary)
    codingPath.removeLast()
    return KeyedEncodingContainer(container)
  }

  mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
    let array = ArrayWrapper()
    storage[key.stringValue] = array
    codingPath.append(key)

    let container = _DictionaryUnkeyedEncodingContainer(encoder: self.encoder, codingPath: self.codingPath, storage: array)
    codingPath.removeLast()
    return container
  }

  mutating func superEncoder() -> Encoder {
    return _DictionaryContainerAlias(encoder: self.encoder, key: _DKey.super, storage: self.storage)
  }

  mutating func superEncoder(forKey key: K) -> Encoder {
    return _DictionaryContainerAlias(encoder: self.encoder, key: key, storage: self.storage)
  }
}

struct _DictionaryUnkeyedEncodingContainer: UnkeyedEncodingContainer {
  private let encoder: _DictionaryEncoder
  private var storage: ArrayWrapper
  private(set) public var codingPath: [CodingKey]
  public var count: Int { return storage.count }

  init(encoder: _DictionaryEncoder, codingPath: [CodingKey], storage: ArrayWrapper) {
    self.encoder = encoder
    self.codingPath = codingPath
    self.storage = storage
  }

  mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
    let dictionary = DictionaryWrapper()
    storage.append(dictionary)
    codingPath.append(_DKey(index: self.count))

    let container = _DictionaryKeyedEncodingContainer<NestedKey>(encoder: self.encoder, codingPath: self.codingPath, storage: dictionary)
    codingPath.removeLast()
    return KeyedEncodingContainer(container)

  }

  mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
    codingPath.append(_DKey(index: self.count))

    let lstorage = ArrayWrapper()
    self.storage.append(lstorage)
    let container = _DictionaryUnkeyedEncodingContainer(encoder: self.encoder, codingPath: self.codingPath, storage: lstorage)
    codingPath.removeLast()
    return container
  }

  mutating func superEncoder() -> Encoder {
    return _DictionaryContainerAlias(encoder: self.encoder, index: self.storage.count, storage: self.storage)
  }

  // Encoding
  mutating func encodeNil() throws {
    storage.append(nil)
  }

  mutating func encode(_ value: Bool)   throws { self.storage.append(value) }
  mutating func encode(_ value: Int)    throws { self.storage.append(value) }
  mutating func encode(_ value: Int8)   throws { self.storage.append(value) }
  mutating func encode(_ value: Int16)  throws { self.storage.append(value) }
  mutating func encode(_ value: Int32)  throws { self.storage.append(value) }
  mutating func encode(_ value: Int64)  throws { self.storage.append(value) }
  mutating func encode(_ value: UInt)   throws { self.storage.append(value) }
  mutating func encode(_ value: UInt8)  throws { self.storage.append(value) }
  mutating func encode(_ value: UInt16) throws { self.storage.append(value) }
  mutating func encode(_ value: UInt32) throws { self.storage.append(value) }
  mutating func encode(_ value: UInt64) throws { self.storage.append(value) }
  mutating func encode(_ value: String) throws { self.storage.append(value) }
  mutating func encode(_ value: Float)  throws { self.storage.append(value) }
  mutating func encode(_ value: Double) throws { self.storage.append(value) }
  mutating func encode<T: Encodable>(_ value: T) throws {
    let type = Swift.type(of: value)
    if type == Date.self || type == NSDate.self
        || type == Data.self || type == NSData.self
        || type == URL.self || type == NSURL.self
        || type == Decimal.self || type == NSDecimalNumber.self {
      self.storage.append(value)
      return
    }

    try value.encode(to: self.encoder)
    if let popped = self.encoder.popEncoded() {
      switch popped {
      case .keyed(let dct):
        self.storage.append(dct.unwrapped)
      case .unkeyed(let arr):
        self.storage.append(arr.unwrapped)
      case .single(let val):
        self.storage.append(val)
      case .nil:
        self.storage.append(nil)
      }
    } else {
      throw DictionaryCodingError("Trying to pop past last encoded")
    }
  }
}

// MARK: Decoding

class _DictionaryDecoder: Decoder {
  public var codingPath: [CodingKey]
  public var userInfo: [CodingUserInfoKey: Any] = [:]

  enum ContainerKind {
    case dictionary([String: Any?])
    case array([Any?])
    case decodable(Decodable)
    case single(Any)
    case `nil`
  }

  static func wrapper(for value: Any?) -> ContainerKind {
    let type = Swift.type(of: value)
    if let dct = value as? [String: Any?] { return .dictionary(dct) } else if let arr = value as? [Any?] { return .array(arr) } else if type == Date.self || type == NSDate.self
              || type == Data.self || type == NSData.self
              || type == URL.self || type == NSURL.self
              || type == Decimal.self || type == NSDecimalNumber.self { // comes before Decodable
      return .single(value!)
    } else if let val = value as? Decodable {
      return .decodable(val)
    } else if value != nil {
      return .single(value!)
    } else {
      return .nil
    }
  }

  var storage = [ContainerKind]()

  init(codingPath: [CodingKey] = [], storage: [ContainerKind] = []) {
    self.codingPath = codingPath
    self.storage = storage
  }

  func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
    guard let lcontainer = self.storage.last else { throw DictionaryCodingError("Trying to decode a non value") }
    switch lcontainer {
    case .dictionary(let dct):
      let ctr = _DictionaryKeyedDecodingContainer<Key>(decoder: self, codingPath: self.codingPath, storage: dct)
      return KeyedDecodingContainer(ctr)
    default:
      throw DictionaryCodingError("Type mismatch")
    }
  }

  func unkeyedContainer() throws -> UnkeyedDecodingContainer {
    guard let lcontainer = self.storage.last else { throw DictionaryCodingError("Trying to decode a non value") }
    switch lcontainer {
    case .array(let arr):
      let ctr = _DictionaryUnkeyedDecodingContainer(decoder: self, codingPath: self.codingPath, storage: arr)
      return ctr
    default:
      throw DictionaryCodingError("Type mismatch")
    }
  }

  func singleValueContainer() throws -> SingleValueDecodingContainer {
    return self
  }
}

extension _DictionaryDecoder: SingleValueDecodingContainer {
  func decodeNil() -> Bool {
    guard let lst = self.storage.last else { return false }
    switch lst {
    case .nil:
      return true
    default:
      return false
    }
  }

  func decode(_ type: Bool.Type) throws -> Bool {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? Bool { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode(_ type: String.Type) throws -> String {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? String { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    case .decodable(let sval): // enums fit in this category
      if let val = sval as? String { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode(_ type: Double.Type) throws -> Double {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? Double { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    case .decodable(let sval): // enums fit in this category
      if let val = sval as? Double { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode(_ type: Float.Type) throws -> Float {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? Float { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    case .decodable(let sval): // enums fit in this category
      if let val = sval as? Float { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode(_ type: Int.Type) throws -> Int {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? Int { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    case .decodable(let sval): // enums fit in this category
      if let val = sval as? Int { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode(_ type: Int8.Type) throws -> Int8 {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? Int8 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    case .decodable(let sval): // enums fit in this category
      if let val = sval as? Int8 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode(_ type: Int16.Type) throws -> Int16 {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? Int16 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    case .decodable(let sval): // enums fit in this category
      if let val = sval as? Int16 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode(_ type: Int32.Type) throws -> Int32 {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? Int32 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    case .decodable(let sval): // enums fit in this category
      if let val = sval as? Int32 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode(_ type: Int64.Type) throws -> Int64 {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? Int64 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    case .decodable(let sval): // enums fit in this category
      if let val = sval as? Int64 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode(_ type: UInt.Type) throws -> UInt {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? UInt { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    case .decodable(let sval): // enums fit in this category
      if let val = sval as? UInt { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode(_ type: UInt8.Type) throws -> UInt8 {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? UInt8 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    case .decodable(let sval): // enums fit in this category
      if let val = sval as? UInt8 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode(_ type: UInt16.Type) throws -> UInt16 {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? UInt16 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    case .decodable(let sval): // enums fit in this category
      if let val = sval as? UInt16 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode(_ type: UInt32.Type) throws -> UInt32 {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? UInt32 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    case .decodable(let sval): // enums fit in this category
      if let val = sval as? UInt32 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode(_ type: UInt64.Type) throws -> UInt64 {
    guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
    switch lst {
    case .single(let sval):
      if let val = sval as? UInt64 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    case .decodable(let sval): // enums fit in this category
      if let val = sval as? UInt64 { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
    default:
      throw DictionaryCodingError("Trying to decode wrong type")
    }
  }

  func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
    if type == Date.self || type == NSDate.self
        || type == Data.self || type == NSData.self
        || type == URL.self || type == NSURL.self
        || type == Decimal.self || type == NSDecimalNumber.self {
      guard let lst = self.storage.last else { throw DictionaryCodingError("Trying to decode past last container") }
      switch lst {
      case .single(let sval):
        if let val = sval as? T { return val } else { throw DictionaryCodingError("Trying to decode wrong type") }
      default:
        throw DictionaryCodingError("Trying to decode wrong type")
      }

    }

    // interesting case
    return try type.init(from: self)
  }
}

struct _DictionaryKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
  typealias Key = K

  private let decoder: _DictionaryDecoder // attached encoder
  private var storage: [String: Any?]
  private(set) public var codingPath: [CodingKey]

  init(decoder: _DictionaryDecoder, codingPath: [CodingKey], storage: [String: Any?]) {
    self.decoder = decoder
    self.codingPath = codingPath
    self.storage = storage
  }

  public var allKeys: [Key] {
    return self.storage.keys.compactMap { Key(stringValue: $0) }
  }

  public func contains(_ key: Key) -> Bool {
    return self.storage.contains { $0.key == key.stringValue }
  }

  func decodeNil(forKey key: K) throws -> Bool {
    return self.storage[key.stringValue] == nil
  }

  func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? Bool else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode(_ type: String.Type, forKey key: K) throws -> String {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? String else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode(_ type: Double.Type, forKey key: K) throws -> Double {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? Double else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode(_ type: Float.Type, forKey key: K) throws -> Float {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? Float else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode(_ type: Int.Type, forKey key: K) throws -> Int {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? Int else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? Int8 else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? Int16 else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? Int32 else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? Int64 else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? UInt else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? UInt8 else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? UInt16 else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? UInt32 else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
    guard let sval = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = sval as? UInt64 else { throw DictionaryCodingError("Type mismatch") }
    return val
  }

  func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[key.stringValue] else { throw DictionaryCodingError("Nothing to decode") }
    if type == Date.self || type == NSDate.self
        || type == Data.self || type == NSData.self
        || type == URL.self || type == NSURL.self
        || type == Decimal.self || type == NSDecimalNumber.self {
      if let val = sval as? T { return val } else { throw DictionaryCodingError("Type mismatch") }
    }

    let ctr = _DictionaryDecoder.wrapper(for: sval)
    self.decoder.storage.append(ctr)
    defer { self.decoder.storage.removeLast() }
    return try T.init(from: self.decoder)
  }

  func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let val = self.storage[key.stringValue] else { throw DictionaryCodingError("Absent key in structure") }
    guard let dec = val as? [String: Any] else { throw DictionaryCodingError("Type mismatch") }
    let container = _DictionaryKeyedDecodingContainer<NestedKey>(decoder: self.decoder, codingPath: self.decoder.codingPath, storage: dec)
    return KeyedDecodingContainer<NestedKey>(container)
  }

  func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let arr = storage[key.stringValue] as? [Any?] else { throw DictionaryCodingError("Type mismatch") }

    let container = _DictionaryUnkeyedDecodingContainer(decoder: self.decoder, codingPath: self.codingPath, storage: arr)
    return container
  }

  func superDecoder() throws -> Decoder {
    let key = _DKey.super
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    let lstorage = self.storage[key.stringValue] ?? nil // keeps the compiler happy
    return _DictionaryDecoder(codingPath: self.codingPath, storage: [_DictionaryDecoder.wrapper(for: lstorage)])
  }

  func superDecoder(forKey key: K) throws -> Decoder {
    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    let lstorage = self.storage[key.stringValue] ?? nil // keeps the compiler happy
    return _DictionaryDecoder(codingPath: self.codingPath, storage: [_DictionaryDecoder.wrapper(for: lstorage)])
  }
}

struct _DictionaryUnkeyedDecodingContainer: UnkeyedDecodingContainer {
  private let decoder: _DictionaryDecoder
  private var storage: [Any?]
  private(set) public var codingPath: [CodingKey]
  public var count: Int? { return storage.count }
  private(set) public var currentIndex: Int
  public var isAtEnd: Bool {
    return self.currentIndex >= self.count!
  }

  private func checkBounds(_ dct: _DictionaryUnkeyedDecodingContainer) throws {
    if dct.isAtEnd {
      throw DictionaryCodingError("Array has no more element")
    }
  }

  init(decoder: _DictionaryDecoder, codingPath: [CodingKey], storage: [Any?] = []) {
    self.decoder = decoder
    self.codingPath = codingPath
    self.storage = storage
    self.currentIndex = 0
  }

  mutating func decodeNil() throws -> Bool {
    try checkBounds(self)

    if storage[self.currentIndex] == nil {
      self.currentIndex += 1
      return true
    } else {
      return false
    }
  }

  mutating func decode(_ type: Bool.Type) throws -> Bool {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? Bool else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode(_ type: String.Type) throws -> String {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? String else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode(_ type: Double.Type) throws -> Double {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? Double else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode(_ type: Float.Type) throws -> Float {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? Float else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode(_ type: Int.Type) throws -> Int {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? Int else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode(_ type: Int8.Type) throws -> Int8 {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? Int8 else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode(_ type: Int16.Type) throws -> Int16 {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? Int16 else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode(_ type: Int32.Type) throws -> Int32 {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? Int32 else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode(_ type: Int64.Type) throws -> Int64 {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? Int64 else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode(_ type: UInt.Type) throws -> UInt {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? UInt else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? UInt8 else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? UInt16 else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? UInt32 else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let sval = storage[self.currentIndex] as? UInt64 else { throw DictionaryCodingError("Type mismatch") }

    self.currentIndex += 1
    return sval
  }

  mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer {
      self.currentIndex += 1
      self.decoder.codingPath.removeLast()
    }

    guard let sval = storage[self.currentIndex] else { throw DictionaryCodingError("Nothing to decode") }
    if type == Date.self || type == NSDate.self
        || type == Data.self || type == NSData.self
        || type == URL.self || type == NSURL.self
        || type == Decimal.self || type == NSDecimalNumber.self {
      if let val = sval as? T {
        return val
      } else { throw DictionaryCodingError("Type mismatch") }
    }

    let ctr = _DictionaryDecoder.wrapper(for: sval)
    self.decoder.storage.append(ctr)
    defer { self.decoder.storage.removeLast() }
    return try T.init(from: self.decoder)
  }

  mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let dct = storage[self.currentIndex] as? [String: Any?] else { throw DictionaryCodingError("Type mismatch") }
    self.currentIndex += 1

    let container = _DictionaryKeyedDecodingContainer<NestedKey>(decoder: self.decoder, codingPath: self.codingPath, storage: dct)
    return KeyedDecodingContainer(container)
  }

  mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let arr = storage[self.currentIndex] as? [Any?] else { throw DictionaryCodingError("Type mismatch") }
    self.currentIndex += 1

    let container = _DictionaryUnkeyedDecodingContainer(decoder: self.decoder, codingPath: self.codingPath, storage: arr)
    return container
  }

  mutating func superDecoder() throws -> Decoder {
    try checkBounds(self)

    self.decoder.codingPath.append(_DKey(index: self.currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    let sval = storage[self.currentIndex] ?? nil
    let wrapper = _DictionaryDecoder.wrapper(for: sval)
    self.currentIndex += 1
    return _DictionaryDecoder(codingPath: self.decoder.codingPath, storage: [wrapper])
  }

}
