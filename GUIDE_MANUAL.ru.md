<p align="center">
  <a href="GUIDE_MANUAL.md">English</a> · <a href="GUIDE_MANUAL.ru.md">Русский</a> · <a href="GUIDE_MANUAL.zh-CN.md">中文</a>
</p>

> Перевод [GUIDE_MANUAL.md](GUIDE_MANUAL.md). Канонический текст — английский: при расхождении верен он.

# Manual Mode

Alloy без кодогенерации: ни аннотаций, ни `build_runner`, ничего не генерируется и нечего коммитить.
Регистрации пишете вы, а рантайм — тот же самый, под который пишет генератор.

Это фреймворк целиком, а не его урезанная версия. Всё, что эмитит генератор, выражено в терминах
того, что описано в этом документе, — таков стоящий инвариант проекта: в тот момент, когда генерации
понадобится что-то, чего не выражает Manual Mode, это два фреймворка под одним именем.

Берите этот режим, когда постепенно мигрируете существующий контейнер, когда граф достаточно мал,
чтобы шаг сборки не окупался, или когда вы в пакете, куда шаг сборки не добавить вовсе. Когда
захочется, чтобы граф проверялся на сборке, а не в рантайме, — читайте
[GUIDE_CODEGEN.ru.md](GUIDE_CODEGEN.ru.md): оба режима композируются в одном графе, так что это не
решение, в котором вы застреваете.

---

## Содержание

