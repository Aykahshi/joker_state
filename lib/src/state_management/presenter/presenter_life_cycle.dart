import 'package:flutter/foundation.dart';

mixin PresenterLifeCycle {
  @protected
  @mustCallSuper
  void onInit() {}

  @protected
  @mustCallSuper
  void onReady() {}

  @protected
  @mustCallSuper
  void onDone() {}
}
