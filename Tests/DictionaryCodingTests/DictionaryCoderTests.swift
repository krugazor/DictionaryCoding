import XCTest
@testable import DictionaryCoding

struct SimpleTest : Codable, Equatable {
    var msg : String
    var timestamp : Date
    var iteration : UInt64
    var nullable: String?
    
    public static func == (lhs: SimpleTest, rhs: SimpleTest) -> Bool {
        return ((lhs.msg == rhs.msg) && (lhs.iteration == rhs.iteration) && (lhs.timestamp == rhs.timestamp) && (lhs.nullable == rhs.nullable))
    }
}

struct CompoundTest : Codable, Equatable {
    var msg : String
    var array : [SimpleTest]
    var dic : [String:SimpleTest]
    
    public static func == (lhs: CompoundTest, rhs: CompoundTest) -> Bool {
        let mEq = lhs.msg == rhs.msg
        var arrayEq = true
        lhs.array.forEach { (s) in
            arrayEq = arrayEq && rhs.array.contains(s)
        }
        var dicEq = true
        lhs.dic.keys.forEach { (s) in
            dicEq = dicEq && (rhs.dic[s] == lhs.dic[s])
        }
        
        return mEq && arrayEq && dicEq
    }

}

final class DictionaryCodingTests: XCTestCase {
    func testSimple() {
        let now = Date()
        let m = "This is a test"
        let i = UInt64(1)
        let test = SimpleTest(msg: m, timestamp: now, iteration: i, nullable: "This is not a null string")
        
        guard let r = try? DictionaryCoding().encode(test) else { XCTFail() ; return }
        
        switch r {
        case .dictionary(let d):
            XCTAssert(d.keys.count == 4)
            XCTAssert(((d["msg"] as? String) ?? "") == m)
            XCTAssert((d["timestamp"] as? Date) == now)
            XCTAssert((d["iteration"] as? UInt64) == i)
        default:
            XCTFail()
        }
    }

    func testArray() {
        let test = ["0", "1", "2"]
        guard let r = try? DictionaryCoding().encode(test) else { XCTFail() ; return }

        switch r {
        case .array(let a):
            XCTAssert(a.count == test.count)
        default:
            XCTFail()
        }

    }
    
    func testCompound() {
        let now = Date()
        let m = "This is a test"
        let i = UInt64(1)
        let test = SimpleTest(msg: m, timestamp: now, iteration: i, nullable: "This is not a null string")

        let now2 = Date()
        let m2 = "This is a test"
        let i2 = UInt64(2)
        let test2 = SimpleTest(msg: m2, timestamp: now2, iteration: i2, nullable: nil)
        
        guard let r = try? DictionaryCoding().encode([test,test2]) else { XCTFail() ; return }
        switch r {
        case .array(let a):
            XCTAssert(a.count == 2)
            
            let first = a[0] as? [String:Any]
            XCTAssertNotNil(first)
            XCTAssert((first?["iteration"] as? UInt64) == 1)

        default:
            XCTFail()
        }
        
        guard let r2 = try? DictionaryCoding().encode(["test" : test]) else { XCTFail() ; return }
        switch r2 {
        case .dictionary(let d):
            XCTAssert(d.count == 1)
            guard let t = d["test"] as? [String:Any?] else { XCTFail() ; return }
            XCTAssert(t.count == 4)
            XCTAssert((t["iteration"] as? UInt64) == 1)
        default:
            XCTFail()
        }
    }
    
    func testSimpleDecode() {
        let now = Date()
        let d : [String:Any?] = ["msg" : "this is a test", "timestamp" : now, "iteration" : UInt64(1)]
        let r = try? DictionaryCoding().decode(SimpleTest.self, from: d)
        
        XCTAssertNotNil(r)
        XCTAssert(r?.msg == "this is a test")
        XCTAssert(r?.timestamp == now)
        XCTAssert(r?.iteration == 1)
    }
    
    func testArrayDecode() {
        let now = Date()
        let d : [String:Any?] = ["msg" : "this is a test", "timestamp" : now, "iteration" : UInt64(1)]
        let d2 : [String:Any?] = ["msg" : "this is a another test", "timestamp" : now, "iteration" : UInt64(2)]
        let r = try? DictionaryCoding().decode([SimpleTest].self, from: [d,d2])
        
        XCTAssertNotNil(r)
        
        guard let first = r?.first else { XCTFail() ; return }
        XCTAssert(first.msg == "this is a test")
        XCTAssert(first.timestamp == now)
        XCTAssert(first.iteration == 1)
    }
    
    func testDictionaryDecode() {
        let now = Date()
        let d : [String:Any?] = ["msg" : "this is a test", "timestamp" : now, "iteration" : UInt64(1)]
        let d2 : [String:Any?] = ["msg" : "this is a another test", "timestamp" : now, "iteration" : UInt64(2)]
        let r = try? DictionaryCoding().decode([String:SimpleTest].self, from: ["first":d, "second":d2])

        XCTAssertNotNil(r)
        guard let first = r?["first"] else { XCTFail() ; return }
        XCTAssert(first.msg == "this is a test")
        XCTAssert(first.timestamp == now)
        XCTAssert(first.iteration == 1)
    }
    
    func testLoop() {
        let now = Date()
        let m = "This is a test"
        let i = UInt64(1)
        let test = SimpleTest(msg: m, timestamp: now, iteration: i, nullable: "This is not a null string")
        
        let now2 = Date()
        let m2 = "This is a test"
        let i2 = UInt64(2)
        let test2 = SimpleTest(msg: m2, timestamp: now2, iteration: i2, nullable: nil)

        let compound = CompoundTest(msg: "compound", array: [test, test2], dic: ["first":test, "second":test2])
        
        guard let encodedT = try? DictionaryCoding().encode(compound) else { XCTFail() ; return }
        var encoded : [String:Any?]
        switch encodedT {
        case .dictionary(let d):
            encoded = d
        default:
            XCTFail()
            return
        }
        XCTAssert(encoded.count == 3)
        guard let decoded = try? DictionaryCoding().decode(CompoundTest.self, from: encoded) else { XCTFail() ; return }
        
        XCTAssert(decoded == compound)
    }
    
    static var allTests = [
        ("testSimple", testSimple), ("testArray", testArray), ("testCompound", testCompound),
        ("testSimpleDecode", testSimpleDecode), ("testDictionaryDecode", testDictionaryDecode),
        ("testLoop", testLoop)
    ]
}
