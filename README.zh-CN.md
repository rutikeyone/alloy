[English](README.md) · [Русский](README.ru.md) · [中文](README.zh-CN.md)

> 本文档译自 [README.md](README.md)。英文版为准：若有出入，以英文为准。
> 各个包自身的 README 不作翻译——它们是 API 参考。

# Alloy

面向 Dart 和 Flutter 的依赖注入框架。双模式：声明式代码生成，以及基于同一套运行时的纯 Dart 手写 API。

状态：**第一阶段已完成。** 运行时、Flutter 绑定、注解、分析层、两个生成器和 lint 插件均已实现并覆盖测试。

已经在用 `get_it` 或 `injectable`？请先看 [MIGRATION.zh-CN.md](MIGRATION.zh-CN.md)——
里面讲了什么能一一对应，以及更有用的：什么根本对不上。

## 包

| 包 | 依赖 | 是否进入应用 |
|---|---|---|
| `alloy_annotations` | `meta` | 是 |
| `alloy` | `alloy_annotations` | 是，运行时核心，不含 Flutter |
| `alloy_flutter` | `alloy`、`flutter` | 是 |
| `alloy_go_router` | `alloy_flutter`、`go_router` | 是，可选 |
| `alloy_talker` | `alloy`、`talker` | 是，可选 |
| `alloy_logging` | `alloy`、`logging` | 是，可选 |
| `alloy_logger` | `alloy`、`logger` | 是，可选 |
| `alloy_analyzer` | `alloy_annotations`、`analyzer` | 否 |
| `alloy_generator` | `alloy_analyzer`、`build`、`source_gen`、`code_builder` | 仅 dev_dependency |
| `alloy_lint` | `alloy_analyzer`、`analysis_server_plugin` | 仅 dev_dependency |
| `alloy_test` | `alloy`、`test_api`、`matcher` | 仅 dev_dependency |
| `alloy_inspector` | `alloy_flutter`、`flutter` | 仅 dev_dependency |
| `alloy_talker_flutter` | `alloy_inspector`, `alloy_talker`, `talker_flutter` | dev_dependency only |

`alloy_analyzer` 的存在是为了让生成器和 lint 插件用**同一套**实现解析 Alloy 声明，而不是两套迟早会
各说各话的实现。它持有 IR 和拓扑排序，并且既不依赖 `build`，也不依赖插件 API。

**项目不变量：** 生成的代码只允许使用 `alloy` 的公开 API。一旦生成需要 Manual Mode 无法表达的东西，
那就是两个共用一个名字的框架了。

## 工具链

在 **Flutter 3.47.1 / Dart 3.13.1**、analyzer 13.3.0 上构建并测试。

所有包都要求 Dart `^3.13.0`，而 3.47 以下的 Flutter 都不附带该版本——所以这就是统一的下限，包与包
之间并不存在需要留意的版本差异。CI 跑 `stable` 和 `beta`，而不是历史版本矩阵：值得提前发现的是**尚未
发布**的那个问题。

不要让 Homebrew 的 `dart` 出现在 PATH 前面——把 Flutter SDK 放在最前。旧版 `dart` 不会大声报错：
`dart analyze .` 会用错误的 analyzer 报出几十条幻觉问题，而 `dart pub get` 则直接拒绝 SDK 约束。
在信任一次运行结果之前，先看 `dart --version`。

有意锁定 `dart_style`：3.1.7 要求 `analyzer <12.0.0`，会悄无声息地把整个 workspace 拖后三个大版本。
黄金输出也会随格式化器版本变化。

## 验证

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

`tool/coverage.sh` 测量十一个有测试的可发布包的行覆盖率，从最低者开始打印，并在**总计**低于下限时失败
——下限 85%，当前 92.6%。下限放在总计而非每个包上是有意为之：覆盖率按包测量，而代码是共享的，
`alloy_analyzer` 的解析器主要由 `alloy_generator` 的测试和 `compat/external_consumer` 驱动，
而非它自己的用例。按包设下限会迫使测试写在不属于它们的地方。可用
`COVERAGE_FLOOR=90 ./tool/coverage.sh` 覆盖。

