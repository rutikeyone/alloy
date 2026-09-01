<p align="center">
  <a href="GUIDE_CODEGEN.md">English</a> · <a href="GUIDE_CODEGEN.ru.md">Русский</a> · <a href="GUIDE_CODEGEN.zh-CN.md">中文</a>
</p>

> Перевод [GUIDE_CODEGEN.md](GUIDE_CODEGEN.md). Канонический текст — английский: при расхождении верен он.

# Code-Gen Mode

Alloy с генератором: вы размечаете классы, `build_runner` пишет контейнер, и граф проверяется до
того, как соберётся. На выходе — обычный Dart, не использующий ничего, кроме публичного API `alloy`:
его можно прочитать, и всё в нём можно было бы написать руками.

Это стоящий инвариант проекта, и у него есть практическое следствие, которым вы будете
пользоваться: сгенерированный контейнер — такой же `AlloyScopeBuilder`, как любой другой, поэтому
рукописные регистрации композируются с ним в одном графе. Ничего здесь не «всё или ничего».

Что покупает шаг сборки и о чём в основном этот документ:

- **граф проверяется на сборке** — зависимость, которую никто не регистрирует, валит сборку, называя
  все пробелы разом, вместо того чтобы упасть на том экране, который первым до неё дойдёт;
- **property injection** — поля `late final`, заполняемые сгенерированным миксином, так что у класса
  с пятью зависимостями пустой конструктор;
- **двенадцать правил линтера**, ловящих остальное в редакторе.

Если ничего из этого не нужно или вы постепенно мигрируете существующий контейнер — всё работает и
без генератора: [GUIDE_MANUAL.ru.md](GUIDE_MANUAL.ru.md).

---

## Содержание

