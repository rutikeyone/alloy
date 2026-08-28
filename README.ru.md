[English](README.md) · [Русский](README.ru.md) · [中文](README.zh-CN.md)

> Перевод [README.md](README.md). Канонический текст — английский: при расхождении верен он.
> README отдельных пакетов не переводятся — это справочники по API.

# Alloy

Фреймворк внедрения зависимостей для Dart и Flutter. Два режима: декларативная кодогенерация и
рукописный API на чистом Dart поверх одного и того же рантайма.

Статус: **Фаза 1 завершена.** Рантайм, Flutter-биндинги, аннотации, слой анализа, оба генератора и
плагин линтера реализованы и покрыты тестами.

Пришли с уже работающим `get_it` или `injectable`? Начните с
[MIGRATION.ru.md](MIGRATION.ru.md) — там разобрано, что во что переводится и, что полезнее,
что не переводится вовсе.

## Пакеты

| Пакет | Зависит от | Попадает в приложение |
|---|---|---|
| `alloy_annotations` | `meta` | да |
| `alloy` | `alloy_annotations` | да, ядро рантайма, без Flutter |
| `alloy_flutter` | `alloy`, `flutter` | да |
| `alloy_go_router` | `alloy_flutter`, `go_router` | да, опционально |
| `alloy_talker` | `alloy`, `talker` | да, опционально |
| `alloy_logging` | `alloy`, `logging` | да, опционально |
| `alloy_logger` | `alloy`, `logger` | да, опционально |
| `alloy_analyzer` | `alloy_annotations`, `analyzer` | нет |
| `alloy_generator` | `alloy_analyzer`, `build`, `source_gen`, `code_builder` | только dev_dependency |
| `alloy_lint` | `alloy_analyzer`, `analysis_server_plugin` | только dev_dependency |
| `alloy_test` | `alloy`, `test_api`, `matcher` | только dev_dependency |
| `alloy_inspector` | `alloy_flutter`, `flutter` | только dev_dependency |
| `alloy_talker_flutter` | `alloy_inspector`, `alloy_talker`, `talker_flutter` | dev_dependency only |

`alloy_analyzer` существует затем, чтобы генератор и линтер разбирали объявления Alloy **одной**
реализацией, а не двумя, которые неизбежно разойдутся. Он владеет IR и топологической сортировкой и
не зависит ни от `build`, ни от API плагина.

**Инвариант проекта:** сгенерированный код имеет право использовать только публичный API `alloy`.
В тот момент, когда генерации понадобится что-то, чего не выражает Manual Mode, это два разных
фреймворка под одним именем.

## Инструментарий

Собрано и проверено на **Flutter 3.47.1 / Dart 3.13.1**, analyzer 13.3.0.

Все пакеты требуют Dart `^3.13.0`, а его не поставляет ни один Flutter ниже **3.47** — значит это
единый пол для всех, и расхождения версий между пакетами, за которым надо следить, попросту нет.
CI гоняет `stable` и `beta`, а не матрицу прошлых релизов: полезно ловить ту поломку, которая ещё
не вышла.

Не держите в PATH `dart` из Homebrew — ставьте Flutter SDK первым. Старый `dart` ломается негромко:
`dart analyze .` выдаёт десятки фантомных issue против чужого анализатора, а `dart pub get` честно
отказывается от констрейнта SDK. Проверяйте `dart --version`, прежде чем верить прогону.

`dart_style` пиньте сознательно: 3.1.7 требует `analyzer <12.0.0` и молча держит весь workspace на
три мажора позади. Эталонный вывод к тому же меняется между релизами форматтера.

## Проверка

```
dart analyze --fatal-infos .
dart format --output=none --set-exit-if-changed .
(cd packages/alloy && dart test)
(cd packages/alloy_flutter && flutter test)
(cd examples/manual_mode && dart test)
(cd examples/codegen_basics && dart run build_runner build && flutter test)
(cd examples/notes_app && dart run build_runner build && flutter test)
(cd packages/alloy_lint && dart test)
(cd packages/alloy_test && dart test)
(cd packages/alloy_inspector && flutter test)
(cd packages/alloy_talker_flutter && flutter test)
(cd examples/gallery && flutter test)
(cd compat/external_consumer && dart pub get && dart run build_runner build && dart test)
./tool/coverage.sh
```