CI（`.github/workflows/ci.yml`）会跑完上述全部内容，并在重新生成两个示例**以及
`compat/external_consumer`** 之后执行 `git diff --exit-code`，因此过期的生成代码会让构建失败。
生成器用与格式检查相同的 `dart_style` 版本格式化自己的输出，所以两者永远不会打架。

## 测试基于 Alloy 的应用

`testWidgets` 在 fake-async 区域内执行函数体，因此初始化器里的 `Future.delayed` 在那里永远不会完成。
请在 `setUp` 中构建根作用域，而不是在 `testWidgets` 内部；把针对整张图的断言放在普通的 `test` 里。
`examples/notes_app/test/screens_test.dart` 两种写法都有。

要替换某个依赖，就压入一个子作用域并重新注册它——同一作用域内重复注册是错误，但从子作用域遮蔽是受支持
的做法，测试与生产环境同理。

`alloy_test` 把这些机械动作打包好了：`alloyTestScope` 构建图并随测试一起释放，`pushForTest` 对覆盖
作用域做同样的事，而 `ownerOf<T>()` 回答那个人人都会踩一次的问题——工厂运行在拥有**它自己**注册的
作用域上，因此位于消费者下方的覆盖对它不可见。

其中还有 `expectGraphResolves`，这是检查手写图的唯一办法。生成器会在构建期拒绝不完整的图，但它只看得见
自己生成的部分；工厂从不声明它会索取什么，所以手写的图只能靠运行来检查。该检查是终结性的：解析**就是**
检查，因此之后每个惰性单例都已被构建。

## 已知的发布警告

`alloy_lint` 会报告 "the name of lib/main.dart should match the name of the package"。这个入口点由
分析服务器插件 API 固定——服务器生成的代码会导入 `package:alloy_lint/main.dart` 并读取其中的 `plugin`
变量。`riverpod_lint` 也带着同样的警告。

## 目录结构

每个文件一个公开类型。密封（sealed）的 `AlloyRegistration` 层次结构是有意的例外：密封层次必须位于同一
个库中，所以它的子类是 `src/registration/alloy_registration.dart` 的 `part` 文件，而不是独立的库。

`compat/external_consumer` 是唯一不遵循这条经验法则的目录：它是一个**刻意不加入** workspace、也不声明
`resolution: workspace` 的包，因此 pub 会像对待第三方项目那样独立解析它。它的存在是为了从仓库外部检验
代码生成流水线是否诚实——详见它自己的 README。

## 生成器

`alloy_generator` 提供三个 builder：

| Builder | 输入 → 输出 | 用途 |
|---|---|---|
| `alloy_property_injection` | `.dart` → `.alloy.g.part` | 注入 `late final` 字段的 mixin |
| `alloy_scan` | `.dart` → `.alloy.json`（缓存） | 单库 IR |
| `alloy_container` | `$lib$` → `lib/alloy.g.dart` | `$AlloyRootScope`、`$alloyBootstrap`、`$startAlloy()` |

`alloy_scan` 先于 `alloy_container` 运行；容器 builder 通过 `findAssets` 读取全部 `.alloy.json`，
因为单个 build step 看不到整个程序。它产出私有的 const 工厂类和一个 `$AlloyRootScope`，其中注册顺序
由编译期拓扑排序决定。属性注入的字段同样计为依赖边，所以一个 bloc 总是在它注入的东西之后注册。
出现依赖环时构建失败并指出环本身，而不是生成有问题的代码。

泛型既可以作为依赖，也可以作为 `exposeAs` 的目标：`Repository<User>` 和 `Repository<Order>` 是两个
独立的注册，因为运行时 `AlloyKey` 由 `Type` 构造，而它们是不同的类型。但**被注入的类本身**不能是泛型
——`@AlloyInject class Cache<T>` 会被拒绝，因为没有任何信息告诉生成器该注册哪些具体化。请注解一个具体
子类型，或者用 `exposeAs` 暴露一个。

