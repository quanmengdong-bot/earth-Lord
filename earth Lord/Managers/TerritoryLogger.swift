//
//  TerritoryLogger.swift
//  earth Lord
//
//  圈地测试日志管理器 - 记录圈地功能的运行日志
//

import Foundation
import SwiftUI
import Combine

/// 日志类型
enum LogType: String {
    case info = "INFO"
    case success = "SUCCESS"
    case warning = "WARNING"
    case error = "ERROR"

    /// 对应的颜色
    var color: Color {
        switch self {
        case .info:
            return .cyan
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

/// 日志条目
struct LogEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let message: String
    let type: LogType

    init(message: String, type: LogType) {
        self.id = UUID()
        self.timestamp = Date()
        self.message = message
        self.type = type
    }

    /// 格式化为显示文本（HH:mm:ss）
    var displayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let time = formatter.string(from: timestamp)
        return "[\(time)] [\(type.rawValue)] \(message)"
    }

    /// 格式化为导出文本（完整时间戳）
    var exportText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let time = formatter.string(from: timestamp)
        return "[\(time)] [\(type.rawValue)] \(message)"
    }
}

/// 圈地测试日志管理器（单例 + ObservableObject）
class TerritoryLogger: ObservableObject {

    // MARK: - Singleton

    static let shared = TerritoryLogger()

    // MARK: - Published Properties

    /// 日志数组
    @Published var logs: [LogEntry] = []

    /// 格式化的日志文本（用于显示）
    @Published var logText: String = "等待日志..."

    // MARK: - Private Properties

    /// 最大日志条数（防止内存溢出）
    private let maxLogCount = 200

    // MARK: - Initialization

    private init() {
        print("📋 TerritoryLogger 初始化")
    }

    // MARK: - Public Methods

    /// 添加日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - type: 日志类型
    func log(_ message: String, type: LogType = .info) {
        // 确保在主线程更新
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 创建日志条目
            let entry = LogEntry(message: message, type: type)

            // 添加到数组
            self.logs.append(entry)

            // 限制最大条数
            if self.logs.count > self.maxLogCount {
                self.logs.removeFirst()
            }

            // 更新格式化文本
            self.updateLogText()

            // 同时打印到控制台
            print("📋 [\(type.rawValue)] \(message)")
        }
    }

    /// 清空所有日志
    func clear() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.logs.removeAll()
            self.logText = "日志已清空"

            print("📋 日志已清空")
        }
    }

    /// 导出日志为文本
    /// - Returns: 包含头信息和所有日志的文本
    func export() -> String {
        // 生成头信息
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let exportTime = formatter.string(from: Date())

        var text = """
        === 圈地功能测试日志 ===
        导出时间: \(exportTime)
        日志条数: \(logs.count)

        """

        // 添加所有日志
        for entry in logs {
            text += entry.exportText + "\n"
        }

        return text
    }

    // MARK: - Private Methods

    /// 更新格式化的日志文本
    private func updateLogText() {
        if logs.isEmpty {
            logText = "暂无日志"
        } else {
            logText = logs.map { $0.displayText }.joined(separator: "\n")
        }
    }
}