`tool/coverage.sh` меряет построчное покрытие одиннадцати публикуемых пакетов с тестами, печатает
их от худшего и падает ниже порога по **сумме** — 85% против 92.2% сегодня. Порог именно на сумме,
а не на каждом пакете, и это осознанно: покрытие меряется по пакетам, а код общий, поэтому парсеры
`alloy_analyzer` гоняются куда больше из тестов `alloy_generator` и из `compat/external_consumer`,
чем из собственного набора. Порог на пакет требовал бы писать тесты не там, где им место.
Переопределяется через `COVERAGE_FLOOR=90 ./tool/coverage.sh`.

CI (`.github/workflows/ci.yml`) гоняет всё перечисленное плюс `git diff --exit-code` после
регенерации обоих примеров **и `compat/external_consumer`**, так что устаревший сгенерированный код
валит сборку. Генератор форматирует свой вывод той же версией `dart_style`, что и проверка формата,
поэтому они никогда не спорят.

## Тестирование приложения на Alloy

`testWidgets` выполняет тело в fake-async зоне, поэтому `Future.delayed` в инициализаторе там не
завершается никогда. Стройте корневой скоуп в `setUp`, а не внутри `testWidgets`, а утверждения про
граф целиком держите в обычном `test`. `examples/notes_app/test/screens_test.dart` использует оба
подхода.

Чтобы подменить зависимость, создайте дочерний скоуп и зарегистрируйте её заново: дубликат внутри
одного скоупа — ошибка, а затенение из дочернего — штатный способ, и в тестах, и в продакшене.

`alloy_test` упаковывает механику: `alloyTestScope` строит граф и разбирает его вместе с тестом,
`pushForTest` делает то же для скоупа подмены, а `ownerOf<T>()` отвечает на вопрос, на котором
спотыкаются все однажды: фабрика вызывается на скоупе-**владельце** своей регистрации, поэтому
подмена ниже потребителя ему не видна.

Там же `expectGraphResolves` — единственный способ проверить рукописный граф. Генератор отвергает
неполный граф на сборке, но видит только то, что сам сгенерировал; фабрика не объявляет, что
попросит, поэтому ручной граф проверяется только исполнением. Проверка терминальна: резолв **и
есть** проверка, поэтому после неё каждый ленивый синглтон построен.

## Известное предупреждение при публикации

`alloy_lint` сообщает «the name of lib/main.dart should match the name of the package». Эта точка
входа задана API плагина сервера анализа — сервер генерирует код, который импортирует
`package:alloy_lint/main.dart` и читает его переменную `plugin`. У `riverpod_lint` то же самое
предупреждение.

## Раскладка

Один публичный тип на файл. Sealed-иерархия `AlloyRegistration` — осознанное исключение: sealed
обязана жить в одной библиотеке, поэтому её наследники это `part`-файлы
`src/registration/alloy_registration.dart`, а не отдельные библиотеки.

`compat/external_consumer` — единственный каталог вне этого правила: это пакет, намеренно **не**
входящий в workspace и не объявляющий `resolution: workspace`, так что pub резолвит его
самостоятельно, ровно как сторонний проект. Он существует, чтобы держать пайплайн кодогенерации
честным снаружи репозитория — см. его собственный README.

## Генераторы

`alloy_generator` поставляет три билдера:

| Билдер | Вход → выход | Назначение |
|---|---|---|
| `alloy_property_injection` | `.dart` → `.alloy.g.part` | миксины, заполняющие `late final` поля |
| `alloy_scan` | `.dart` → `.alloy.json` (кэш) | IR по одной библиотеке |
| `alloy_container` | `$lib$` → `lib/alloy.g.dart` | `$AlloyRootScope`, `$alloyBootstrap`, `$startAlloy()` |

`alloy_scan` идёт до `alloy_container`; агрегирующий билдер читает все `.alloy.json` через
`findAssets`, потому что один build step не видит программу целиком. На выходе — приватные
const-классы-фабрики и `$AlloyRootScope`, где регистрации упорядочены компайл-тайм топологической
сортировкой. Поля с property injection считаются рёбрами графа, поэтому блок всегда регистрируется
после того, что он инжектит. Цикл валит сборку, называя цикл, а не эмитит сломанный код.

Дженерики работают и как зависимости, и как цель `exposeAs`: `Repository<User>` и
`Repository<Order>` — две разные регистрации, потому что в рантайме `AlloyKey` строится от `Type`, а
это разные типы. А вот **сам инъектируемый класс** дженериком быть не может:
`@AlloyInject class Cache<T>` отвергается, поскольку ничто не сообщает генератору, какие
инстанциации регистрировать. Аннотируйте конкретный подтип или выставьте его через `exposeAs`.