可空性不属于注册*键*的一部分——`Foo?` 依赖读取的仍是 `Foo` 的注册——但它把该依赖标记为**可选**。
可空的构造函数参数或 `@injected` 字段通过 `getOrNull` 解析，因此当图中没有对应注册时会注入 null，
而不是让构建失败。必需依赖不受影响；而当注册确实存在时，可选依赖依然是一条排序边。

可选性由类型表达，而不是注解：没有 `?`，字段本来也无法持有 null。运行时写法是
`scope.getOrNull<Foo>()`，它**只**在无人注册时返回 null——在 `init()` 之前请求异步单例仍会抛出，
因为"尚未就绪"和"不存在"是两件不同的事。

带 `@AlloyBootstrap` 的类会被收集进 `$alloyBootstrap`，先按 `order` 再按名称排序，以保证输出稳定。
它们在容器存在之前严格顺序执行，因此解析器会拒绝构造函数需要参数的引导步骤。

`$alloyBootstrap` 以**getter** 形式产出，而不是存储的列表：顶层 `final` 会让这些步骤每个进程只构建
一次，在重试启动之间、测试之间悄悄共享，并且在收养它们的作用域消失后仍然存活。步骤跑完后由根作用域
**收养**，所以打开了某样东西的步骤会在拆卸时关闭它——而且是最后关闭，排在所有构建于其上的东西之后。
如果某个步骤失败，已经跑过的会按相反顺序释放，然后才抛出错误：因为此时还没有作用域可以交接。

带 `@AlloyInit` 的类会成为异步单例：生成的工厂构造对象、await 它的 `init()`，并以翻译成 `AlloyKey`
的 `dependsOn` 注册它。注意这个集合字面量是在运行时构建的而非 `const`——`AlloyKey` 重写了 `==`，
而 const 集合的元素必须具有原始相等性。

### 环境——可选

到此为止的一切都不需要它。从不书写 `@AlloyEnvironment` 的项目只有一张图，所有注册都属于它，
`$startAlloy()` 也不接收任何环境参数。只有当某个构建需要与另一个构建不同的实现时，才需要往下读。

`@AlloyEnvironment` 把一个注册限制到一个或多个环境：

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

`dev`、`stage`、`prod` 和 `test` 是常量，而不是封闭集合——`@AlloyEnvironment('canary')` 声明你自己的
环境，行为完全相同。注解是**可重复**的而非接收列表，因为一个注册属于环境的*集合*，而启动时恰好选中
*一个*：

```dart
final scope = await $startAlloy(environment: AlloyEnvironment.prod);
```

生成的容器把这个选择作为字段接收，并且只给受限的注册加上守卫：

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

这个形状带来三个结果：

- **它自始至终都是可选的。** 只有当某个声明提到了环境，`environment` 参数才会出现；即便如此它也有默认值
  `AlloyEnvironment.defaultEnvironment`——即未拆分的图所处的那个唯一环境。该默认值只匹配无限制的注册，
  所以在没有选择的情况下启动一张已拆分的图，会让被拆分的类型处于未注册状态，首次解析它们时会明确报错，
  而不是悄悄返回错误的类。
- **不会有任何东西被注册两次。** 生成器会拒绝同一类型的两个注册，只要它们的环境有交集——包括其中一个
  完全不提环境的情况，因为无限制的注册在每个环境中都存在。原本会是悄无声息的 last-one-wins，现在是
  构建失败，并指名两个类以及它们冲突的环境。
- **Manual Mode 能做同样的事。** `matches` 就是普通的公开 API，所以手写的 builder 写出的 `if` 与生成器
  产出的一模一样。继承 `AlloyEnvironment` 并重写 `matches`，即可一次激活多个环境，或按名称之外的条件匹配。

`@AlloyBootstrap` 步骤同样接受环境。只要其中任何一个用到，`$alloyBootstrap` 就会从 getter 变成关于所选
环境的函数，被跳过的步骤既不会运行也不会被收养：

```dart
List<AlloyBootstrapStep> $alloyBootstrap(AlloyEnvironment environment) => [
  BindPlatform(),
  if (environment.matches(const <String>{'prod', 'stage'})) ReportCrashes(),
];
```

