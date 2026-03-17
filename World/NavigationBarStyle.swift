//
//  NavigationBarStyle.swift
//  World
//
//  Created by Skyler on 2/28/26.
//

import UIKit

enum NavigationBarStyle {
    static func apply() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 48, weight: .bold)
        ]
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 24, weight: .semibold)
        ]

        let navigationBar = UINavigationBar.appearance()
        navigationBar.prefersLargeTitles = true
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }
}
