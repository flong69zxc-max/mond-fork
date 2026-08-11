//
//  display.swift
//  mond
//
//  Created by ruter on 11.08.26.
//

import Foundation

func applyDisplayFix(subtype: Int) {
    let plistPath = "/var/mobile/Library/Preferences/com.apple.iokit.IOMobileGraphicsFamily.plist"
    
    let resolutions: [Int: (width: Int, height: Int)] = [
        2436: (1179, 2556),
        2556: (1179, 2556),
        2622: (1206, 2622),
        2796: (1290, 2796),
        2868: (1320, 2868),
        2976: (1356, 2976),
        2736: (1290, 2736),
    ]
    
    guard let res = resolutions[subtype] else {
        print("(display) No resolution for subtype \(subtype)")
        return
    }
    
    guard let token = sandbox_extension_issue_file(path: "/var/mobile/Library/Preferences/") else {
        print("(display) Failed to get token")
        return
    }
    
    let handle = sandbox_extension_consume(token)
    guard handle != nil && handle! >= 0 else {
        print("(display) Failed to consume token")
        return
    }
    
    let url = URL(fileURLWithPath: plistPath)
    var dict: NSMutableDictionary
    
    if let data = try? Data(contentsOf: url),
       let plist = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? NSMutableDictionary {
        dict = plist
    } else {
        dict = NSMutableDictionary()
    }
    
    dict["canvas_width"] = res.width
    dict["canvas_height"] = res.height
    
    do {
        let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        try data.write(to: url, options: .atomic)
        print("(display) Applied: \(res.width)x\(res.height)")
    } catch {
        print("(display) Write failed: \(error)")
    }
}

func revertDisplayFix() {
    let plistPath = "/var/mobile/Library/Preferences/com.apple.iokit.IOMobileGraphicsFamily.plist"
    
    guard let token = sandbox_extension_issue_file(path: "/var/mobile/Library/Preferences/") else {
        print("(display) Failed to get token")
        return
    }
    
    let handle = sandbox_extension_consume(token)
    guard handle != nil && handle! >= 0 else {
        print("(display) Failed to consume token")
        return
    }
    
    let url = URL(fileURLWithPath: plistPath)
    guard let data = try? Data(contentsOf: url),
          let dict = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? NSMutableDictionary else {
        print("(display) Failed to read plist")
        return
    }
    
    dict.removeObject(forKey: "canvas_width")
    dict.removeObject(forKey: "canvas_height")
    
    do {
        let newData = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        try newData.write(to: url, options: .atomic)
        print("(display) Reverted")
    } catch {
        print("(display) Revert failed: \(error)")
    }
}
