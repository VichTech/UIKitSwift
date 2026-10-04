# UIKitSwift

The UIKit version of [SwiftUISwift](https://github.com/VichTech/SwiftUISwift): the same app rebuilt with view controllers, programmatic Auto Layout, and a diffable data source. It practices **concurrency** (GCD compared with Swift Concurrency, actors, cancellation), **local persistence** (a JSON file cache and SwiftData behind one protocol), and **unit testing** with Swift Testing.

The app has two tabs:

- **List**: todos fetched from [JSONPlaceholder](https://jsonplaceholder.typicode.com/todos). Tap a todo to open its detail screen and toggle `completed`.
- **Map**: five California locations shown as MapKit annotations, loaded when the tab appears.

## Same app, two UI frameworks

The point of this repo is the comparison with the SwiftUI version. Everything below the view layer is shared unchanged; only the views were rewritten.

| Layer | SwiftUI version | UIKit version |
|---|---|---|
| Models, protocols, data source | shared | shared |
| `DataService`, `ItemFileStore`, `ItemDBStore` | shared | shared |
| `ContentViewModel` (`@MainActor @Observable`) | shared | shared, plus one change (see below) |
| Tests (15) | shared | shared, all passing unchanged |
| App entry | `App` struct | `SceneDelegate` building the window in code |
| Tabs | `TabView` | `UITabBarController` with one `UINavigationController` per tab |
| List | `ListView` | `ListViewController` |
| Detail | `ItemView` | `ItemViewController` |
| Map | `MapView` | `MapViewController` |

## Scope

This project uses **MVVM only**. It is not a Clean Architecture example: there are no use cases and no separate domain layer. Navigation uses `UINavigationController` directly; with three screens, a coordinator would add a layer without solving a real problem yet.

```
ViewController  →  ViewModel  →  DataService  ─┬─  DataSourceProtocol
                                               │      ├── RemoteDataSource   (app)
                                               │      └── MockDataSource     (tests)
                                               │
                                               └─  ItemStoreProtocol
                                                      ├── ItemDBStore        (SwiftData, used by the app)
                                                      └── ItemFileStore      (JSON file, kept for comparison)
```

## UIKit implementation

### No storyboard

`Main.storyboard` is removed. `SceneDelegate` creates the `UIWindow`, the shared view model, and the tab bar. All layout uses programmatic Auto Layout constraints and `UIStackView`.

### Observation in UIKit

The view model is `@Observable`, as in the SwiftUI version. Each view controller reads its properties in `updateProperties()`, and UIKit calls that method again whenever an observed property changes. It plays the role SwiftUI's `body` plays: no closures, delegates, or Combine bindings are needed to keep the UI in sync.

### List screen

- **Diffable data source** identified by `Item.ID`, not by `Item`. With the whole `Item` as identifier, toggling `completed` would change its hash, and the table would treat it as a different row. With the id, the row keeps its identity and `reconfigureItems` refreshes its content.
- **View states** with `UIContentUnavailableConfiguration`: an empty state prompting to tap Fetch, a loading state, and an error state with a Retry button. It is UIKit's counterpart to SwiftUI's `ContentUnavailableView`.
- **Pull-to-refresh** with `UIRefreshControl`. The full-screen loading state only shows when there are no items yet, so a refresh keeps the list on screen.

### No bindings

SwiftUI's `@Binding` let the detail view's toggle write directly into the view model's array. UIKit has no equivalent, so `ItemViewController` works on its own copy of the item and reports changes through an `onUpdate` closure. `ContentViewModel.updateItem(item:)` updates the `items` array and saves the item. This is the only view model change from the SwiftUI version, and it works for both apps.

### Manual cancellation

SwiftUI's `.task` cancels its work when a view disappears. UIKit has no equivalent, so `MapViewController` stores the fetch `Task`, starts it in `viewWillAppear`, and cancels it in `viewWillDisappear`. The view model checks `Task.isCancelled` before assigning `pins`, so a cancelled fetch can't overwrite existing pins with an empty result.

## Concurrency

The pins are fetched in three parallel steps, implemented two ways in `DataService`:

- **`fetchAsyncPins()`, Swift Concurrency (used by the app).** Uses `withTaskGroup` to run the three steps as child tasks.
- **`fetchGCDPins(completion:)`, Grand Central Dispatch (kept for comparison).** Uses `DispatchGroup` with a serial queue to protect the shared array.

Both behave the same way: a failed step is logged and skipped, the other steps' pins are still returned, and the result is sorted by id. The comparison shows what structured concurrency removes: no manual `enter()`/`leave()` pairing, no queue to guard shared state, and cancellation that propagates to child tasks automatically.

Both stores are actors, so file and database access is serialized and runs off the main thread. `Item` is a `Sendable` struct that crosses the actor boundary. `ItemEntity`, the SwiftData model, never leaves `ItemDBStore`: the store converts entities to `Item` values before returning them.

## Caching and persistence

- The first fetch after launch reads from the local store. If the store is empty or fails, it falls through to the network.
- Every successful network fetch is saved to the store.
- Toggling `completed` saves that item immediately.
- A failed save is logged but never breaks the fetch or the UI.

**Known limitation:** local edits aren't synced to a server. JSONPlaceholder doesn't persist changes, and a later network fetch overwrites a local toggle with the server's value.

## Tests

The `alphaTests` target uses **Swift Testing** (`@Test`, `#expect`) with a `MockDataSource`. Each test gets its own store, either a temporary JSON file or an in-memory SwiftData container. The 15 tests are the same as in the SwiftUI version, and they pass unchanged, which confirms the shared layers behave identically under both UI frameworks.

- **`DataService` (10):** item fetching, cache behavior (first fetch from cache, then network, saving, empty-database fallback), and both pin implementations (sorting, skipping a failed step).
- **`ItemDBStore` (5):** empty load, save and load, upsert by unique id, and both branches of `update(item:)`.

## How AI was used

- **Data layer and view model:** rewritten by me from the SwiftUI version, then reviewed by Claude (Anthropic).
- **View controllers and `SceneDelegate` setup:** written by Claude at my request, then reviewed, run, and adjusted by me.
- **Tests:** written entirely by Claude in the SwiftUI version, reused here unchanged.

## Requirements

- Xcode 27
- iOS 27

## Author

Christophe Vichery · [github.com/VichTech](https://github.com/VichTech)
