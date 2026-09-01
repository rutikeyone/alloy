<p align="center">
  <a href="GUIDE_CODEGEN.md">English</a> · <a href="GUIDE_CODEGEN.ru.md">Русский</a> · <a href="GUIDE_CODEGEN.zh-CN.md">中文</a>
</p>

> 本文档译自 [GUIDE_CODEGEN.md](GUIDE_CODEGEN.md)。英文版为准：若有出入，以英文为准。

# Code-Gen Mode（代码生成模式）

带生成器的 Alloy：你给类加注解，`build_runner` 写出容器，而这张图在构建出来之前就被检查过。
产物是普通的 Dart 代码，除了 `alloy` 的公开 API 之外什么都不用——你读得懂它，
而且里面的一切本来都可以手写。

这是本项目一直坚持的不变量，它有一个你会用到的实际后果：生成的容器和别的
`AlloyScopeBuilder` 没有区别，所以手写的注册可以和它组合在同一张图里。这里没有「全有或全无」。

构建步骤为你买到什么，也正是本文的主要内容：

- **图在构建期被检查**——没有人注册的依赖会让构建失败，并一次性点出所有缺口，
  而不是等到某个界面第一个解析到它时才失败；
- **属性注入**——`late final` 字段由生成的 mixin 填充，于是有五个协作对象的类拥有一个空构造函数；
- **十二条 lint 规则**，在编辑器里抓住其余的问题。

如果这些你都不需要，或者你正在逐步迁移一个已有的容器，那么不用生成器一切照样能跑：
[GUIDE_MANUAL.zh-CN.md](GUIDE_MANUAL.zh-CN.md)。

---

## 目录