Нуллабельность не входит в *ключ* регистрации — зависимость `Foo?` по-прежнему читает регистрацию
`Foo`, — но помечает зависимость **опциональной**. Нуллабельный параметр конструктора или
`@injected`-поле резолвятся через `getOrNull`, поэтому граф, в котором для них ничего не
зарегистрировано, подставит null, а не уронит сборку. Обязательные зависимости не меняются, а
опциональная остаётся ребром порядка, если регистрация всё-таки есть.

Опциональность — работа типа, а не аннотации: без `?` поле всё равно не примет null. В рантайме это
`scope.getOrNull<Foo>()`, который возвращает null **только** когда ничего не зарегистрировано:
async-синглтон, запрошенный до `init()`, по-прежнему бросает, потому что «не готово» и «нет» —
разные факты.

Классы с `@AlloyBootstrap` собираются в `$alloyBootstrap`, упорядоченные по `order`, а затем по
имени, чтобы вывод был стабильным. Они выполняются строго последовательно, до появления контейнера,
поэтому парсер отвергает шаг, чей конструктор требует параметры.

`$alloyBootstrap` эмитится **геттером**, а не хранимым списком: top-level `final` построил бы шаги
один раз на процесс, молча разделив их между повторной попыткой старта и между тестами, и оставив
живыми после смерти усыновившего их скоупа. Отработавшие шаги корневой скоуп **усыновляет**, так
что шаг, который что-то открыл, закрывается при разборе — последним, после всего, что построено
поверх него. Если шаг упал, уже отработавшие освобождаются в обратном порядке до выброса ошибки:
скоупа, которому их передать, ещё нет.

Классы с `@AlloyInit` становятся асинхронными синглтонами: сгенерированная фабрика конструирует
объект, дожидается его `init()` и регистрирует с `dependsOn`, переведённым в `AlloyKey`. Заметьте,
что литерал множества строится в рантайме, а не `const`: `AlloyKey` переопределяет `==`, а элементы
const-множества обязаны иметь примитивное равенство.

### Окружения — опционально

Пока ничего из перечисленного этого не требует. Проект, который никогда не пишет
`@AlloyEnvironment`, имеет ровно один граф, все регистрации принадлежат ему, а `$startAlloy()` не
принимает никакого окружения. Читайте дальше только когда одной сборке нужна другая реализация,
чем другой.

`@AlloyEnvironment` ограничивает регистрацию одним или несколькими окружениями:

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

`dev`, `stage`, `prod` и `test` — константы, а не закрытое множество: `@AlloyEnvironment('canary')`
объявляет своё собственное и ведёт себя точно так же. Аннотация **повторяется**, а не принимает
список, потому что регистрация принадлежит *множеству* окружений, а старт выбирает ровно *одно*:

```dart
final scope = await $startAlloy(environment: AlloyEnvironment.prod);
```

Сгенерированный контейнер принимает выбор полем и оборачивает условием только ограниченные
регистрации:

```dart
final class $AlloyRootScope implements AlloyScopeBuilder {
  const $AlloyRootScope({
    this.environment = AlloyEnvironment.defaultEnvironment,
  });

  final AlloyEnvironment environment;

  @override
  void build(AlloyScope scope) {
    scope.registerLazySingleton<EventLog>(const _EventLogFactory());
    if (environment.matches(const <String>{'dev', 'test'})) {
      scope.registerLazySingleton<ApiClient>(const _FakeApiClientFactory());
    }
    if (environment.matches(const <String>{'prod', 'stage'})) {
      scope.registerLazySingleton<ApiClient>(const _LiveApiClientFactory());
    }
  }
}
```

Из этой формы следуют три вещи:

- **Опциональность сохраняется до конца.** Параметр `environment` появляется только когда какое-то
  объявление называет окружение, и даже тогда у него есть дефолт
  `AlloyEnvironment.defaultEnvironment` — то самое единственное окружение неразделённого графа. Этот
  дефолт матчит только регистрации без ограничений, поэтому запуск разделённого графа без выбора
  оставляет разделённые типы незарегистрированными, и первый же их резолв падает с внятной ошибкой,
  а не молча отдаёт не тот класс.
