//
//  User.swift
//  earth Lord
//
//  Created by AI Assistant on 2026/01/01.
//

import Foundation

// MARK: - 用户模型
struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let createdAt: Date?

    // 自定义解码键
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}
