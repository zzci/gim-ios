//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import UserNotifications

class NotificationHandler {
    private let userSession: NSEUserSession
    private let settings: CommonSettingsProtocol
    private let contentHandler: (UNNotificationContent) -> Void
    private var notificationContent: UNMutableNotificationContent
    private let tag: String
    
    private let notificationContentBuilder: NotificationContentBuilder
    
    init(userSession: NSEUserSession,
         settings: CommonSettingsProtocol,
         contentHandler: @escaping (UNNotificationContent) -> Void,
         notificationContent: UNMutableNotificationContent,
         tag: String) {
        self.userSession = userSession
        self.settings = settings
        self.contentHandler = contentHandler
        self.notificationContent = notificationContent
        self.tag = tag
        
        let eventStringBuilder = RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(mentionBuilder: PlainMentionBuilder()),
                                                               destination: .notification)
        
        notificationContentBuilder = NotificationContentBuilder(messageEventStringBuilder: eventStringBuilder,
                                                                notificationSoundName: settings.notificationSoundName.publisher.value,
                                                                userSession: userSession)
    }
    
    func processEvent(_ eventID: String, roomID: String) async {
        MXLog.info("\(tag) Processing event: \(eventID) in room: \(roomID)")
        
        // Copy over the unread information to the notification badge
        notificationContent.badge = notificationContent.unreadCount as NSNumber?
        MXLog.info("\(tag) New badge value: \(notificationContent.badge?.stringValue ?? "nil")")
        
        guard let notificationItemProxy = await userSession.notificationItemProxy(roomID: roomID, eventID: eventID) else {
            MXLog.error("\(tag) Failed retrieving notification item")
            discardNotification()
            return
        }
        
        switch await preprocessNotification(notificationItemProxy) {
        case .processedShouldDiscard, .unsupportedShouldDiscard:
            discardNotification()
        case .shouldDisplay:
            await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                     notificationItem: notificationItemProxy,
                                                     mediaProvider: userSession.mediaProvider)
            
            deliverNotification()
        }
    }
    
    func handleTimeExpiration() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content
        MXLog.info("\(tag) Extension time will expire")
        deliverNotification()
    }
    
    // MARK: - Private
    
    private func deliverNotification() {
        MXLog.info("\(tag) Delivering notification")
        contentHandler(notificationContent)
    }

    private func discardNotification() {
        MXLog.info("\(tag) Discarding notification")
        
        let content = UNMutableNotificationContent()
        content.badge = notificationContent.unreadCount as NSNumber?
        MXLog.info("\(tag) New badge value: \(content.badge?.stringValue ?? "nil")")
        
        contentHandler(content)
    }
    
    private func preprocessNotification(_ itemProxy: NotificationItemProxyProtocol) async -> NotificationProcessingResult {
        if settings.hideQuietNotificationAlerts, !itemProxy.isNoisy {
            return .processedShouldDiscard
        }
        
        guard case let .timeline(event) = itemProxy.event else {
            return .shouldDisplay
        }
        
        switch try? event.content() {
        case .messageLike(let messageContent):
            switch messageContent {
            case .poll,
                 .roomEncrypted,
                 .sticker:
                return .shouldDisplay
            case .roomMessage(let messageType, _):
                switch messageType {
                case .emote, .image, .audio, .video, .file, .notice, .text, .location, .gallery:
                    return .shouldDisplay
                case .other:
                    return .unsupportedShouldDiscard
                }
            case .roomRedaction(let redactedEventID, _):
                guard let redactedEventID else {
                    MXLog.error("Unable to handle redact notification due to missing event ID")
                    return .processedShouldDiscard
                }
                
                let deliveredNotifications = await UNUserNotificationCenter.current().deliveredNotifications()
                
                if let targetNotification = deliveredNotifications.first(where: { $0.request.content.eventID == redactedEventID }) {
                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [targetNotification.request.identifier])
                }
                
                return .processedShouldDiscard
            case .rtcNotification(let notificationType, let expirationTimestamp):
                return await handleCallNotification(notificationType: notificationType,
                                                    rtcNotifyEventID: event.eventId(),
                                                    timestamp: event.timestamp(),
                                                    expirationTimestamp: expirationTimestamp,
                                                    roomID: itemProxy.roomID,
                                                    roomDisplayName: itemProxy.roomDisplayName)
            case .callAnswer,
                 .callInvite,
                 .callHangup,
                 .callCandidates,
                 .keyVerificationReady,
                 .keyVerificationStart,
                 .keyVerificationCancel,
                 .keyVerificationAccept,
                 .keyVerificationKey,
                 .keyVerificationMac,
                 .keyVerificationDone,
                 .reactionContent:
                return .unsupportedShouldDiscard
            }
        case .state:
            return .unsupportedShouldDiscard
        case .none:
            return .unsupportedShouldDiscard
        }
    }
    
    /// Handle incoming call notifications.
    /// Call functionality has been removed, so call notifications are displayed as regular notifications.
    private func handleCallNotification(notificationType: RtcNotificationType,
                                        rtcNotifyEventID: String,
                                        timestamp: Timestamp,
                                        expirationTimestamp: Timestamp,
                                        roomID: String,
                                        roomDisplayName: String) async -> NotificationProcessingResult {
        .shouldDisplay
    }
    
    private enum NotificationProcessingResult {
        case shouldDisplay
        case processedShouldDiscard
        case unsupportedShouldDiscard
    }
}