无人认领的环境是合法的，只是会让那些类型处于未注册状态——解析它们时会得到普通的"未注册"错误，
而不是悄悄拿到错误的类。

`@AlloyScopeRoot` 为根作用域命名，并把启动收敛为一次调用：

```dart
final scope = await $startAlloy();
```

生成器会产出 `$alloyRootScopeName`，以及把容器、引导列表和名称接在一起的 `$startAlloy()`。没有该注解时
名称默认为 `root`；同一个包中出现两个被注解的类是生成错误。

### 注册并非你编写的类型

`@AlloyInject` 只能加在类上，因此只覆盖你自己的类。其余的一切——来自其他包的客户端、SDK 交给你的
值——都通过模块进入图：

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

注解本身不携带任何配置：每个成员用与类相同的注解配置自己的注册，其参数像构造函数参数一样被解析。
该类需要一个不带参数的公开 `const` 构造函数，这样生成的工厂持有 `const NetworkModule()`，不携带状态。

`Future<T>` 是唯一的异步信号：这样的成员成为异步单例，而异步成员之间的顺序由生成器推导，而不是要你
手写。成员不能是抽象的：「用类自己的构造函数来构建」正是 `@AlloyInject` 已有的含义。

`dispose` 是外来类型的关闭方式。作用域拥有它构建的东西，但来自其他包的类型既不实现 `Disposable`
也不实现 `AsyncDisposable`，无法说明如何关闭自己。该参数对任何被保留的注册都可用，Manual Mode 亦然：

```dart
scope.registerLazySingleton<http.Client>(
  const ClientFactory(),
  dispose: (client) => client.close(),
);
```

### 图必须在构建之前就是完整的

没有任何东西注册的依赖会让构建失败，并一次性列出全部缺口：

```
Diagnostics requires DeviceInfo, which nothing registers. Annotate the class that
provides it with @AlloyInject, or name it in @AlloyScopeRoot(provides: [...]) when
something outside the generated container registers it.
```

标了 `@AlloyParam` 的参数不算在内：它由调用处提供，因此没有人注册它，也没有围绕它的顺序。加上这个标记
后该类就成为参数化注册，生成器会在容器旁写出它的参数类型，形式是具名 record：

```dart
@alloyInject
class NoteEditor {
  NoteEditor(this._notes, {@alloyParam required this.id, @alloyParam this.draft = false});
  ...
}

// typedef $NoteEditorArgs = ({int id, bool draft});
context.alloyWithParam<NoteEditor, $NoteEditorArgs>((id: 7, draft: true));
```

构造函数参数、`@injected` 字段和 `@AlloyInit(dependsOn:)` 都算在内；`@Named` 限定名是键的一部分，
因此在只有匿名 `Logger` 时请求 `@Named('audit') Logger` 同样是缺口。每个环境单独检查，所以只在
`dev` 下注册的东西无法满足同时运行于 `prod` 的消费者。

容器只看得见本包的注解。任何手写注册——包裹 `$AlloyRootScope` 的作用域构建器，或来自另一个包的
提供者——都必须事先声明：

```dart
@AlloyScopeRoot(name: 'app', provides: [SessionManager])
class AppScope {
  const AppScope();
}
```

声明本身不注册任何东西，它只是告诉检查：这件事由别人来做。`AlloyProvided(Logger, name: 'audit')`
用来声明带名字的注册。

这是 Code-Gen Mode 的保证。手写工厂在 `create` 内部解析，静态无法看出它会索取什么——Manual Mode
的图仍然会在运行时以 `AlloyNotRegisteredError` 失败。

## 谁拥有根作用域

`AlloyAppScope`。它构建图、发布图、在卸载时释放图，并把启动失败变成一个带重试按钮的界面，而不是一个
连第一帧都没来得及画就死掉的应用。

它接收图的方式与 `AlloyApplication.start` 相同，并且位于 `MaterialApp.builder` 之中，因此 `loading`
和 `errorBuilder` 是带着应用主题的普通界面，而不是第二个 `MaterialApp`：

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

