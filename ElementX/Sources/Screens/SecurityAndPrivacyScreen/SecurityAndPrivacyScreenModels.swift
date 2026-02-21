//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SecurityAndPrivacyScreenViewModelAction {
    case displayEditAddressScreen
    case dismiss
}

struct SecurityAndPrivacyScreenViewState: BindableState {
    let serverName: String
    
    var currentSettings: SecurityAndPrivacySettings
    var bindings: SecurityAndPrivacyScreenViewStateBindings
    let strings: SecurityAndPrivacyScreenStrings
    
    var canonicalAlias: String?
    var isKnockingEnabled: Bool

    var canEditAddress = false
    var canEditJoinRule = false
    var canEnableEncryption = false
    var canEditHistoryVisibility = false
    
    private var hasChanges: Bool {
        currentSettings != bindings.desiredSettings
    }
    
    var isSaveDisabled: Bool {
        !hasChanges ||
            (currentSettings.isVisibileInRoomDirectory == nil &&
                bindings.desiredSettings.accessType != .inviteOnly &&
                canonicalAlias != nil)
    }
    
    var availableVisibilityOptions: [SecurityAndPrivacyHistoryVisibility] {
        var options = [SecurityAndPrivacyHistoryVisibility.shared]
        if !bindings.desiredSettings.isEncryptionEnabled, bindings.desiredSettings.accessType == .anyone {
            options.append(.worldReadable)
        } else {
            options.append(.invited)
        }
        return options.sorted()
    }
    
    init(serverName: String,
         accessType: SecurityAndPrivacyRoomAccessType,
         isEncryptionEnabled: Bool,
         historyVisibility: SecurityAndPrivacyHistoryVisibility,
         isKnockingEnabled: Bool,
         historySharingDetailsURL: URL) {
        self.serverName = serverName
        self.isKnockingEnabled = isKnockingEnabled

        let settings = SecurityAndPrivacySettings(accessType: accessType,
                                                  isEncryptionEnabled: isEncryptionEnabled,
                                                  historyVisibility: historyVisibility)
        currentSettings = settings
        bindings = SecurityAndPrivacyScreenViewStateBindings(desiredSettings: settings)
        strings = SecurityAndPrivacyScreenStrings(historySharingDetailsURL: historySharingDetailsURL)
    }
}

struct SecurityAndPrivacyScreenViewStateBindings {
    var desiredSettings: SecurityAndPrivacySettings
    var alertInfo: AlertInfo<SecurityAndPrivacyAlertType>?
}

struct SecurityAndPrivacySettings: Equatable {
    var accessType: SecurityAndPrivacyRoomAccessType
    var isEncryptionEnabled: Bool
    var historyVisibility: SecurityAndPrivacyHistoryVisibility
    var isVisibileInRoomDirectory: Bool?
}

enum SecurityAndPrivacyRoomAccessType: Equatable {
    case inviteOnly
    case askToJoin
    case anyone

    var isAddressRequired: Bool {
        switch self {
        case .inviteOnly:
            false
        case .anyone, .askToJoin:
            true
        }
    }
}

enum SecurityAndPrivacyAlertType {
    case enableEncryption
    case unsavedChanges
}

enum SecurityAndPrivacyScreenViewAction {
    case cancel
    case save
    case tryUpdatingEncryption(Bool)
    case editAddress
}

enum SecurityAndPrivacyHistoryVisibility: Int, Comparable {
    case invited
    case shared
    case worldReadable
    
    var fallbackOption: Self {
        switch self {
        case .invited, .shared:
            return .shared
        case .worldReadable:
            return .invited
        }
    }
    
    static func < (lhs: SecurityAndPrivacyHistoryVisibility, rhs: SecurityAndPrivacyHistoryVisibility) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct SecurityAndPrivacyScreenStrings {
    let historySectionFooterString: AttributedString

    init(historySharingDetailsURL: URL) {
        let linkPlaceholder = "{link}"

        var historyFooterString = AttributedString(L10n.screenSecurityAndPrivacyRoomHistorySectionFooter(linkPlaceholder))
        var historyLinkString = AttributedString(L10n.actionLearnMore)
        historyLinkString.link = historySharingDetailsURL
        historyLinkString.bold()
        historyFooterString.replace(linkPlaceholder, with: historyLinkString)
        historySectionFooterString = historyFooterString
    }
}
