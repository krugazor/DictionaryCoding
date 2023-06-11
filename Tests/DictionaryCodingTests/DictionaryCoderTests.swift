import XCTest
@testable import DictionaryCoding

struct SimpleTest: Codable, Equatable {
    var msg: String
    var timestamp: Date
    var iteration: UInt64
    var nullable: String?

    public static func == (lhs: SimpleTest, rhs: SimpleTest) -> Bool {
        return ((lhs.msg == rhs.msg) && (lhs.iteration == rhs.iteration) && (lhs.timestamp == rhs.timestamp) && (lhs.nullable == rhs.nullable))
    }
}

struct CompoundTest: Codable, Equatable {
    var msg: String
    var array: [SimpleTest]
    var dic: [String: SimpleTest]

    public static func == (lhs: CompoundTest, rhs: CompoundTest) -> Bool {
        let mEq = lhs.msg == rhs.msg
        var arrayEq = true
        lhs.array.forEach { (item) in
            arrayEq = arrayEq && rhs.array.contains(item)
        }
        var dicEq = true
        lhs.dic.keys.forEach { (item) in
            dicEq = dicEq && (rhs.dic[item] == lhs.dic[item])
        }

        return mEq && arrayEq && dicEq
    }

}

enum EnumTest: String, Codable {
    case one
    case two
    case three
}

enum EnumIntTest: Int, Codable {
    case one = 0
    case two = 1
    case three = 2
}

struct EnumCompoundTest: Codable, Equatable {
    var msg: String
    var type: EnumTest
    var itype: EnumIntTest
}

final class DictionaryCodingTests: XCTestCase {
    func testSimple() {
        let now = Date()
        let msg = "This is a test"
        let idx = UInt64(1)
        let test = SimpleTest(msg: msg, timestamp: now, iteration: idx, nullable: "This is not a null string")

        guard let res = try? DictionaryCoding().encode(test) else { XCTFail() ; return }

        switch res {
        case .dictionary(let dct):
            XCTAssert(dct.keys.count == 4)
            XCTAssert(((dct["msg"] as? String) ?? "") == msg)
            XCTAssert((dct["timestamp"] as? Date) == now)
            XCTAssert((dct["iteration"] as? UInt64) == idx)
        default:
            XCTFail()
        }
    }

    func testEnum() {
        let msg = "This is a test"
        let tst = EnumTest.one
        let tst2 = EnumIntTest.one
        let test = EnumCompoundTest(msg: msg, type: tst, itype: tst2)

        guard let res = try? DictionaryCoding().encode(test) else { XCTFail() ; return }

        var encoded: [String: Any?]?
        switch res {
        case .dictionary(let dct):
            XCTAssert(dct.keys.count == 3)
            XCTAssert(((dct["msg"] as? String) ?? "") == msg)
            XCTAssert((dct["type"] as? String) == tst.rawValue)
            XCTAssert((dct["itype"] as? Int) == tst2.rawValue)
            encoded = dct
        default:
            XCTFail()
        }

        guard let enc = try? DictionaryCoding().decode(EnumCompoundTest.self, from: encoded) else {
            XCTFail()
            return
        }
        XCTAssert(enc.msg == msg)
        XCTAssert(enc.type == tst)
        XCTAssert(enc.itype == tst2)
    }

    func testArray() {
        let test = ["0", "1", "2"]
        guard let res = try? DictionaryCoding().encode(test) else { XCTFail() ; return }

        switch res {
        case .array(let arr):
            XCTAssert(arr.count == test.count)
        default:
            XCTFail()
        }

    }

    func testCompound() {
        let now = Date()
        let msg = "This is a test"
        let idx = UInt64(1)
        let test = SimpleTest(msg: msg, timestamp: now, iteration: idx, nullable: "This is not a null string")

        let now2 = Date()
        let msg2 = "This is a test"
        let idx2 = UInt64(2)
        let test2 = SimpleTest(msg: msg2, timestamp: now2, iteration: idx2, nullable: nil)

        guard let res = try? DictionaryCoding().encode([test, test2]) else { XCTFail() ; return }
        switch res {
        case .array(let arr):
            XCTAssert(arr.count == 2)

            let first = arr[0] as? [String: Any]
            XCTAssertNotNil(first)
            XCTAssert((first?["iteration"] as? UInt64) == 1)

        default:
            XCTFail()
        }

        guard let res2 = try? DictionaryCoding().encode(["test": test]) else { XCTFail() ; return }
        switch res2 {
        case .dictionary(let dct):
            XCTAssert(dct.count == 1)
            guard let tst = dct["test"] as? [String: Any?] else { XCTFail() ; return }
            XCTAssert(tst.count == 4)
            XCTAssert((tst["iteration"] as? UInt64) == 1)
        default:
            XCTFail()
        }
    }

