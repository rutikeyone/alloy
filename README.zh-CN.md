[English](README.md) · [Русский](README.ru.md) · [中文](README.zh-CN.md)

> 本文档译自 [README.md](README.md)。英文版为准：若有出入，以英文为准。
> 各个包自身的 README 不作翻译——它们是 API 参考。

# Alloy

面向 Dart 和 Flutter 的依赖注入框架。双模式：声明式代码生成，以及基于同一套运行时的纯 Dart 手写 API。

状态：**第一阶段已完成。** 运行时、Flutter 绑定、注解、分析层、两个生成器和 lint 插件均已实现并覆盖测试。

| | |
|---|---|
| **不用代码生成** | [GUIDE_MANUAL.zh-CN.md](GUIDE_MANUAL.zh-CN.md)——注册由你来写 |
| **用生成器** | [GUIDE_CODEGEN.zh-CN.md](GUIDE_CODEGEN.zh-CN.md)——注解，以及在构建期被检查的图 |
| **从 `get_it` 或 `injectable` 过来** | [MIGRATION.zh-CN.md](MIGRATION.zh-CN.md)——哪些对得上，哪些对不上 |
| **跑起来看看** | `cd examples/gallery && flutter run` |

## 它是什么

一个拥有自己所构建之物的容器。作用域构成一棵树而不是一个栈，
因此会话、结账流程和界面各有自己的生命周期，结束其中之一会连带结束在它内部构建的一切——
登出就是 `await scope.dispose()`，而不是九处对会话流的订阅，
外加四个渗进领域接口的 `reset()` 方法。

代码生成是这套运行时之上的便利，而不是第二个框架。生成器写出的正是你会手写的东西，
除了 `alloy` 的公开 API 之外什么都不用——这正是渐进式迁移得以可能的原因：
生成的容器和手写的容器可以组合在同一张图里。

## 特性

| | |
|---|---|
| **层级作用域** | 是树而不是扁平的栈——两棵互不相关的子树可以并存，而栈表达不了这一点 |
| **所有权与销毁** | 作用域释放它构建的东西，按**创建**顺序倒序，尽力而为，整棵树共用一个截止时间 |
| **两阶段启动** | `@AlloyBootstrap` 在容器存在之前，`@AlloyInit` 在容器内部，`start` 返回前两者都已完成 |
| **拓扑排序** | 异步初始化器按 Kahn 算法分层；互不相关的分支通过 `Future.wait` 并行，出现环则构建失败并指出这个环 |
| **属性注入** | `late final` 字段由生成的 mixin 填充，于是有五个协作对象的类拥有一个空构造函数 |
| **编译期完整性** | 没有人注册的依赖会让构建失败，并一次性点出所有缺口 |
| **参数化注册** | `@AlloyParam` 表示由调用方提供的部分；生成器把参数类型写成具名 record |
| **可选依赖** | `Foo?` 通过 `getOrNull` 解析，注入 null 而不是让构建失败 |
| **模块** | 注册不是你写的类型——别的包里的客户端、SDK 交给你的值 |
| **环境** | 同一个抽象，按构建给出不同实现，重叠会在构建期被拒绝 |
| **命名注册与多重注入** | `@Named` 限定符，以及遍历某类型全部注册的 `getAll<T>()` |
| **可观测性** | 类型化事件而不是字符串——日志、结构化上报，以及带线索的崩溃报告 |
| **应用内检查器** | 实时作用域树、构建了什么及其生命周期，以及上报过的一切 |
| **导航流程** | 生命周期即一段 go_router 流程的作用域，并且没有任何东西去镜像路由 |
| **lint 插件** | 十二条规则，建立在生成器所用的同一套解析层上 |
| **测试辅助** | 随测试一起销毁的作用域，以及与生产环境同一套机制的依赖覆盖 |
| **没有全局容器** | 没有任何东西是环境隐式的，所以测试可以并行，同一进程里的两张图互不相关 |

