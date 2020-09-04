//
//  ViewController.swift
//  CacheTest
//
//  Created by xiecj1 on 2020/9/3.
//  Copyright © 2020 weiyi. All rights reserved.
//

import UIKit
import Track
import Cache
import Haneke

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        TestCache().testMemoryWrite()
        _ = TestCache().testMemoryRead()
        
    }


}

public class DictionaryCache {
    static let shared = DictionaryCache()
    private func `init`() {}
    
    private var cache: [String: Any] = [:]
    private let semaphoreLock: DispatchSemaphore = DispatchSemaphore(value: 1)

    public func set(_ object: Any, key: String) {
        _ = semaphoreLock.wait(timeout: DispatchTime.distantFuture)
        cache[key] = object
        semaphoreLock.signal()
    }
    
    public func object(_ key: String) -> Any {
        var value: Any = ""
        _ = semaphoreLock.wait(timeout: DispatchTime.distantFuture)
        value = cache[key] ?? ""
        semaphoreLock.signal()
        return value
    }
        
}

struct TestCache {
    
    public func `init`() {}
    var n = 5000
    
    let dictionaryCache = DictionaryCache.shared
    let yyMemoryCache = YYMemoryCache()
    let track_memory = Track.MemoryCache.init()
    let cache_memory_storage = MemoryStorage<Any>.init(config: MemoryConfig(expiry: .never, countLimit: UInt(5000), totalCostLimit: 1000))
    let nsCache: NSCache = NSCache<AnyObject, AnyObject>()
    
    private func testWrite(_ tag: String, clourse: (String, String) -> Void) {
        let start = CACurrentMediaTime()
        for i in 0 ..< n {
            let key: String = "key" + String(i) + "key"
            let value: String = "value" + String(i) + "value"
            clourse(key, value)
        }
        let end = CACurrentMediaTime()
        print("\(tag) write \(n) times qps : \(Double(n) / (end - start))")
    }
    
    
    private func testRead(_ tag: String, clourse: (String) -> Void) {
        let start = CACurrentMediaTime()
        for i in 0 ..< n {
            let key: String = "key" + String(i) + "key"
            clourse(key)
        }
        let end = CACurrentMediaTime()
        print("\(tag) read \(n) times qps : \(Double(n) / (end - start))")
    }

    
    /// 测试内存缓存写入
    func testMemoryWrite() {
        // Dictionary + Lock
        testWrite("dictionaryCache") { (key, value) in
            dictionaryCache.set(value, key: key)
        }
        
        // YYCahe
        testWrite("yycache_memory") { (key, value) in
            yyMemoryCache.setObject(value, forKey: key)
        }
        
        // Track
        testWrite("Track_memory") { (key, value) in
            track_memory.set(object: value as AnyObject, forKey: key)
        }
        
        // Cache
        testWrite("Cache_memory") { (key, value) in
            cache_memory_storage.setObject(value, forKey: key)
        }
       
        // NSCache
        testWrite("NSCache") { (key, value) in
            nsCache.setObject(value as AnyObject, forKey: key as AnyObject, cost: 0)
        }
        
        
//        let diskConfig = DiskConfig(name: "Floppy")
//        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 1000, totalCostLimit: 1000)
//        let storage = try? Storage(
//          diskConfig: diskConfig,
//          memoryConfig: memoryConfig,
//          transformer: TransformerFactory.forCodable(ofType: String.self) // Storage<User>
//        )
//        testWrite("Cache") { (key, value) in
//            try? storage?.setObject(value, forKey: key)
//        }
        
        
//        let cache = Shared.stringCache
//        testWrite("Haneke") { (key, value) in
//            cache.set(value: value, key: key)
//        }
    }
    
    
    /// 测试内存缓存读
    public func testMemoryRead() -> Any {
        var result: Any = ""
        
        // Dictionary + Lock
        testRead("dictionaryCache") { (key) in
            result = dictionaryCache.object(key)
        }
        
        // YYCahe
        testRead("yycache_memory") { (key) in
            result = yyMemoryCache.object(forKey: key) ?? ""
        }
        
        // Track
        testRead("Track_memory") { (key) in
            result = track_memory.object(forKey: key) as Any
        }
        
        // Cache
        testRead("Cache_memory") { (key) in
            result = try! cache_memory_storage.object(forKey: key)
        }
       
        // NSCache
        testRead("NSCache") { (key) in
            result = nsCache.object(forKey: key as AnyObject) as Any
        }
        return result
    }
    
    
    
    
    
    struct User: Codable {
      let firstName: String
      let lastName: String
    }
    private func test_read() {
        print("\(NSHomeDirectory())")
        var s = ""
        let track = Track.Cache.shareInstance
        testRead("track") { (key) in
            let value = track[key]
            s = value as! String
        }
       
        
        let diskConfig = DiskConfig(name: "Floppy")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 1000, totalCostLimit: 1000)
        let storage = try? Storage(
          diskConfig: diskConfig,
          memoryConfig: memoryConfig,
          transformer: TransformerFactory.forCodable(ofType: String.self) // Storage<User>
        )
        testRead("storage") { (key) in
            let value = try? storage?.object(forKey: key)
            s = value ?? ""
        }
        
        
        let cache = Shared.stringCache
        testRead("Haneke") { (key) in
            cache.fetch(key: key).onSuccess { (value) in
                s = value
            }
        }
        
        print(s)
    }
    
     
}

