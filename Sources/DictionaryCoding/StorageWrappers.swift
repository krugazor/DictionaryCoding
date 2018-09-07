// Crafted by Nicolas Zinovieff
// Inspired by JSONEncoder.swift -- https://swift.org/LICENSE.txt
// CC BY-SA 1.0 -- https://creativecommons.org/licenses/by-sa/1.0/

import Foundation

// A stupid workaround for reference variables without using the NSMutable*

class DictionaryWrapper {
    private var storage : [String:Any?] = [:]
    
    var count : Int { return storage.count }
    
    subscript(key: String) -> Any? {
        get {
            if let v = storage[key] { return v }
            else { return nil }
        }
        
        set(newValue) {
            storage[key] = newValue
        }
    }
    
    var unwrapped : [String:Any?] {
        var result = [String:Any?]()
        result.merge(storage) { $1 }
        return result
    }
}

class ArrayWrapper {
    private var storage : [Any?] = []

    var count : Int { return storage.count }

    subscript(index: Int) -> Any? {
        get {
            if let v = storage[index] { return v }
            else { return nil }
        }
        
        set(newValue) {
            storage[index] = newValue
        }
    }
    
    func insert(_ v: Any?, at index: Int) {
        storage.insert(v, at: index)
    }
    
    func append(_ v: Any?) {
        storage.append(v)
    }
    
    var unwrapped : [Any?] {
        var result = [Any?]()
        result.append(contentsOf: storage)
        return result
    }
}