- **Ничто не регистрируется дважды.** Генератор отвергает две регистрации одного типа с
  пересекающимися окружениями — включая случай, когда одна не называет окружения вовсе, ведь
  неограниченная регистрация присутствует везде. То, что иначе было бы молчаливым last-one-wins,
  становится ошибкой сборки с именами обоих классов и окружения, в котором они столкнулись.
- **Manual Mode умеет то же самое.** `matches` — обычный публичный API, поэтому рукописный билдер
  пишет тот же `if`, что эмитит генератор. Унаследуйтесь от `AlloyEnvironment` и переопределите
  `matches`, чтобы активировать несколько сразу или матчить не по имени.

Шаги `@AlloyBootstrap` тоже принимают окружения. Когда хоть один это делает, `$alloyBootstrap`
превращается из геттера в функцию выбранного окружения, а пропущенные шаги не выполняются и не
усыновляются:

```dart
List<AlloyBootstrapStep> $alloyBootstrap(AlloyEnvironment environment) => [
  BindPlatform(),
  if (environment.matches(const <String>{'prod', 'stage'})) ReportCrashes(),
];
```

Окружение, которого никто не заявляет, легально и оставляет соответствующие типы
незарегистрированными: их резолв упадёт обычной ошибкой «не зарегистрировано», а не подсунет
чужой класс.

`@AlloyScopeRoot` именует корневой скоуп и сводит старт к одному вызову:

```dart
final scope = await $startAlloy();
```

Генератор эмитит `$alloyRootScopeName` и `$startAlloy()`, связывающий контейнер, список bootstrap и
имя. Без аннотации имя по умолчанию `root`; два аннотированных класса в одном пакете — ошибка
генерации.

### Регистрация типов, которые писали не вы

`@AlloyInject` вешается на класс, поэтому достаёт только до ваших классов. Всё остальное — клиент
из другого пакета, значение из SDK — попадает в граф через модуль:

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

Сама аннотация ничего не несёт: каждый член настраивает свою регистрацию теми же аннотациями, что и
класс, а его параметры резолвятся как параметры конструктора. Классу нужен публичный `const`
конструктор без аргументов — тогда фабрика держит `const NetworkModule()` и не несёт состояния.

`Future<T>` — единственный признак асинхронности: такой член становится async-синглтоном, а порядок
между async-членами генератор вычисляет сам, а не просит написать. Абстрактным член быть не может:
«собрать класс из его конструктора» — это ровно то, что уже значит `@AlloyInject`.

`dispose` — то, чем закрывается чужой тип. Скоуп владеет тем, что построил, но тип из другого
пакета не реализует ни `Disposable`, ни `AsyncDisposable` и не может сказать, как его закрыть.
Параметр доступен у любой удерживаемой регистрации, в том числе в Manual Mode:

```dart
scope.registerLazySingleton<http.Client>(
  const ClientFactory(),
  dispose: (client) => client.close(),
);
```

### Граф обязан быть полным до того, как соберётся

Зависимость, которую никто не регистрирует, валит сборку и перечисляет сразу все пробелы:

```
Diagnostics requires DeviceInfo, which nothing registers. Annotate the class that
provides it with @AlloyInject, or name it in @AlloyScopeRoot(provides: [...]) when
something outside the generated container registers it.
```

Параметр, помеченный `@AlloyParam`, не считается: его подаёт место вызова, поэтому его никто не
регистрирует и вокруг него нечего упорядочивать. Такая пометка делает класс параметризованной
регистрацией, а генератор пишет тип аргумента рядом с контейнером как именованную запись:

```dart
@alloyInject
class NoteEditor {
  NoteEditor(this._notes, {@alloyParam required this.id, @alloyParam this.draft = false});
  ...
}

// typedef $NoteEditorArgs = ({int id, bool draft});
context.alloyWithParam<NoteEditor, $NoteEditorArgs>((id: 7, draft: true));
```

Считаются параметры конструктора, поля `@injected` и `@AlloyInit(dependsOn:)`, а имя из `@Named`
входит в ключ: запрос `@Named('audit') Logger` при одном лишь безымянном `Logger` — тоже пробел.
Каждое окружение проверяется отдельно, поэтому регистрация только для `dev` не удовлетворяет
потребителя, который работает ещё и в `prod`.

Контейнер видит аннотации только своего пакета. Всё, что зарегистрировано руками — билдер скоупа
поверх `$AlloyRootScope` или провайдер из другого пакета, — нужно пообещать:

```dart
@AlloyScopeRoot(name: 'app', provides: [SessionManager])
class AppScope {
  const AppScope();
}
```

Обещание ничего не регистрирует, оно лишь сообщает проверке, что это сделает кто-то другой.
`AlloyProvided(Logger, name: 'audit')` обещает именованную регистрацию.

Это гарантия Code-Gen Mode. Рукописная фабрика резолвит внутри `create`, и статически увидеть, что
она попросит, нельзя — графы Manual Mode по-прежнему падают в рантайме с
`AlloyNotRegisteredError`.

## Кто владеет корневым скоупом

`AlloyAppScope`. Он строит граф, публикует его, разбирает при размонтировании и превращает падение
старта в экран с кнопкой повтора вместо приложения, умершего до первого кадра.

Граф он принимает так же, как `AlloyApplication.start`, и живёт в `MaterialApp.builder`, поэтому
`loading` и `errorBuilder` — обычные экраны с темой приложения, а не второй `MaterialApp`:

```dart
void main() => runApp(
  MaterialApp(
    builder: AlloyAppScope.builder(
      root: $AlloyRootScope(environment: environment),
      bootstrap: () => $alloyBootstrap(environment),
      rootName: $alloyRootScopeName,
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    home: const HomeScreen(),
  ),
);
```

`bootstrap` — функция, а не список, и это намеренно: шаги держат ресурсы, а рестарт обязан получить
новые. Для графа, который эта форма не выражает, остаётся `AlloyAppScope.start(start: ...)`.

`AlloyAppScope.of(context).restart()` пересобирает граф — тот же вызов повторяет упавший старт.
Разбор при завершении приложения включается вручную (`disposeOnExitRequest`) и на практике работает
только на десктопе; почему Flutter не может обещать это на мобильных, написано в README
`alloy_flutter`.

## Наблюдение за графом

`AlloyObserver` сообщает, что делает граф: появляются скоупы, строятся инстансы, завершается старт,
падает разбор. Наблюдатели передаются туда, где граф создаётся:

```dart
final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyLogObserver(const AlloyDeveloperLogSink())],
);
```

Наблюдателей наследует каждый скоуп, созданный ниже, так что одна регистрация покрывает дерево.

Дизайн определяют две вещи. Колбэки получают `AlloyScopeRef` и `AlloyKey` — описатели, а не живые
объекты, потому что наблюдатель, способный резолвить из скоупа посреди разбора или диспоузнуть его
второй раз, уже не наблюдает. И исключение из колбэка проглатывается: наблюдение не должно уметь
ломать наблюдаемое.

Резолв не логируется. Попадание в кэш — горячий путь, и событие на каждый `get` было бы шумом;
видеть стоит **создание** инстанса, что и покрывает `onInstanceCreated`. Без зарегистрированных
наблюдателей цена каждого события — одна проверка пустого списка.

`AlloyLogObserver` превращает события в `AlloyLogRecord` и отдаёт их в `AlloyLogSink`.
`AlloyDeveloperLogSink` (`dart:developer`, без зависимостей) поставляется в `alloy`; остальное
подключают пакеты-адаптеры:

| Пакет | Форма | Зачем |
|---|---|---|
| `alloy_talker` | `AlloyObserver` | каждый вид события — свой цветной `TalkerLog`, фильтруемый в `TalkerScreen` |
| `alloy_logging` | `AlloyLogSink` | у `logging` с dart.dev нет понятия вида записи |
| `alloy_logger` | `AlloyLogSink` | то же плюс собственный вывод в консоль |

### Любой другой логгер, без пакета

Приёмник — это один колбэк, поэтому ничто не остаётся за бортом из-за отсутствия адаптера:

```dart
AlloyLogObserver(AlloyLogSink.from((record) => myLogger.debug(record.message)))
```

| Логгер | Вся интеграция целиком |
|---|---|
| `loggy` | `AlloyLogSink.from((r) => logDebug(r.message))` |
| `fimber` | `AlloyLogSink.from((r) => Fimber.d(r.message, ex: r.error))` |
| `simple_logger` | `AlloyLogSink.from((r) => logger.info(r.message))` |
| Graylog и любой JSON-приёмник | `AlloyLogSink.from((r) => gelf.send(r.toStructured()))` |

