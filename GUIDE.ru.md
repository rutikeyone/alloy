[English](GUIDE.md) · [Русский](GUIDE.ru.md) · [中文](GUIDE.zh-CN.md)

> Перевод [GUIDE.md](GUIDE.md). Канонический текст — английский: при расхождении верен он.

# Alloy на практике

Всё, что здесь показано, — рабочие формы, снятые с пакетов в `examples/`, а не написанные под текст.
[README.ru.md](README.ru.md) отвечает, что такое Alloy и почему он устроен так; этот документ — как
им пользоваться, в том порядке, в каком вы встречаете каждую часть.

Пришли с `get_it` или `injectable`? Сначала прочтите [MIGRATION.ru.md](MIGRATION.ru.md) — там
знакомый API переведён на этот и, что полезнее, названо то, что не переводится.

---

## Содержание

1. [Установка](#1-установка)
2. [Граф, написанный руками](#2-граф-написанный-руками)
3. [Тот же граф, сгенерированный](#3-тот-же-граф-сгенерированный)
4. [Запуск Flutter-приложения](#4-запуск-flutter-приложения)
5. [Чтение из графа в виджете](#5-чтение-из-графа-в-виджете)
6. [Скоупы, которые кончаются раньше приложения](#6-скоупы-которые-кончаются-раньше-приложения)
7. [Как закрывается то, что вы зарегистрировали](#7-как-закрывается-то-что-вы-зарегистрировали)
8. [Работа, которая обязана завершиться до старта](#8-работа-которая-обязана-завершиться-до-старта)
9. [Значения, приходящие с места вызова](#9-значения-приходящие-с-места-вызова)
10. [Типы, которые написали не вы](#10-типы-которые-написали-не-вы)
11. [Один граф, несколько сборок](#11-один-граф-несколько-сборок)
12. [Наблюдение за графом](#12-наблюдение-за-графом)
13. [Тесты](#13-тесты)
14. [Плагин линтера](#14-плагин-линтера)
15. [Ошибки, о которых стоит знать заранее](#15-ошибки-о-которых-стоит-знать-заранее)

---

## 1. Установка

Добавляйте только то, чем пользуетесь. Рантайм — чистый Dart, ничего ниже него не тянет Flutter.

| Что нужно | Что добавить |
|---|---|
| контейнер, руками, в любой Dart-программе | `alloy` |
| виджеты, `context.alloy<T>()`, корень во владении приложения | `alloy_flutter` |
| аннотации и сгенерированный контейнер | `alloy_generator` (dev), `build_runner` (dev) |
| правила в редакторе | `alloy_lint` (dev) |
| хелперы для тестов | `alloy_test` (dev), `alloy_test_flutter` (dev, виджет-тесты) |
| скоуп на навигационный флоу | `alloy_go_router` |
| блоки, которые скоуп умеет закрывать | `alloy_bloc` |
| граф на экране работающего приложения | `alloy_inspector` (dev) |

Flutter-приложение с кодогенерацией:

```yaml
environment:
  sdk: ^3.13.0
  flutter: ">=3.47.0"

dependencies:
  alloy: ^0.1.0
  alloy_flutter: ^0.1.0

dev_dependencies:
  alloy_generator: ^0.1.0
  build_runner: ^2.15.0
  alloy_lint: ^0.1.0
  alloy_test: ^0.1.0
  alloy_test_flutter: ^0.1.0
```

Программе на чистом Dart — CLI, серверу, пакету без виджетов — хватит одной строки:

```yaml
dependencies:
  alloy: ^0.1.0
```

`alloy_flutter` реэкспортирует весь рантайм, поэтому приложение никогда не импортирует оба.

---

## 2. Граф, написанный руками

Начните отсюда, даже если собираетесь генерировать. Генератор пишет ровно это и не пользуется ничем,
кроме публичного API, — поэтому знать, как выглядит его вывод, значит знать фреймворк.

Регистрация — это объект, а не замыкание. Именно поэтому фабрика может быть `const`, не носить
захваченного состояния и переиспользоваться между всеми запусками графа.

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

**Билдер скоупа** говорит, что в скоупе лежит. Он только регистрирует и никогда не резолвит.

```dart
class AppScope implements AlloyScopeBuilder {
  const AppScope();

  @override
  void build(AlloyScope scope) {
    scope
      ..registerLazySingleton<Clock>(const ClockFactory())
      ..registerLazySingleton<EventLog>(const EventLogFactory());
  }
}

Future<void> main() async {
  final app = await AlloyApplication.start(root: const AppScope(), rootName: 'app');

  app.get<EventLog>().add('запуск в ${app.get<Clock>().now()}');

  await app.dispose();
}
```

### Пять способов зарегистрировать

| Вызов | Когда строится | Скоуп удерживает |
|---|---|---|
| `registerSingleton<T>(value)` | уже построено вами | да |
| `registerLazySingleton<T>(factory)` | при первом резолве | да |
| `registerAsyncSingleton<T>(factory)` | в `init()`, в порядке зависимостей | да |
| `registerFactory<T>(factory)` | на каждый резолв | нет |
| `registerParamFactory<T, P>(factory)` | на каждый резолв, из аргумента | нет |

«Удерживает» — и есть всё различие: скоуп освобождает то, что удерживает, а транзиент освобождать
некому — см. [§7](#7-как-закрывается-то-что-вы-зарегистрировали).

### Пять способов прочитать

```dart
scope.get<Repository>();                       // бросает, если ничего не зарегистрировано
scope.getOrNull<Telemetry>();                  // вместо этого null — когда это уместно, см. §9
scope.get<Logger>(name: 'audit');              // именованная регистрация
scope.getAll<NoteFormatter>();                 // все регистрации типа, ближний скоуп первым
scope.getWithParam<Counter, String>('alice');  // параметризованная
```

`isRegistered<T>()` отвечает, ничего не строя, — это то, что нужно экрану, когда регистрация зависит
от окружения и законно может отсутствовать.

---

## 3. Тот же граф, сгенерированный

Разметьте классы, и билдер напишет генератор.

```dart
import 'package:alloy/alloy.dart';

@alloyInject
class Config {
  Config();

  final String environment = 'test';
}

@alloyInject
class Repository {
  Repository(this.config);

  final Config config;
}

@alloyInject
class Telemetry implements Disposable {
  final events = <String>[];

  void record(String event) => events.add(event);

  @override
  void dispose() => events.clear();
}
```

`@alloyInject` — ленивый синглтон. `@alloySingleton` и `@alloyTransient` выбирают другие времена
жизни, а полная форма принимает остальное:

```dart
@AlloyInject(exposeAs: ApiClient, name: 'live', dispose: closeClient)
class LiveApiClient implements ApiClient { ... }
```

Корень называется один раз, в любом месте пакета:

```dart
@AlloyScopeRoot(name: 'app')
class AppScope {
  const AppScope();
}
```

Дальше — генерация:

```bash
dart run build_runner build
```

На выходе `lib/alloy.g.dart`: приватные const-фабрики, `$AlloyRootScope`, чьи регистрации
упорядочены компайл-тайм топологической сортировкой, и `$startAlloy()`, связывающий его со списком
bootstrap-шагов и именем корня:

```dart
final scope = await $startAlloy();
```

Сгенерированный файл коммитьте. CI перегенерирует и падает на диффе — так ловится устаревший вывод.

### Property injection — для конструкторов, которые разрослись

Классу с пятью зависимостями не нужны пять аргументов конструктора. Объявите поля и подмешайте то,
что генератор напишет рядом:

```dart
part 'counter_bloc.g.dart';

@alloyTransient
class CounterBloc with _$CounterBloc {
  CounterBloc();

  @injected
  late final Repository _repository;

  @injected
  late final Telemetry _telemetry;

  void increment() => _telemetry.record('${_repository.hashCode}');
}
```

Поля `late final`, то есть пишутся один раз — повторное присваивание даёт `LateError`, — и могут быть
приватными, потому что сгенерированный миксин это `part` той же библиотеки. Инъектируемые поля — такие
же рёбра графа, как всё остальное, поэтому блок всегда регистрируется после того, что он инъектирует.

### Композиция поверх сгенерированного корня

Генератор видит только аннотации своего пакета. Всё прочее — значение из `--dart-define`, объект,
которому нужен сам скоуп, — кладётся в билдер, оборачивающий сгенерированный, чтобы оно попало
**внутрь** фазы 1, а не приколачивалось после старта:

```dart
class NotesScope implements AlloyScopeBuilder {
  const NotesScope(this.environment);

  final AlloyEnvironment environment;

  @override
  void build(AlloyScope scope) {
    $AlloyRootScope(environment: environment).build(scope);
    scope
      ..registerSingleton<AlloyEnvironment>(environment)
      ..registerSingleton<SessionManager>(SessionManager(scope));
  }
}
```

Скажите об этом проверке полноты, иначе она сочтёт их отсутствующими:

```dart
@AlloyScopeRoot(name: 'app', provides: [SessionManager, AlloyEnvironment])
class AppScope {
  const AppScope();
}
```

Обещание ничего не регистрирует — оно только говорит, что это сделает кто-то другой.
`AlloyProvided(Logger, name: 'audit')` обещает именованную.

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
      root: const NotesScope(notesEnvironment),
      bootstrap: () => $alloyBootstrap(notesEnvironment),
      rootName: $alloyRootScopeName,
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
  root: const NotesScope(notesEnvironment),
  child: myWrapper(child!),
),
```

---

## 5. Чтение из графа в виджете

```dart
final repository = context.alloy<Repository>();
final formatters = context.alloyAll<NoteFormatter>();
final editor = context.alloyWithParam<NoteEditor, $NoteEditorArgs>((id: 7, draft: true));
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
      ..registerLazySingleton<Draft>(const DraftFactory());
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

### Экран

```dart
AlloyScopeWidget(
  name: 'counter-screen',
  builder: const ScreenScope(),
  child: const Counter(),
)
```

Создаётся при монтировании, разбирается при размонтировании. Учтите: скоуп публикуется только после
`init()`, поэтому даже полностью синхронный граф даёт один кадр `loading`.

### Навигационный флоу

`alloy_go_router` делает время жизни флоу, а не виджетом, который вы не забыли поставить:

```dart
class OrderFlowRoute extends AlloyShellRoute {
  OrderFlowRoute()
    : super(
        name: 'order',
        identity: _orderId,
        scope: (state) => OrderFlowScope(_orderId(state)),
        shell: (_, _, child) => OrderFlowChrome(child: child),
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
```

Навигация между `summary` и `payment` сохраняет один скоуп. Выход из флоу его разбирает. `identity`
отвечает на единственный вопрос, который роутер решить не может: одно ли это флоу — `/orders/1` и
`/orders/2`; смените identity, и скоуп будет пересоздан.

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
пока от него ещё кто-то зависит. И разбор best-effort: упавший `dispose` записывается, остальные всё
равно выполняются, у всего дерева один дедлайн, а несделанное перечисляется в `AlloyDisposeError`
вместо того, чтобы первая ошибка спрятала остальные девять.

Маршрута три, и, поскольку в Dart нет структурной типизации, совпадающего метода `dispose()` самого
по себе недостаточно:

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
Future<void> closeEvents(StreamController<String> events) => events.close();

@alloyModule
class PlatformModule {
  const PlatformModule();

  @AlloyInject(dispose: closeEvents)
  StreamController<String> events() => StreamController<String>.broadcast();
}
```

Руками — тот же аргумент:

```dart
scope.registerLazySingleton<http.Client>(
  const ClientFactory(),
  dispose: (client) => client.close(),
);
```

`dispose:` есть только у регистраций, которые скоуп удерживает. У `registerFactory` и
`registerParamFactory` его нет вовсе: транзиент закрывать не скоупу — случай сделан невыразимым по
построению, а не проверяемым в рантайме.

### Flutter-типы, которые выглядят закрываемыми и не являются

`ChangeNotifier.dispose` совпадает с `Disposable.dispose` дословно — и всё равно скоупу невидим.
Скажите об этом:

```dart
class Filters extends ChangeNotifier implements Disposable {}
```

Для блоков `alloy_bloc` — это одна строка:

```dart
@alloyInject
class CounterCubit extends Cubit<int> with AlloyBloc {
  CounterCubit() : super(0);
}
```

или, где миксин не достанет, `@AlloyInject(dispose: closeBloc)`.

Дальше отдавайте блок в дерево виджетов через `BlocProvider.value` и никогда через
`BlocProvider(create:)`: второй закрывает то, что ему передали, при размонтировании, тогда как скоуп
всё ещё держит объект и на следующем резолве отдаст мёртвый.

`adopt` привязывает к жизни скоупа объект, не являющийся зависимостью:

```dart
scope.adopt(subscription, dispose: (it) => it.cancel());
```

---

## 8. Работа, которая обязана завершиться до старта

Две фазы, и отвечают они на разные вопросы.

**Фаза 0 — `@AlloyBootstrap`.** До того, как контейнер существует: платформенные биндинги, удалённый
конфиг, всё, что нужно самому графу. Шаги идут строго по порядку и не могут ничего инъектировать —
инъектировать пока неоткуда.

```dart
@AlloyBootstrap(order: 0)
class BindPlatform implements AlloyBootstrapStep {
  const BindPlatform();

  @override
  String get name => 'bind-platform';

  @override
  Future<void> run() async => WidgetsFlutterBinding.ensureInitialized();
}
```

Отработав, шаги усыновляются корневым скоупом: шаг, который что-то открыл, закрывается вместе с ним —
последним, после всего, что построено поверх. Если шаг падает, уже отработавшие освобождаются в
обратном порядке до того, как ошибка будет переброшена.

**Фаза 1 — `@AlloyInit`.** Внутри контейнера: асинхронные синглтоны, строящиеся в порядке
зависимостей.

```dart
@AlloyInit(dependsOn: [Database])
class SearchIndex {
  final _terms = <String>[];

  Future<void> init() async => _terms.addAll(await loadTerms());
}
```

`dependsOn` — ребро порядка, а не инъекция. Независимые инициализаторы одного уровня едут вместе
через `Future.wait`; ждёт только тот, кто действительно зависит. Указание на то, что не является
async-регистрацией, — ошибка сборки, а не тихий no-op, на который это похоже.

`AlloyApplication.start` возвращается, когда обе фазы закончены, поэтому нет ни `allReady()`, ни
состояния «зарегистрировано, но не готово», о котором пришлось бы думать.

---

## 9. Значения, приходящие с места вызова

Половина объекта приходит из графа, половина — от того, кто его строит. Разметьте ту половину,
которой контейнер знать не может:

```dart
@alloyInject
class Greeting {
  Greeting(this._config, {@alloyParam required this.name, @alloyParam required this.loud});

  final Config _config;
  final String name;
  final bool loud;
}
```

Генератор пишет тип аргумента рядом с контейнером как именованную запись и регистрирует
параметризованную фабрику:

```dart
// typedef $GreetingArgs = ({String name, bool loud});
final greeting = context.alloyWithParam<Greeting, $GreetingArgs>((name: 'Alloy', loud: false));
```

Именованная запись, а не позиционная, даже для одного аргумента: добавление второго меняет
содержимое типа, а не его имя и не форму вызова.

Помеченные параметры не участвуют ни в проверке полноты, ни в упорядочивании — `String` никто не
регистрирует. Они обязаны быть required или нуллабельными: у записи нет значений по умолчанию,
поэтому `@alloyParam this.draft = false` оставил бы вызывающего обязанным передать `draft`, а
написанный дефолт — мёртвым. Это ошибка сборки.

Руками то же самое — `registerParamFactory<T, P>` с одним параметром; несколько складывайте в запись
или в свой маленький класс.

### Опциональные зависимости

Вся запись — это `?` на типе:

```dart
@alloyInject
class Reporter {
  Reporter(this.clock, this.telemetry);

  final Clock clock;
  final Telemetry? telemetry;   // резолвится через getOrNull
}
```

Граф, в котором `Telemetry` не зарегистрирована, получит null вместо падения сборки. Нуллабельность
не входит в ключ регистрации — `Foo?` по-прежнему читает регистрацию `Foo`, — а опциональная
зависимость остаётся ребром порядка, если её всё-таки кто-то регистрирует.

`getOrNull` отдаёт null только на «не зарегистрировано». Async-синглтон, спрошенный до `init()`,
по-прежнему бросает: «не готово» и «нет вовсе» — разные факты, и схлопывание их превращает ошибку
порядка старта в значение.

---

## 10. Типы, которые написали не вы

`@AlloyInject` вешается на класс, поэтому достаёт только до ваших классов. Для всего остального вход
— модуль:

```dart
@alloyModule
class NetworkModule {
  const NetworkModule();

  @alloyInject
  Dio dio(AppConfig config) => Dio(BaseOptions(baseUrl: config.apiBase));

  @AlloyInject(dispose: closeClient)
  http.Client client() => http.Client();

  @alloySingleton
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
```

Аннотация на классе не несёт ничего: каждый член настраивает свою регистрацию теми же аннотациями,
что и класс, а его параметры резолвятся как параметры конструктора. Классу нужен публичный
`const`-конструктор без аргументов — тогда сгенерированная фабрика держит `const NetworkModule()` и
не носит состояния.

Возврат `Future<T>` — единственный признак асинхронности: такой член становится async-синглтоном, а
порядок между async-членами вычисляет генератор, а не вы руками. Члены не могут быть абстрактными:
«собрать класс из его же конструктора» — это то, что уже значит `@AlloyInject`.

---

## 11. Один граф, несколько сборок

Пропустите этот раздел, пока одной сборке действительно не понадобится другая реализация, чем
другой. Проект, никогда не пишущий `@AlloyEnvironment`, имеет один граф, и `$startAlloy()` не берёт
аргументов вовсе.

```dart
@AlloyInject(exposeAs: ApiClient)
@AlloyEnvironment.prod
@AlloyEnvironment.stage
class LiveApiClient implements ApiClient { ... }

@AlloyInject(exposeAs: ApiClient)
@AlloyEnvironment.dev
@AlloyEnvironment.test
class FakeApiClient implements ApiClient { ... }
```

```dart
final scope = await $startAlloy(environment: AlloyEnvironment.prod);
```

Аннотация повторяется, а не принимает список: регистрация принадлежит *множеству* окружений, а старт
выбирает ровно *одно*. `dev`, `stage`, `prod` и `test` — константы, а не закрытое множество:
`@AlloyEnvironment('canary')` ведёт себя точно так же.

Две регистрации одного типа с пересекающимися окружениями — ошибка сборки, называющая обе; сюда же
входит случай, когда одна не называет окружения вовсе. Полнота проверяется для каждого окружения
отдельно, поэтому `dev`-регистрация не удовлетворит зависимого, который работает и в `prod`.

Стартовать, не выбрав, законно — разделённые типы просто остаются незарегистрированными: первый же
резолв падает обычной ошибкой «не зарегистрировано», а не отдаёт молча не тот класс.

---

## 12. Наблюдение за графом

Наблюдатели видят появление скоупов, построение инстансов, завершение старта, падение разбора.
Передавайте их туда, где создаётся граф; каждый скоуп, поднятый ниже, их наследует.

```dart
final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyLogObserver(const AlloyDeveloperLogSink())],
);
```

`push(name, observers: [...])` добавляет наблюдателей одному поддереву.

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

### Проверка рукописного графа

Генератор отвергает неполный граф на сборке, но только то, что сгенерировал сам: рукописная фабрика
резолвит внутри `create`, поэтому статически не видно, что она попросит. Единственная проверка —
прогон:

```dart
await expectGraphResolves(scope);
```

Он терминален: резолв **и есть** проверка, поэтому после него каждый ленивый синглтон построен, а
порядок разбора другой. Держите его в отдельном тесте.

Параметризованную регистрацию без значения не зарезолвить, поэтому она попадает в отчёт поимённо
как `unchecked`, а не пропускается молча. Дайте ей образец, чтобы покрыть и её:

```dart
await expectGraphResolves(scope, params: {AlloyKey(Counter): 'alice'});
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

Async-регистрации обязаны существовать **до** `init()`. Он берёт те async-регистрации, которые
находит на старте, и отрабатывает один раз, поэтому регистрация в уже активный скоуп — ошибка, а не
что-то, что молча никогда не построится; из-за этого уже запущенный скоуп — неподходящее место для
фикстур.

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

---

## 14. Плагин линтера

Двенадцать правил на том же слое разбора, которым пользуется генератор, — ошибка видна в редакторе, а
не только когда отработает `build_runner`.

```yaml
# analysis_options.yaml
plugins:
  alloy_lint: ^0.1.0
```

Две вещи про подключение стоят реального времени:

1. Секция `plugins:` **работает только в корне пакета или workspace**. Во вложенном
   `analysis_options.yaml` она молча игнорируется — ни ошибки, ни диагностик. По той же причине
   `dart analyze <вложенный/каталог>` её не применяет; анализируйте корень workspace.
2. Сервер анализа кэширует сборку плагина на контекст. «Правило не срабатывает» чаще означает
   устаревшую сборку, чем неверное правило: тронь файл плагина или перезапусти сервер.

---

## 15. Ошибки, о которых стоит знать заранее

Каждая найдена дорого — в этом репозитории или в приложениях, ради которых он писался.

- **Построение графа внутри `testWidgets`.** Fake-async, ничего не завершается, таймаут, которому
  нечего предъявить. `setUp`.
- **Подмена ниже потребителя.** Фабрика выполняется на скоупе-владельце. `ownerOf<T>()` скажет об
  этом раньше, чем ассерт.
- **`bootstrap` как хранимый список.** Шаги держат ресурсы; рестарт обязан получить новые.
  Передавайте функцию.
- **`BlocProvider(create:)` для блока, которым владеет скоуп.** Два владельца, и виджет успевает
  первым. `BlocProvider.value`.
- **`ChangeNotifier` или `Cubit`, зарегистрированный без объявления закрываемости.** Построен,
  использован, никогда не закрыт, молча. `implements Disposable`, `with AlloyBloc` или `dispose:`.
- **`@AlloyInject` на generic-классе.** Отвергается: генератору никто не говорит, какие инстанциации
  регистрировать. Разметьте конкретный подтип или выставьте его через `exposeAs`. Дженерики
  прекрасно работают как зависимости и как цели `exposeAs`.
- **Старый `dart` первым в PATH.** Ломается негромко и не там: `dart analyze` выдаёт фантомные issue
  против чужого анализатора, а `dart format` переписывает нетронутые файлы. Проверяйте
  `dart --version`, прежде чем верить прогону.

---

## Куда дальше

- [README.ru.md](README.ru.md) — что такое Alloy и почему каждое решение принято именно так.
- [MIGRATION.ru.md](MIGRATION.ru.md) — с `get_it` и `injectable`, включая то, что не переводится.
- `examples/gallery` — одно Flutter-приложение, четырнадцать записей, по одной на возможность:
  `cd examples/gallery && flutter run`.
- README пакетов за подробностями: [`alloy`](packages/alloy/README.md),
  [`alloy_flutter`](packages/alloy_flutter/README.md),
  [`alloy_generator`](packages/alloy_generator/README.md),
  [`alloy_lint`](packages/alloy_lint/README.md),
  [`alloy_test`](packages/alloy_test/README.md).
