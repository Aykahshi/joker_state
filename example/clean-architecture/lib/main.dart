// import 'package:flutter/material.dart';
// import 'package:joker_state/joker_state.dart';

// import 'data/repository/counter_repository_impl.dart';
// import 'domain/entity/counter.dart';
// import 'domain/repository/counter_repository.dart';
// import 'domain/usecase/get_counter_use_case.dart';
// import 'domain/usecase/increment_counter_use_case.dart';
// import 'presentation/page/counter_page.dart';
// import 'presentation/presenter/counter_presenter.dart';

// void main() {
//   // Configure CircusRing dependencies before running the app.
//   _setupDependencies();

//   // Run the Flutter application.
//   runApp(const MyApp());
// }

// // Sets up dependency injection using CircusRing.
// void _setupDependencies() {
//   // Register a dummy logger instance (replace with a real logger if needed)
//   Circus.hire<Logger>(Logger());

//   // Register repository implementation (singleton).
//   Circus.hire<CounterRepository>(CounterRepositoryImpl());

//   // Register use cases (factories or singletons depending on need).
//   // Here using factories as they are simple.
//   Circus.contract<GetCounterUseCase>(
//     () => GetCounterUseCase(Circus.find<CounterRepository>()),
//   );
//   Circus.contract<IncrementCounterUseCase>(
//     () => IncrementCounterUseCase(Circus.find<CounterRepository>()),
//   );

//   // Explicitly initialize the default RingCueMaster to ensure it's ready.
//   // While cue() and onCue() extensions can lazy-init, explicit init is safer.
//   Circus.ringMaster();

//   // Register the state holder Joker<Counter> using summon.
//   // Use the tag defined in counter_presenter.dart.
//   Circus.summon<Counter>(
//     const Counter(value: 0), // Initial state
//     tag: COUNTER_JOKER_TAG,
//   );

//   // Register the CounterPresenter.
//   // It depends on UseCases and the Joker<Counter> we just registered.
//   Circus.hireLazily<CounterPresenter>(
//     () => CounterPresenter(
//       Circus.find<GetCounterUseCase>(),
//       Circus.find<IncrementCounterUseCase>(),
//       Circus.spotlight<Counter>(tag: COUNTER_JOKER_TAG), // Find the Joker state
//     ),
//     fenix: true, // Example: automatically re-register if disposed
//   );
// }

// // The root widget of the application.
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'JokerState Clean Arch Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.deepPurple,
//         useMaterial3: true, // Optional: Enable Material 3
//       ),
//       home: const CounterPage(),
//       // Example of using JokerPortal if needed higher up:
//       // home: JokerPortal<Counter>(
//       //   joker: Circus.spotlight<Counter>(tag: CounterJoker.JOKER_TAG),
//       //   tag: CounterJoker.JOKER_TAG,
//       //   child: const CounterPage(),
//       // ),
//     );
//   }
// }
