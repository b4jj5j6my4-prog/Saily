//
//  DepictionSpacerView.swift
//  Sileo
//
//  Created by CoolStar on 7/6/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//
// Make sure to also update FeaturedSpacerView.swift

import UIKit

class DepictionSpacerView: DepictionBaseView {
    let spacing: CGFloat

    required init?(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor, isActionable: Bool) {
        guard let spacing = dictionary["spacing"] as? CGFloat else {
            return nil
        }
        self.spacing = spacing
        super.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor, isActionable: isActionable)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func depictionHeight(width _: CGFloat) -> CGFloat {
        spacing
    }
}
