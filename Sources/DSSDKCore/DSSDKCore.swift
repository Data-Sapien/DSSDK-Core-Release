//
//  _DSSDKCore.swift
//
//
//  Created by Metecan Duyal on 29.05.2025.
//

@_exported import DSSDK

public enum _DSSDKCore {}  // keep this so SPM still sees at least one Swift file


extension DataSapien {
    @MainActor public static func getIntelligenceService() -> IntelligenceService {
        return IntelligenceService.shared
    }
}
