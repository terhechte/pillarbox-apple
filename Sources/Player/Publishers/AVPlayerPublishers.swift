//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import AVFoundation
import Combine
import PillarboxCore

extension AVPlayer {
    func currentItemPublisher() -> AnyPublisher<AVPlayerItem?, Never> {
        publisher(for: \.currentItem)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func itemTransitionPublisher() -> AnyPublisher<ItemTransition, Never> {
        currentItemPublisher()
            .map { item -> AnyPublisher<AVPlayerItem?, Never> in
                guard let item else { return Just(nil).eraseToAnyPublisher() }
                return item
                    .errorPublisher()
                    .map { _ in item }
                    .prepend(item)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .withPrevious(nil)
            .map { ItemTransition.transition(from: $0.previous, to: $0.current) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func playerItemPropertiesPublisher() -> AnyPublisher<PlayerItemProperties, Never> {
        currentItemPublisher()
            .map { item in
                guard let item else { return Just(PlayerItemProperties.empty).eraseToAnyPublisher() }
                return item.propertiesPublisher()
            }
            .switchToLatest()
            .prepend(.empty)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func playbackPropertiesPublisher() -> AnyPublisher<PlaybackProperties, Never> {
        Publishers.CombineLatest3(
            publisher(for: \.rate),
            publisher(for: \.isExternalPlaybackActive),
            publisher(for: \.isMuted)
        )
        .map { .init(rate: $0, isExternalPlaybackActive: $1, isMuted: $2) }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}