## 包

| 包 | 依赖 | 是否进入应用 |
|---|---|---|
| `alloy_annotations` | `meta` | 是 |
| `alloy` | `alloy_annotations` | 是，运行时核心，不含 Flutter |
| `alloy_flutter` | `alloy`、`flutter` | 是 |
| `alloy_go_router` | `alloy_flutter`、`go_router` | 是，可选 |
| `alloy_bloc` | `alloy`、`bloc` | 是，可选 |
| `alloy_talker` | `alloy`、`talker` | 是，可选 |
| `alloy_logging` | `alloy`、`logging` | 是，可选 |
| `alloy_logger` | `alloy`、`logger` | 是，可选 |
| `alloy_analyzer` | `alloy_annotations`、`analyzer` | 否 |
| `alloy_generator` | `alloy_analyzer`、`build`、`source_gen`、`code_builder` | 仅 dev_dependency |
| `alloy_lint` | `alloy_analyzer`、`analysis_server_plugin` | 仅 dev_dependency |
| `alloy_test` | `alloy`、`test_api`、`matcher` | 仅 dev_dependency |
| `alloy_test_flutter` | `alloy_flutter`、`flutter_test` | 仅 dev_dependency |
| `alloy_inspector` | `alloy_flutter`、`flutter` | 仅 dev_dependency |
| `alloy_talker_flutter` | `alloy_inspector`、`alloy_talker`、`talker_flutter` | 仅 dev_dependency |

`alloy_analyzer` 的存在是为了让生成器和 lint 插件用**同一套**实现解析 Alloy 声明，而不是两套迟早会
各说各话的实现。它持有 IR 和拓扑排序，并且既不依赖 `build`，也不依赖插件 API。

**项目不变量：** 生成的代码只允许使用 `alloy` 的公开 API。一旦生成需要 Manual Mode 无法表达的东西，
那就是两个共用一个名字的框架了。

## 环境要求

在 **Flutter 3.47.1 / Dart 3.13.1**、analyzer 13.3.0 上构建并测试。

所有包都要求 Dart `^3.13.0`，而 3.47 以下的 Flutter 都不附带该版本——所以这就是统一的下限，包与包
之间并不存在需要留意的版本差异。CI 跑 `stable` 和 `beta`，而不是历史版本矩阵：值得提前发现的是**尚未
发布**的那个问题。

不要让 Homebrew 的 `dart` 出现在 PATH 前面——把 Flutter SDK 放在最前。旧版 `dart` 不会大声报错：
`dart analyze .` 会用错误的 analyzer 报出几十条幻觉问题，而 `dart pub get` 则直接拒绝 SDK 约束。
在相信一次运行结果之前，先用 `dart --version` 确认。

## 它如何工作

### 作用域拥有它构建的东西

作用域是一个节点，有父节点、子节点和自己的注册项。解析沿树向上，
因此子作用域中的注册会遮蔽上层的同名注册——测试里的依赖覆盖就是这样工作的，
生产环境中会话的仓储替换掉匿名仓储也是这样，用的是同一套机制，而不是什么后门。

销毁按**创建**顺序倒序，而不是声明顺序。这个区别正是多数手写容器里的 bug：
先声明、后创建的组件会被先销毁，而那时还有人依赖它。销毁是尽力而为的：
抛异常的 `dispose` 会被记录、其余照常执行，整棵树共用一个截止时间，
没做完的事列在 `AlloyDisposeError` 里，而不是让第一个错误盖住其余九个。

父作用域强引用子作用域。弱引用曾被考虑并否决：它会允许子作用域在 `dispose()` 运行前被回收，
也就是永远不运行；而且它根本防不住泄漏——内部的活对象自己就撑着自己。

### 图在构建之前就被检查

Code-Gen Mode 在构建期拒绝不完整的图，并在一条消息里点出所有缺口：

