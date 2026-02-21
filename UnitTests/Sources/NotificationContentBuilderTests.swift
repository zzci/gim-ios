//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import XCTest

final class NotificationContentBuilderTests: XCTestCase {
    var notificationContentBuilder: NotificationContentBuilder!
    var mediaProvider: MediaProviderMock!
    var notificationContent: UNMutableNotificationContent!

    override func setUp() {
        notificationContent = .init()
        let stringBuilder = RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(mentionBuilder: PlainMentionBuilder()),
                                                          destination: .notification)
        mediaProvider = MediaProviderMock(configuration: .init())
        notificationContentBuilder = NotificationContentBuilder(messageEventStringBuilder: stringBuilder,
                                                                notificationSoundName: UNNotificationSoundName("message.caf"),
                                                                userSession: NSEUserSessionMock(.init()))
    }

    // MARK: - Helpers

    /// Extracts the private `communicationContext` from a `UNMutableNotificationContent` using the ObjC runtime.
    private func communicationContext(from content: UNMutableNotificationContent) -> NSObject? {
        content.value(forKey: "communicationContext") as? NSObject
    }

    /// Extracts the `displayName` from a communication context object.
    private func displayName(from context: NSObject?) -> String? {
        context?.value(forKey: "displayName") as? String
    }

    /// Extracts the sender's `displayName` from a communication context object.
    private func senderDisplayName(from context: NSObject?) -> String? {
        guard let sender = context?.value(forKey: "sender") as? NSObject else { return nil }
        return sender.value(forKey: "displayName") as? String
    }

    func testDMMessageNotification() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!test:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true))
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)

        let context = communicationContext(from: notificationContent)
        // Checking if nil without using asObject always fails
        XCTAssertNil(displayName(from: context))
        XCTAssertEqual(senderDisplayName(from: context), "Alice")
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNil(notificationContent.threadRootEventID)
        XCTAssertNotNil(notificationContent.sound)
        // Remember we remove the @ due to an iOS bug
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!test:matrix.org")
        XCTAssertEqual(notificationContent.attachments, [])
    }

    func testDMMessageNotificationWithMention() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!test:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true,
                                                               hasMention: true))

        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)

        let context = communicationContext(from: notificationContent)
        // Checking if nil without using asObject always fails
        XCTAssertNil(displayName(from: context))
        XCTAssertEqual(senderDisplayName(from: context), L10n.notificationSenderMentionReply("Alice"))
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNil(notificationContent.threadRootEventID)
        XCTAssertNotNil(notificationContent.sound)
        // Remember we remove the @ due to an iOS bug
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!test:matrix.org")
        XCTAssertEqual(notificationContent.attachments, [])
    }

    func testDMMessageNotificationWithThread() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!test:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true,
                                                               hasMention: false,
                                                               threadRootEventID: "thread"))

        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)

        let context = communicationContext(from: notificationContent)
        XCTAssertEqual(displayName(from: context), L10n.commonThread)
        XCTAssertEqual(senderDisplayName(from: context), "Alice")
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNotNil(notificationContent.threadRootEventID)
        XCTAssertNotNil(notificationContent.sound)
        // Remember we remove the @ due to an iOS bug
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!test:matrix.orgthread")
        XCTAssertEqual(notificationContent.attachments, [])
    }

    func testDMMessageNotificationWithThreadAndMention() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!test:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true,
                                                               hasMention: true,
                                                               threadRootEventID: "thread"))

        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)

        let context = communicationContext(from: notificationContent)
        XCTAssertEqual(displayName(from: context), L10n.commonThread)
        XCTAssertEqual(senderDisplayName(from: context), L10n.notificationSenderMentionReply("Alice"))
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNotNil(notificationContent.threadRootEventID)
        XCTAssertNotNil(notificationContent.sound)
        // Remember we remove the @ due to an iOS bug
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!test:matrix.orgthread")
        XCTAssertEqual(notificationContent.attachments, [])
    }

    func testRoomMessageNotification() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!testroom:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "General",
                                                               roomJoinedMembers: 5,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: false,
                                                               isNoisy: false))

        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        let context = communicationContext(from: notificationContent)

        XCTAssertEqual(displayName(from: context), "General")
        XCTAssertEqual(senderDisplayName(from: context), "Alice")
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNil(notificationContent.threadRootEventID)
        XCTAssertNil(notificationContent.sound)
        // Remember we remove the @ due to an iOS bug
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!testroom:matrix.org")
        XCTAssertEqual(notificationContent.attachments, [])
    }

    func testRoomMessageNotificationWithMention() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!testroom:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "General",
                                                               roomJoinedMembers: 5,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: false,
                                                               isNoisy: true,
                                                               hasMention: true))

        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)

        let context = communicationContext(from: notificationContent)
        XCTAssertEqual(displayName(from: context), "General")
        XCTAssertEqual(senderDisplayName(from: context), L10n.notificationSenderMentionReply("Alice"))
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNil(notificationContent.threadRootEventID)
        XCTAssertNotNil(notificationContent.sound)
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!testroom:matrix.org")
        XCTAssertEqual(notificationContent.attachments, [])
    }

    func testRoomMessageNotificationWithThread() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!testroom:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "General",
                                                               roomJoinedMembers: 5,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: false,
                                                               isNoisy: false,
                                                               threadRootEventID: "thread123"))

        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)

        let context = communicationContext(from: notificationContent)
        XCTAssertEqual(displayName(from: context), L10n.notificationThreadInRoom("General"))
        XCTAssertEqual(senderDisplayName(from: context), "Alice")
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNotNil(notificationContent.threadRootEventID)
        XCTAssertNil(notificationContent.sound)
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!testroom:matrix.orgthread123")
        XCTAssertEqual(notificationContent.attachments, [])
    }

    func testRoomMessageNotificationWithThreadAndMention() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!testroom:matrix.org",
                                                               receiverID: "@bob:matrix.org",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "General",
                                                               roomJoinedMembers: 5,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: false,
                                                               isNoisy: true,
                                                               hasMention: true,
                                                               threadRootEventID: "thread123"))
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        let context = communicationContext(from: notificationContent)
        XCTAssertEqual(displayName(from: context), L10n.notificationThreadInRoom("General"))
        XCTAssertEqual(senderDisplayName(from: context), L10n.notificationSenderMentionReply("Alice"))
        XCTAssertEqual(notificationContent.body, "Hello world!")
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationConstants.Category.message)
        XCTAssertNotNil(notificationContent.threadRootEventID)
        XCTAssertNotNil(notificationContent.sound)
        XCTAssertEqual(notificationContent.threadIdentifier, "bob:matrix.org!testroom:matrix.orgthread123")
        XCTAssertEqual(notificationContent.attachments, [])
    }
}
