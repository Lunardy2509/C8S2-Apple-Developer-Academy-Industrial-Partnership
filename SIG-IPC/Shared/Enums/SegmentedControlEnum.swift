//
//  SegmentedControlEnum.swift
//  SIG-IPC
//
//  Created by jonathan calvin sutrisna on 15/07/25.
//
import Foundation

enum SegmentedControlEnum: String, CaseIterable, Identifiable {
    case brand = "Brand"
    case activity = "Activity"
    case heatMap = "Heat Map"
    var id: String { self.rawValue }
}