    func testSimpleDecode() {
        let now = Date()
        let dct: [String: Any?] = ["msg": "this is a test", "timestamp": now, "iteration": UInt64(1)]
        let res = try? DictionaryCoding().decode(SimpleTest.self, from: dct)

        XCTAssertNotNil(res)
        XCTAssert(res?.msg == "this is a test")
        XCTAssert(res?.timestamp == now)
        XCTAssert(res?.iteration == 1)
    }

    func testArrayDecode() {
        let now = Date()
        let dct: [String: Any?] = ["msg": "this is a test", "timestamp": now, "iteration": UInt64(1)]
        let dct2: [String: Any?] = ["msg": "this is a another test", "timestamp": now, "iteration": UInt64(2)]
        let res = try? DictionaryCoding().decode([SimpleTest].self, from: [dct, dct2])

        XCTAssertNotNil(res)

        guard let first = res?.first else { XCTFail() ; return }
        XCTAssert(first.msg == "this is a test")
        XCTAssert(first.timestamp == now)
        XCTAssert(first.iteration == 1)
    }

    func testDictionaryDecode() {
        let now = Date()
        let dct: [String: Any?] = ["msg": "this is a test", "timestamp": now, "iteration": UInt64(1)]
        let dct2: [String: Any?] = ["msg": "this is a another test", "timestamp": now, "iteration": UInt64(2)]
        let res = try? DictionaryCoding().decode([String: SimpleTest].self, from: ["first": dct, "second": dct2])

        XCTAssertNotNil(res)
        guard let first = res?["first"] else { XCTFail() ; return }
        XCTAssert(first.msg == "this is a test")
        XCTAssert(first.timestamp == now)
        XCTAssert(first.iteration == 1)
    }

    func testLoop() {
        let now = Date()
        let msg = "This is a test"
        let idx = UInt64(1)
        let test = SimpleTest(msg: msg, timestamp: now, iteration: idx, nullable: "This is not a null string")

        let now2 = Date()
        let msg2 = "This is a test"
        let idx2 = UInt64(2)
        let test2 = SimpleTest(msg: msg2, timestamp: now2, iteration: idx2, nullable: nil)

        let compound = CompoundTest(msg: "compound", array: [test, test2], dic: ["first": test, "second": test2])

        guard let encodedT = try? DictionaryCoding().encode(compound) else { XCTFail() ; return }
        var encoded: [String: Any?]
        switch encodedT {
        case .dictionary(let dct):
            encoded = dct
        default:
            XCTFail()
            return
        }
        XCTAssert(encoded.count == 3)
        guard let decoded = try? DictionaryCoding().decode(CompoundTest.self, from: encoded) else { XCTFail() ; return }

        XCTAssert(decoded == compound)
    }

    func testTime() {
        let now = Date()

        let max = 100000
        // loop json
        var start = Date()
        for idx in 0...max {
            let tst = SimpleTest(msg: "test \(idx)", timestamp: now.addingTimeInterval(Double(idx/10)), iteration: UInt64(idx), nullable: "vOv \(idx)")
            let cst = CompoundTest(msg: "\(idx)", array: [tst], dic: ["test": tst])

            if let exp = try? JSONEncoder().encode(cst) {
                _ = try? JSONDecoder().decode(CompoundTest.self, from: exp)
            }
        }
        print("time for json: \(Date().timeIntervalSince(start))")

        start = Date()
        for idx in 0...max {
            let tst = SimpleTest(msg: "test \(idx)", timestamp: now.addingTimeInterval(Double(idx/10)), iteration: UInt64(idx), nullable: "vOv \(idx)")
            let cst = CompoundTest(msg: "\(idx)", array: [tst], dic: ["test": tst])

            if let exp = try? JSONEncoder().encode(cst), let ser = String(data: exp, encoding: .utf8), let ree = ser.data(using: .utf8) {
                _ = try? JSONDecoder().decode(CompoundTest.self, from: ree)
            }
        }
        print("time for json+text: \(Date().timeIntervalSince(start))")

        // loop dic
        start = Date()
        for idx in 0...max {
            let tst = SimpleTest(msg: "test \(idx)", timestamp: now.addingTimeInterval(Double(idx/10)), iteration: UInt64(idx), nullable: "vOv \(idx)")
            let cst = CompoundTest(msg: "\(idx)", array: [tst], dic: ["test": tst])

            if let exp = try? DictionaryCoding().encode(cst), case let .dictionary(dct) = exp {
                _ = try? DictionaryCoding().decode(CompoundTest.self, from: dct)
            }
        }
        print("time for dic: \(Date().timeIntervalSince(start))")
     }

    static var allTests = [
        ("testSimple", testSimple), ("testArray", testArray), ("testCompound", testCompound),
        ("testEnum", testEnum),
        ("testSimpleDecode", testSimpleDecode), ("testDictionaryDecode", testDictionaryDecode),
        ("testLoop", testLoop)
    ]
}
