import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:test/test.dart';

class Repo {
  const Repo();
}

class Editor {
  Editor(
    this.repo, {
    required this.id,
    required this.title,
    required this.draft,
  });

  final Repo repo;
  final int id;
  final String title;
  final bool draft;
}

typedef EditorArgs = ({int id, String title, bool draft});

final class EditorFactory implements AlloyParamFactory<Editor, EditorArgs> {
  const EditorFactory();

  @override
  Editor create(AlloyResolver resolver, EditorArgs args) => Editor(
    resolver.get<Repo>(),
    id: args.id,
    title: args.title,
    draft: args.draft,
  );
}

class Ticket {
  Ticket(this.row, this.seat);

  final int row;
  final String seat;
}

final class TicketFactory implements AlloyParamFactory<Ticket, (int, String)> {
  const TicketFactory();

  @override
  Ticket create(AlloyResolver resolver, (int, String) args) =>
      Ticket(args.$1, args.$2);
}

void main() {
  /// `registerParamFactory` takes one parameter, and a record is how several
  /// become one. The named form matters more than it looks: production graphs
  /// hand these factories four, five, ten runtime values, and a positional
  /// record would be less readable than the constructor it replaced.
  group('a record as the runtime argument', () {
    test('a named record keeps the names, at both ends', () {
      final scope = alloyTestRoot(name: 'app')
        ..registerSingleton<Repo>(const Repo())
        ..registerParamFactory<Editor, EditorArgs>(const EditorFactory());

      final editor = scope.getWithParam<Editor, EditorArgs>((
        id: 42,
        title: 'card',
        draft: true,
      ));

      expect(editor.id, 42);
      expect(editor.title, 'card');
      expect(editor.draft, isTrue);
      expect(
        editor.repo,
        isA<Repo>(),
        reason:
            'dependencies still come from the resolver; only the values '
            'the container cannot know travel in the record',
      );
    });

    test('a positional record works too', () {
      final scope = alloyTestRoot(name: 'app')
        ..registerParamFactory<Ticket, (int, String)>(const TicketFactory());

      final ticket = scope.getWithParam<Ticket, (int, String)>((7, 'B'));

      expect(ticket.row, 7);
      expect(ticket.seat, 'B');
    });

    test('the wrong record shape is refused by the type check', () {
      final scope = alloyTestRoot(name: 'app')
        ..registerParamFactory<Ticket, (int, String)>(const TicketFactory());

      expect(
        () => scope.getWithParam<Ticket, Object>('not a pair'),
        throwsA(
          isA<AlloyParamTypeError>().having(
            (error) => error.expected.toString(),
            'expected',
            '(int, String)',
          ),
        ),
      );
    });
  });
}