`bootstrap` 是函数而不是列表，这是有意为之：步骤持有资源，而重启必须拿到新的。对于这个形状无法表达的图，
仍然有 `AlloyAppScope.start(start: ...)`。

`AlloyAppScope.of(context).restart()` 会重建图——重试失败的启动用的也是这个调用。在应用终止时释放是需要
显式开启的（`disposeOnExitRequest`），并且实际上只在桌面端有效；关于 Flutter 为什么无法在移动端做出这个
承诺，见 `alloy_flutter` 的 README。

## 观察这张图

`AlloyObserver` 报告图在做什么：作用域出现、实例被构建、启动完成、拆卸失败。观察者在创建图的地方传入：

```dart
final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyLogObserver(const AlloyDeveloperLogSink())],
);
```

下方压入的每个作用域都会继承这些观察者，所以注册一次即可覆盖整棵树。

有两点决定了这个设计。回调接收的是 `AlloyScopeRef` 和 `AlloyKey`——描述符，而不是活着的对象——因为一个能
在拆卸途中从作用域里解析、或者把它第二次释放的观察者，已经不算在观察了。而从回调抛出的异常会被吞掉：
观察不应该有能力破坏被观察的东西。

解析不会被上报。缓存命中是热路径，为每次 `get` 发一个事件只会变成噪音；值得看见的是实例**被构建**，
这由 `onInstanceCreated` 覆盖。没有注册任何观察者时，每个事件的代价就是一次空列表检查。

`AlloyLogObserver` 把事件转成 `AlloyLogRecord` 并交给 `AlloyLogSink`。`AlloyDeveloperLogSink`
（`dart:developer`，无依赖）随 `alloy` 一起提供；其余由适配器包接入：

| 包 | 形态 | 原因 |
|---|---|---|
| `alloy_talker` | `AlloyObserver` | 每类事件都成为各自带颜色的 `TalkerLog`，可在 `TalkerScreen` 中筛选 |
| `alloy_logging` | `AlloyLogSink` | dart.dev 的 `logging` 没有"记录种类"这一概念 |
| `alloy_logger` | `AlloyLogSink` | 同上，外加它自己的控制台打印 |

### 任何其他日志库，无需额外的包

一个 sink 就是一个回调，所以不会因为缺少适配器而把谁挡在门外：

```dart
AlloyLogObserver(AlloyLogSink.from((record) => myLogger.debug(record.message)))
```

| 日志库 | 全部集成代码 |
|---|---|
| `loggy` | `AlloyLogSink.from((r) => logDebug(r.message))` |
| `fimber` | `AlloyLogSink.from((r) => Fimber.d(r.message, ex: r.error))` |
| `simple_logger` | `AlloyLogSink.from((r) => logger.info(r.message))` |
| Graylog 或任何 JSON 接收端 | `AlloyLogSink.from((r) => gelf.send(r.toStructured()))` |

记录不只是一个字符串。`level`、`scope`、`key`、`error` 和 `stackTrace` 都在里面，而 `kind` 用值来
命名事件——`AlloyEventKind.scopeInitFailed`，而不是随时可能改写的句子
`scope "app" failed to initialize`。`toStructured()` 把这一切作为 map 交出去，这就是一个 GELF 或
JSON sink 的全部。

### 崩溃上报是另一种形态

日志 sink 收到的是每一行，因此必须廉价。崩溃上报收到的是离散事件，每一个都要花掉一次网络调用和一份
配额；而让一份报告可执行的不是异常本身，而是图在此之前在做什么。`AlloyErrorObserver` 会带着这条线索
上报失败：

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

| 上报服务 | 全部集成代码 |
|---|---|
| Sentry | `AlloyErrorSink.from((r) => Sentry.captureException(r.error, stackTrace: r.stackTrace))` |
| Crashlytics | `AlloyErrorSink.from((r) => FirebaseCrashlytics.instance.recordError(r.error, r.stackTrace))` |

