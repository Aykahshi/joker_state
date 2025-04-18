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