//
//  IBBase.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import PropertyWrapper
import UIKit

enum InterfaceBridge {
    @PropertiesWrapper(key: "collectedPackages", defaultValue: Data())
    private static var _collectedPackages: Data
    static var collectedPackages: [Package] {
        get {
            (try? JSONDecoder().decode([Package].self, from: _collectedPackages)) ?? []
        }
        set {
            _collectedPackages = (try? JSONEncoder().encode(newValue)) ?? Data()
            NotificationCenter.default.post(name: .PackageCollectionChanged, object: nil)
        }
    }

    @PropertiesWrapper(key: "enableShareSheet", defaultValue: false)
    static var enableShareSheet: Bool

    @PropertiesWrapper(key: "enableQuickMode", defaultValue: false)
    static var enableQuickMode: Bool

    static func removeRecoveryFlag(with reason: String, userRequested: Bool) {
        if !applicationShouldEnterRecovery || userRequested {
            debugPrint("\(#function) \(reason)")
            try? FileManager.default.removeItem(at: applicationRecoveryFlag)
        } else {
            debugPrint("app in recovery mode")
        }
    }

    @PropertiesWrapper(key: "mainUserAgent", defaultValue: "Saily/3.0 Cydia/1.1.32")
    static var mainUserAgent: String
}

public extension PackageDepiction.PreferredDepiction {
    func localizedDescription() -> String {
        switch self {
        case .automatically:
            NSLocalizedString("AUTOMATICALLY", comment: "Automatically")
        case .preferredNative:
            NSLocalizedString("NATIVE", comment: "Native")
        case .preferredWeb:
            NSLocalizedString("WEB", comment: "Web")
        case .onlyNative:
            NSLocalizedString("ONLY_NATIVE", comment: "Native Only")
        case .onlyWeb:
            NSLocalizedString("ONLY_WEB", comment: "Web Only")
        case .never:
            NSLocalizedString("NONE", comment: "None")
        }
    }
}
