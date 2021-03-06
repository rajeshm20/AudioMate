//
//  UserNotificationDispatcher.swift
//  AudioMate
//
//  Created by Ruben Nine on 19/01/16.
//  Copyright © 2016 Ruben Nine. All rights reserved.
//

import Foundation
import AMCoreAudio

/**
    `UserNotificationDispatcher` is a singleton class that wraps all the user notifications 
    that AudioMate generates.
 */
public final class UserNotificationDispatcher {

    /// Shared instance
    static let sharedDispatcher = UserNotificationDispatcher()

    private var lastNotification: NSUserNotification?
    private var lastNotificationTime: NSTimeInterval?
    private let minIntervalBetweenNotifications: NSTimeInterval = 0.05 // in seconds

    private init() {}

    func samplerateChangeNotification(audioDevice: AMAudioDevice) {
        let notification = NSUserNotification()
        let sampleRate = audioDevice.nominalSampleRate() ?? 0.0

        notification.title = NSLocalizedString("Sample Rate Changed", comment: "")

        notification.informativeText = String(
            format: NSLocalizedString("%@ sample rate changed to %@", comment: ""),
            audioDevice.deviceName(),
            String(format: NSLocalizedString("%.1f kHz", comment: ""), sampleRate * 0.001)
        )

        debouncedDeliverNotification(notification)
    }

    func volumeChangeNotification(audioDevice: AMAudioDevice, direction: AMCoreAudio.Direction) {
        if let volumeInDb = audioDevice.masterVolumeInDecibelsForDirection(direction) {
            let formattedVolume = String(format: NSLocalizedString("%.1fdBFS", comment: ""), volumeInDb)
            let notification = NSUserNotification()

            notification.title = NSLocalizedString("Volume Changed", comment: "")

            notification.informativeText = String(
                format: NSLocalizedString("%@ volume changed to %@", comment: ""),
                audioDevice.deviceName(),
                formattedVolume
            )

            debouncedDeliverNotification(notification)
        }
    }

    func muteChangeNotification(audioDevice: AMAudioDevice, direction: AMCoreAudio.Direction) {
        let notification = NSUserNotification()

        if audioDevice.isMasterVolumeMutedForDirection(direction) == true {
            notification.title = NSLocalizedString("Audio Muted", comment: "")

            notification.informativeText = String(
                format: NSLocalizedString("%@ audio was muted", comment: ""),
                audioDevice.deviceName()
            )
        } else {
            notification.title = NSLocalizedString("Audio Unmuted", comment: "")

            notification.informativeText = String(
                format: NSLocalizedString("%@ audio was unmuted", comment: ""),
                audioDevice.deviceName()
            )
        }

        debouncedDeliverNotification(notification)
    }

    func clockSourceChangeNotification(audioDevice: AMAudioDevice, channelNumber: UInt32, direction: AMCoreAudio.Direction) {
        if let clockSourceName = audioDevice.clockSourceForChannel(channelNumber, andDirection: direction) {
            let notification = NSUserNotification()

            notification.title = NSLocalizedString("Clock Source Changed", comment: "")

            notification.informativeText = String(
                format: NSLocalizedString("%@ clock source changed to %@", comment: ""),
                audioDevice.deviceName(),
                clockSourceName
            )

            debouncedDeliverNotification(notification)
        }
    }

    func deviceListChangeNotification(addedDevices: [AMAudioDevice], removedDevices: [AMAudioDevice]) {
        for audioDevice in addedDevices {
            let notification = NSUserNotification()

            notification.title = NSLocalizedString("Audio Device Appeared", comment: "")

            notification.informativeText = String(
                format: NSLocalizedString("%@ appeared", comment: ""),
                audioDevice.deviceName()
            )

            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        }

        for audioDevice in removedDevices {
            let notification = NSUserNotification()

            notification.title = NSLocalizedString("Audio Device Disappeared", comment: "")

            notification.informativeText = String(
                format: NSLocalizedString("%@ disappeared", comment: ""),
                audioDevice.deviceName()
            )

            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        }
    }

    func defaultOutputDeviceChangeNotification(audioDevice: AMAudioDevice) {
        let notification = NSUserNotification()

        notification.title = NSLocalizedString("Default Output Device Changed", comment: "")

        notification.informativeText = String(
            format: NSLocalizedString("%@ is the new default output device", comment: ""),
            audioDevice.deviceName()
        )

        debouncedDeliverNotification(notification)
    }

    func defaultInputDeviceChangeNotification(audioDevice: AMAudioDevice) {
        let notification = NSUserNotification()

        notification.title = NSLocalizedString("Default Input Device Changed", comment: "")

        notification.informativeText = String(
            format: NSLocalizedString("%@ is the new default input device", comment: ""),
            audioDevice.deviceName()
        )

        debouncedDeliverNotification(notification)
    }

    func defaultSystemOutputDeviceChangeNotification(audioDevice: AMAudioDevice) {
        let notification = NSUserNotification()

        notification.title = NSLocalizedString("Default System Output Device Changed", comment: "")

        notification.informativeText = String(
            format: NSLocalizedString("%@ is the new default system output device", comment: ""),
            audioDevice.deviceName()
        )

        debouncedDeliverNotification(notification)
    }

    // MARK: Private Methods

    // Discards duplicate notifications or those that happen faster than the min interval.
    private func debouncedDeliverNotification(notification: NSUserNotification) {
        let timeInterval = NSDate().timeIntervalSinceReferenceDate

        if lastNotification != notification &&
           timeInterval - (lastNotificationTime ?? 0) > minIntervalBetweenNotifications {
            lastNotification = notification
            lastNotificationTime = timeInterval

            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        }
    }
}
