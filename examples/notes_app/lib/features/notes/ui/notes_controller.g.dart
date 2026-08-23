// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_controller.dart';

// **************************************************************************
// PropertyInjectionGenerator
// **************************************************************************

mixin _$NotesController implements AlloyInjectable {
  set _store(NoteStore value);
  set _log(EventLog value);
  @override
  void onInject(AlloyResolver resolver) {
    _store = resolver.get<NoteStore>();
    _log = resolver.get<EventLog>();
  }
}
