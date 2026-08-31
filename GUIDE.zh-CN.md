[English](GUIDE.md) · [Русский](GUIDE.ru.md) · [中文](GUIDE.zh-CN.md)

> 本文档译自 [GUIDE.md](GUIDE.md)。英文版为准：若有出入，以英文为准。

# Alloy 实践指南

这里的每段代码都是可用的写法，取自 `examples/` 下的示例包，而不是为文档现编的。
[README.zh-CN.md](README.zh-CN.md) 讲的是 Alloy 是什么、为什么这样设计；本文讲的是怎么用，
顺序就是你实际遇到每一部分的顺序。

从 `get_it` 或 `injectable` 过来？先看 [MIGRATION.zh-CN.md](MIGRATION.zh-CN.md)——
它把你已经熟悉的 API 映射到这一套上，更有用的是，说清了哪些根本对不上。

---

## 目录

1. [安装](#1-安装)
2. [手写的依赖图](#2-手写的依赖图)
3. [同一张图，改用生成](#3-同一张图改用生成)
4. [启动 Flutter 应用](#4-启动-flutter-应用)
5. [在 widget 中读取依赖](#5-在-widget-中读取依赖)
6. [比应用先结束的作用域](#6-比应用先结束的作用域)
7. [关闭你注册的东西](#7-关闭你注册的东西)
8. [必须在启动前完成的工作](#8-必须在启动前完成的工作)
9. [来自调用方的值](#9-来自调用方的值)
10. [不是你写的类型](#10-不是你写的类型)
11. [一张图，多种构建](#11-一张图多种构建)
12. [观察这张图](#12-观察这张图)
13. [测试](#13-测试)
14. [lint 插件](#14-lint-插件)
15. [值得提前知道的坑](#15-值得提前知道的坑)

---

## 1. 安装

只加你要用的。运行时是纯 Dart，它以下的任何东西都不会拉进 Flutter。

| 你想要 | 加什么 |
|---|---|
| 在任意 Dart 程序里手写容器 | `alloy` |
| widget、`context.alloy<T>()`、由应用持有的根作用域 | `alloy_flutter` |
| 注解与生成的容器 | `alloy_generator`（dev）、`build_runner`（dev） |
| 编辑器里的规则 | `alloy_lint`（dev） |
| 测试辅助 | `alloy_test`（dev）、`alloy_test_flutter`（dev，widget 测试） |
| 每个导航流程一个作用域 | `alloy_go_router` |
| 作用域能关闭的 bloc | `alloy_bloc` |
| 运行时在屏幕上看这张图 | `alloy_inspector`（dev） |

带代码生成的 Flutter 应用：

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

纯 Dart 程序——命令行工具、服务端、没有 widget 的包——一行就够：

```yaml
dependencies:
  alloy: ^0.1.0
```

`alloy_flutter` 会重新导出整个运行时，所以应用永远不需要同时导入两个。

---

## 2. 手写的依赖图

即使你打算用生成，也请从这里开始。生成器写出来的就是这些，且只用公开 API——
所以知道它的产物长什么样，就是知道这个框架。

注册项是一个对象，不是闭包。正因如此工厂可以是 `const`、不持有捕获状态，并在每次启动之间复用。

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

**作用域构建器**说明一个作用域里有什么。它只注册，从不解析。

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

  app.get<EventLog>().add('started at ${app.get<Clock>().now()}');

  await app.dispose();
}
```

### 五种注册方式

| 调用 | 何时构建 | 作用域是否持有 |
|---|---|---|
| `registerSingleton<T>(value)` | 已由你构建 | 是 |
| `registerLazySingleton<T>(factory)` | 首次解析时 | 是 |
| `registerAsyncSingleton<T>(factory)` | 在 `init()` 中，按依赖顺序 | 是 |
| `registerFactory<T>(factory)` | 每次解析 | 否 |
| `registerParamFactory<T, P>(factory)` | 每次解析，带一个参数 | 否 |

「是否持有」就是全部区别所在：作用域销毁时释放它持有的东西，而瞬态对象不归它释放——
见 [§7](#7-关闭你注册的东西)。

### 五种读取方式

```dart
scope.get<Repository>();                       // 没有注册就抛异常
scope.getOrNull<Telemetry>();                  // 改为返回 null——什么时候该这样，见 §9
scope.get<Logger>(name: 'audit');              // 命名注册
scope.getAll<NoteFormatter>();                 // 该类型的全部注册，就近作用域在前
scope.getWithParam<Counter, String>('alice');  // 参数化注册
```

`isRegistered<T>()` 不构建任何东西就能回答——当某个注册与环境相关、合法地可能不存在时，
界面需要的正是它。

---

## 3. 同一张图，改用生成

给类加上注解，构建器交给生成器写。

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

`@alloyInject` 是懒汉单例。`@alloySingleton` 和 `@alloyTransient` 选择另外两种生命周期，
完整形式则承载其余配置：

```dart
@AlloyInject(exposeAs: ApiClient, name: 'live', dispose: closeClient)
class LiveApiClient implements ApiClient { ... }
```

根作用域在包内任意位置命名一次：

```dart
@AlloyScopeRoot(name: 'app')
class AppScope {
  const AppScope();
}
```

然后生成：

```bash
dart run build_runner build
```

产物是 `lib/alloy.g.dart`：私有 const 工厂类、注册顺序由编译期拓扑排序确定的 `$AlloyRootScope`，
以及把容器、bootstrap 列表和根名称串起来的 `$startAlloy()`：

```dart
final scope = await $startAlloy();
```

生成的文件要提交。CI 会重新生成并在有 diff 时失败——过时的产物就是这样被抓住的。

### 属性注入，写给变长的构造函数

有五个协作对象的类不需要五个构造参数。声明字段，混入生成器写在旁边的 mixin：

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

字段是 `late final`，因此只写一次——再次赋值会抛 `LateError`——并且可以是私有的，
因为生成的 mixin 是同一个库的 `part`。被注入的字段和其他依赖一样是图的边，
所以 bloc 总是排在它注入的东西之后注册。

### 在生成的根之上做组合

生成器只看得见本包的注解。其余的东西——来自 `--dart-define` 的值、需要作用域本身的对象——
放进一个包住生成器产物的构建器里，这样它们落在**阶段 1 内部**，而不是启动之后再补上去：

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

要告诉完整性检查它们的存在，否则会被报成缺失：

```dart
@AlloyScopeRoot(name: 'app', provides: [SessionManager, AlloyEnvironment])
class AppScope {
  const AppScope();
}
```

承诺本身不注册任何东西，只是说明会有别人来注册。
`AlloyProvided(Logger, name: 'audit')` 承诺的是一个命名注册。

---

## 4. 启动 Flutter 应用

根作用域由 `AlloyAppScope` 持有：构建图、发布到 widget 树、卸载时销毁，
并把启动失败变成一个带重试的界面，而不是一个还没画出第一帧就死掉的应用。

把它放进 `MaterialApp.builder`，不要放在 `MaterialApp` 之上。在那里它位于 `Theme`、
`Directionality` 和 `Localizations` 之下，于是 `loading` 和 `errorBuilder` 就是普通界面，
而不是第二个 `MaterialApp`：

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

`bootstrap` 是函数而不是列表，这是有意的：步骤持有资源，重启必须拿到新的。
存成列表会悄悄把同一批对象交给第二次启动。

`AlloyAppScope.of(context).restart()` 重建整张图——同一个调用也用于重试失败的启动。

如果应用已经有自己的 `builder`，请自己组合，不要指望框架去合并两个：

```dart
builder: (context, child) => AlloyAppScope(
  root: const NotesScope(notesEnvironment),
  child: myWrapper(child!),
),
```

---

## 5. 在 widget 中读取依赖

```dart
final repository = context.alloy<Repository>();
final formatters = context.alloyAll<NoteFormatter>();
final editor = context.alloyWithParam<NoteEditor, $NoteEditorArgs>((id: 7, draft: true));
final scope = context.alloyScope;
```

每一个都从 widget 之上**最近**的作用域开始解析，然后逐级向上；
因此流程作用域或会话作用域中的注册，会对其内部的一切遮蔽根作用域的同名注册。

有一件事最好在被它咬到之前知道：`Navigator.push` 用的是 navigator 的 context，
而不是发起 push 的那个 widget 的 context。如果一个界面读取的 provider 位于发起 push 的界面**内部**，
那么它就地挂载时解析正常，被 push 打开时就会抛 `AlloyNoScopeError`。
这种情况下请显式传入作用域，或者在 provider 之下 push。

---

## 6. 比应用先结束的作用域

框架就是为这件事写的。作用域是树上的一个节点，它拥有自己构建的东西，
销毁它会连带销毁其内部构建的一切。

### 会话

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

登出就是 `await scope.dispose()`。没有仓储去订阅会话流，
也没有领域接口被迫长出一个它并不想要的 `reset()`。

### 界面

```dart
AlloyScopeWidget(
  name: 'counter-screen',
  builder: const ScreenScope(),
  child: const Counter(),
)
```

挂载时创建，卸载时销毁。注意：作用域要等 `init()` 完成后才发布，
所以即使是完全同步的图也会渲染一帧 `loading`。

### 导航流程

`alloy_go_router` 让生命周期由流程决定，而不是由「你记得放上去的那个 widget」决定：

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

在 `summary` 与 `payment` 之间导航共用同一个作用域，离开流程则销毁它。
`identity` 回答的是路由自己判断不了的那个问题：`/orders/1` 和 `/orders/2` 算不算同一个流程；
换了 identity，作用域就会重建。

路由表**只构建一次**，和 router 一起。对 go_router 来说，新的 `AlloyShellRoute` 实例就是另一个流程，
所以每帧重建这个列表就等于每帧重建作用域。

标签页是同样的做法——`AlloyStatefulShellRoute` 和 `AlloyStatefulShellBranch`——
但有一点值得直说：分支是被保持**存活**，不是被保持**可见**。
go_router 会在屏幕外保留分支的 navigator，所以标签页的作用域活到 shell 关闭为止，
而不是活到你切走为止。

---

## 7. 关闭你注册的东西

作用域按**创建**顺序倒序释放它持有的东西，而不是按声明顺序。
这个区别正是手写容器的老 bug：先声明、后创建的组件会被先销毁，而那时还有人依赖它。
释放过程是尽力而为的：抛异常的 `dispose` 会被记录下来、其余的照常执行，整棵树共用一个截止时间，
没做完的事列在 `AlloyDisposeError` 里，而不是让第一个错误盖住其余九个。

一共三条路径。由于 Dart 没有结构化类型，光有一个签名相同的 `dispose()` 方法是不够的：

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

对于你改不了的类型——来自 SDK、来自别的包、藏在基类后面——在注册处指明如何关闭：

```dart
Future<void> closeEvents(StreamController<String> events) => events.close();

@alloyModule
class PlatformModule {
  const PlatformModule();

  @AlloyInject(dispose: closeEvents)
  StreamController<String> events() => StreamController<String>.broadcast();
}
```

手写时是同一个参数：

```dart
scope.registerLazySingleton<http.Client>(
  const ClientFactory(),
  dispose: (client) => client.close(),
);
```

`dispose:` 只存在于作用域会持有的注册上。`registerFactory` 和 `registerParamFactory` 没有这个参数，
因为瞬态对象不归作用域关闭——这个情况在构造上就无法表达，而不是留到运行时去检查。

### 看着像可关闭、其实不是的 Flutter 类型

`ChangeNotifier.dispose` 与 `Disposable.dispose` 完全一致，但作用域依然看不见它。明说即可：

```dart
class Filters extends ChangeNotifier implements Disposable {}
```

对 bloc 来说，`alloy_bloc` 就是那一行：

```dart
@alloyInject
class CounterCubit extends Cubit<int> with AlloyBloc {
  CounterCubit() : super(0);
}
```

mixin 够不着的地方，用 `@AlloyInject(dispose: closeBloc)`。

之后交给 widget 树时请用 `BlocProvider.value`，绝不要用 `BlocProvider(create:)`：
后者会在卸载时关闭别人交给它的对象，而此时作用域仍然持有它，下次解析就会把一个死对象交出去。

`adopt` 把「不是依赖、但生命周期绑在作用域上」的对象挂上去：

```dart
scope.adopt(subscription, dispose: (it) => it.cancel());
```

---

## 8. 必须在启动前完成的工作

两个阶段，回答的是不同的问题。

**阶段 0 —— `@AlloyBootstrap`。** 在容器存在之前：平台绑定、远端配置，
以及这张图本身所需要的一切。步骤严格按顺序执行，且无法注入任何东西——因为还没有可注入的来源。

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

跑完之后，根作用域会「收养」这些步骤：打开过资源的步骤会随作用域一起关闭——
而且是最后关闭，排在建立于其之上的一切之后。若某个步骤失败，
已经跑完的那些会按倒序释放，然后错误才被重新抛出。

**阶段 1 —— `@AlloyInit`。** 在容器内部：异步单例，按依赖顺序构建。

```dart
@AlloyInit(dependsOn: [Database])
class SearchIndex {
  final _terms = <String>[];

  Future<void> init() async => _terms.addAll(await loadTerms());
}
```

`dependsOn` 是排序的边，不是注入。同一层上互不相关的初始化器通过 `Future.wait` 一起跑，
只有真正存在依赖的才会等待。指向一个并非异步注册的类型是构建错误，
而不是它看起来的那种静默空操作。

`AlloyApplication.start` 在两个阶段都完成后才返回，
所以没有 `allReady()` 要调用，也没有「已注册但尚未就绪」这种状态需要你去推理。

---

## 9. 来自调用方的值

对象的一半来自图，另一半来自构建它的人。把容器无从知晓的那一半标出来：

```dart
@alloyInject
class Greeting {
  Greeting(this._config, {@alloyParam required this.name, @alloyParam required this.loud});

  final Config _config;
  final String name;
  final bool loud;
}
```

生成器会在容器旁边把参数类型写成一个具名 record，并注册为参数化工厂：

```dart
// typedef $GreetingArgs = ({String name, bool loud});
final greeting = context.alloyWithParam<Greeting, $GreetingArgs>((name: 'Alloy', loud: false));
```

即使只有一个参数也用具名 record 而非位置式：加第二个参数改变的是这个类型的内容，
而不是它的名字或调用处的形状。

被标记的参数不参与完整性检查，也不参与排序——没有人会去注册一个 `String`。
它们必须是 required 或可空的：record 没有默认值，
所以 `@alloyParam this.draft = false` 会让调用方仍然必须传 `draft`，而你写的默认值形同虚设。
这是构建错误。

手写时对应的是带一个参数的 `registerParamFactory<T, P>`；多个参数请打包成 record 或你自己的小类。

### 可选依赖

写法就是类型上的一个 `?`：

```dart
@alloyInject
class Reporter {
  Reporter(this.clock, this.telemetry);

  final Clock clock;
  final Telemetry? telemetry;   // 通过 getOrNull 解析
}
```

没有注册 `Telemetry` 的图会注入 null，而不是让构建失败。可空性不属于注册键——
`Foo?` 读的仍然是 `Foo` 的注册——而当确实有人注册它时，可选依赖依然是一条排序的边。

`getOrNull` 只在「没有注册」时返回 null。在 `init()` 之前请求异步单例仍然会抛异常，
因为「尚未就绪」和「根本没有」是两回事，把它们合并会把一个启动顺序的 bug 变成一个值。

---

## 10. 不是你写的类型

`@AlloyInject` 加在类上，所以它只够得着你自己的类。其余一切的入口是模块：

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

类上的注解本身不携带任何配置：每个成员用和类一样的注解配置自己的注册，
其参数像构造参数一样被解析。这个类需要一个无参的公开 `const` 构造函数，
这样生成的工厂就持有 `const NetworkModule()`，不带任何状态。

返回 `Future<T>` 是唯一的异步信号——这样的成员成为异步单例，
异步成员之间的顺序由生成器算出来，而不是你手写。成员不能是抽象的：
「用类自己的构造函数来构建它」正是 `@AlloyInject` 已有的含义。

---

## 11. 一张图，多种构建

在确实需要「这次构建要换一个实现」之前，可以跳过本节。
从不写 `@AlloyEnvironment` 的项目只有一张图，`$startAlloy()` 连参数都不带。

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

注解是重复书写而不是接受一个列表：一个注册属于一个环境的*集合*，而启动时只挑*一个*。
`dev`、`stage`、`prod`、`test` 是常量，不是封闭集合——`@AlloyEnvironment('canary')` 行为完全一样。

同一类型的两个注册若环境有交集，就是构建失败，并会同时点名两者；
其中一个根本不写环境的情况也算在内。完整性对每个环境分别检查，
所以只在 `dev` 存在的注册无法满足一个同样跑在 `prod` 的依赖方。

不做选择就启动是合法的，被切分的类型只是没有被注册：
第一次解析会以普通的「未注册」错误失败，而不是悄悄交回错误的类。

---

## 12. 观察这张图

观察者能看到作用域出现、实例被构建、启动完成、销毁失败。
在创建图的地方传入它们；之后压入的每个作用域都会继承。

```dart
final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyLogObserver(const AlloyDeveloperLogSink())],
);
```

`push(name, observers: [...])` 给某一棵子树追加观察者。

回调收到的是 `AlloyScopeRef` 和 `AlloyKey`——描述符，不是活对象——
而回调里抛出的异常会被吞掉：观察不能有能力破坏被观察者。
解析不会被上报：命中缓存是热路径，值得看见的是实例**被构建**这件事。

### 送到哪里去

| 包 | 形态 |
|---|---|
| `alloy_talker` | 观察者，每个事件家族一种带颜色的日志类型 |
| `alloy_logging` | 基于 dart.dev `logging` 的 sink |
| `alloy_logger` | 基于 `logger` 的 sink |

其余都是一个回调的事，所以不会有哪个日志库因为「没人写适配包」而被挡在外面：

```dart
AlloyLogObserver(AlloyLogSink.from((r) => myLogger.debug(r.message)))
AlloyLogObserver(AlloyLogSink.from((r) => gelf.send(r.toStructured())))
```

记录不只是一个字符串：`level`、`scope`、`key`、`error`、`stackTrace` 和 `kind` 都在里面，
而 `kind` 是一个值——`AlloyEventKind.scopeInitFailed`，而不是一句还得你去解析的话。

### 崩溃上报是另一种形态

让一份报告有用的不是异常本身，而是图在那之前正在做什么。

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

线索是一个 20 条记录的环形缓冲，各个级别都收，包括日志 sink 会丢掉的逐实例记录。
阈值是 `error` 而不是 `warning`：销毁失败确实意味着泄漏，
但每次小磕碰都去惊动一个付费服务，正是报告从此没人看的原因。用 `reportAt` 调低它。

### 运行时，直接在屏幕上

```dart
final log = AlloyInspectorLog();

// observers: [log]

AlloyInspectorScreen(log: log, scope: context.alloyScope)
```

三个标签页：带生命周期与归属的实时作用域树；实际已经构建出来的东西；
以及上报过的一切，可搜索、可暂停。打开树不会构建任何东西——
为了显示而去实例化一个懒汉单例，就等于改变了你本来要看的东西。

---

## 13. 测试

第一件要知道的事是个坑，而不是 API。`testWidgets` 在 fake-async 区域里执行测试体，
初始化器里的 `Future.delayed` 在那里永远不会完成。**请在 `setUp` 里构建图**，
把针对整张图的断言放在普通的 `test` 里。

```dart
late AlloyScope scope;

setUp(() async {
  scope = await alloyTestScope(root: const AppScope());
});
```

`alloyTestScope` 和 `alloyTestRoot` 会随测试一起销毁——这恰恰是最容易漏掉的一步，
而漏掉它不会报错，只会泄漏到下一个测试里。

### 覆盖依赖

压入一个子作用域并重新注册。遮蔽也正是生产环境里覆盖依赖的方式，
所以测试用的是应用同一套机制，而不是什么后门：

```dart
final overrides = scope.pushForTest()
  ..registerSingleton<Clock>(FixedClock(DateTime(2026)));
```

这能不能生效由一条规则决定，每个人都会撞上一次：
**工厂运行在拥有它自身那条注册的作用域上。** 在消费者之下做的覆盖，对消费者是不可见的。
`ownerOf<T>()` 会比断言更早告诉你答案：

```dart
expect(scope.ownerOf<Greeter>(), same(scope.root));   // 注册在根上，就得在根上覆盖
```

### 检查手写的图

生成器在构建期就会拒绝不完整的图，但只针对它自己生成的部分：
手写工厂是在 `create` 内部解析的，静态分析看不到它将要请求什么。唯一的检查手段是跑一遍：

```dart
await expectGraphResolves(scope);
```

它是终局性的：解析**本身**就是检查，所以跑完之后每个懒汉单例都已构建，销毁顺序也变了。
请把它单独放在一个测试里。

参数化注册没有值就无法解析，所以它会以 `unchecked` 的形式被点名列出，而不是被静默跳过。
给它一个样例值，就能真正覆盖到：

```dart
await expectGraphResolves(scope, params: {AlloyKey(Counter): 'alice'});
```

### 测试替身

```dart
final scope = alloyTestRoot()
  ..registerLazySingleton<Clock>(FnFactory((_) => FixedClock(DateTime(2026))))
  ..registerSingleton<Config>(const Config())
  ..registerAsyncSingleton<Db>(AsyncFnFactory((_) async => Db()))
  ..registerParamFactory<Counter, String>(FnParamFactory((_, id) => Counter(id)));

await scope.init();
```

异步注册必须在 `init()` **之前**就存在。`init()` 只取它启动那一刻找到的异步注册，且只运行一次，
所以往一个已经激活的作用域里注册会直接报错，而不是悄悄永远不构建——
也正因如此，已经启动的作用域不是添加测试替身的地方。

`DisposeRecorder` 是用于销毁断言的替身，它的日志是按实例而非共享的：
某个测试结束后才销毁的作用域，无法把记录写进下一个测试。

```dart
final recorder = DisposeRecorder();
scope.registerLazySingleton<Disposable>(recorder.factory('cache'));
scope.get<Disposable>();

await scope.dispose();
expect(recorder.entries, ['cache']);
```

`CapturingObserver` 收集事件，供你断言这张图做过什么。

### widget 测试

`alloy_test_flutter` 提供了两个「显而易见的写法恰好是错的」的辅助函数：

```dart
await settle(tester);                    // 不是 pumpAndSettle：它在加载指示器上会一直转下去
final scope = mountedRootScope(tester);  // 应用的图，取自 MaterialApp builder 之下
```

---

## 14. lint 插件

十二条规则，建立在生成器所用的同一套解析层之上，
因此错误会在编辑器里出现，而不是非等到 `build_runner` 跑完。

```yaml
# analysis_options.yaml
plugins:
  alloy_lint: ^0.1.0
```

配置它有两件事会实打实地耗掉你的时间：

1. `plugins:` 一节**只在包或 workspace 的根目录生效**。放在嵌套的 `analysis_options.yaml` 里
   会被静默忽略——没有错误，也没有诊断。同理，`dart analyze <嵌套/目录>` 也不会应用它；
   请分析 workspace 根目录。
2. 分析服务器会按上下文缓存插件的构建产物。「规则不触发」通常意味着构建产物过期，
   而不是规则写错了：碰一下插件的文件，或者重启分析服务器。

---

## 15. 值得提前知道的坑

每一条都是付出代价才发现的——在这个仓库里，或在它当初为之而写的那些应用里。

- **在 `testWidgets` 内部构建图。** fake-async，什么都完成不了，超时了还找不到原因。用 `setUp`。
- **在消费者之下做覆盖。** 工厂运行在持有该注册的作用域上。`ownerOf<T>()` 比断言更早告诉你。
- **把 `bootstrap` 写成存下来的列表。** 步骤持有资源，重启必须拿到新的。传一个函数。
- **对作用域持有的 bloc 使用 `BlocProvider(create:)`。** 两个所有者，而 widget 先动手。
  用 `BlocProvider.value`。
- **注册了 `ChangeNotifier` 或 `Cubit` 却没声明它可关闭。** 被构建、被使用、永不关闭，且悄无声息。
  用 `implements Disposable`、`with AlloyBloc` 或 `dispose:`。
- **在泛型类上用 `@AlloyInject`。** 会被拒绝：没有人告诉生成器该注册哪些具体实例化。
  请给具体子类型加注解，或用 `exposeAs` 暴露一个。泛型作为依赖和 `exposeAs` 目标都完全可用。
- **PATH 里旧版 `dart` 排在前面。** 它出错时既不响亮也不在正确的位置——
  `dart analyze` 会用错误的 analyzer 报出幻觉问题，`dart format` 会重写你没碰过的文件。
  在相信一次运行结果之前先看 `dart --version`。

---

## 接下来看什么

- [README.zh-CN.md](README.zh-CN.md)——Alloy 是什么，以及每个决定为何是现在这样。
- [MIGRATION.zh-CN.md](MIGRATION.zh-CN.md)——从 `get_it` 和 `injectable` 迁移，包括对不上的部分。
- `examples/gallery`——一个 Flutter 应用，十四个条目，一个能力一条：
  `cd examples/gallery && flutter run`。
- 细节见各个包的 README：[`alloy`](packages/alloy/README.md)、
  [`alloy_flutter`](packages/alloy_flutter/README.md)、
  [`alloy_generator`](packages/alloy_generator/README.md)、
  [`alloy_lint`](packages/alloy_lint/README.md)、
  [`alloy_test`](packages/alloy_test/README.md)。