1. [Установка](#1-установка)
2. [Первый сгенерированный граф](#2-первый-сгенерированный-граф)
3. [Что выходит на выходе](#3-что-выходит-на-выходе)
4. [Property injection](#4-property-injection)
5. [Граф обязан быть полным](#5-граф-обязан-быть-полным)
6. [Композиция поверх сгенерированного корня](#6-композиция-поверх-сгенерированного-корня)
7. [Запуск Flutter-приложения](#7-запуск-flutter-приложения)
8. [Чтение из графа в виджете](#8-чтение-из-графа-в-виджете)
9. [Скоупы, которые кончаются раньше приложения](#9-скоупы-которые-кончаются-раньше-приложения)
10. [Как закрывается то, что вы зарегистрировали](#10-как-закрывается-то-что-вы-зарегистрировали)
11. [Работа, которая обязана завершиться до старта](#11-работа-которая-обязана-завершиться-до-старта)
12. [Значения, приходящие с места вызова](#12-значения-приходящие-с-места-вызова)
13. [Опциональные зависимости](#13-опциональные-зависимости)
14. [Типы, которые написали не вы](#14-типы-которые-написали-не-вы)
15. [Один граф, несколько сборок](#15-один-граф-несколько-сборок)
16. [Плагин линтера](#16-плагин-линтера)
17. [Наблюдение за графом](#17-наблюдение-за-графом)
18. [Тесты](#18-тесты)
19. [Ошибки, о которых стоит знать заранее](#19-ошибки-о-которых-стоит-знать-заранее)

---

## 1. Установка

Рантайм уезжает в приложение, генератор — никогда.

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

**Пол здесь выше, чем в другом режиме, и это настоящее ограничение, а не круглое число.**
`alloy_generator` и `alloy_lint` требуют analyzer 13, которому через `_fe_analyzer_shared` нужен
Dart 3.11; ниже него парсер вдобавок перестаёт видеть `@AlloyParam` на параметрах конструктора.
Одному рантайму хватает Dart `^3.10.0` / Flutter `>=3.38.0`, поэтому приложение, ещё не дошедшее до
3.47, может сегодня работать по [GUIDE_MANUAL.ru.md](GUIDE_MANUAL.ru.md) и прийти сюда позже.

Пакет на чистом Dart — CLI, сервер, пакет без виджетов — выбрасывает `alloy_flutter` и
`alloy_test_flutter`. Рантайму Flutter не нужен нигде.

Аннотации приезжают вместе с `alloy`, который их реэкспортирует, поэтому одного импорта достаточно:

```dart
import 'package:alloy/alloy.dart';
```

Опционально и только если нужно: `alloy_go_router`, `alloy_bloc`, `alloy_inspector` и один из
`alloy_talker` / `alloy_logging` / `alloy_logger`.

---

## 2. Первый сгенерированный граф

Разметьте классы. Зависимости — это параметры конструктора, а что чем резолвится, вычисляет
генератор.

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
  Telemetry();

  final events = <String>[];

  void record(String event) => events.add(event);

  @override
  void dispose() => events.clear();
}
```

`@alloyInject` — ленивый синглтон: строится при первом резолве, удерживается скоупом. У остальных
времён жизни свои константы, а полная форма принимает всё прочее:

| Аннотация | Время жизни |
|---|---|
| `@alloyInject` | ленивый синглтон |
| `@alloySingleton` | eager-синглтон, строится вместе с графом |
| `@alloyTransient` | новый инстанс на каждый резолв, не удерживается никем |

```dart
@AlloyInject(exposeAs: ApiClient, name: 'live', dispose: closeClient)
class LiveApiClient implements ApiClient { ... }
```

`exposeAs` регистрирует класс под интерфейсом — так потребитель зависит от `ApiClient`, а не от
реализации. `name` — квалификатор, поэтому вторая регистрация того же типа законна и читается через
`get<Logger>(name: 'audit')`.

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

Во время работы — `dart run build_runner watch`. Вывод коммитьте: CI перегенерирует и падает на
диффе, и так устаревший сгенерированный код ловится, а не уезжает в релиз.

**Один корень на пакет.** `alloy_container` агрегирует весь пакет в единственный `$AlloyRootScope`;
два `@AlloyScopeRoot` в одном пакете — ошибка генерации. Значит два независимых сгенерированных
графа требуют двух пакетов — ровно поэтому примеры в этом репозитории отдельные пакеты, а не папки.

---

## 3. Что выходит на выходе

`lib/alloy.g.dart`, и его стоит прочитать один раз, чтобы режим перестал быть чёрным ящиком:

```dart
final class _RepositoryFactory implements AlloyFactory<Repository> {
  const _RepositoryFactory();

  @override
  Repository create(AlloyResolver resolver) => Repository(resolver.get<Config>());
}

final class $AlloyRootScope implements AlloyScopeBuilder {
  const $AlloyRootScope();

  @override
  void build(AlloyScope scope) {
    scope.registerLazySingleton<Config>(const _ConfigFactory());
    scope.registerLazySingleton<Telemetry>(const _TelemetryFactory());
    scope.registerLazySingleton<Repository>(const _RepositoryFactory());
  }
}

const String $alloyRootScopeName = 'app';

Future<AlloyScope> $startAlloy() => AlloyApplication.start(
  root: const $AlloyRootScope(),
  rootName: $alloyRootScopeName,
);
```

```dart
final scope = await $startAlloy();
```

Здесь они для читаемости опущены, но в настоящем файле каждое импортированное имя носит префикс,
выведенный из хеша URL библиотеки: `_i178.AlloyFactory`. Именно хеш, а не счётчик, — чтобы
добавление одного импорта не перенумеровало все остальные и не превратило правку в одну строку в
дифф на весь файл.

Четыре свойства этого вывода сознательны:

- **Приватные const-классы-фабрики, а не замыкания.** `const`-фабрика не носит захваченного
  состояния, поэтому второй старт не может переиспользовать объекты первого графа.
- **Регистрации в топологическом порядке**, вычисленном на сборке. Инъектируемые поля тоже рёбра,
  поэтому блок всегда регистрируется после того, что он инъектирует.
- **Ни рефлексии, ни сканирования в рантайме.** Что лежит в файле — то и есть весь граф.
- **`$alloyBootstrap` — геттер**, а не хранимый список, поэтому рестарт получает свежие шаги — см.
  [§11](#11-работа-которая-обязана-завершиться-до-старта).

Генератор форматирует свой вывод той же версией `dart_style`, которой пользуется ваша проверка
формата, — расходиться им негде.

---

## 4. Property injection

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

Три вещи делают это надёжным, а не магическим:

- Поля `late final`, то есть **пишутся один раз** — повторное присваивание даёт `LateError`.
- Они могут быть **приватными**: сгенерированный миксин — `part` той же библиотеки и потому их
  видит.
- Они — **рёбра графа** наравне с остальными, поэтому участвуют и в упорядочивании, и в проверке
  полноты.

Директиву `part` и `with _$ClassName` пишете вы. Забудете миксин — `alloy_missing_injection_mixin`
скажет об этом в редакторе; поставите `@injected` на класс, который контейнер не регистрирует, —
скажет уже `alloy_injected_field_needs_an_injectable`, потому что чинятся эти две ошибки по-разному.

---

## 5. Граф обязан быть полным

Ради этого шаг сборки и нужен. Зависимость, которую никто не регистрирует, валит сборку, называя все
пробелы разом, а не по одному на пересборку:

```
The graph is missing 2 registrations.
  CatalogService requires Repository<User>
  ApiGateway requires HttpClient in dev, test
Annotate the classes that provide them with @AlloyInject, or name them in
@AlloyScopeRoot(provides: [...]) when something outside the generated container
registers them.
```

Зависимостями считается всё: параметры конструктора, `@injected`-поля и `@AlloyInit(dependsOn:)`.
Квалификатор `@Named` входит в ключ, поэтому запрос `@Named('audit') Logger` там, где есть только
безымянный `Logger`, — это пробел. Каждое окружение проверяется отдельно, поэтому `dev`-регистрация
не удовлетворит зависимого, который работает и в `prod`.

Отвергается на сборке и остальное: дубликаты одного ключа, циклы зависимостей (с указанием цикла),
два `@AlloyScopeRoot` в пакете, `@AlloyInject` на абстрактном классе или на классе без публичного
генеративного конструктора, и `@AlloyInject` на **generic-классе** — генератору никто не говорит,
какие инстанциации регистрировать, поэтому разметьте конкретный подтип или выставьте его через
`exposeAs`.

Во всём остальном дженерики работают. `Repository<User>` и `Repository<Order>` — две отдельные
регистрации, потому что `AlloyKey` строится из `Type`, а это разные типы.

Границу стоит назвать честно: проверка покрывает то, что генератор сгенерировал. Рукописная фабрика
резолвит внутри `create`, поэтому статически не видно, что она попросит, — для таких проверкой
служит `expectGraphResolves` из `alloy_test`, см. [§18](#18-тесты).

---

## 6. Композиция поверх сгенерированного корня

Генератор видит только аннотации своего пакета. Всё прочее — значение из `--dart-define`, объект,
которому нужен сам скоуп, провайдер из чужого пакета — кладётся в билдер, оборачивающий
сгенерированный:

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

Обёртка, а не регистрация после возврата из `$startAlloy()`, — это то, что держит их внутри фазы 1:
зарегистрированы до запуска async-инициализаторов, а не приколочены после того, как граф уже поднят.

Теперь скажите об этом проверке полноты, иначе она сочтёт их отсутствующими:

```dart
@AlloyScopeRoot(name: 'app', provides: [SessionManager, AlloyEnvironment])
class AppScope {
  const AppScope();
}
```

Обещание ничего не регистрирует — оно только говорит, что это сделает кто-то другой.
`AlloyProvided(Logger, name: 'audit')` обещает именованную. Пообещать и не зарегистрировать — значит
вернуться к отказу в рантайме: этот список ваше утверждение, а не то, что генератор может проверить.

---

## 7. Запуск Flutter-приложения

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

`bootstrap` — функция, а не список, и генератор эмитит `$alloyBootstrap` геттером по той же причине:
шаги держат ресурсы, и рестарт обязан получить новые.

`AlloyAppScope.of(context).restart()` пересобирает граф — тот же вызов повторяет упавший старт.

Вне Flutter всё сводится к `await $startAlloy()`.

---

## 8. Чтение из графа в виджете

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

## 9. Скоупы, которые кончаются раньше приложения

Генератор пишет **корень**. Скоупы короче приложения — сессия, флоу, экран — это
`AlloyScopeBuilder`'ы, которые пишете вы, и регистрируют они через тот же публичный API, которым
пользуется сгенерированный файл. Это не пробел генератора: что положить в сессионный скоуп — решение
о времени жизни, а никакая аннотация не говорит, когда сессия кончается.

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

Создаётся при монтировании, разбирается при размонтировании. Скоуп публикуется только после
`init()`, поэтому даже полностью синхронный граф даёт один кадр `loading`.

Здесь `@alloyTransient` и оправдывает своё существование: транзиент пересоздаётся на каждый резолв и
не удерживается никем, поэтому собственный скоуп — это то, что даёт ему время жизни и точку разбора.

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
```

Навигация между `summary` и `payment` сохраняет один скоуп. Выход из флоу его разбирает. `identity`
отвечает на единственный вопрос, который роутер решить не может: одно ли это флоу — `/orders/1` и
`/orders/2`.

Таблицу роутов стройте **один раз**, вместе с роутером. Новый экземпляр `AlloyShellRoute` — это
другой флоу с точки зрения go_router, поэтому пересборка списка на каждом кадре разбирала бы скоуп
на каждом кадре.

Вкладки устроены так же — `AlloyStatefulShellRoute` и `AlloyStatefulShellBranch`, — с одной
особенностью: ветка держится **живой**, а не **видимой**. go_router сохраняет навигаторы веток за
экраном, поэтому скоуп вкладки живёт до закрытия шелла, а не до переключения с неё.

---

## 10. Как закрывается то, что вы зарегистрировали

Скоуп освобождает удержанное в обратном порядке **создания**, а не объявления, — именно это различие
баг рукописных контейнеров. В Dart нет структурной типизации, поэтому совпадающего метода
`dispose()` самого по себе недостаточно:

```dart
@alloyInject
class Cache implements Disposable {
  @override
  void dispose() { ... }
}

@alloyInit
class Database implements AsyncInitializable, AsyncDisposable {
  @override
  Future<void> init() async { ... }

  @override
  Future<void> dispose() async { ... }
}
```

Для типа, который вам не изменить — из SDK, из чужого пакета, за базовым классом, — назовите
teardown в аннотации. Она принимает top-level-функцию, потому что аргумент аннотации обязан быть
константой:

```dart
Future<void> closeClient(http.Client client) => client.close();

@AlloyInject(dispose: closeClient)
class ApiClientHolder { ... }
```

`dispose:` что-то значит только у регистрации, которую скоуп удерживает. На `@alloyTransient` или на
классе с `@AlloyParam` это ошибка сборки, а не колбэк, который никогда не вызовут: транзиент
закрывать не скоупу.

### Flutter-типы, которые выглядят закрываемыми и не являются

`ChangeNotifier.dispose` совпадает с `Disposable.dispose` дословно — и всё равно скоупу невидим.
Скажите об этом:

```dart
@alloyInject
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

`alloy_registration_is_never_released` ловит всё это в редакторе: зарегистрированный класс с
`dispose()` или `close()`, которых скоуп не видит.

### Когда разбор идёт не так

Он best-effort по замыслу. Упавший шаг записывается, остальные всё равно выполняются; у всего дерева
один дедлайн; скоуп всегда доходит до `disposed`. Несделанное перечисляется в `AlloyDisposeError` —
`failures`, `timeouts`, `hasTimeout`.

`adopt` привязывает к жизни скоупа объект, не являющийся зависимостью:

```dart
scope.adopt(subscription, dispose: (it) => it.cancel());
```

---

## 11. Работа, которая обязана завершиться до старта

Две фазы, отвечают на разные вопросы.

**Фаза 0 — `@AlloyBootstrap`.** До того, как контейнер существует: платформенные биндинги, удалённый
конфиг, всё, что нужно самому графу. Шаги идут строго по порядку — сначала `order`, затем имя, чтобы
вывод был стабильным — и не могут ничего инъектировать: инъектировать пока неоткуда. Bootstrap-шаг,
чей конструктор берёт обязательные параметры, — ошибка сборки, а `alloy_bootstrap_step_cannot_inject`
скажет об этом раньше.

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

Отработав, шаги усыновляются корневым скоупом: шаг, который что-то открыл, закрывается вместе с ним
— последним, после всего, что построено поверх. Если шаг падает, уже отработавшие освобождаются в
обратном порядке до того, как ошибка будет переброшена.

**Фаза 1 — `@AlloyInit`.** Внутри контейнера: асинхронные синглтоны в порядке зависимостей.

```dart
@AlloyInit(dependsOn: [Database])
class SearchIndex implements AsyncInitializable {
  SearchIndex(this._database);

  final Database _database;
  final _terms = <String>[];

  @override
  Future<void> init() async => _terms.addAll(await _database.terms());
}
```

`AsyncInitializable` — интерфейс, который подразумевает аннотация. Обязателен только сам *метод*
`init()` — и парсер, и правило линтера ищут его по имени, — но объявленный интерфейс делает контракт
видимым читателю, и именно это советует каждое сообщение об отсутствующем `init()`.

Сгенерированная фабрика конструирует объект, дожидается `init()` и регистрирует его async-синглтоном
с `dependsOn`, переведённым в `AlloyKey`. Независимые инициализаторы одного уровня едут вместе через
`Future.wait`; ждёт только тот, кто действительно зависит.

`dependsOn` — ребро порядка, а не инъекция: зависимость вы берёте в конструктор как обычно. Указание
ключа, который зарегистрирован, но **не** async, — ошибка сборки, а не тихий no-op, на который это
похоже: ждать нечего.

`AlloyApplication.start` возвращается, когда обе фазы закончены, поэтому нет ни `allReady()`, ни
состояния «зарегистрировано, но не готово».

---

## 12. Значения, приходящие с места вызова

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

Два правила, которые генератор проверяет:

- Помеченные параметры **не участвуют** ни в проверке полноты, ни в упорядочивании. `String` никто
  не регистрирует, и не должен пытаться.
- Они обязаны быть **required или нуллабельными**. У записи нет значений по умолчанию, поэтому
  `@alloyParam this.draft = false` оставил бы вызывающего обязанным передать `draft`, а написанный
  дефолт — мёртвым. Это ошибка сборки, а не сюрприз.

Резолв такой регистрации обычным `get<T>()` бросает `AlloyParamRequiredError`; неверный тип —
`AlloyParamTypeError` с ключом и обоими типами.

---

## 13. Опциональные зависимости

Вся запись — это `?` на типе; отдельной аннотации нет, потому что без `?` поле всё равно не примет
null:

```dart
@alloyInject
class Reporter {
  Reporter(this.clock, this.telemetry);

  final Clock clock;
  final Telemetry? telemetry;
}

@alloyInject
class Dashboard with _$Dashboard {
  Dashboard();

  @injected
  late final Telemetry? _telemetry;
}
```

Оба резолвятся через `getOrNull`, поэтому граф, в котором `Telemetry` не зарегистрирована, получит
null вместо падения сборки.

Нуллабельность не входит в **ключ** регистрации — `Foo?` по-прежнему читает регистрацию `Foo`, — а
опциональная зависимость остаётся ребром порядка, если её всё-таки кто-то регистрирует. `getOrNull`
отдаёт null только на «не зарегистрировано»: async-синглтон, спрошенный до `init()`, по-прежнему
бросает, потому что «не готово» и «нет вовсе» — разные факты.

---

## 14. Типы, которые написали не вы

`@AlloyInject` вешается на класс, поэтому достаёт только до ваших классов. Для всего остального вход
— модуль: клиент из чужого пакета, значение, которое отдаёт SDK.

```dart
Future<void> closeClient(http.Client client) => client.close();

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
что и класс, — время жизни, `name`, `exposeAs`, `dispose`, окружения, — а его параметры резолвятся
как параметры конструктора.

Правила, и у каждого своя причина:

- Классу нужен публичный **`const`-конструктор без аргументов** — тогда сгенерированная фабрика
  держит `const NetworkModule()` и не носит состояния.
- Возврат **`Future<T>` — единственный признак асинхронности.** Такой член становится
  async-синглтоном, а порядок между async-членами вычисляет генератор, а не вы руками.
- Члены **не могут быть абстрактными.** «Собрать класс из его же конструктора» — это то, что уже
  значит `@AlloyInject`; второго способа сказать то же самое не нужно.
- `@AlloyParam` на члене **запрещён.** Модуль регистрирует типы, которые написали не вы, а значение
  с места вызова принадлежит классу, который написали вы.

Члены участвуют во всём, в чём участвует класс: в детекте дубликатов, в топологической сортировке и
в проверке полноты.

---

## 15. Один граф, несколько сборок

Пропустите это, пока одной сборке действительно не понадобится другая реализация, чем другой.
Проект, никогда не пишущий `@AlloyEnvironment`, имеет один граф, все регистрации принадлежат ему, а
`$startAlloy()` не берёт аргументов вовсе.

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

Сгенерированный контейнер принимает выбор полем и оборачивает `if` только ограниченные регистрации —
ровно то, что вы написали бы руками:

```dart
if (environment.matches(const <String>{'dev', 'test'})) {
  scope.registerLazySingleton<ApiClient>(const _FakeApiClientFactory());
}
```

Отсюда три следствия:

- **Это остаётся опциональным до конца.** Параметр появляется, только когда что-то называет
  окружение, и даже тогда у него дефолт `AlloyEnvironment.defaultEnvironment` — то единственное
  окружение, в котором живёт неразделённый граф. Этот дефолт матчит только неограниченные
  регистрации, поэтому старт разделённого графа без выбора оставляет разделённые типы
  незарегистрированными, и первый же резолв падает, сообщая об этом, а не отдаёт молча не тот класс.
- **Ничто не регистрируется дважды.** Две регистрации одного ключа с пересекающимися окружениями —
  ошибка сборки, называющая обе; сюда входит и случай, когда одна не называет окружения вовсе, ведь
  неограниченная регистрация присутствует везде.
- **Полнота проверяется по каждому окружению отдельно**, поэтому `dev`-регистрация не удовлетворит
  зависимого, который работает и в `prod`.

Bootstrap-шаги тоже принимают окружения. Когда хоть один это делает, `$alloyBootstrap` становится
функцией выбранного окружения, а пропущенные шаги не запускаются и не усыновляются.

`alloy_environment_needs_a_registration` ловит случай, когда `@AlloyEnvironment` стоит на классе,
который никто не регистрирует, — там она молча ничего не делает.

---

## 16. Плагин линтера

Двенадцать правил на том же слое разбора, которым пользуется генератор, — ошибка видна в редакторе,
а не только когда отработает `build_runner`.

```yaml
# analysis_options.yaml
plugins:
  alloy_lint: ^0.1.0
```

| Правило | Что ловит |
|---|---|
| `alloy_missing_injection_mixin` | `@injected`-поля без `with _$ClassName` на классе, который контейнер регистрирует |
| `alloy_injected_field_needs_an_injectable` | `@injected`-поля на классе, который контейнер не регистрирует вовсе |
| `alloy_param_needs_an_injectable` | `@AlloyParam` на классе, который контейнер не регистрирует вовсе |
| `alloy_injected_field_must_be_late_final` | `@injected` на изменяемом, не-late или статическом поле |
| `alloy_injectable_must_be_constructible` | `@AlloyInject` на абстрактном классе или классе без публичного генеративного конструктора |
| `alloy_init_requires_init_method` | `@AlloyInit` на классе без `init()` |
| `alloy_bootstrap_requires_run_method` | `@AlloyBootstrap` на классе без `run()` |
| `alloy_bootstrap_step_cannot_inject` | bootstrap-шаг, чей конструктор берёт обязательные параметры |
| `alloy_environment_needs_a_registration` | `@AlloyEnvironment` на классе, который никто не регистрирует |
| `alloy_dependency_is_not_registered` | инъектируемая зависимость, которую ничто в пакете не регистрирует |
| `alloy_dependency_cycle` | инъектируемый класс, который в итоге зависит от самого себя |
| `alloy_registration_is_never_released` | зарегистрированный класс с `dispose()` или `close()`, которых скоуп не видит |

Две вещи про подключение стоят реального времени:

1. Секция `plugins:` **работает только в корне пакета или workspace**. Во вложенном
   `analysis_options.yaml` она молча игнорируется — ни ошибки, ни диагностик. По той же причине
   `dart analyze <вложенный/каталог>` её не применяет; анализируйте корень workspace.
2. Сервер анализа кэширует сборку плагина на контекст. «Правило не срабатывает» чаще означает
   устаревшую сборку, чем неверное правило: тронь файл плагина или перезапусти сервер.

Последние два правила отвечают на те же вопросы, что и генератор, только раньше и без полной сборки.
Они сознательно тише генератора: читают синтаксический индекс пакета, поэтому там, где индекс не
может быть уверен, они молчат, а не сообщают о том, что на самом деле в порядке. Авторитет — сборка;
редактор — быстрый путь.

---

## 17. Наблюдение за графом

Наблюдатели видят появление скоупов, построение инстансов, завершение старта, падение разбора.
Передавайте их туда, где создаётся граф; каждый скоуп, поднятый ниже, их наследует.

`$startAlloy()` наблюдателей не принимает — это короткий путь. Как только они понадобились,
идите через билдер, который вы и так композируете:

```dart
final scope = await AlloyApplication.start(
  root: const NotesScope(notesEnvironment),
  bootstrap: $alloyBootstrap(notesEnvironment),
  rootName: $alloyRootScopeName,
  observers: [AlloyLogObserver(const AlloyDeveloperLogSink())],
);
```

Во Flutter-приложении это параметр `observers:` у `AlloyAppScope.builder`.

В колбэки приходят `AlloyScopeRef` и `AlloyKey` — описатели, а не живые объекты, — и исключение из
колбэка проглатывается: наблюдение не должно ломать наблюдаемое. Резолв не логируется: попадание в
кэш — горячий путь, а видеть стоит **построение** инстанса.

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

## 18. Тесты

Первое, что надо знать, — это ловушка, а не API. `testWidgets` выполняет своё тело в fake-async
зоне, где `Future.delayed` в инициализаторе не завершается никогда. **Стройте граф в `setUp`**, а
утверждения обо всём графе держите в обычном `test`.

```dart
late AlloyScope scope;

setUp(() async {
  scope = await alloyTestScope(root: const $AlloyRootScope());
});
```

Сгенерированный билдер идёт туда напрямую — ровно так же, как им пользуется приложение.
`alloyTestScope` и `alloyTestRoot` разбираются вместе с тестом: это как раз та часть, которую легко
забыть, а забытая она не падает, а протекает в следующий тест.

### Подмена

Поднимите дочерний скоуп и зарегистрируйте заново. Затенение — это и есть штатный механизм подмены в
продакшене, поэтому тест пользуется тем же, чем приложение; и это же способ заменить
сгенерированную регистрацию без ведома генератора:

```dart
final overrides = scope.pushForTest()
  ..registerSingleton<ApiClient>(FakeApiClient());
```

Сработает это или нет, решает одно правило, на которое каждый однажды наступает: **фабрика
выполняется на скоупе, которому принадлежит её собственная регистрация.** Подмена ниже потребителя
ему невидима. `ownerOf<T>()` отвечает раньше, чем тест:

```dart
expect(scope.ownerOf<Repository>(), same(scope.root));
```

### Что всё ещё требует проверки в рантайме

Проверка полноты покрывает сгенерированный контейнер. Две вещи лежат вне неё и стоят теста:

```dart
await expectGraphResolves(scope);
```

Первая — всё, что вы пообещали через `provides:`: проверка вам поверила. Вторая — любая рукописная
регистрация, которую вы вкомпоновали ([§6](#6-композиция-поверх-сгенерированного-корня)).

Он терминален: резолв **и есть** проверка, поэтому после него каждый ленивый синглтон построен, а
порядок разбора другой. Держите его в отдельном тесте. Параметризованная регистрация попадает в
отчёт поимённо как `unchecked`, а не пропускается молча, — дайте ей образец, чтобы покрыть:

```dart
await expectGraphResolves(scope, params: {AlloyKey(Greeting): (name: 'x', loud: false)});
```

### Фикстуры

```dart
final scope = alloyTestRoot()
  ..registerLazySingleton<Clock>(FnFactory((_) => FixedClock(DateTime(2026))))
  ..registerSingleton<Config>(const Config())
  ..registerAsyncSingleton<Db>(AsyncFnFactory((_) async => Db()));

await scope.init();
```

Они избавляют от класса-фабрики на каждую заглушку в тестах, которым не нужен весь сгенерированный
граф. Async-регистрации обязаны существовать **до** `init()` — поэтому фикстуры кладутся в свежий
корень, а не в уже запущенный скоуп.

`DisposeRecorder` — фикстура для утверждений о разборе, с журналом на инстанс, а не общим: скоуп,
разобравшийся после своего теста, не сможет отчитаться в следующий. `CapturingObserver` собирает
события для утверждений о том, что граф делал.

### Виджет-тесты

`alloy_test_flutter` несёт два хелпера, у которых очевидное написание — неверное:

```dart
await settle(tester);                    // не pumpAndSettle: он крутится вечно на индикаторе загрузки
final scope = mountedRootScope(tester);  // граф приложения, из-под билдера MaterialApp
```

### Как держать сгенерированный код честным в CI

Перегенерировать и упасть на диффе:

```bash
dart run build_runner build
git diff --exit-code
```

Без этого вывод генератора расходится с аннотациями, и никто не замечает, пока граф не окажется
неверным в рантайме.

---

## 19. Ошибки, о которых стоит знать заранее

Каждая найдена дорого — в этом репозитории или в приложениях, ради которых он писался.

- **Не закоммитить `alloy.g.dart` или закоммитить устаревший.** Перегенерируйте в CI и сверяйте
  диффом. Это единственная реальная обязанность по обслуживанию в этом режиме.
- **Два `@AlloyScopeRoot` в одном пакете.** Ошибка сборки, и лечится она двумя пакетами:
  `alloy_container` агрегирует весь пакет в один корень.
- **`@AlloyInject` на generic-классе.** Отвергается: генератору никто не говорит, какие
  инстанциации регистрировать. Разметьте конкретный подтип или выставьте его через `exposeAs`.
  Дженерики прекрасно работают как зависимости и как цели `exposeAs`.
- **`@injected` без `with _$ClassName`.** Поля остаются незаполненными, и первое же чтение даёт
  `LateError`. Линтер скажет раньше.
- **Пообещать через `provides:` и не зарегистрировать.** Проверка вам поверила, поэтому отказ уехал
  в рантайм. Покрывайте `expectGraphResolves`.
- **Построение графа внутри `testWidgets`.** Fake-async, ничего не завершается, таймаут, которому
  нечего предъявить. `setUp`.
- **Подмена ниже потребителя.** Фабрика выполняется на скоупе-владельце. `ownerOf<T>()` скажет об
  этом раньше, чем ассерт.
- **`BlocProvider(create:)` для блока, которым владеет скоуп.** Два владельца, и виджет успевает
  первым. `BlocProvider.value`.
- **`ChangeNotifier` или `Cubit`, зарегистрированный без объявления закрываемости.** Построен,
  использован, никогда не закрыт, молча. `implements Disposable`, `with AlloyBloc` или `dispose:`.
- **Старый `dart` первым в PATH.** Ломается негромко и не там: `dart analyze` выдаёт фантомные issue
  против чужого анализатора, а вывод генератора смещается между версиями форматтера. Проверяйте
  `dart --version`, прежде чем верить прогону.

---

## Куда дальше

- [GUIDE_MANUAL.ru.md](GUIDE_MANUAL.ru.md) — тот же рантайм без шага сборки и что с чем
  композируется.
- [README.ru.md](README.ru.md) — что такое Alloy и почему каждое решение принято именно так.
- [MIGRATION.ru.md](MIGRATION.ru.md) — с `get_it` и `injectable`, включая то, что не переводится.
- `examples/codegen_basics` — наименьшая генерируемая обвязка, `examples/notes_app` — наибольшая.
  Оба запускаются из галереи: `cd examples/gallery && flutter run`.
