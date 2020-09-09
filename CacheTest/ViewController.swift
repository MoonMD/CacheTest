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
    
    let test = TestCache()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("------------")
        test.testMemoryWrite()
        print("------------")
        _ = test.testMemoryRead()
        print("------------")
        test.testDiskWriteString()
        print("------------")
        _ = test.testDiskReadString()
        print("------------")
        test.testDiskWriteData()
        print("------------")
        _ = test.testDiskReadData()
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



 func formatPath(withFormatName formatName: String) -> String {
    let basePath = DiskCache.basePath()
    let cachePath = (basePath as NSString).appendingPathComponent("haneke_disk")
    let formatPath = (cachePath as NSString).appendingPathComponent(formatName)
    do {
        try FileManager.default.createDirectory(atPath: formatPath, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print("Failed to create directory \(formatPath)")
    }
    return formatPath
}

struct TestCache {
    
    public func `init`() {}
    
    // MARK:  Necessary initial property
    
    let n = 5000
    let imageData = UIImage(named: "some")!.pngData()!
    
    let dictionary_memory = DictionaryCache.shared
    let yy_memory = YYMemoryCache()
    let track_memory = Track.MemoryCache.init()
    let cache_memory = MemoryStorage<Any>.init(config: MemoryConfig(expiry: .never, countLimit: UInt(5000), totalCostLimit: 1000))
    let nsCache_memory: NSCache = NSCache<AnyObject, AnyObject>()
    
    let yy_disk_string = YYDiskCache(path: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!.appending("/yy_disk"))!
    let track_disk_string = Track.DiskCache(name: "track_disk")!
    let cache_disk_string = try! DiskStorage(config: DiskConfig(name: "cache_Disk"), transformer: TransformerFactory.forCodable(ofType: String.self))
    let haneke_disk_string = Haneke.DiskCache(path: formatPath(withFormatName: "haneke_disk"))
    

    let yy_disk_data = YYDiskCache(path: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!.appending("/yy_disk_data"))!
    let track_disk_data = Track.DiskCache(name: "track_disk_data")!
    let cache_disk_data = try! DiskStorage(config: DiskConfig(name: "cache_Disk_data"), transformer: TransformerFactory.forCodable(ofType: Data.self))
    let haneke_disk_data = Haneke.DiskCache(path: formatPath(withFormatName: "haneke_disk_data"))
    
    // MARK: Public function
    
    /// 测试内存缓存写入
    func testMemoryWrite() {
        // Dictionary + Lock
        testWrite("dictionary_memory") { (key, value) in
            dictionary_memory.set(value, key: key)
        }
        
        // YYCahe
        testWrite("yy_memory") { (key, value) in
            yy_memory.setObject(value, forKey: key)
        }
        
        // Track
        testWrite("track_memory") { (key, value) in
            track_memory.set(object: value as AnyObject, forKey: key)
        }
        
        // Cache
        testWrite("cache_memory") { (key, value) in
            cache_memory.setObject(value, forKey: key)
        }
       
        // NSCache
        testWrite("nsCache_memory") { (key, value) in
            nsCache_memory.setObject(value as AnyObject, forKey: key as AnyObject, cost: 0)
        }
    }
    
    
    /// 测试内存缓存读
    public func testMemoryRead() -> Any {
        // Dictionary + Lock
        testRead("dictionary_memory") { (key) in
            return dictionary_memory.object(key)
        }
        
        // YYCahe
        testRead("yy_memory") { (key) in
            return yy_memory.object(forKey: key)
        }
        
        // Track
        testRead("track_memory") { (key) in
            return track_memory.object(forKey: key) as Any?
        }
        
        // Cache
        testRead("cache_memory") { (key) in
            return try! cache_memory.entry(forKey: key).object
        }
       
        // NSCache
        testRead("nsCache_memory") { (key) in
            return nsCache_memory.object(forKey: key as AnyObject) as Any?
        }
        return "temp"
    }
    
    
    
    /// 测试磁盘缓存写入字符串
    func testDiskWriteString() {
        // YYCahe
        testWrite("yy_disk_string") { (key, value) in
            yy_disk_string.setObject(value as NSCoding, forKey: key)
        }
        
        // Track
        testWrite("track_disk_string") { (key, value) in
            track_disk_string.set(object: value as NSCoding, forKey: key)
        }
        
        // Cache
        testWrite("cache_disk_string") { (key, value) in
            try! cache_disk_string.setObject(value, forKey: key)
        }
       
        // Haneke
        testWrite("haneke_disk") { (key, value) in
            haneke_disk_string.setDataSync(value.asData(), key: key)
        }
    }
    
    
    /// 测试磁盘缓存读字符串
    public func testDiskReadString() -> Any {
        // YYCahe
        testRead("yy_disk_string") { (key) in
            return yy_disk_string.object(forKey: key) as Any
        }
        
        // Track
        testRead("track_disk_string") { (key) in
            return track_disk_string.object(forKey: key)
        }

        // Cache
        testRead("cache_disk_string") { (key) in
            return try! cache_disk_string.entry(forKey: key).object
        }
       
        // Haneke
        testRead("haneke_disk_string") { (key) in
            return haneke_disk_string.syncFetchData(key: key)
        }
        return "temp"
    }
    
    /// 测试磁盘缓存写入 50k data
    func testDiskWriteData() {
        // YYCahe
        testWriteData("yy_disk_data") { (key, value) in
            yy_disk_data.setObject(value as NSCoding, forKey: key)
        }
        
        // Track
        testWriteData("track_disk_data") { (key, value) in
            track_disk_data.set(object: value as NSCoding, forKey: key)
        }
        
        // Cache
        testWriteData("cache_disk_data") { (key, value) in
            try! cache_disk_data.setObject(value, forKey: key)
        }
       
        // Haneke
        testWriteData("haneke_disk_data") { (key, value) in
            haneke_disk_data.setDataSync(value, key: key)
        }
    }
    
    
    /// 测试磁盘缓存读 50k data
    public func testDiskReadData() -> Any {
        // YYCahe
        testReadData("yy_disk_data") { (key) in
            return yy_disk_data.object(forKey: key) as Any
        }
        
        // Track
        testRead("track_disk_data") { (key) in
            return track_disk_data.object(forKey: key)
        }

        // Cache
        testRead("cache_disk_data") { (key) in
            return try! cache_disk_data.entry(forKey: key).object
        }
       
        // Haneke
        testRead("haneke_disk_data") { (key) in
            return haneke_disk_data.syncFetchData(key: key)
        }
        return "temp"
    }
    
    
    // MARK: Convinence test method
    
    private func testWrite(_ tag: String, clourse: (String, String) -> Void) {
        let start = CACurrentMediaTime()
        for i in 0 ..< n {
            autoreleasepool {
                let key: String = "key" + String(i) + "key"
                let value: String = "value" + String(i) + "value"
                clourse(key, value)
            }
        }
        let end = CACurrentMediaTime()
        print("\(tag) write \(n) times qps : \(Double(n) / (end - start))")
    }
    
    
    private func testRead(_ tag: String, clourse: (String) -> Any?) {
        let start = CACurrentMediaTime()
        for i in 0 ..< n {
            autoreleasepool {
                let key: String = "key" + String(i) + "key"
                _ = clourse(key)
            }
        }
        let end = CACurrentMediaTime()
        print("\(tag) read \(n) times qps : \(Double(n) / (end - start))")
    }
    
    private func testWriteData(_ tag: String, clourse: (String, Data) -> Void) {
        let start = CACurrentMediaTime()
        for i in 0 ..< n {
            autoreleasepool {
                let key: String = "key" + String(i) + "key"
                let value: Data = imageData + key.asData()
                clourse(key, value)
            }
        }
        let end = CACurrentMediaTime()
        print("\(tag) write \(n) times qps : \(Double(n) / (end - start))")
    }
    
    
    private func testReadData(_ tag: String, clourse: (String) -> Any?) {
        let start = CACurrentMediaTime()
        for i in 0 ..< n {
            autoreleasepool {
                let key: String = "key" + String(i) + "key"
                _ = clourse(key)
            }
        }
        let end = CACurrentMediaTime()
        print("\(tag) read \(n) times qps : \(Double(n) / (end - start))")
    }

     
}

