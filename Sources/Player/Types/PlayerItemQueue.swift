//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import DequeModule

enum ItemIndex: Equatable {
    case valid(Int?)
    case invalid
}

// TODO: Generics for all valid / invalid enums
enum QueueItem: Equatable {
    case valid(PlayerItem?)
    case invalid
}

enum PlayerItemQueueUpdate {
    case items(Deque<PlayerItem>)
    case itemTransition(ItemTransition)
}

// TODO: Generics for ItemQueue / PlayerItemQueue, same idea 
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

    var currentIndex: ItemIndex {
        switch itemTransition {
        case let .advance(to: item):
            if let item {
                guard let index = items.firstIndex(where: { $0.matches(item) }) else { return .invalid }
                return .valid(index)
            }
            else if !items.isEmpty {
                return .valid(0)
            }
            else {
                return .valid(nil)
            }
        case let .stop(on: item):
            guard let index = items.firstIndex(where: { $0.matches(item) }) else { return .invalid }
            return .valid(index)
        case .finish:
            return .valid(nil)
        }
    }

    var currentPlayerItem: QueueItem {
        switch itemTransition {
        case let .advance(to: item):
            if let item {
                guard let item = items.first(where: { $0.matches(item) }) else { return .invalid }
                return .valid(item)
            }
            else {
                return .valid(items.first)
            }
        case let .stop(on: item):
            guard let item = items.first(where: { $0.matches(item) }) else { return .invalid }
            return .valid(item)
        case .finish:
            return .valid(nil)
        }
    }
}