有两个默认值值得知道。线索在所有级别上都会保留，包括日志 sink 默认丢弃的逐实例记录——在出问题之前
它们不花什么代价，而"最后构建的是什么"通常正是有用的那一行；它是一个 20 条的环形缓冲，所以长时间
运行的应用不会让它无限增长。上报阈值是 `error` 而不是 `warning`：拆卸失败以 warning 到达，它确实
意味着资源泄漏，但每次小问题都惊动付费服务，是让报告没人再看的可靠办法。需要时用 `reportAt` 调低。

它只上报 Alloy 自己知道出错的事情——抛异常的初始化器、失败的引导步骤、没能完成的拆卸。没有上报任意
错误的方法，因为这不是通用的错误通道；你已经在用的那个上报服务才是。

`AlloyMultiSink` 把一条记录分发给多个目的地，而且某个 sink 抛异常不会让其余的失声——控制台加崩溃上报
是生产环境的常见搭配：

```dart
AlloyLogObserver(
  const AlloyMultiSink([AlloyDeveloperLogSink(), _CrashReporterSink()]),
)
```

`alloy` 自身提供两个零依赖的 sink：`AlloyDeveloperLogSink`（`dart:developer`，Flutter 应用里的正确默认）
和 `AlloyPrintLogSink`（stdout，适合 CLI 或初次查看）。

这条通道也修补了一个真实的缺口：当启动失败、Alloy 回滚时，一个**同样**释放失败的引导步骤无法通过
`AlloyBootstrapError` 上报，否则就会掩盖导致失败的原因。以前它被一个裸 `catch` 丢掉了。现在它是
`onBootstrapStepReleaseFailed`。

## 流程作用域

`alloy_go_router` 让作用域的生命周期等于一段导航流程——流程打开时创建，关闭时释放：

```dart
AlloyShellRoute(
  name: 'checkout',
  identity: (state) => state.pathParameters['orderId'],
  scope: (state) => CheckoutScope(state.pathParameters['orderId']!),
  routes: [...],
)
```

它就是一个普通的 `ShellRoute` 子类——因此凡是接受 `RouteBase` 的路由表都能放进去，而且通过继承它可以给
一段流程起自己的名字。作用域由流程内部的一个 widget 拥有。这就够了，因为 go_router 用路由对象的标识来
为 shell 的 page 生成 key，所以子树能挺过流程*内部*的每一次导航，并在流程离开 match list 的那一帧被销毁。
没有任何东西去监听路由器并镜像它的状态——手写版本正是在镜像这一步上，栽在返回键、深链接和标签切换上。

标签页也是同样的待遇：`AlloyStatefulShellRoute` 为整个 `StatefulShellRoute` 划定作用域，
`AlloyStatefulShellBranch` 为单个标签划定作用域，两者组合成三层。不过分支是被保持*存活*而非保持*可见*的
——go_router 会在屏幕外保留分支的导航器，所以一个标签的作用域活到 shell 关闭为止，而不是活到你切走为止。

路由器唯一无法决定的是：`/orders/1` 和 `/orders/2` 算不算同一段流程；这由 `identity` 回答。路由不位于
同一棵子树的流程无法用这种方式表达，而这个限制是有意的——见该包的 README。

## 示例

一个应用把它们全部跑起来：

```bash
cd examples/gallery && flutter run
```

这个 gallery 按**能力**组织，而不是按项目——读者是来搞清楚作用域怎么结束的，不是来看 `notes_app` 的。
六个分区，十四个条目：

| 分区 | 条目 |
|---|---|
| Startup | 两阶段启动 · 环境 |
| Injection | 属性注入 · 具名与多重注入 |
| Scopes & lifetime | 组件持有的作用域 · 会话作用域 · 作用域树 · 导航流程 · 拆卸 |
| Code generation | 生成的容器 · 手写模式 |
| Observability | 图的事件 · 应用内检查器 |
| Testing | 测试写法 |

每个有界面的条目都以**自己的**图打开：进入时构建，离开时释放。同时打开两个，它们的作用域树互不相干
——而这正是 gallery 真正要展示的东西。三个没有界面的条目（`拆卸`、`手写模式`、`测试写法`）显示的是
控制台输出而不是按钮，因为一个提出要"打开"命令行程序的 gallery 是在撒谎。

