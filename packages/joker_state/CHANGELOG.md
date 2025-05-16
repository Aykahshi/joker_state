## [4.0.0]

**BREAKING CHANGES**

* `Joker` is now a simple, locally reactive state container with auto-dispose capabilities, for complex state management, consider using a `Presenter`.
* `CircusRing` is now a standalone package. While still usable in JokerState, it no longer provides Joker-specific integrations. Please use the [circus_ring](https://pub.dev/packages/circus_ring) package.
* RingCueMaster now leverages `rx_dart`, offering a superior Event bus system.
* The constructors for `JokerStage` and `JokerFrame` are now private. Please use the `perform` and `focusOn` APIs.
* `Presenter` has been completely refactored. It is now based on `BehaviorSubject` instead of `ChangeNotifier`, providing more flexible state management and better performance.
* `JokerPortal` and `JokerCast` are deprecated. Please use the CircusRing API combined with `Presenter` for context-free state management.
* `JokerReveal` is deprecated. Please use native Dart language features for conditional rendering.
* `JokerTrap` is deprecated. Please use the `onDone` method of `Presenter`, or the `dispose` method of `StatefulWidget` to manage controllers.

## [3.1.1]
* Fix RingCueMaster regirestration issue

## [3.1.0]
* Missing export for new Presenter features.

## [3.0.0]

**BREAKING CHANGES**

*   **`CircusRing` Disposal Logic for `Joker`/`Presenter`**: 
    *   `CircusRing` methods (`fire`, `fireByTag`, `fireAll`, `fireAsync`) now **actively manage the disposal** of removed `Joker` and `Presenter` instances.
    *   When a `Joker` or `Presenter` is removed via these methods, `CircusRing` will now call its `dispose()` method **UNLESS** the instance's `keepAlive` property is set to `true`.
    *   This is a significant change from v2.x where `CircusRing` *never* initiated the disposal of `Joker` instances (lifecycle was purely self-managed by Joker based on listeners).
    *   Ensure your application logic correctly handles this new disposal behavior, especially for instances previously expected to persist after being removed from `CircusRing` without `keepAlive: true`.

**New Features**

*   **Added `Presenter<T>` Class**: Introduced an abstract class `Presenter<T>` extending `Joker<T>`. It provides a standard lifecycle (`onInit`, `onReady`, `onDone`) suitable for controllers or presenters in Flutter applications, integrating state management with lifecycle events.
*   **Added `Presenter` Extensions**: Added extension methods `.perform()` and `.focusOn()` to simplify using `Presenter` instances with `JokerStage` and `JokerFrame` widgets respectively.

## [2.1.1]

* fix CHANGELOG.md typo

## [2.1.0]

**BREAKING CHANGES**

*   **CircusRing Disposal**: Major changes to how resources are disposed.
    *   `Circus.fireAll()` is now asynchronous (`Future<void>`) and handles both synchronous (`Disposable`, `ChangeNotifier`) and asynchronous (`AsyncDisposable`) disposal for non-Joker instances. Update calls to `await Circus.fireAll()`.
    *   `Circus.fireAllAsync()` has been removed. Use `await Circus.fireAll()` instead.
    *   `Circus.fire()` and `Circus.fireByTag()` now throw a `CircusRingException` if attempting to synchronously dispose an `AsyncDisposable` instance. Use `fireAsync()` or `fireAsyncByTag()` for these cases.
    *   `Circus.dispose()` is now asynchronous (`Future<void>`) due to the changes in `fireAll()`. Update calls to `await Circus.dispose()`.
*   **Tests Updated**: Tests related to CircusRing disposal (`circus_ring_test.dart`, `circus_ring_reactive_test.dart`, examples) have been updated to reflect the new asynchronous `fireAll` and removal of `fireAllAsync`.
*   **Documentation Updated**: README files (`README-di-*.md`) and documentation comments updated for `fireAll`, `fireAllAsync`, `fire`, `fireByTag`, and `dispose` methods.

## [2.0.3]

* Major update: All README files (Chinese and English) have been rewritten for a more conversational, developer-friendly tone.
* Documentation is now easier to read, with clearer explanations and practical examples.
* No breaking changes; all APIs and features remain the same.

## [2.0.2]

* Update example usage in README

## [2.0.1]

* Update README

## [2.0.0]

**BREAKING CHANGES**

*   **Joker Lifecycle**: 
    *   Removed `autoDispose` parameter from `Joker`, `JokerStage`, `JokerFrame`, and `JokerTroupe`.
    *   Added `keepAlive` parameter to `Joker` (default: `false`). Joker instances now automatically schedule disposal via `Future.microtask` when they have no listeners **unless** `keepAlive` is `true`.
    *   Adding a listener cancels the scheduled disposal.
*   **CircusRing Disposal**: 
    *   `CircusRing` methods (`fire`, `fireByTag`, `fireAll`, `fireAsync`, `fireAllAsync`, internal `_deleteSingle*`) now perform **conditional disposal**. They only dispose non-Joker instances that implement `Disposable`, `AsyncDisposable`, or `ChangeNotifier`.
    *   `CircusRing` **no longer automatically disposes `Joker` instances** upon removal (e.g., via `Circus.vanish`). Joker lifecycle is self-managed based on listeners and `keepAlive`.
*   **Tests Updated**: Tests related to Joker lifecycle and CircusRing disposal have been updated to reflect the new behavior.
*   **Documentation**: README files updated to reflect lifecycle and disposal changes.
*   Fixed dependency check logic in `CircusRing.fire` and `CircusRing.fireByTag` to correctly use the `_dependents` map.
*   Improved documentation in `JokerPortal` regarding the necessity of using `tag` when dealing with common types.

## [1.2.2]
* fix Circus.ringMaster cannot find correct CueMaster error

## [1.2.1]
* Update README.md

## [1.2.0]
* CueGate(Debouncer/throttler) added
* CueGateMixin for StatefulWidget

## [1.1.1]
* fix lint warning
* remove useless test case

## [1.1.0+2]
* adjusting key condition way in CircusRing

## [1.1.0+1]

* make Circus.ringMaster() can be use with CustomCueMaster

## [1.1.0]

* RingCueMaster(event bus) support
* JokerTrap(auto-dispose controllers) support
* JokerReveal(conditional display) support
* Update README
* Add Example for RingCueMaster

## [1.0.3]

* make JokerPortal/JokerCast can be link to Joker by tag

## [1.0.2+2]

* fix export missing

## [1.0.2+1]

* fix lint warning

## [1.0.1]

* feat: add fenix support to CircusRing
* Add examples/tests

## [1.0.0]

* Initial release
* Joker, JokerCast, JokerFrame, JokerListener, JokerPortal, JokerStage, JokerTroupe (State
  Management)
* CircusRing (Dependency Injection)