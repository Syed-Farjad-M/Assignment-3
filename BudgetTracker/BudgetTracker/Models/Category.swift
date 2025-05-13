import Foundation
import SwiftUI

// Cross-platform Color extension to make it Codable
extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, opacity
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let r = try container.decode(Double.self, forKey: .red)
        let g = try container.decode(Double.self, forKey: .green)
        let b = try container.decode(Double.self, forKey: .blue)
        let o = try container.decode(Double.self, forKey: .opacity)
        
        self.init(red: r, green: g, blue: b, opacity: o)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        
        #if canImport(UIKit)
        // iOS
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &o)
        #elseif canImport(AppKit)
        // macOS
        NSColor(self).usingColorSpace(.sRGB)?.getRed(&r, green: &g, blue: &b, alpha: &o)
        #endif
        
        try container.encode(r, forKey: .red)
        try container.encode(g, forKey: .green)
        try container.encode(b, forKey: .blue)
        try container.encode(o, forKey: .opacity)
    }
}

struct Category: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var icon: String
    var color: Color
    
    init(id: UUID = UUID(), name: String, icon: String, color: Color) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
    }
}

// Sample categories for preview
extension Category {
    static var sampleData: [Category] {
        [
            Category(name: "Food", icon: "cart.fill", color: .red),
            Category(name: "Transport", icon: "car.fill", color: .blue),
            Category(name: "Housing", icon: "house.fill", color: .green),
            Category(name: "Entertainment", icon: "film.fill", color: .purple),
            Category(name: "Utilities", icon: "bolt.fill", color: .orange),
            Category(name: "Income", icon: "dollarsign.circle.fill", color: .mint),
            Category(name: "Health", icon: "heart.fill", color: .pink),
            Category(name: "Education", icon: "book.fill", color: .cyan)
        ]
    }
}