1. [Установка](#1-установка)
2. [Первый граф](#2-первый-граф)
3. [Регистрация и чтение](#3-регистрация-и-чтение)
4. [Запуск Flutter-приложения](#4-запуск-flutter-приложения)
5. [Чтение из графа в виджете](#5-чтение-из-графа-в-виджете)
6. [Скоупы, которые кончаются раньше приложения](#6-скоупы-которые-кончаются-раньше-приложения)
7. [Как закрывается то, что вы зарегистрировали](#7-как-закрывается-то-что-вы-зарегистрировали)
8. [Работа, которая обязана завершиться до старта](#8-работа-которая-обязана-завершиться-до-старта)
9. [Значения, приходящие с места вызова](#9-значения-приходящие-с-места-вызова)
10. [Опциональные зависимости](#10-опциональные-зависимости)
11. [Один граф, несколько сборок](#11-один-граф-несколько-сборок)
12. [Наблюдение за графом](#12-наблюдение-за-графом)
13. [Тесты](#13-тесты)
14. [Ошибки, о которых стоит знать заранее](#14-ошибки-о-которых-стоит-знать-заранее)
15. [Когда добавлять генератор](#15-когда-добавлять-генератор)

---

## 1. Установка

Для программы на чистом Dart — CLI, сервера, пакета без виджетов — одна зависимость:

```yaml
environment:
  sdk: ^3.13.0

dependencies:
  alloy: ^0.1.0
```

Flutter-приложение добавляет биндинги, которые реэкспортируют весь рантайм, поэтому оба сразу
импортировать не нужно:

```yaml
environment:
  sdk: ^3.13.0
  flutter: ">=3.47.0"

dependencies:
  alloy: ^0.1.0
  alloy_flutter: ^0.1.0

dev_dependencies:
  alloy_test: ^0.1.0
  alloy_test_flutter: ^0.1.0
```

Опционально и только если нужно: `alloy_go_router` — скоуп на навигационный флоу, `alloy_bloc` —
чтобы скоуп умел закрывать блок, `alloy_inspector` — смотреть на граф в работающем приложении, и
один из `alloy_talker` / `alloy_logging` / `alloy_logger` для наблюдаемости.

Ничему здесь не нужны `alloy_generator`, `build_runner` и `alloy_lint` — они принадлежат другому
режиму.

---

## 2. Первый граф

Три части: классы, фабрика на класс и билдер, который их регистрирует.

```dart
import 'package:alloy/alloy.dart';

class Clock {
  DateTime now() => DateTime.now();
}

class EventLog implements Disposable {
  final entries = <String>[];

  void add(String entry) => entries.add(entry);

  @override
  void dispose() => entries.clear();
}
```

**Фабрика** — это объект, а не замыкание. Именно поэтому она может быть `const`, не носить
захваченного состояния и переиспользоваться между всеми запусками графа; замыкание захватило бы то,
что оказалось в области видимости в месте, где вы его написали, — а это и есть тот баг, из-за
которого второй старт переиспользует объекты первого.

```dart
class ClockFactory implements AlloyFactory<Clock> {
  const ClockFactory();

  @override
  Clock create(AlloyResolver resolver) => Clock();
}

class EventLogFactory implements AlloyFactory<EventLog> {
  const EventLogFactory();

  @override
  EventLog create(AlloyResolver resolver) => EventLog();
}
```

Зависимости резолвятся внутри `create`, из переданного резолвера:

```dart
class ReportFactory implements AlloyFactory<Report> {
  const ReportFactory();

  @override
  Report create(AlloyResolver resolver) =>
      Report(resolver.get<Clock>(), resolver.get<EventLog>());
}
```

**Билдер скоупа** говорит, что в скоупе лежит. Он только регистрирует и никогда не резолвит: резолв
во время `build` читал бы граф, который ещё описывается.

```dart
class AppScope implements AlloyScopeBuilder {
  const AppScope();

  @override
  void build(AlloyScope scope) {
    scope
      ..registerLazySingleton<Clock>(const ClockFactory())
      ..registerLazySingleton<EventLog>(const EventLogFactory())
      ..registerLazySingleton<Report>(const ReportFactory());
  }
}

Future<void> main() async {
  final app = await AlloyApplication.start(root: const AppScope(), rootName: 'app');

  app.get<EventLog>().add('запуск в ${app.get<Clock>().now()}');

  await app.dispose();
}
```

Порядок регистраций значения не имеет. `Report` можно зарегистрировать раньше `Clock`: во время
`build` ничего не строится, а к моменту первого резолва существуют все регистрации.

Глобального контейнера нет. `AlloyApplication.start` отдаёт вам корень, ничего не лежит в окружении,
поэтому два графа в одном процессе не связаны, а тесты идут параллельно.

`examples/manual_mode` — это оно же, целиком и запускаемое:

```bash
cd examples/manual_mode && dart run
```

---

## 3. Регистрация и чтение

### Пять способов зарегистрировать

| Вызов | Когда строится | Скоуп удерживает |
|---|---|---|
| `registerSingleton<T>(value)` | уже построено вами | да |
| `registerLazySingleton<T>(factory)` | при первом резолве | да |
| `registerAsyncSingleton<T>(factory)` | в `init()`, в порядке зависимостей | да |
| `registerFactory<T>(factory)` | на каждый резолв | нет |
| `registerParamFactory<T, P>(factory)` | на каждый резолв, из аргумента | нет |

«Удерживает» — и есть всё различие, и оно решает разбор: скоуп освобождает удержанное, а транзиент
освобождать некому — см. [§7](#7-как-закрывается-то-что-вы-зарегистрировали).

Квалификатор `name` делает вторую регистрацию того же типа законной, потому что ключ — это тип
**и** имя:

```dart
scope
  ..registerLazySingleton<Logger>(const AppLoggerFactory())
  ..registerLazySingleton<Logger>(const AuditLoggerFactory(), name: 'audit');
```

Один и тот же ключ дважды в одном скоупе — исключение. Затенение его из дочернего скоупа —
нет: это штатный способ подменить что-либо, и в тестах, и в продакшене.

### Пять способов прочитать

```dart
scope.get<Repository>();                       // бросает, если ничего не зарегистрировано
scope.getOrNull<Telemetry>();                  // вместо этого null — см. §10
scope.get<Logger>(name: 'audit');              // именованная регистрация
scope.getAll<NoteFormatter>();                 // все регистрации типа, ближний скоуп первым
scope.getWithParam<Counter, String>('alice');  // параметризованная
```

`isRegistered<T>()` отвечает, ничего не строя.

Резолв идёт вверх: этот скоуп, затем родитель, и так до корня. `getAll` собирает по всей цепочке,
ближние первыми, и затенённый ключ берёт ровно один раз — из ближайшего скоупа, где он есть.

### Как посмотреть, что в скоупе лежит

Диагностика, и ничего из этого ничего не строит:

```dart
scope.keys;                  // свои регистрации, в порядке регистрации
scope.visibleKeys;           // они же плюс унаследованные, с указанием скоупа-владельца
scope.root;                  // вершина дерева
scope.debugDescribeTree();   // дерево текстом
```

`visibleKeys` — карта, а не множество, по причине, которую стоит усвоить сразу: фабрика выполняется
на скоупе, которому принадлежит **её собственная** регистрация, а не на том, у которого вы спросили.
Знание владельца ключа и говорит, будет ли подмена видна, — см. [§13](#13-тесты).

---

## 4. Запуск Flutter-приложения

Корнем владеет `AlloyAppScope`: строит граф, публикует его в дерево, разбирает при размонтировании и
превращает упавший старт в экран с повтором вместо приложения, которое умерло до первого кадра.

Ставьте его в `MaterialApp.builder`, а не над `MaterialApp`. Там он оказывается ниже `Theme`,
`Directionality` и `Localizations`, поэтому `loading` и `errorBuilder` — обычные экраны, а не второй
`MaterialApp`:

```dart
void main() => runApp(
  MaterialApp(
    theme: appTheme,
    builder: AlloyAppScope.builder(
      root: const AppScope(),
      bootstrap: () => [const BindPlatform()],
      rootName: 'app',
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
      errorBuilder: (context, error, retry) => StartupFailed(error: error, retry: retry),
    ),
    home: const HomeScreen(),
  ),
);
```

`bootstrap` — функция, а не список, и это принципиально: шаги держат ресурсы, и рестарт обязан
получить новые. Хранимый список молча отдал бы второму старту те же объекты.

`AlloyAppScope.of(context).restart()` пересобирает граф — тот же вызов повторяет упавший старт.

Если у приложения уже есть свой `builder`, композируйте сами, а не ждите, что фреймворк сольёт два:

```dart
builder: (context, child) => AlloyAppScope(
  root: const AppScope(),
  child: myWrapper(child!),
),
```

---

## 5. Чтение из графа в виджете

```dart
final repository = context.alloy<Repository>();
final formatters = context.alloyAll<NoteFormatter>();
final counter = context.alloyWithParam<Counter, String>('alice');
final scope = context.alloyScope;
```

Каждый резолвит из **ближайшего** скоупа над виджетом и дальше идёт вверх, поэтому регистрация во
флоу или сессионном скоупе затеняет корневую для всего, что внутри.

Об одном стоит знать до того, как оно случится: `Navigator.push` строит новый маршрут из контекста
навигатора, а не из виджета, который его толкнул. Экран, прекрасно резолвящий на своём месте,
бросит `AlloyNoScopeError`, если тот же виджет открыть пушем, а провайдер, из которого он читал,
живёт **внутри** толкающего экрана. Передавайте скоуп явно или пушьте ниже провайдера.

---

## 6. Скоупы, которые кончаются раньше приложения

Ради этого фреймворк и написан. Скоуп — узел дерева, он владеет тем, что построил, и его разбор
уносит с собой всё, что ниже.

### Сессия

```dart
class SessionManager {
  SessionManager(this._root);

  final AlloyScope _root;
  AlloyScope? _session;

  Future<void> signIn(User user) async {
    _session = _root.push('session:${user.id}')
      ..registerLazySingleton<Draft>(const DraftFactory())
      ..registerLazySingleton<SyncQueue>(const SyncQueueFactory());
    await _session!.init();
  }

  Future<void> signOut() async {
    await _session?.dispose();
    _session = null;
  }
}
```

Логаут — это `await scope.dispose()`. Ни один репозиторий не подписывается на сессионный стрим, и ни
один доменный интерфейс не обрастает методом `reset()`, которого он не хотел.

`push` отдаёт ребёнка сразу, `init()` строит его async-регистрации. Зовите `init()` даже когда их
нет: он дёшев, идемпотентен, и тогда добавление async-регистрации позже не меняет место вызова.

### Экран

```dart
AlloyScopeWidget(
  name: 'editor',
  builder: const EditorScope(),
  child: const EditorBody(),
)
```

Создаётся при монтировании, разбирается при размонтировании. Учтите: скоуп публикуется только после
`init()`, поэтому даже полностью синхронный граф даёт один кадр `loading`.

### Навигационный флоу

С `alloy_go_router` время жизни задаёт флоу, а не виджет, который вы не забыли поставить:

```dart
class OrderFlowRoute extends AlloyShellRoute {
  OrderFlowRoute()
    : super(
        name: 'order',
        identity: _orderId,
        scope: (state) => OrderFlowScope(_orderId(state)),
        routes: [
          GoRoute(
            path: '/orders/:orderId/summary',
            builder: (_, state) => OrderSummaryScreen(orderId: _orderId(state)),
          ),
          GoRoute(
            path: '/orders/:orderId/payment',
            builder: (_, state) => OrderPaymentScreen(orderId: _orderId(state)),
          ),
        ],
      );

  static String _orderId(GoRouterState state) => state.pathParameters['orderId']!;
}

class OrderFlowScope implements AlloyScopeBuilder {
  const OrderFlowScope(this.orderId);

  final String orderId;

  @override
  void build(AlloyScope scope) =>
      scope.registerLazySingleton<OrderDraft>(OrderDraftFactory(orderId));
}
```

Обратите внимание: `OrderDraftFactory` здесь не `const` — она несёт id заказа. Фабрика, принимающая
конфигурацию, — это нормально; чего ей нельзя, так это захватывать окружающий граф.

Навигация между `summary` и `payment` сохраняет один скоуп. Выход из флоу его разбирает. `identity`
отвечает на единственный вопрос, который роутер решить не может: одно ли это флоу — `/orders/1` и
`/orders/2`.

Таблицу роутов стройте **один раз**, вместе с роутером. Новый экземпляр `AlloyShellRoute` — это
другой флоу с точки зрения go_router, поэтому пересборка списка на каждом кадре разбирала бы скоуп
на каждом кадре.

Вкладки устроены так же — `AlloyStatefulShellRoute` и `AlloyStatefulShellBranch`, — с одной
особенностью, которую стоит назвать прямо: ветка держится **живой**, а не **видимой**. go_router
сохраняет навигаторы веток за экраном, поэтому скоуп вкладки живёт до закрытия шелла, а не до
переключения с неё.

---

## 7. Как закрывается то, что вы зарегистрировали

Скоуп освобождает удержанное в обратном порядке **создания**, а не объявления. Именно это различие —
баг рукописных контейнеров: компонент, объявленный первым, но созданный последним, умирает первым,
пока от него ещё кто-то зависит.

В Dart нет структурной типизации, поэтому совпадающего метода `dispose()` самого по себе
недостаточно. Скажите, какой это интерфейс:

```dart
class Cache implements Disposable {
  @override
  void dispose() { ... }
}

class Database implements AsyncDisposable {
  @override
  Future<void> dispose() async { ... }
}
```

Для типа, который вам не изменить — из SDK, из чужого пакета, за базовым классом, — назовите
teardown прямо в регистрации:

```dart
scope.registerLazySingleton<http.Client>(
  const ClientFactory(),
  dispose: (client) => client.close(),
);

scope.registerAsyncSingleton<Isar>(
  const IsarFactory(),
  dispose: (isar) => isar.close(),
);
```

`dispose:` есть только у регистраций, которые скоуп удерживает. У `registerFactory` и
`registerParamFactory` его нет: транзиент закрывать не скоупу — случай сделан невыразимым по
построению, а не проверяемым в рантайме. Если транзиент чем-то владеет, то владеет им и его
потребитель.

### Flutter-типы, которые выглядят закрываемыми и не являются

`ChangeNotifier.dispose` совпадает с `Disposable.dispose` дословно — и всё равно скоупу невидим,
потому что Dart сопоставляет интерфейсы по имени, а не по форме. Скажите об этом:

```dart
class Filters extends ChangeNotifier implements Disposable {}
```

Для блоков `alloy_bloc` — это одна строка:

```dart
class CounterCubit extends Cubit<int> with AlloyBloc {
  CounterCubit() : super(0);
}
```

или, где миксин не достанет, `dispose: closeBloc` в регистрации.

Дальше отдавайте блок в дерево виджетов через `BlocProvider.value` и никогда через
`BlocProvider(create:)`: второй закрывает то, что ему передали, при размонтировании, тогда как скоуп
всё ещё держит объект и на следующем резолве отдаст мёртвый.

### Когда разбор идёт не так

Он best-effort по замыслу. Упавший шаг записывается, остальные всё равно выполняются; у всего дерева
один дедлайн; скоуп всегда доходит до `disposed`. Несделанное перечисляется в `AlloyDisposeError` —
`failures`, `timeouts`, `hasTimeout` — вместо того, чтобы первая ошибка спрятала остальные девять.

`adopt` привязывает к жизни скоупа объект, не являющийся зависимостью, — подписку или таймер,
который никто не резолвит:

```dart
scope.adopt(subscription, dispose: (it) => it.cancel());
```

---

## 8. Работа, которая обязана завершиться до старта

Две фазы, отвечают на разные вопросы.

**Фаза 0 — bootstrap-шаги.** До того, как контейнер существует: платформенные биндинги, удалённый
конфиг, всё, что нужно самому графу. Шаги идут строго в том порядке, в каком перечислены, и не могут
ничего инъектировать — инъектировать пока неоткуда.

```dart
class BindPlatform implements AlloyBootstrapStep {
  const BindPlatform();

  @override
  String get name => 'bind-platform';

  @override
  Future<void> run() async => WidgetsFlutterBinding.ensureInitialized();
}

final app = await AlloyApplication.start(
  root: const AppScope(),
  bootstrap: const [BindPlatform(), LoadRemoteConfig()],
  rootName: 'app',
);
```

Отработав, шаги усыновляются корневым скоупом: шаг, который что-то открыл, закрывается вместе с ним
— последним, после всего, что построено поверх. Если шаг падает, уже отработавшие освобождаются в
обратном порядке до того, как ошибка будет переброшена: скоупа, которому их можно передать, ещё нет.

**Фаза 1 — асинхронные синглтоны.** Внутри контейнера, в порядке зависимостей:

```dart
class DatabaseFactory implements AlloyAsyncFactory<Database> {
  const DatabaseFactory();

  @override
  Future<Database> create(AlloyResolver resolver) async {
    final database = Database(resolver.get<Config>());
    await database.open();
    return database;
  }
}

scope
  ..registerAsyncSingleton<Database>(const DatabaseFactory())
  ..registerAsyncSingleton<SearchIndex>(
    const SearchIndexFactory(),
    dependsOn: {AlloyKey(Database)},
  );
```

`dependsOn` — ребро порядка, а не инъекция: `Database` вы всё равно резолвите внутри
`SearchIndexFactory.create`. Независимые инициализаторы одного уровня едут вместе через
`Future.wait`; ждёт только тот, кто действительно зависит. Цикл бросает `AlloyCycleError` с путём, а
не подвисает.

Указание ключа, который зарегистрирован, но **не** async, — ошибка, а не no-op: ждать нечего.
Указание того, что async в **предке**, разрешено и игнорируется: предок отработал свою фазу 1 ещё до
того, как этот скоуп появился.

`AlloyApplication.start` возвращается, когда обе фазы закончены, поэтому нет ни `allReady()`, ни
состояния «зарегистрировано, но не готово».

Async-регистрации обязаны существовать до `init()`. Он берёт те, что находит на старте, и
отрабатывает один раз, поэтому регистрация ещё одной в уже активный скоуп — ошибка, а не что-то, что
молча никогда не построится. Поднимите дочерний скоуп и инициализируйте его.

---

## 9. Значения, приходящие с места вызова

Половина объекта приходит из графа, половина — от того, кто его строит:

```dart
class CounterFactory implements AlloyParamFactory<Counter, String> {
  const CounterFactory();

  @override
  Counter create(AlloyResolver resolver, String sessionId) =>
      Counter(resolver.get<CounterStorage>(), sessionId);
}

scope.registerParamFactory<Counter, String>(const CounterFactory());

final counter = scope.getWithParam<Counter, String>('alice');
```

Параметр один. Если нужно больше, складывайте их в запись — именованную, чтобы место вызова
осталось читаемым:

```dart
typedef EditorArgs = ({int id, String title, bool draft});

class EditorFactory implements AlloyParamFactory<Editor, EditorArgs> {
  const EditorFactory();

  @override
  Editor create(AlloyResolver resolver, EditorArgs args) =>
      Editor(resolver.get<Notes>(), id: args.id, title: args.title, draft: args.draft);
}

scope.getWithParam<Editor, EditorArgs>((id: 7, title: 'draft', draft: true));
```

Тип параметра проверяется на вызове, а не внутри вашей фабрики: неверный тип даёт
`AlloyParamTypeError` с ключом, ожидаемым типом и тем, что пришло. Законный подтип принимается,
потому что проверяется значение, а не литерал типа.

Резолв параметризованной регистрации обычным `get<T>()` бросает `AlloyParamRequiredError` —
аргументу неоткуда взяться.

---

## 10. Опциональные зависимости

```dart
class ReportFactory implements AlloyFactory<Report> {
  const ReportFactory();

  @override
  Report create(AlloyResolver resolver) =>
      Report(resolver.get<Clock>(), resolver.getOrNull<Telemetry>());
}
```

`getOrNull` отдаёт null только на «не зарегистрировано». Async-синглтон, спрошенный до `init()`,
по-прежнему бросает, и параметризованная регистрация без аргумента — тоже: «не готово» и «нет вовсе»
разные факты, и схлопывание их превращает ошибку порядка старта в значение, которое читается как
отсутствие.

---

## 11. Один граф, несколько сборок

Пропустите это, пока одной сборке действительно не понадобится другая реализация, чем другой. До тех
пор у вашего графа ровно одно окружение, и ничего отсюда не применяется.

`AlloyEnvironment.matches` — обычный публичный API, поэтому выбор — это `if`:

```dart
class AppScope implements AlloyScopeBuilder {
  const AppScope(this.environment);

  final AlloyEnvironment environment;

  @override
  void build(AlloyScope scope) {
    scope.registerLazySingleton<EventLog>(const EventLogFactory());

    if (environment.matches(const {'dev', 'test'})) {
      scope.registerLazySingleton<ApiClient>(const FakeApiClientFactory());
    }
    if (environment.matches(const {'prod', 'stage'})) {
      scope.registerLazySingleton<ApiClient>(const LiveApiClientFactory());
    }
  }
}
```

`dev`, `stage`, `prod` и `test` — константы, а не закрытое множество: `AlloyEnvironment('canary')`
ведёт себя точно так же. Наследуйте класс и переопределяйте `matches`, чтобы активировать несколько
сразу или сопоставлять не по имени.

Эти ветки здесь никто за вас не проверяет. Два `if`, оба истинные, регистрируют один ключ дважды и
бросают на старте; два ложных оставляют тип незарегистрированным, и первый резолв падает, сообщая
об этом. Это и есть размен данного режима — другой отвергает оба случая на сборке.

---

## 12. Наблюдение за графом

Наблюдатели видят появление скоупов, построение инстансов, завершение старта, падение разбора.
Передавайте их туда, где создаётся граф; каждый скоуп, поднятый ниже, их наследует.

```dart
final app = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyLogObserver(const AlloyPrintLogSink())],
);
```

`AlloyPrintLogSink` пишет в stdout — правильный дефолт вне приложения; `AlloyDeveloperLogSink`
(`dart:developer`) — тот, что для Flutter-приложения. `push(name, observers: [...])` добавляет
наблюдателей одному поддереву.

В колбэки приходят `AlloyScopeRef` и `AlloyKey` — описатели, а не живые объекты, — и исключение из
колбэка проглатывается: наблюдение не должно ломать наблюдаемое. Резолв не логируется: попадание в
кэш — горячий путь, а видеть стоит **построение** инстанса.

### Куда это отправить

| Пакет | Форма |
|---|---|
| `alloy_talker` | наблюдатель, свой цветной тип лога на семейство событий |
| `alloy_logging` | sink поверх `logging` с dart.dev |
| `alloy_logger` | sink поверх `logger` |

Всё остальное — один колбэк, поэтому ни один логгер не остаётся за бортом из-за отсутствия пакета:

```dart
AlloyLogObserver(AlloyLogSink.from((r) => myLogger.debug(r.message)))
AlloyLogObserver(AlloyLogSink.from((r) => gelf.send(r.toStructured())))
```

Запись — не просто строка: в ней `level`, `scope`, `key`, `error`, `stackTrace` и `kind`, причём
`kind` — значение (`AlloyEventKind.scopeInitFailed`), а не предложение, которое пришлось бы
разбирать.

### Крашрепортинг — другая форма

Отчёт делает полезным не исключение, а то, что граф делал перед этим.

```dart
observers: [
  AlloyErrorObserver(
    AlloyErrorSink.from((report) => Sentry.captureException(
      report.error,
      stackTrace: report.stackTrace,
      withScope: (scope) => scope.setContexts('alloy', report.toStructured()),
    )),
  ),
],
```

След — кольцо из 20 записей, копящееся на всех уровнях, включая поинстансные, которые лог-sink
отбрасывает. Порог — `error`, а не `warning`: упавший разбор действительно означает утечку, но
дёргать платный сервис на каждую заминку — верный способ добиться, чтобы отчёты перестали читать.
Понижается через `reportAt`.

### На экране, пока приложение работает

```dart
final log = AlloyInspectorLog();

// observers: [log]

AlloyInspectorScreen(log: log, scope: context.alloyScope)
```

Три вкладки: живое дерево скоупов с временем жизни каждой регистрации и её владельцем; то, что
действительно построено; и всё, о чём сообщили, — с поиском и паузой. Открытие дерева ничего не
строит: материализовать ленивый синглтон ради показа значило бы изменить то, на что вы пришли
посмотреть.

---

## 13. Тесты

Первое, что надо знать, — это ловушка, а не API. `testWidgets` выполняет своё тело в fake-async
зоне, где `Future.delayed` в инициализаторе не завершается никогда. **Стройте граф в `setUp`**, а
утверждения обо всём графе держите в обычном `test`.

```dart
late AlloyScope scope;

setUp(() async {
  scope = await alloyTestScope(root: const AppScope());
});
```

`alloyTestScope` и `alloyTestRoot` разбираются вместе с тестом — это как раз та часть, которую легко
забыть, а забытая она не падает, а протекает в следующий тест.

### Проверка, что граф полон

**Здесь это важнее, чем где-либо ещё.** Рукописная фабрика резолвит внутри `create`, поэтому
статически не видно, что она попросит: пропущенная регистрация — отказ в рантайме, и всплывёт он на
том экране, который первым до неё дойдёт. Единственная проверка — прогон графа:

```dart
await expectGraphResolves(scope);
```

Он сообщает про каждый ключ, который не смог построить, а не про первый. Он терминален: резолв **и
есть** проверка, поэтому после него каждый ленивый синглтон построен, а порядок разбора другой.
Держите его в отдельном тесте.

Параметризованную регистрацию без значения не зарезолвить, поэтому она попадает в отчёт поимённо
как `unchecked`, а не пропускается молча. Дайте ей образец, чтобы покрыть и её:

```dart
await expectGraphResolves(scope, params: {AlloyKey(Counter): 'alice'});
```

Заводите этот тест с первого дня графа в Manual Mode. Это то, что другой режим получает от
компилятора.

### Подмена

Поднимите дочерний скоуп и зарегистрируйте заново. Затенение — это и есть штатный механизм подмены в
продакшене, поэтому тест пользуется тем же, чем приложение:

```dart
final overrides = scope.pushForTest()
  ..registerSingleton<Clock>(FixedClock(DateTime(2026)));
```

Сработает это или нет, решает одно правило, на которое каждый однажды наступает: **фабрика
выполняется на скоупе, которому принадлежит её собственная регистрация.** Подмена ниже потребителя
ему невидима. `ownerOf<T>()` отвечает раньше, чем тест:

```dart
expect(scope.ownerOf<Greeter>(), same(scope.root));   // зарегистрирован в корне — подменять там
```

### Фикстуры

```dart
final scope = alloyTestRoot()
  ..registerLazySingleton<Clock>(FnFactory((_) => FixedClock(DateTime(2026))))
  ..registerSingleton<Config>(const Config())
  ..registerAsyncSingleton<Db>(AsyncFnFactory((_) async => Db()))
  ..registerParamFactory<Counter, String>(FnParamFactory((_, id) => Counter(id)));

await scope.init();
```

Эти четыре избавляют от класса-фабрики на каждую заглушку. Async-регистрации обязаны существовать
**до** `init()` — поэтому фикстуры кладутся в свежий корень, а не в уже запущенный скоуп.

`DisposeRecorder` — фикстура для утверждений о разборе, с журналом на инстанс, а не общим: скоуп,
разобравшийся после своего теста, не сможет отчитаться в следующий.

```dart
final recorder = DisposeRecorder();
scope.registerLazySingleton<Disposable>(recorder.factory('cache'));
scope.get<Disposable>();

await scope.dispose();
expect(recorder.entries, ['cache']);
```

`CapturingObserver` собирает события для утверждений о том, что граф делал.

### Виджет-тесты

`alloy_test_flutter` несёт два хелпера, у которых очевидное написание — неверное:

```dart
await settle(tester);                    // не pumpAndSettle: он крутится вечно на индикаторе загрузки
final scope = mountedRootScope(tester);  // граф приложения, из-под билдера MaterialApp
```

`examples/testing_patterns` — пакет, весь смысл которого в его каталоге `test/`.

---

## 14. Ошибки, о которых стоит знать заранее

Каждая найдена дорого — в этом репозитории или в приложениях, ради которых он писался.

- **Нет `expectGraphResolves` в наборе.** В этом режиме полноту графа больше не проверяет ничто.
  Пропущенная регистрация уезжает в релиз и падает на экране.
- **Построение графа внутри `testWidgets`.** Fake-async, ничего не завершается, таймаут, которому
  нечего предъявить. `setUp`.
- **Подмена ниже потребителя.** Фабрика выполняется на скоупе-владельце. `ownerOf<T>()` скажет об
  этом раньше, чем ассерт.
- **Фабрика, которая захватывает вместо того, чтобы резолвить.** Читайте зависимости из `resolver`,
  переданного в `create`, а не из переменных в месте, где фабрика написана, — иначе второй старт
  переиспользует объекты первого графа.
- **Резолв внутри `AlloyScopeBuilder.build`.** Он выполняется, пока скоуп ещё описывается.
  Регистрируйте там, резолвьте позже.
- **`bootstrap` как хранимый список**, когда корнем владеет `AlloyAppScope`. Шаги держат ресурсы;
  рестарт обязан получить новые. Передавайте функцию.
- **`BlocProvider(create:)` для блока, которым владеет скоуп.** Два владельца, и виджет успевает
  первым. `BlocProvider.value`.
- **`ChangeNotifier` или `Cubit`, зарегистрированный без объявления закрываемости.** Построен,
  использован, никогда не закрыт, молча. `implements Disposable`, `with AlloyBloc` или `dispose:`.
- **Старый `dart` первым в PATH.** Ломается негромко и не там. Проверяйте `dart --version`, прежде
  чем верить прогону.

---

## 15. Когда добавлять генератор

Ничего из написанного выбрасывать не придётся. Сгенерированный контейнер — такой же
`AlloyScopeBuilder`, как те, что выше, поэтому он композируется с уже написанным:

```dart
class AppScope implements AlloyScopeBuilder {
  const AppScope();

  @override
  void build(AlloyScope scope) {
    $AlloyRootScope().build(scope);          // то, что нашёл генератор
    scope.registerSingleton<Config>(config); // то, о чём он знать не может
  }
}
```

Три вещи окупают шаг сборки, когда граф разрастается:

- **полнота, проверенная на сборке**, а не через `expectGraphResolves` на тестах;
- **property injection**, опустошающий конструкторы, доросшие до пяти и более зависимостей;
- **двенадцать правил линтера**, ловящих ошибки из §14 прямо в редакторе.

Что остаётся ровно как есть: скоупы, разбор, две фазы, параметризованные регистрации,
наблюдаемость, тесты. [GUIDE_CODEGEN.ru.md](GUIDE_CODEGEN.ru.md) продолжает отсюда, а
[MIGRATION.ru.md](MIGRATION.ru.md) — про приход с `get_it` или `injectable`.
