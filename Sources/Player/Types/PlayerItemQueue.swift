//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import DequeModule

enum PlayerItemQueueUpdate {
    case items(Deque<PlayerItem>)
    case itemTransition(ItemTransition)
}

struct PlayerItemQueue {
    static var initial: Self {
        .init(items: [], itemTransition: .advance(to: nil))
    }
    
    let items: Deque<PlayerItem>
    let itemTransition: ItemTransition

    init(items: Deque<PlayerItem>, itemTransition: ItemTransition) {
        self.items = items
        self.itemTransition = !items.isEmpty ? itemTransition : .advance(to: nil)
    }

    func updated(with update: PlayerItemQueueUpdate) -> Self {
        switch update {
        case let .items(items):
            return .init(items: items, itemTransition: itemTransition)
        case let .itemTransition(itemTransition):
            return .init(items: items, itemTransition: itemTransition)
        }
    }

    var currentIndex: Int? {
        switch itemTransition {
        case let .advance(to: item):
            if let item {
                return items.firstIndex { $0.matches(item) }
            }
            else if !items.isEmpty {
                return 0
            }
            else {
                return nil
            }
        case let .stop(on: item):
            return items.firstIndex { $0.matches(item) }
        case .finish:
            return nil
        }
    }

    var currentPlayerItem: PlayerItem? {
        switch itemTransition {
        case let .advance(to: item):
            if let item {
                return items.first { $0.matches(item) }
            }
            else {
                return items.first
            }
        case let .stop(on: item):
            return items.first { $0.matches(item) }
        case .finish:
            return nil
        }
    }
}