1. [安装](#1-安装)
2. [你的第一张生成图](#2-你的第一张生成图)
3. [产物长什么样](#3-产物长什么样)
4. [属性注入](#4-属性注入)
5. [图必须是完整的](#5-图必须是完整的)
6. [在生成的根之上做组合](#6-在生成的根之上做组合)
7. [启动 Flutter 应用](#7-启动-flutter-应用)
8. [在 widget 中读取依赖](#8-在-widget-中读取依赖)
9. [比应用先结束的作用域](#9-比应用先结束的作用域)
10. [关闭你注册的东西](#10-关闭你注册的东西)
11. [必须在启动前完成的工作](#11-必须在启动前完成的工作)
12. [来自调用方的值](#12-来自调用方的值)
13. [可选依赖](#13-可选依赖)
14. [不是你写的类型](#14-不是你写的类型)
15. [一张图，多种构建](#15-一张图多种构建)
16. [lint 插件](#16-lint-插件)
17. [观察这张图](#17-观察这张图)
18. [测试](#18-测试)
19. [值得提前知道的坑](#19-值得提前知道的坑)

---

## 1. 安装

运行时会进入应用，生成器永远不会。

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

纯 Dart 包——命令行工具、服务端、没有 widget 的包——去掉 `alloy_flutter` 和
`alloy_test_flutter`。运行时任何地方都不需要 Flutter。

注解随 `alloy` 一起到来，它会重新导出它们，所以一个 import 就够了：

```dart
import 'package:alloy/alloy.dart';
```

可选，且只在你需要时才加：`alloy_go_router`、`alloy_bloc`、`alloy_inspector`，
以及 `alloy_talker` / `alloy_logging` / `alloy_logger` 之一。

---

## 2. 你的第一张生成图

给类加注解。依赖就是构造参数，什么解析什么由生成器算出来。

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

`@alloyInject` 是懒汉单例——首次解析时构建，由作用域持有。
另外两种生命周期各有自己的常量，完整形式则承载其余配置：

| 注解 | 生命周期 |
|---|---|
| `@alloyInject` | 懒汉单例 |
| `@alloySingleton` | 饿汉单例，构建图时就构建 |
| `@alloyTransient` | 每次解析都是新实例，不被任何人持有 |

```dart
@AlloyInject(exposeAs: ApiClient, name: 'live', dispose: closeClient)
class LiveApiClient implements ApiClient { ... }
```

`exposeAs` 把类注册在某个接口之下，这样使用方依赖的是 `ApiClient` 而不是实现。
`name` 是限定符，因此同一类型的第二个注册是合法的，用 `get<Logger>(name: 'audit')` 读取。

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

开发时用 `dart run build_runner watch`。产物要提交：CI 会重新生成并在有 diff 时失败，
过时的生成代码就是这样被抓住的，而不是被发布出去。

**一个包一个根。** `alloy_container` 会把整个包聚合成唯一的 `$AlloyRootScope`；
同一个包里有两个 `@AlloyScopeRoot` 是生成错误。因此两张互相独立的生成图需要两个包——
这正是本仓库的示例是一个个独立的包而不是文件夹的原因。

---

## 3. 产物长什么样

`lib/alloy.g.dart`，值得读一遍，好让这个模式不再是黑盒：

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

为了便于阅读，这里省略了前缀，但真实文件会给每个导入的名字加上由其 URL 哈希得出的别名——
`_i178.AlloyFactory`。用哈希而不是计数器，是为了让新增一个导入不会把其余全部重新编号，
把一行改动变成整份文件的 diff。

这份产物有四点是刻意为之的：

- **私有 const 工厂类，而不是闭包。** `const` 工厂不持有捕获状态，
  所以第二次启动不可能复用第一张图的对象。
- **注册按拓扑顺序排列**，顺序在构建期算出。被属性注入的字段同样算作边，
  所以 bloc 总是排在它注入的东西之后注册。
- **没有反射，也没有运行时扫描。** 那个文件里有什么，整张图就是什么。
- **`$alloyBootstrap` 是 getter**，而不是存下来的列表，所以重启会拿到新的步骤——见
  [§11](#11-必须在启动前完成的工作)。

生成器用与你的格式检查相同的 `dart_style` 版本来格式化自己的产物，所以两者不会有分歧。

---

## 4. 属性注入

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

有三点让这件事是可靠的而不是魔法：

- 字段是 `late final`，因此**只写一次**——再次赋值会抛 `LateError`。
- 它们可以是**私有的**：生成的 mixin 是同一个库的 `part`，因此看得见它们。
- 它们和别的依赖一样是**图的边**，所以排序和完整性检查都把它们算在内。

`part` 指令和 `with _$ClassName` 需要你自己写。忘了 mixin，
`alloy_missing_injection_mixin` 会在编辑器里告诉你；
把 `@injected` 放在容器根本不注册的类上，则是
`alloy_injected_field_needs_an_injectable` 来说——因为这两个错误的修法不同。

---

## 5. 图必须是完整的

这就是构建步骤存在的意义。没有人注册的依赖会让构建失败，一次点出所有缺口，
而不是每次重建才报一个：

```
The graph is missing 2 registrations.
  CatalogService requires Repository<User>
  ApiGateway requires HttpClient in dev, test
Annotate the classes that provide them with @AlloyInject, or name them in
@AlloyScopeRoot(provides: [...]) when something outside the generated container
registers them.
```

一切都算作依赖：构造参数、`@injected` 字段，以及 `@AlloyInit(dependsOn:)`。
`@Named` 限定符是键的一部分，所以在只有匿名 `Logger` 的地方请求 `@Named('audit') Logger`
就是一个缺口。每个环境分别检查，所以只在 `dev` 存在的注册无法满足一个同样跑在 `prod` 的依赖方。

同样在构建期被拒绝的还有：同一个键的重复注册、依赖环（并指出这个环）、
同一个包里两个 `@AlloyScopeRoot`、`@AlloyInject` 用在抽象类或没有公开生成式构造函数的类上，
以及 `@AlloyInject` 用在**泛型类**上——没有人告诉生成器该注册哪些具体实例化，
所以请给具体子类型加注解，或用 `exposeAs` 暴露一个。

泛型在其他任何地方都没问题。`Repository<User>` 和 `Repository<Order>` 是两条独立的注册，
因为 `AlloyKey` 由 `Type` 构成，而它们是不同的类型。

边界值得说老实话：这项检查覆盖的是生成器生成的东西。手写工厂在 `create` 内部解析，
静态分析看不到它将要请求什么——对那些，检查手段是 `alloy_test` 的 `expectGraphResolves`，
见 [§18](#18-测试)。

---

## 6. 在生成的根之上做组合

生成器只看得见本包的注解。其余的一切——来自 `--dart-define` 的值、需要作用域本身的对象、
来自别的包的提供者——都放进一个包住生成产物的构建器里：

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

用包裹而不是在 `$startAlloy()` 返回之后再注册，才能让它们留在阶段 1 内部——
在异步初始化器运行之前就注册好，而不是等图已经起来了再补上去。

接下来要告诉完整性检查它们的存在，否则会被报成缺失：

```dart
@AlloyScopeRoot(name: 'app', provides: [SessionManager, AlloyEnvironment])
class AppScope {
  const AppScope();
}
```

承诺本身不注册任何东西，只是说明会有别人来注册。
`AlloyProvided(Logger, name: 'audit')` 承诺的是一个命名注册。
承诺了却没有真的去注册，你就又回到了运行期故障——这份列表是你做出的声明，
不是生成器能够核实的东西。

---

## 7. 启动 Flutter 应用

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

`bootstrap` 是函数而不是列表，生成器把 `$alloyBootstrap` 写成 getter 也是同一个原因：
步骤持有资源，重启必须拿到新的。

`AlloyAppScope.of(context).restart()` 重建整张图——同一个调用也用于重试失败的启动。

在 Flutter 之外，全部内容就是 `await $startAlloy()`。

---

## 8. 在 widget 中读取依赖

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

## 9. 比应用先结束的作用域

生成器写的是**根**。比应用生命周期更短的作用域——会话、流程、界面——
是由你来写的 `AlloyScopeBuilder`，它们注册时用的是生成文件所用的同一套公开 API。
这不是生成器的缺失：什么该放进会话作用域，是一个关于生命周期的决定，
而没有哪个注解能说出会话何时结束。

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

挂载时创建，卸载时销毁。作用域要等 `init()` 完成后才发布，
所以即使是完全同步的图也会渲染一帧 `loading`。

这里正是 `@alloyTransient` 体现价值的地方：瞬态对象每次解析都会重建、不被任何人持有，
所以给它一个属于自己的作用域，才是给了它一个生命周期和一个销毁点。

### 导航流程

用 `alloy_go_router`，生命周期由流程决定，而不是由「你记得放上去的那个 widget」决定：

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

在 `summary` 与 `payment` 之间导航共用同一个作用域，离开流程则销毁它。
`identity` 回答的是路由自己判断不了的那个问题：`/orders/1` 和 `/orders/2` 算不算同一个流程。

路由表**只构建一次**，和 router 一起。对 go_router 来说，新的 `AlloyShellRoute` 实例就是另一个流程，
所以每帧重建这个列表就等于每帧重建作用域。

标签页是同样的做法——`AlloyStatefulShellRoute` 和 `AlloyStatefulShellBranch`——
但有一点值得直说：分支是被保持**存活**，不是被保持**可见**。
go_router 会在屏幕外保留分支的 navigator，所以标签页的作用域活到 shell 关闭为止，
而不是活到你切走为止。

---

## 10. 关闭你注册的东西

作用域按**创建**顺序倒序释放它持有的东西，而不是按声明顺序——这个区别正是手写容器里的 bug。
Dart 没有结构化类型，所以光有一个签名相同的 `dispose()` 方法是不够的：

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

对于你改不了的类型——来自 SDK、来自别的包、藏在基类后面——在注解里指明如何关闭。
它接受一个顶层函数，因为注解的参数必须是常量：

```dart
Future<void> closeClient(http.Client client) => client.close();

@AlloyInject(dispose: closeClient)
class ApiClientHolder { ... }
```

`dispose:` 只在作用域会持有的注册上才有意义。用在 `@alloyTransient` 或带 `@AlloyParam` 的类上
是构建错误，而不是一个永远不会被调用的回调，因为瞬态对象不归作用域关闭。

### 看着像可关闭、其实不是的 Flutter 类型

`ChangeNotifier.dispose` 与 `Disposable.dispose` 完全一致，但作用域依然看不见它。明说即可：

```dart
@alloyInject
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

`alloy_registration_is_never_released` 会在编辑器里抓住上述所有情况：
已注册的类带有作用域看不见的 `dispose()` 或 `close()`。

### 当销毁出错时

它按设计是尽力而为的。抛异常的步骤会被记录，其余的照常执行；整棵树共用一个截止时间；
作用域最终一定会到达 `disposed`。没做完的事列在 `AlloyDisposeError` 里——
`failures`、`timeouts`、`hasTimeout`。

`adopt` 把「不是依赖、但生命周期绑在作用域上」的对象挂上去：

```dart
scope.adopt(subscription, dispose: (it) => it.cancel());
```

---

## 11. 必须在启动前完成的工作

两个阶段，回答的是不同的问题。

**阶段 0 —— `@AlloyBootstrap`。** 在容器存在之前：平台绑定、远端配置，
以及这张图本身所需要的一切。步骤严格按顺序执行——先按 `order`，再按名字，这样产物才稳定——
且无法注入任何东西，因为还没有可注入的来源。构造函数带必填参数的 bootstrap 步骤是构建错误，
而 `alloy_bootstrap_step_cannot_inject` 会更早告诉你。

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
class SearchIndex implements AsyncInitializable {
  SearchIndex(this._database);

  final Database _database;
  final _terms = <String>[];

  @override
  Future<void> init() async => _terms.addAll(await _database.terms());
}
```

`AsyncInitializable` 就是这个注解所隐含的接口。真正必需的只有 `init()` **方法**本身——
解析器和 lint 规则都是按名字找它的——但把接口声明出来能让契约对读者可见，
而且每一条「缺少 `init()`」的错误提示都是这么建议的。

生成的工厂会构造对象、等待 `init()`，并把它注册为异步单例，
`dependsOn` 被翻译成一组 `AlloyKey`。同一层上互不相关的初始化器通过 `Future.wait` 一起跑，
只有真正存在依赖的才会等待。

`dependsOn` 是排序的边，不是注入——依赖照常从构造函数拿。
指向一个已注册但**不是**异步的键是构建错误，而不是它看起来的那种静默空操作：没有构建可等。

`AlloyApplication.start` 在两个阶段都完成后才返回，
所以没有 `allReady()` 要调用，也没有「已注册但尚未就绪」这种状态需要你去推理。

---

## 12. 来自调用方的值

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

生成器强制两条规则：

- 被标记的参数**不参与**完整性检查，也不参与排序。没有人会去注册一个 `String`，也不该去试。
- 它们必须是 **required 或可空**的。record 没有默认值，
  所以 `@alloyParam this.draft = false` 会让调用方仍然必须传 `draft`，而你写的默认值形同虚设。
  这是构建错误，而不是一个意外。

用普通的 `get<T>()` 去解析会抛 `AlloyParamRequiredError`；传错类型会抛 `AlloyParamTypeError`，
并点明键和两个类型。

---

## 13. 可选依赖

写法就是类型上的一个 `?`——没有对应的注解，因为没有 `?` 的话字段本来也装不下 null：

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

两者都通过 `getOrNull` 解析，所以没有注册 `Telemetry` 的图会注入 null，而不是让构建失败。

可空性不属于注册**键**——`Foo?` 读的仍然是 `Foo` 的注册——
而当确实有人注册它时，可选依赖依然是一条排序的边。`getOrNull` 只在「没有注册」时返回 null：
在 `init()` 之前请求异步单例仍然会抛异常，因为「尚未就绪」和「根本没有」是两回事。

---

## 14. 不是你写的类型

`@AlloyInject` 加在类上，所以它只够得着你自己的类。其余一切的入口是模块——
别的包里的客户端、SDK 交给你的值：

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

类上的注解本身不携带任何配置：每个成员用和类一样的注解配置自己的注册——
生命周期、`name`、`exposeAs`、`dispose`、环境——其参数像构造参数一样被解析。

规则，每条都有其理由：

- 这个类需要一个无参的公开 **`const` 构造函数**，这样生成的工厂就持有
  `const NetworkModule()`，不带任何状态。
- 返回 **`Future<T>` 是唯一的异步信号。** 这样的成员成为异步单例，
  异步成员之间的顺序由生成器算出来，而不是你手写。
- 成员**不能是抽象的。**「用类自己的构造函数来构建它」正是 `@AlloyInject` 已有的含义，
  不需要第二种说法。
- 成员上**不允许** `@AlloyParam`。模块注册的是不是你写的类型，
  而来自调用方的值属于一个你自己写的类。

成员参与类所参与的一切：重复检测、拓扑排序，以及完整性检查。

---

## 15. 一张图，多种构建

在确实需要「这次构建要换一个实现」之前，可以跳过本节。
从不写 `@AlloyEnvironment` 的项目只有一张图，所有注册都属于它，`$startAlloy()` 连参数都不带。

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

生成的容器把这个选择作为一个字段，并只给受限的注册加上守卫——这正是你会手写的东西：

```dart
if (environment.matches(const <String>{'dev', 'test'})) {
  scope.registerLazySingleton<ApiClient>(const _FakeApiClientFactory());
}
```

由此有三点：

- **它自始至终都是可选的。** 只有当某处指定了环境时这个参数才会出现，
  而且即便如此也默认为 `AlloyEnvironment.defaultEnvironment`——未被切分的图所处的那唯一一个环境。
  这个默认值只匹配无环境限制的注册，所以启动一张被切分的图而不做选择，
  会让被切分的类型没有注册，第一次解析就会失败并说明原因，而不是悄悄交回错误的类。
- **不会有东西被注册两次。** 同一个键的两个注册若环境有交集，就是构建失败并同时点名两者——
  其中一个根本不写环境的情况也算在内，因为无限制的注册在任何地方都存在。
- **完整性按环境分别检查**，所以只在 `dev` 存在的注册无法满足一个同样跑在 `prod` 的依赖方。

bootstrap 步骤同样接受环境。只要其中任何一个用到，`$alloyBootstrap` 就变成所选环境的函数，
被跳过的步骤既不会运行，也不会被收养。

`alloy_environment_needs_a_registration` 会抓住这种情况：`@AlloyEnvironment` 落在一个
没人注册的类上，此时它静默地什么也不做。

---

## 16. lint 插件

十二条规则，建立在生成器所用的同一套解析层之上，
因此错误会在编辑器里出现，而不是非等到 `build_runner` 跑完。

```yaml
# analysis_options.yaml
plugins:
  alloy_lint: ^0.1.0
```

| 规则 | 捕捉什么 |
|---|---|
| `alloy_missing_injection_mixin` | 容器会注册的类上有 `@injected` 字段却没有 `with _$ClassName` |
| `alloy_injected_field_needs_an_injectable` | 容器根本不注册的类上有 `@injected` 字段 |
| `alloy_param_needs_an_injectable` | 容器根本不注册的类上有 `@AlloyParam` |
| `alloy_injected_field_must_be_late_final` | `@injected` 用在可变、非 late 或静态字段上 |
| `alloy_injectable_must_be_constructible` | `@AlloyInject` 用在抽象类或没有公开生成式构造函数的类上 |
| `alloy_init_requires_init_method` | `@AlloyInit` 用在没有 `init()` 的类上 |
| `alloy_bootstrap_requires_run_method` | `@AlloyBootstrap` 用在没有 `run()` 的类上 |
| `alloy_bootstrap_step_cannot_inject` | 构造函数带必填参数的 bootstrap 步骤 |
| `alloy_environment_needs_a_registration` | `@AlloyEnvironment` 用在无人注册的类上 |
| `alloy_dependency_is_not_registered` | 包内无人注册的被注入依赖 |
| `alloy_dependency_cycle` | 最终依赖到自身的可注入类 |
| `alloy_registration_is_never_released` | 已注册的类带有作用域看不见的 `dispose()` 或 `close()` |

配置它有两件事会实打实地耗掉你的时间：

1. `plugins:` 一节**只在包或 workspace 的根目录生效**。放在嵌套的 `analysis_options.yaml` 里
   会被静默忽略——没有错误，也没有诊断。同理，`dart analyze <嵌套/目录>` 也不会应用它；
   请分析 workspace 根目录。
2. 分析服务器会按上下文缓存插件的构建产物。「规则不触发」通常意味着构建产物过期，
   而不是规则写错了：碰一下插件的文件，或者重启分析服务器。

最后两条规则回答的问题生成器也会回答，只是更早、而且不需要一次完整构建。
它们刻意比生成器更沉默：它们读的是包的语法索引，所以在索引无法确定的地方，
它们选择沉默，而不是去报告一个其实没问题的东西。构建是权威，编辑器是快速通道。

---

## 17. 观察这张图

观察者能看到作用域出现、实例被构建、启动完成、销毁失败。
在创建图的地方传入它们；之后压入的每个作用域都会继承。

`$startAlloy()` 不接受观察者——它是那条捷径。一旦需要观察者，
就走你本来就在组合的那个构建器：

```dart
final scope = await AlloyApplication.start(
  root: const NotesScope(notesEnvironment),
  bootstrap: $alloyBootstrap(notesEnvironment),
  rootName: $alloyRootScopeName,
  observers: [AlloyLogObserver(const AlloyDeveloperLogSink())],
);
```

在 Flutter 应用里，它就是 `AlloyAppScope.builder` 的 `observers:` 参数。

回调收到的是 `AlloyScopeRef` 和 `AlloyKey`——描述符，不是活对象——
而回调里抛出的异常会被吞掉：观察不能有能力破坏被观察者。
解析不会被上报：命中缓存是热路径，值得看见的是实例**被构建**这件事。

| 包 | 形态 |
|---|---|
| `alloy_talker` | 观察者，每个事件家族一种带颜色的日志类型 |
| `alloy_logging` | 基于 dart.dev `logging` 的 sink |
| `alloy_logger` | 基于 `logger` 的 sink |

其余都是一个回调的事，所以不会有哪个日志库因为没人写适配包而被挡在外面：

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

## 18. 测试

第一件要知道的事是个坑，而不是 API。`testWidgets` 在 fake-async 区域里执行测试体，
初始化器里的 `Future.delayed` 在那里永远不会完成。**请在 `setUp` 里构建图**，
把针对整张图的断言放在普通的 `test` 里。

```dart
late AlloyScope scope;

setUp(() async {
  scope = await alloyTestScope(root: const $AlloyRootScope());
});
```

生成的构建器可以直接放进去，和应用用它的方式一模一样。
`alloyTestScope` 和 `alloyTestRoot` 会随测试一起销毁——这恰恰是最容易漏掉的一步，
而漏掉它不会报错，只会泄漏到下一个测试里。

### 覆盖依赖

压入一个子作用域并重新注册。遮蔽也正是生产环境里覆盖依赖的方式，
所以测试用的是应用同一套机制；这同时也是在生成器不知情的情况下替换一条生成注册的办法：

```dart
final overrides = scope.pushForTest()
  ..registerSingleton<ApiClient>(FakeApiClient());
```

这能不能生效由一条规则决定，每个人都会撞上一次：
**工厂运行在拥有它自身那条注册的作用域上。** 在消费者之下做的覆盖，对消费者是不可见的。
`ownerOf<T>()` 会比断言更早告诉你答案：

```dart
expect(scope.ownerOf<Repository>(), same(scope.root));
```

### 仍然需要在运行期检查的东西

完整性检查覆盖的是生成的容器。有两样东西在它之外，值得写个测试：

```dart
await expectGraphResolves(scope);
```

第一是你用 `provides:` 承诺过的任何东西——检查选择了相信你。
第二是你组合进来的任何手写注册（[§6](#6-在生成的根之上做组合)）。

它是终局性的：解析**本身**就是检查，所以跑完之后每个懒汉单例都已构建，销毁顺序也变了。
请把它单独放在一个测试里。参数化注册会以 `unchecked` 的形式被点名列出，而不是被静默跳过——
给它一个样例值就能覆盖到：

```dart
await expectGraphResolves(scope, params: {AlloyKey(Greeting): (name: 'x', loud: false)});
```

### 测试替身

```dart
final scope = alloyTestRoot()
  ..registerLazySingleton<Clock>(FnFactory((_) => FixedClock(DateTime(2026))))
  ..registerSingleton<Config>(const Config())
  ..registerAsyncSingleton<Db>(AsyncFnFactory((_) async => Db()));

await scope.init();
```

对那些不需要整张生成图的测试来说，这些让你不必为每个桩对象写一个工厂类。
异步注册必须在 `init()` **之前**就存在——所以测试替身要放进一个新的根作用域，
而不是一个已经启动的作用域。

`DisposeRecorder` 是用于销毁断言的替身，它的日志是按实例而非共享的：
某个测试结束后才销毁的作用域，无法把记录写进下一个测试。
`CapturingObserver` 收集事件，供你断言这张图做过什么。

### widget 测试

`alloy_test_flutter` 提供了两个「显而易见的写法恰好是错的」的辅助函数：

```dart
await settle(tester);                    // 不是 pumpAndSettle：它在加载指示器上会一直转下去
final scope = mountedRootScope(tester);  // 应用的图，取自 MaterialApp builder 之下
```

### 在 CI 里让生成代码保持诚实

重新生成，并在有 diff 时失败：

```bash
dart run build_runner build
git diff --exit-code
```

没有这一步，生成产物就会和注解脱节，而在运行期图已经不对之前不会有人发现。

---

## 19. 值得提前知道的坑

每一条都是付出代价才发现的——在这个仓库里，或在它当初为之而写的那些应用里。

- **不提交 `alloy.g.dart`，或者提交了一份过时的。** 在 CI 里重新生成并比对 diff。
  这是本模式唯一一项实打实的维护义务。
- **同一个包里两个 `@AlloyScopeRoot`。** 这是构建错误，解法是拆成两个包——
  `alloy_container` 会把整个包聚合成一个根。
- **在泛型类上用 `@AlloyInject`。** 会被拒绝：没有人告诉生成器该注册哪些具体实例化。
  请给具体子类型加注解，或用 `exposeAs` 暴露一个。泛型作为依赖和 `exposeAs` 目标都完全可用。
- **写了 `@injected` 却没有 `with _$ClassName`。** 字段不会被赋值，第一次读取就抛 `LateError`。
  lint 会更早告诉你。
- **用 `provides:` 承诺了却没去注册。** 检查相信了你，于是故障挪到了运行期。
  用 `expectGraphResolves` 覆盖它。
- **在 `testWidgets` 内部构建图。** fake-async，什么都完成不了，超时了还找不到原因。用 `setUp`。
- **在消费者之下做覆盖。** 工厂运行在持有该注册的作用域上。`ownerOf<T>()` 比断言更早告诉你。
- **对作用域持有的 bloc 使用 `BlocProvider(create:)`。** 两个所有者，而 widget 先动手。
  用 `BlocProvider.value`。
- **注册了 `ChangeNotifier` 或 `Cubit` 却没声明它可关闭。** 被构建、被使用、永不关闭，且悄无声息。
  用 `implements Disposable`、`with AlloyBloc` 或 `dispose:`。
- **PATH 里旧版 `dart` 排在前面。** 它出错时既不响亮也不在正确的位置——
  `dart analyze` 会用错误的 analyzer 报出幻觉问题，生成产物也会随格式化器版本而变动。
  在相信一次运行结果之前先看 `dart --version`。

---

## 接下来看什么

- [GUIDE_MANUAL.zh-CN.md](GUIDE_MANUAL.zh-CN.md)——同一套运行时，不带构建步骤，以及什么能和什么组合。
- [README.zh-CN.md](README.zh-CN.md)——Alloy 是什么，以及每个决定为何是现在这样。
- [MIGRATION.zh-CN.md](MIGRATION.zh-CN.md)——从 `get_it` 和 `injectable` 迁移，包括对不上的部分。
- `examples/codegen_basics` 是最小的生成设置，`examples/notes_app` 是最大的。
  两者都从画廊运行：`cd examples/gallery && flutter run`。