```
Diagnostics requires DeviceInfo, which nothing registers. Annotate the class that
provides it with @AlloyInject, or name it in @AlloyScopeRoot(provides: [...]) when
something outside the generated container registers it.
```

构造参数、`@injected` 字段和 `@AlloyInit(dependsOn:)` 都算在内，`@Named` 限定符是键的一部分，
每个环境分别检查。重复注册、依赖环、同一个包里两个作用域根、泛型可注入类、抽象类——同样都是构建失败。

这是 Code-Gen 才有的保证，边界也说得很老实：手写工厂在 `create` 内部解析，
静态分析看不到它将要请求什么。Manual Mode 的图仍然会在运行时失败——
`alloy_test` 里的 `expectGraphResolves` 正是为这个缺口准备的。

### 生成的代码就是你本来会写的代码

三个构建器：一个写属性注入的 mixin，一个把每个库扫描成 IR，一个把整个包聚合成 `lib/alloy.g.dart`。
聚合之所以分两阶段，是因为单个构建步骤看不到整个程序。

产物是私有 const 工厂类和一个 `$AlloyRootScope`，其顺序由编译期拓扑排序确定——
没有闭包、没有反射、没有运行时扫描。`$alloyBootstrap` 是 getter 而不是存下来的列表，
所以重启拿到的是新的步骤，而不是上次启动已经用掉的那些。

泛型作为依赖和 `exposeAs` 目标都可用：`Repository<User>` 和 `Repository<Order>` 是两条注册，
因为 `AlloyKey` 由 `Type` 构成，而它们是不同的类型。但可注入类本身不能是泛型：
没有人告诉生成器该注册哪些具体实例化。

### 可观测性是类型化事件

`AlloyObserver` 汇报这张图在做什么——作用域出现、实例被构建、启动完成、销毁失败。
回调收到的是描述符而不是活对象，因为一个能在销毁进行到一半时从作用域里解析东西的观察者，
就不再只是在观察了；回调抛出的异常会被吞掉：观察不能有能力破坏被观察者。

记录把 `kind` 作为值而不是一句话来携带，这正是结构化上报端能够以
`AlloyEventKind.scopeInitFailed` 为键、而不必解析散文的原因。日志 sink 只是一个回调，
所以不会有哪个日志库因为缺少适配包而被挡在外面；崩溃上报则自成一种形态，
因为让报告有用的是「图在那之前正在做什么」这条线索。

没有注册任何观察者时，每个事件的代价是一次空列表判断。

### 导航流程

`alloy_go_router` 让作用域的生命周期成为一段导航流程：进入流程时创建，离开时销毁。
它就是一个普通的 `ShellRoute` 子类，作用域由其内部的一个 widget 持有——
没有任何东西去监听并镜像路由，因为手写版本恰恰是在镜像这件事上，
栽在返回键、深链接和标签页切换上的。

路由不构成单一子树的流程无法用这种方式表达，这个限制是有意的——见该包的 README。

## lint 规则

`alloy_lint` 是 `analysis_server_plugin`，不是 `custom_lint` 插件。它提供十二条 warning 规则，
全部建立在生成器所用的同一套 `alloy_analyzer` 解析层上，
因此错误会在 IDE 里出现，而不是非等到 `build_runner` 跑完：

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
| `alloy_environment_needs_a_registration` | `@AlloyEnvironment` 用在无人注册的类上，此时它静默地什么也不做 |
| `alloy_dependency_is_not_registered` | 包内无人注册的被注入依赖 |
| `alloy_dependency_cycle` | 最终依赖到自身的可注入类 |
| `alloy_registration_is_never_released` | 已注册的类带有作用域看不见的 `dispose()` 或 `close()` |

不使用 `custom_lint`：它的最新版本（0.8.1）被钉在 `analyzer ^8.0.0`，无法与现代 analyzer 共存。
`riverpod_lint` 已迁移到官方的 `analysis_server_plugin`，`alloy_lint` 亦然。

