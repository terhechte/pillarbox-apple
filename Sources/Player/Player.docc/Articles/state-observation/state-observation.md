# State Observation

@Metadata {
    @PageColor(purple)
    @PageImage(purpose: card, source: state-observation-card, alt: "An image depicting an eye.")
}

Learn how to observe state associated with a player.

## Overview

The PillarboxPlayer framework heavily relies on [Combine](https://developer.apple.com/documentation/combine),  [`ObservableObject`](https://developer.apple.com/documentation/combine/observableobject) and published properties. This makes it possible for SwiftUI views to automatically observe and respond to change.

Unsupervised property publishing can lead to an explosion of updates sent from an observable object, though, leading to potentially unnecessary SwiftUI view body refreshes, poor layout performance and energy consumption issues.

For this reason ``Player`` only broadcasts essential state, for example whether it is playing or paused, or what kind of stream is being played. Observing states that can frequently change requires explicit subscription.

### Observe essential player state

Essential player states like ``Player/playbackState`` or ``Player/mediaType`` are automatically published by a player instance, which means most of your playback view layout can usually be implemented with minimal effort:

```swift
struct PlaybackView: View {
    @StateObject private var player = Player(
        item: .simple(url: URL(string: "https://www.server.com/master.m3u8")!)
    )

    var body: some View {
        VStack {
            VideoView(player: player)
            Button(action: player.togglePlayPause) {
                Text(player.shouldPlay ? "Pause" : "Play")
            }
        }
    }
}
```

### Observe time updates

Observing time is essential to any playback experience implementation. Time often needs to be observed at various time intervals for the same player instance. For example a progress bar might need to be refreshed every 1/10th of a second, while other parts of the same user interface might only require one refresh per second.

Even if a single small time interval could be suitable for all needs (say 1/10th of a second) it would follow that ``Player``, being an observable object, would force all associated view updates to be performed at the same pace.

For these reasons ``Player`` does not publish time updates automatically. Explicit publisher subscriptions are required:

- ``Player/periodicTimePublisher(forInterval:queue:)`` for periodic time updates.
- ``Player/boundaryTimePublisher(for:queue:)`` to detect time traversal.

When implementing a user interface use ``ProgressTracker`` to conveniently observe progress changes without the need for explicit subscriptions.

### Explicitly subscribe to frequent updates

As for time updates discussed above, any other non-essential player state is not published and requires explicit subscription. This includes states derived from time range information, for example the stream type, or states which might be frequently updated like the current buffer position. Code that needs to observe these properties can subscribe to ``Player/propertiesPublisher``.

When implementing a user interface use ``SwiftUI/View/onReceive(player:assign:to:)`` to locally observe a specific property and store it into a view state. For example, to display when a player is busy (seeking or buffering), subscribe to the corresponding change stream:

```swift
struct PlaybackView: View {
    @StateObject private var player = Player(
        item: .simple(url: URL(string: "https://www.server.com/master.m3u8")!)
    )
    @State private var isBusy = false

    var body: some View {
        ZStack {
            VideoView(player: player)
            ProgressView()
                .opacity(isBusy ? 1 : 0)
        }
        .onAppear(perform: player.play)
        .onReceive(player: player, assign: \.isBusy, to: $isBusy)
    }
}
```

Check ``PlayerProperties`` for the list of all properties that are available for explicit observation.

### Use SwiftUI property wrappers wisely

With SwiftUI it is especially important to [properly annotate](https://developer.apple.com/documentation/swiftui/model-data) properties so that changes to your models correctly drive updates to your user interface.

Since ``Player`` is an [`ObservableObject`](https://developer.apple.com/documentation/combine/observableobject) the usual rules apply. Here is a quick summary that might prove helpful.

#### Player neither owned nor observed by a view

Receive the player as a `let` constant:

```swift
struct Widget: View {
    let player: Player

    var body: some View {
        // Not updated when the player publishes changes
    }
}
```

#### Player owned but not observed by a view

Store the player in a `@State`:

```swift
struct PlayerInterface: View {
    @State var player = Player(item: .urn("urn:rts:video:13444390"))

    var body: some View {
        // Not updated when the player publishes changes
    }
}
```

> Warning: On iOS / tvOS 17.0 and 17.1 this code [leaks](https://developer.apple.com/forums/thread/736110?login=true&page=1#769898022) when `PlayerInterface` is displayed in a modal. Should you need to support these platforms you can safely replace `@State` with `@StateObject` since ``Player`` has been optimized to minimize updates anyway.

#### Player not owned but observed by a view

Receive the player as an `@ObservedObject`:

```swift
struct Widget: View {
    @ObservedObject var player: Player

    var body: some View {
        // Updated when the player publishes changes
    }
}
```

#### Player owned and observed by a view

Store the player in a `@StateObject`:

```swift
struct PlayerInterface: View {
    @StateObject var player = Player(item: .urn("urn:rts:video:13444390"))

    var body: some View {
        // Updated when the player publishes changes
    }
}
```

### Optimize state observations

Having your whole user interface refreshed every 1/10th of a second is not required if only a progress bar at the bottom requires periodic refreshes at this pace. This is why subscription to state update streams or use of ``ProgressTracker`` should occur in the smallest required view scope.

Here are a few tips to help you identify and fix superfluous refreshes in your layouts:

- Use the `View/_debugBodyCounter()` modifier available from the PillarboxCore framework to identify which views are refreshed unnecessarily often.
- Extract views that require higher refresh rates into subviews so that ``ProgressTracker`` or explicit subscriptions using ``SwiftUI/View/onReceive(player:assign:to:)`` only affect smaller subsets of your view hierarchy.
- Use the `View/_debugBodyCounter()` modifier to check your layout again after optimization.

> Note: For concrete optimization examples have a look at the <doc:optimizing-custom-layouts> tutorial.
