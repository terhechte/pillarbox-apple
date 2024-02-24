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

    func itemStatePublisher() -> AnyPublisher<ItemState, Never> {
        currentItemPublisher()
            .map { item -> AnyPublisher<ItemState, Never> in
                if let item {
                    if let error = item.error {
                        return Just(.init(item: item, error: error)).eraseToAnyPublisher()
                    }
                    else {
                        return item.errorPublisher()
                            .map { .init(item: item, error: $0) }
                            .prepend(.init(item: item, error: nil))
                            .eraseToAnyPublisher()
                    }
                }
                else {
                    print("--> here")
                    return Just(.empty).eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .withPrevious(ItemState.empty)
            .map { state -> ItemState in
                if state.current.item == nil && state.previous.error != nil {
                    return state.previous
                }
                else {
                    return state.current
                }
            }
            .map { state in
                print("--> item state change: \(state)")
                return state
            }
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
