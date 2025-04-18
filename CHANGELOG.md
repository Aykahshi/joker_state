### 2.0.2
* Update example usage in README

### 2.0.1
* Update README

## 2.0.0

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

## 1.2.2
* fix Circus.ringMaster cannot find correct CueMaster error

## 1.2.1
* Update README.md

## 1.2.0
* CueGate(Debouncer/throttler) added
* CueGateMixin for StatefulWidget

## 1.1.1
* fix lint warning
* remove useless test case

## 1.1.0+2
* adjusting key condition way in CircusRing

## 1.1.0+1

* make Circus.ringMaster() can be use with CustomCueMaster

## 1.1.0

* RingCueMaster(event bus) support
* JokerTrap(auto-dispose controllers) support
* JokerReveal(conditional display) support
* Update README
* Add Example for RingCueMaster

## 1.0.3

* make JokerPortal/JokerCast can be link to Joker by tag

## 1.0.2+2

* fix export missing

## 1.0.2+1

* fix lint warning

## 1.0.1

* feat: add fenix support to CircusRing
* Add examples/tests

## 1.0.0

* Initial release
* Joker, JokerCast, JokerFrame, JokerListener, JokerPortal, JokerStage, JokerTroupe (State
  Management)
* CircusRing (Dependency Injection)