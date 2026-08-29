<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">
  面向 Noita 的创意工具集：法术、法杖、物品、材料、天赋、生物、效果、传送、天气和世界规则。
</p>

<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [**简体中文**](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## 下载

当前版本：**2.0.0**

| 内容 | 下载 |
|---|---|
| **最新可直接安装版本** | **[⬇️ 下载 Metamorph-Creative-Menu.zip](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)** |
| 版本页面 | [最新可直接安装版本](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) |

> ZIP 中已经包含完整的 `metamorph_creative_menu` 文件夹以及随附的 NoitaPatcher。请直接将该文件夹解压到 `Noita/mods/`。

正确的最终路径：

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

如果得到的是 `metamorph_creative_menu/metamorph_creative_menu/mod.xml`，说明解压时多套了一层文件夹。

---

## 简体中文

### 安装

1. [下载最新的可直接安装 ZIP](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)。
2. 安装或更新模组前请完全关闭 Noita。
3. 在 Steam 中打开 **库 → 右键 Noita → 管理 → 浏览本地文件**。
4. 打开游戏的 `mods` 文件夹，将完整的 **`metamorph_creative_menu`** 文件夹复制进去。
5. 确认 `Noita/mods/metamorph_creative_menu/mod.xml` 存在。不要重命名模组文件夹。
6. 启动 Noita，启用 **Metamorph: Creative Menu**，需要时允许 **Unsafe mods / unrestricted API**，然后在启用模组后重新启动 Noita。
7. 开始一局游戏并按 **TAB**。如果菜单可以打开，安装即完成。

**更新：**关闭 Noita，删除旧的 `metamorph_creative_menu` 文件夹，再把新文件夹复制到 `mods`。完整替换文件夹可以避免旧版本文件残留。

### 操作

- **F4 或 TAB**：打开或关闭 Creative Menu。
- **变形状态下按 TAB**：恢复人类形态。
- **G**（默认）：附身光标下受支持的生物。
- **鼠标中键**：使用当前选中的材料绘制。
- 按键可以在“控制”页面或模组设置中修改。鼠标左键和右键当前可执行的操作会显示在界面中。

### MCM 可以做什么

- 获取和放置法术，并在法杖、“始终施放”槽位、物品栏和世界之间移动法术。
- 编辑法杖属性、外观和锁定状态；保存法杖预设并创建副本。
- 在玩家附近或指定世界位置生成物品，并将受支持的物品直接放入物品栏。
- 创建装有指定液体的烧瓶。
- 选择材料并将其绘制到世界中。
- 生成、添加和移除天赋。
- 在玩家附近或指定世界位置生成生物。
- 变形成生物、附身世界中已有的生物，并恢复人类形态。
- 生成一个独立的 PLAYER 实体。
- 应用和移除游戏效果。
- 修改天气、时间、重力和其他世界规则。
- 传送到游戏中的地点。
- 配合 Entangled Worlds 时，可以传送到其他玩家身边或把其他玩家带到自己身边。
- 修改按键，并搜索法术、物品、材料、天赋和生物目录。
- 移动和调整菜单窗口大小；窗口位置和大小会在不同游戏启动之间保存。

<details>
<summary><strong>变形、兼容性与恢复</strong></summary>

MCM 依据精确的 XML 路径保存兼容性信息，并只为已知不安全或不适合直接使用原生变形机制的实体设置少量安全路由例外。由玩家控制的形态会尽量保留有用的原生移动、攻击、视觉表现和物理行为，同时关闭会与玩家输入冲突的人工智能。复杂首领、脚本驱动较强的实体以及物理对象可能需要专用适配器，而且不一定能完整复现其原本的全部人工智能行为。

NoitaPatcher 用于更强的恢复机制，例如实体序列化与反序列化、玩家实体控制权交接以及其他高级运行时功能。因此，完整的独立版本需要不受限制的模组接口权限。

</details>

<details>
<summary><strong>与 Entangled Worlds 的多人联机集成</strong></summary>

**Entangled Worlds 是可选的。** MCM 本身可以作为完整的单人模组运行，不需要 EW。

启用 `quant.ew` 后，MCM 会为共享物品、天赋、天气、世界规则、形态与附身、同伴请求以及相关的控制权和同步行为启用实验性联机集成。所有参与者都应使用相同版本的 MCM。多人支持被明确视为实验功能，因为 Noita 与 EW 的某些边缘情况无法保证始终完美同步。

</details>

### 要求与第三方组件

- **Noita** — 必需的游戏，由 Nolla Games 开发。
- **NoitaPatcher**（dextercd）— 已随 MCM 提供，用于高级运行和恢复功能。
- **lbase64**（Ilya Kolbin）— 随附的本地 Base64 实现。
- **Entangled Worlds / Noita Proxy**（IntQuant 及贡献者）— 可选的多人联机集成；单人游戏不需要。

第三方项目的准确链接、随附组件路径以及许可证或状态说明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

### 故障排除

- **TAB 没有反应：**检查 `mod.xml` 的准确路径，确认 MCM 已启用，允许 Unsafe mods/unrestricted API，然后重新启动 Noita。
- **缺少高级恢复功能或部分世界规则功能：**确认 `metamorph_creative_menu/NoitaPatcher/noitapatcher.dll` 存在，并且 unrestricted API 权限已允许。
- **某个形态无法正常恢复：**请报告准确的生物名称或 XML，并说明是普通 TAB 返回失败，还是受到致命伤害后的恢复失败。
- **EW 不同步：**确认所有参与者使用相同的 MCM 版本和兼容的 EW 版本。

### 链接

- [最新版本](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)
- [报告问题](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)
- [第三方组件说明](THIRD_PARTY_NOTICES.md)
- [Noita](https://noitagame.com/)
- [NoitaPatcher](https://github.com/dextercd/NoitaPatcher)
- [NoitaPatcher 文档](https://dexter.döpping.eu/NoitaPatcher/)
- [Entangled Worlds](https://github.com/IntQuant/noita_entangled_worlds)
- [lbase64](https://github.com/iskolbin/lbase64)

[↑ 返回语言选择](#languages)

---

## 开发者信息

可运行的模组位于 `metamorph_creative_menu/`。

- 架构与开发说明：`metamorph_creative_menu/README.txt`
- 回归测试套件：`metamorph_creative_menu/tests/`
- 测试说明：`metamorph_creative_menu/tests/TESTING.txt`
- 第三方组件说明：[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

仓库中的自动 `latest-build` 工作流会把可运行的 `metamorph_creative_menu` 文件夹打包为可直接安装的 ZIP，并更新上方的固定下载地址。