Запись — не просто строка. В ней есть `level`, `scope`, `key`, `error` и `stackTrace`, а `kind`
называет событие значением: `AlloyEventKind.scopeInitFailed` вместо фразы
`scope "app" failed to initialize`, которую вольны переписать. `toStructured()` отдаёт всё это
картой — в этом и состоит целиком приёмник GELF или JSON.

### Крашрепортинг — другая форма

Приёмнику логов отдают каждую строку, и он обязан быть дешёвым. Крашрепортеру отдают дискретные
инциденты ценой в сетевой вызов и квоту, а полезным отчёт делает не исключение, а то, что граф
делал до него. `AlloyErrorObserver` сообщает о сбоях вместе с этим следом:

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

| Репортер | Вся интеграция целиком |
|---|---|
| Sentry | `AlloyErrorSink.from((r) => Sentry.captureException(r.error, stackTrace: r.stackTrace))` |
| Crashlytics | `AlloyErrorSink.from((r) => FirebaseCrashlytics.instance.recordError(r.error, r.stackTrace))` |

Два дефолта, о которых стоит знать. След копится на всех уровнях, включая поинстансные записи,
которые приёмник логов по умолчанию отбрасывает: они ничего не стоят, пока ничего не сломалось, а
«что построилось последним» — обычно и есть нужная строка. Это кольцо на 20 записей, так что
долгоживущее приложение не может растить его без предела. Порог отчёта — `error`, а не `warning`:
сбой разбора приходит warning'ом и действительно означает утёкший ресурс, но слать в платный сервис
на каждую заминку — верный способ, чтобы отчёты перестали читать. Понижается через `reportAt`.

Сообщается только то, что Alloy знает сам: упавший инициализатор, упавший bootstrap-шаг,
незавершённый разбор. Метода «зарепортить произвольную ошибку» нет — общей шиной ошибок это не
является, для неё есть тот репортер, который у вас уже стоит.

`AlloyMultiSink` разводит одну запись по нескольким адресатам, и упавший приёмник не заглушает
остальных — консоль плюс крашрепортинг это нормальная продакшен-пара:

```dart
AlloyLogObserver(
  const AlloyMultiSink([AlloyDeveloperLogSink(), _CrashReporterSink()]),
)
```

Два приёмника поставляются в самом `alloy` и не тянут зависимостей: `AlloyDeveloperLogSink`
(`dart:developer`, правильный дефолт во Flutter-приложении) и `AlloyPrintLogSink` (stdout, для CLI
и первого взгляда).

Этот же канал закрыл реальную дыру: когда старт падает и Alloy откатывается, bootstrap-шаг,
который **тоже** не смог освободиться, невозможно сообщить через `AlloyBootstrapError`, не замаскировав
исходную причину. Раньше он терялся в голом `catch`. Теперь это `onBootstrapStepReleaseFailed`.

## Скоупы флоу

`alloy_go_router` делает время жизни скоупа навигационным флоу — создаётся при входе, разбирается
при выходе:

```dart
AlloyShellRoute(
  name: 'checkout',
  identity: (state) => state.pathParameters['orderId'],
  scope: (state) => CheckoutScope(state.pathParameters['orderId']!),
  routes: [...],
)
```

Это обычный наследник `ShellRoute` — то есть он встаёт в таблицу роутов везде, где принимается
`RouteBase`, а флоу можно дать собственное имя, унаследовавшись от него. Скоупом владеет виджет
внутри. Этого достаточно, потому что go_router ключует страницу шелла идентичностью объекта роута,
так что поддерево переживает любую навигацию *внутри* флоу и уничтожается в тот кадр, когда флоу
покидает match list. Никто не слушает роутер и не зеркалит его — именно на зеркалировании
рукописные версии ломаются на кнопке «назад», на deep link и на переключении вкладок.

Вкладки получают то же самое: `AlloyStatefulShellRoute` скоупит весь `StatefulShellRoute`, а
`AlloyStatefulShellBranch` — одну вкладку, и они композируются в три уровня. Но ветка держится
*живой*, а не *видимой*: go_router сохраняет навигаторы веток за кадром, поэтому скоуп вкладки
живёт до закрытия шелла, а не до ухода с неё.

Единственное, чего роутер не может решить, — считать ли `/orders/1` и `/orders/2` одним флоу; на
это отвечает `identity`. Флоу, чьи роуты не лежат одним поддеревом, так выразить нельзя, и это
ограничение осознанное — см. README пакета.

## Примеры