Gallery 提供英文、俄文和中文，可以在首页直接切换 —— 它挂载的每一个界面也一样。每个示例包都带有
自己的 `l10n/*.arb` 并生成自己的 delegate，gallery 把它们和自己的、检查器的一起注册：这正是一个
多包 Flutter 应用的样子。有两处文案原本位于控件层之下，那里没有 `BuildContext` 可以询问语言 ——
现在它们只报告事实，由界面来措辞。

框架自身写出的日志记录仍是英文，界面上的标识符也一样：步骤名、作用域名、注册键、生命周期。哪些
内容有意保留 Alloy 自己的措辞、以及为什么，见
[`alloy_inspector` README](packages/alloy_inspector/README.md)；示例是怎么接线的，见
[gallery 的 README](examples/gallery/README.md)。

在它背后，这些示例仍是 `examples/` 下普通的包——`notes_app`、`flow_scopes`、`graph_events`、
`codegen_basics` 是 gallery 挂载的库，而 `manual_mode`、`teardown`、`testing_patterns` 是纯 Dart
或只有测试。它们分开并不是为了整洁：`alloy_container` 会把整个包聚合成一个 `$AlloyRootScope`，
所以同一个包里的两个生成式示例会把图合并到一起。

## Lint 插件

`alloy_lint` 是一个 `analysis_server_plugin`，而不是 `custom_lint` 插件（见"工具链"）。它提供十一条 warning
级别的规则，全部构建在生成器所用的同一个 `alloy_analyzer` 解析层之上，因此错误会在 IDE 中浮现，而不是
只在跑 `build_runner` 时才出现：

| 规则 | 捕获什么 |
|---|---|
| `alloy_missing_injection_mixin` | 容器会注册的类上有 `@injected` 字段却没有 `with _$ClassName` |
| `alloy_injected_field_needs_an_injectable` | 容器从不注册的类上出现了 `@injected` 字段 |
| `alloy_param_needs_an_injectable` | 容器从不注册的类上出现了 `@AlloyParam` |
| `alloy_injected_field_must_be_late_final` | `@injected` 用在可变、非 late 或静态字段上 |
| `alloy_injectable_must_be_constructible` | `@AlloyInject` 用在抽象类上，或用在没有公开生成式构造函数的类上 |
| `alloy_init_requires_init_method` | `@AlloyInit` 用在没有 `init()` 的类上 |
| `alloy_bootstrap_requires_run_method` | `@AlloyBootstrap` 用在没有 `run()` 的类上 |
| `alloy_bootstrap_step_cannot_inject` | 构造函数需要参数的引导步骤 |
| `alloy_dependency_is_not_registered` | 包内无人注册的被注入依赖 |
| `alloy_dependency_cycle` | 最终依赖到自身的可注入类 |
| `alloy_environment_needs_a_registration` | `@AlloyEnvironment` 用在没人注册的类上，此时它什么也不做 |

接入时有两件事会实实在在地耗掉时间，而且很容易弄错：

1. `plugins:` 段**只在包或 workspace 的根目录生效**。把它放进嵌套的 `analysis_options.yaml` 会被静默忽略
   ——没有错误，也没有诊断。同理，`dart analyze <nested/dir>` 不会应用它；请分析 workspace 根目录。
2. 分析服务器在一个隔离的 pub 上下文中解析插件，因此未发布的 workspace 同级包对它是不可见的。每一个未发布
   的传递依赖都需要在 `plugins: dependency_overrides:` 下有一条记录——见本仓库根目录的
   `analysis_options.yaml`。

规则的行为由 `packages/alloy_lint/test` 中基于 `analyzer_testing` 的测试覆盖，它们直接驱动规则，完全不需要
插件的引导流程。

## 关于 Linting

本项目不使用 `custom_lint`。它的最新版本（0.8.1）被钉死在 `analyzer ^8.0.0`，无法与现代 analyzer 共存；
`riverpod_lint` 已经从它迁移到第一方的 `analysis_server_plugin`，`alloy_lint` 也跟随这一选择。
