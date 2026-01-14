//
//  POISearchManager.swift
//  earth Lord
//
//  POI 搜索管理器 - 使用 MapKit 搜索附近真实地点
//

import Foundation
import MapKit
import CoreLocation

// MARK: - 游戏 POI 类型

/// 游戏中的 POI 类型
enum GamePOIType: String, CaseIterable {
    case store = "store"           // 商店
    case hospital = "hospital"     // 医院
    case pharmacy = "pharmacy"     // 药店
    case gasStation = "gas_station" // 加油站
    case restaurant = "restaurant"  // 餐厅
    case cafe = "cafe"             // 咖啡店
    case convenience = "convenience" // 便利店
    case supermarket = "supermarket" // 超市

    /// 显示名称
    var displayName: String {
        switch self {
        case .store: return "商店"
        case .hospital: return "医院"
        case .pharmacy: return "药店"
        case .gasStation: return "加油站"
        case .restaurant: return "餐厅"
        case .cafe: return "咖啡店"
        case .convenience: return "便利店"
        case .supermarket: return "超市"
        }
    }

    /// SF Symbol 图标名
    var iconName: String {
        switch self {
        case .store: return "bag.fill"
        case .hospital: return "cross.case.fill"
        case .pharmacy: return "pills.fill"
        case .gasStation: return "fuelpump.fill"
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .convenience: return "storefront.fill"
        case .supermarket: return "cart.fill"
        }
    }

    /// 废墟描述（末日风格）
    var ruinDescription: String {
        switch self {
        case .store: return "废弃商店"
        case .hospital: return "废弃医院"
        case .pharmacy: return "废弃药店"
        case .gasStation: return "废弃加油站"
        case .restaurant: return "废弃餐厅"
        case .cafe: return "废弃咖啡店"
        case .convenience: return "废弃便利店"
        case .supermarket: return "废弃超市"
        }
    }

    /// 对应的 MKPointOfInterestCategory（iOS 14+）
    @available(iOS 14.0, *)
    var mapKitCategory: MKPointOfInterestCategory? {
        switch self {
        case .store: return .store
        case .hospital: return .hospital
        case .pharmacy: return .pharmacy
        case .gasStation: return .gasStation
        case .restaurant: return .restaurant
        case .cafe: return .cafe
        case .convenience: return .store
        case .supermarket: return .store
        }
    }

    /// 搜索关键词
    var searchKeyword: String {
        switch self {
        case .store: return "商店"
        case .hospital: return "医院"
        case .pharmacy: return "药房"
        case .gasStation: return "加油站"
        case .restaurant: return "餐厅"
        case .cafe: return "咖啡"
        case .convenience: return "便利店"
        case .supermarket: return "超市"
        }
    }
}

// MARK: - 游戏 POI 模型

/// 游戏中的 POI（兴趣点）
struct GamePOI: Identifiable, Equatable {
    let id: String
    let name: String
    let type: GamePOIType
    let coordinate: CLLocationCoordinate2D
    var isScavenged: Bool = false  // 是否已搜刮

    /// 获取废墟风格的名称
    var ruinName: String {
        return "发现废墟：\(name)"
    }

    static func == (lhs: GamePOI, rhs: GamePOI) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - POI 搜索管理器

/// POI 搜索管理器（单例模式）
class POISearchManager {

    // MARK: - Singleton

    static let shared = POISearchManager()

    // MARK: - Constants

    /// 搜索半径（米）
    private let searchRadius: CLLocationDistance = 1000

    /// 每种类型最大结果数
    private let maxResultsPerType: Int = 5

    /// 总最大 POI 数量（受地理围栏限制）
    private let maxTotalPOIs: Int = 15

    // MARK: - Initialization

    private init() {
        print("🔍 POISearchManager 初始化")
    }

    // MARK: - 日志方法

    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[\(timestamp)] [POISearch] \(message)")
    }

    // MARK: - 搜索方法

    /// 搜索附近的 POI
    /// - Parameter center: 搜索中心点（WGS-84 坐标）
    /// - Returns: POI 列表
    func searchNearbyPOIs(center: CLLocationCoordinate2D) async -> [GamePOI] {
        log("🔍 开始搜索附近 POI，中心点(WGS-84): (\(String(format: "%.4f", center.latitude)), \(String(format: "%.4f", center.longitude)))")

        // ⭐ 关键：将 WGS-84 坐标转换为 GCJ-02，因为 MKLocalSearch 在中国使用 GCJ-02
        let gcj02Centers = CoordinateConverter.wgs84ToGcj02([center])
        guard let gcj02Center = gcj02Centers.first else {
            log("❌ 坐标转换失败")
            return []
        }
        log("📍 转换后的搜索中心(GCJ-02): (\(String(format: "%.4f", gcj02Center.latitude)), \(String(format: "%.4f", gcj02Center.longitude)))")

        var allPOIs: [GamePOI] = []

        // 搜索多种类型的 POI
        let typesToSearch: [GamePOIType] = [.supermarket, .convenience, .pharmacy, .restaurant, .cafe, .gasStation]

        for poiType in typesToSearch {
            let pois = await searchPOIs(ofType: poiType, center: gcj02Center)
            allPOIs.append(contentsOf: pois)

            // 如果已经达到最大数量，停止搜索
            if allPOIs.count >= maxTotalPOIs {
                break
            }
        }

        // 去重（基于坐标相近）
        let uniquePOIs = removeDuplicates(pois: allPOIs)

        // 限制总数
        let limitedPOIs = Array(uniquePOIs.prefix(maxTotalPOIs))

        log("✅ 搜索完成，找到 \(limitedPOIs.count) 个 POI")
        return limitedPOIs
    }

    /// 搜索特定类型的 POI
    private func searchPOIs(ofType type: GamePOIType, center: CLLocationCoordinate2D) async -> [GamePOI] {
        log("🔎 搜索类型: \(type.displayName)")

        // 创建搜索请求
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = type.searchKeyword
        request.region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: searchRadius * 2,
            longitudinalMeters: searchRadius * 2
        )

        // 执行搜索
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()

            // 转换为 GamePOI
            var pois: [GamePOI] = []
            for item in response.mapItems.prefix(maxResultsPerType) {
                // 计算距离，只保留范围内的
                let itemLocation = CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
                let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
                let distance = itemLocation.distance(from: centerLocation)

                if distance <= searchRadius {
                    let poi = GamePOI(
                        id: UUID().uuidString,
                        name: item.name ?? type.displayName,
                        type: type,
                        coordinate: item.placemark.coordinate
                    )
                    pois.append(poi)
                    log("   📍 \(poi.name) - 距离 \(Int(distance))m")
                }
            }

            return pois

        } catch {
            log("❌ 搜索 \(type.displayName) 失败: \(error.localizedDescription)")
            return []
        }
    }

    /// 去除重复的 POI（坐标非常接近的视为同一地点）
    private func removeDuplicates(pois: [GamePOI]) -> [GamePOI] {
        var uniquePOIs: [GamePOI] = []
        let duplicateThreshold: CLLocationDistance = 30 // 30米内视为同一地点

        for poi in pois {
            let isDuplicate = uniquePOIs.contains { existing in
                let existingLocation = CLLocation(latitude: existing.coordinate.latitude, longitude: existing.coordinate.longitude)
                let poiLocation = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
                return existingLocation.distance(from: poiLocation) < duplicateThreshold
            }

            if !isDuplicate {
                uniquePOIs.append(poi)
            }
        }

        return uniquePOIs
    }
}
