// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$HomeStore on _HomeStore, Store {
  late final _$upcomingAtom =
      Atom(name: '_HomeStore.upcoming', context: context);

  @override
  ViewState<UpcomingMeal> get upcoming {
    _$upcomingAtom.reportRead();
    return super.upcoming;
  }

  @override
  set upcoming(ViewState<UpcomingMeal> value) {
    _$upcomingAtom.reportWrite(value, super.upcoming, () {
      super.upcoming = value;
    });
  }

  late final _$loadAsyncAction =
      AsyncAction('_HomeStore.load', context: context);

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  @override
  String toString() {
    return '''
upcoming: ${upcoming}
    ''';
  }
}
