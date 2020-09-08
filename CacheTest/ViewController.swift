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
        
        let test = TestCache()
        test.testMemoryWrite()
        print("------------")
        _ = test.testMemoryRead()
        
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
    
    let yy_Disk = YYDiskCache(path: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!.appending("/yy_disk"))
    let cache_Disk = try! DiskStorage(config: DiskConfig(name: "cache_Disk"), transformer: TransformerFactory.forCodable(ofType: String.self))
    let haneke_Disk = Haneke.DiskCache(path: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!.appending("Haneke_disk"))
    
    
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
    
    
    private func testRead(_ tag: String, clourse: (String) -> Any?) {
        let start = CACurrentMediaTime()
        var missCount = 0
        for i in 0 ..< n {
            let key: String = "key" + String(i) + "key"
            if clourse(key) == nil {
                missCount += 1
            }
        }
        let end = CACurrentMediaTime()
        print("\(tag) read \(n) times qps : \(Double(n) / (end - start))， read miss count \(missCount)")
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
    }
    
    
    /// 测试内存缓存读
    public func testMemoryRead() -> Any {
        // Dictionary + Lock
        testRead("dictionaryCache") { (key) in
            return dictionaryCache.object(key)
        }
        
        // YYCahe
        testRead("yycache_memory") { (key) in
            return yyMemoryCache.object(forKey: key)
        }
        
        // Track
        testRead("Track_memory") { (key) in
            return track_memory.object(forKey: key) as Any?
        }
        
        // Cache
        testRead("Cache_memory") { (key) in
            return try! cache_memory_storage.entry(forKey: key).object
        }
       
        // NSCache
        testRead("NSCache") { (key) in
            return nsCache.object(forKey: key as AnyObject) as Any?
        }
        return "temp"
    }
    
    
    
    /// 测试磁盘缓存写入
    func testDiskWrite() {
        
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
    }
    
    
    /// 测试磁盘缓存读
    public func testDiskRead() -> Any {
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
            result = try! cache_memory_storage.entry(forKey: key).object
        }
       
        // NSCache
        testRead("NSCache") { (key) in
            result = nsCache.object(forKey: key as AnyObject) as Any
        }
        return result
    }
     
}

