//
//  ColorExtensions.swift
//  KiroBookmark
//
//  Platform-specific color extensions
//

import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#endif

extension Color {
    static var systemBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
    
    static var systemGroupedBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGroupedBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
    
    static var systemGray4: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGray4)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemGray)
        #endif
    }
    
    static var systemGray5: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGray5)
        #elseif canImport(AppKit)
        return Color(nsColor: .systemGray)
        #endif
    }
}