Всё запускается одним приложением:

```bash
cd examples/gallery && flutter run
```

Галерея устроена **по возможностям**, а не по проектам: читатель приходит узнать, как заканчиваются
скоупы, а не посмотреть на `notes_app`. Четырнадцать записей в шести секциях:

| Секция | Записи |
|---|---|
| Startup | Двухфазный старт · Окружения |
| Injection | Property injection · Именованные и множественные |
| Scopes & lifetime | Скоуп на виджет · Сессионный скоуп · Дерево скоупов · Навигационные флоу · Разбор |
| Code generation | Сгенерированный контейнер · Manual Mode |
| Observability | События графа · Инспектор внутри приложения |
| Testing | Приёмы тестирования |

Каждая запись с интерфейсом открывается со **своим** графом: он строится при входе и разбирается
при выходе. Откройте две — их деревья скоупов не связаны, и ровно это галерея и показывает. Три
записи без интерфейса (`Разбор`, `Manual Mode`, `Приёмы тестирования`) вместо кнопки показывают
вывод в консоль: галерея, предлагающая «открыть» CLI, врала бы.

Галерея написана на английском, русском и китайском, язык переключается прямо на хабе. Проза
каталога переводится вместе с ней; экраны примеров, которые галерея монтирует, — нет, как и
записи журнала, которые пишет сам фреймворк. Что именно остаётся словами Alloy и почему — в
[README `alloy_inspector`](packages/alloy_inspector/README.md).

Под капотом примеры остаются обычными пакетами в `examples/` — `notes_app`, `flow_scopes`,
`graph_events`, `codegen_basics` это библиотеки, которые галерея монтирует, а `manual_mode`,
`teardown`, `testing_patterns` — чистый Dart или только тесты. Разделены они не ради порядка:
`alloy_container` собирает пакет целиком в один `$AlloyRootScope`, поэтому два генерируемых
примера в одном пакете имели бы общий граф.

## Плагин линтера

`alloy_lint` — это `analysis_server_plugin`, а не плагин `custom_lint` (см. «Инструментарий»). Он
поставляет девять warning-правил, все построены на том же слое разбора `alloy_analyzer`, что и
генератор, поэтому ошибка всплывает в IDE, а не только на прогоне `build_runner`:

| Правило | Что ловит |
|---|---|
| `alloy_missing_injection_mixin` | поля `@injected` без `with _$ClassName` |
| `alloy_injected_field_must_be_late_final` | `@injected` на изменяемом, не-late или статическом поле |
| `alloy_injectable_must_be_constructible` | `@AlloyInject` на абстрактном классе или на классе без публичного генеративного конструктора |
| `alloy_init_requires_init_method` | `@AlloyInit` на классе без `init()` |
| `alloy_bootstrap_requires_run_method` | `@AlloyBootstrap` на классе без `run()` |
| `alloy_bootstrap_step_cannot_inject` | bootstrap-шаг, чей конструктор требует параметры |
| `alloy_dependency_is_not_registered` | зависимость, которую в пакете никто не регистрирует |
| `alloy_dependency_cycle` | инъектируемый класс, который в итоге зависит от самого себя |
| `alloy_environment_needs_a_registration` | `@AlloyEnvironment` на классе, который никто не регистрирует, где она молча ничего не делает |

Две вещи при подключении стоят реального времени и легко делаются неправильно:

1. Секция `plugins:` **работает только в корне пакета или workspace**. Положите её во вложенный
   `analysis_options.yaml` — и она молча проигнорируется: ни ошибки, ни диагностик. По той же
   причине `dart analyze <nested/dir>` её не применяет; анализируйте корень workspace.
2. Сервер анализа резолвит плагины в изолированном pub-контексте, поэтому неопубликованные соседи
   по workspace ему невидимы. Каждой неопубликованной транзитивной зависимости нужна запись в
   `plugins: dependency_overrides:` — см. корневой `analysis_options.yaml` этого репозитория.

Поведение правил покрыто тестами на `analyzer_testing` в `packages/alloy_lint/test`: они гоняют
правила напрямую и не требуют никакой обвязки плагина.

## Линтинг

`custom_lint` не используется. Его последний релиз (0.8.1) прибит к `analyzer ^8.0.0` и не может
сосуществовать с современным анализатором; `riverpod_lint` ушёл с него на первопартийный
`analysis_server_plugin`, и `alloy_lint` следует за ним.
