//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import MediaPlayer

extension Player {
    func updateControlCenter(nowPlayingInfo: NowPlayingInfo) {
        if isControlCenterControlsEnabled {
            if !nowPlayingInfo.isEmpty {
                if nowPlayingSession.nowPlayingInfoCenter.nowPlayingInfo == nil {
                    uninstallRemoteCommands()
                    installRemoteCommands()
                }
                nowPlayingSession.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
            }
            else {
                uninstallRemoteCommands()
                nowPlayingSession.nowPlayingInfoCenter.nowPlayingInfo = nil
            }
        }
    }

    func uninstallRemoteCommands() {
        if isControlCenterControlsEnabled {
            commandRegistrations.forEach { registration in
                nowPlayingSession.remoteCommandCenter.unregister(registration)
            }
            commandRegistrations = []
        }
    }

    func nowPlayingInfoMetadataPublisher() -> AnyPublisher<NowPlayingInfo, Never> {
        queuePublisher
            .compactMap { queue in
                guard let index = queue.index else {
                    return NowPlayingInfo()
                }
                let asset = queue.elements[index].asset
                return !asset.resource.isLoading ? asset.nowPlayingInfo(with: queue.error) : nil
            }
            .removeDuplicates { lhs, rhs in
                // swiftlint:disable:next legacy_objc_type
                NSDictionary(dictionary: lhs).isEqual(to: rhs)
            }
            .eraseToAnyPublisher()
    }

    func nowPlayingInfoPlaybackPublisher() -> AnyPublisher<NowPlayingInfo, Never> {
        propertiesPublisher
            .map { [weak queuePlayer] properties in
                var nowPlayingInfo = NowPlayingInfo()
                if properties.streamType != .unknown {
                    nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = (properties.streamType == .live)
                    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = properties.isBuffering ? 0 : properties.rate
                    if let time = properties.seekTime ?? queuePlayer?.currentTime(), time.isValid {
                        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = (time - properties.seekableTimeRange.start).seconds
                    }
                    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = properties.seekableTimeRange.duration.seconds
                }
                return nowPlayingInfo
            }
            .eraseToAnyPublisher()
    }

    func nowPlayingInfoPublisher() -> AnyPublisher<NowPlayingInfo, Never> {
        $isActive
            .map { [weak self] isActive in
                guard let self, isActive else { return Just(NowPlayingInfo()).eraseToAnyPublisher() }
                return Publishers.CombineLatest(
                    nowPlayingInfoMetadataPublisher(),
                    nowPlayingInfoPlaybackPublisher()
                )
                .map { nowPlayingInfoMetadata, nowPlayingInfoPlayback in
                    nowPlayingInfoMetadata.merging(nowPlayingInfoPlayback) { _, new in new }
                }
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}

private extension Player {
    func installRemoteCommands() {
        if isControlCenterControlsEnabled {
            commandRegistrations = [
                playRegistration(),
                pauseRegistration(),
                togglePlayPauseRegistration(),
                previousTrackRegistration(),
                nextTrackRegistration(),
                changePlaybackPositionRegistration(),
                skipBackwardRegistration(),
                skipForwardRegistration()
            ]
        }
    }

    func playRegistration() -> some RemoteCommandRegistrable {
        nowPlayingSession.remoteCommandCenter.register(command: \.playCommand) { [weak self] _ in
            guard let self else { return .commandFailed }
            if canReplay() {
                replay()
                return .commandFailed
            }
            else {
                play()
                return .success
            }
        }
    }

    func pauseRegistration() -> some RemoteCommandRegistrable {
        nowPlayingSession.remoteCommandCenter.register(command: \.pauseCommand) { [weak self] _ in
            self?.pause()
            return .success
        }
    }

    func togglePlayPauseRegistration() -> some RemoteCommandRegistrable {
        nowPlayingSession.remoteCommandCenter.register(command: \.togglePlayPauseCommand) { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
    }

    func previousTrackRegistration() -> some RemoteCommandRegistrable {
        nowPlayingSession.remoteCommandCenter.previousTrackCommand.isEnabled = false
        return nowPlayingSession.remoteCommandCenter.register(command: \.previousTrackCommand) { [weak self] _ in
            self?.returnToPrevious()
            return .success
        }
    }

    func nextTrackRegistration() -> some RemoteCommandRegistrable {
        nowPlayingSession.remoteCommandCenter.nextTrackCommand.isEnabled = false
        return nowPlayingSession.remoteCommandCenter.register(command: \.nextTrackCommand) { [weak self] _ in
            self?.advanceToNext()
            return .success
        }
    }

    func changePlaybackPositionRegistration() -> some RemoteCommandRegistrable {
        nowPlayingSession.remoteCommandCenter.register(command: \.changePlaybackPositionCommand) { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(near(.init(seconds: positionEvent.positionTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))), smooth: false)
            return .success
        }
    }

    func skipBackwardRegistration() -> some RemoteCommandRegistrable {
        nowPlayingSession.remoteCommandCenter.skipBackwardCommand.isEnabled = false
        nowPlayingSession.remoteCommandCenter.skipBackwardCommand.preferredIntervals = [.init(value: configuration.backwardSkipInterval)]
        return nowPlayingSession.remoteCommandCenter.register(command: \.skipBackwardCommand) { [weak self] _ in
            self?.skipBackward()
            return .success
        }
    }

    func skipForwardRegistration() -> some RemoteCommandRegistrable {
        nowPlayingSession.remoteCommandCenter.skipForwardCommand.isEnabled = false
        nowPlayingSession.remoteCommandCenter.skipForwardCommand.preferredIntervals = [.init(value: configuration.forwardSkipInterval)]
        return nowPlayingSession.remoteCommandCenter.register(command: \.skipForwardCommand) { [weak self] _ in
            self?.skipForward()
            return .success
        }
    }
}