配置这个插件有两个坑，最好在踩上之前先读一读——见
[GUIDE_CODEGEN.zh-CN.md §16](GUIDE_CODEGEN.zh-CN.md#16-lint-插件)。

## 示例

一个应用把它们全部跑起来：

```bash
cd examples/gallery && flutter run
```

画廊是按**能力**而不是按项目组织的——读者来这里是想知道作用域如何结束，
而不是想看 `notes_app`。六个分区，十四个条目：

| 分区 | 条目 |
|---|---|
| 启动 | 两阶段启动 · 环境 |
| 注入 | 属性注入 · 命名与多重注入 |
| 作用域与生命周期 | widget 持有的作用域 · 会话作用域 · 作用域树 · 导航流程 · 销毁 |
| 代码生成 | 生成的容器 · Manual Mode |
| 可观测性 | 图事件 · 应用内检查器 |
| 测试 | 测试范式 |

每个带界面的条目都用**属于自己的**图打开：进入时构建，离开时销毁。
同时打开两个，它们的作用域树互不相关——而这正是画廊真正想展示的东西。
三个没有界面的条目（`销毁`、`Manual Mode`、`测试范式`）展示的是控制台输出而不是一个按钮，
因为一个声称能「打开」命令行程序的画廊是在说谎。

画廊本身用英语、俄语和中文书写，可在首页切换——它挂载的每一个界面同样如此。
每个示例包都带着自己的 `l10n/*.arb` 并生成自己的 delegate，
由画廊连同自己的和检查器的一起收集；一个多包 Flutter 应用就是这个样子。

框架自身的日志记录仍然是英文，屏幕上的标识符也是——步骤名、作用域名、注册键、生命周期。
哪些内容保留 Alloy 自己的措辞、为什么，见
[`alloy_inspector` 的 README](packages/alloy_inspector/README.md)；
示例如何接线，见[画廊的 README](examples/gallery/README.md)。

## 在本仓库上工作

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

`tool/coverage.sh` 统计有测试的可发布包的行覆盖率，从最低往高打印，并在**总和**低于下限时失败——85%。
当前数字以脚本打印的为准，这里不再重复：一个每次提交都会变的数字写进散文里就会过时，
而且没有任何东西会检查它——它已经过时过两次了。下限取总和而非逐包，这是有意的：
覆盖率是按包统计的，而代码是共享的，所以 `alloy_analyzer` 的解析器更多是被
`alloy_generator` 的测试和 `compat/external_consumer` 驱动的，而不是被它自己的测试集。
逐包下限会逼人把测试写在不该写的地方。用 `COVERAGE_FLOOR=90 ./tool/coverage.sh` 覆盖它。

CI（`.github/workflows/ci.yml`）在 `stable` 和 `beta` 上跑上述全部内容，
并在重新生成两个示例**以及 `compat/external_consumer`** 之后执行 `git diff --exit-code`，
因此过时的生成代码会让构建失败。生成器用与格式检查相同的 `dart_style` 版本格式化自己的产物，
所以两者不会有分歧。

**目录约定。** 一个文件一个公开类型。sealed 的 `AlloyRegistration` 层次是有意的例外：
sealed 层次必须位于同一个库中，所以它的子类是 `part` 文件而不是独立的库。
`compat/external_consumer` 则完全在这条经验法则之外——它是一个刻意**不**作为 workspace 成员、
也不声明 `resolution: workspace` 的包，因此 pub 会像对待第三方项目那样独立解析它。
它的存在是为了从仓库之外保持代码生成流水线的诚实。

**已知的发布警告。** `alloy_lint` 会报「the name of lib/main.dart should match the name of the
package」。这个入口点是由分析服务器插件 API 固定的——服务器生成的代码会导入
`package:alloy_lint/main.dart` 并读取其中的 `plugin` 变量。`riverpod_lint` 也带着同样的警告。

## 许可证

MIT。见 [LICENSE](LICENSE)。
