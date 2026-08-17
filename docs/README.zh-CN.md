# Metamorph: Creative Menu — 简体中文

[English](README.en.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es-ES.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## 简介

**Metamorph: Creative Menu (MCM)** 是 **Noita** 的创意/开发者菜单。它可在单人游戏中独立运行，同时提供可选的、实验性的 **Entangled Worlds / Noita Proxy** 兼容层。

MCM 可以编辑法杖、生成或直接获得物品、添加/移除天赋与效果、变形成生物、占据鼠标指向的现有生物、控制天气与世界规则，并生成类似玩家的友方同伴。

## 要求与安装

- 已安装 Noita。
- 将 `metamorph_creative_menu` 放到 `Noita/mods/`。
- 在 Noita 模组菜单中启用 **Unsafe mods / unrestricted API**。MCM 内置的原生 **NoitaPatcher** 扩展需要该权限。
- Entangled Worlds **不是单人模式的必需依赖**。

安装步骤：
1. 从 [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) 下载构建，或下载/克隆本仓库。
2. 将整个 `metamorph_creative_menu` 复制到 `Noita/mods/`。
3. 确认存在 `Noita/mods/metamorph_creative_menu/mod.xml`。
4. 启用 Unsafe mods，然后启用 Metamorph: Creative Menu。

不要重命名模组内部文件夹。

## 操作

- **TAB** — 打开/关闭菜单。
- **变形状态下 TAB** — 返回正常人类形态。
- 默认 **G** — 占据/变形成鼠标指向的兼容生物；可在设置中改键。
- 各标签中的左键/右键用途会在 UI 中显示。

## 功能

### 法术/法杖编辑
手持法杖，选择槽位，再从支持分类与搜索的目录中选择法术。可替换、删除或把法术丢到世界中。替换操作会先确认新法术已正确附加，再删除旧法术。

### 物品
支持容器、液体、石头、蛋、法杖、书、奖励、宝珠、任务物品等。
- **左键：** 在附近生成。
- **右键：** 尝试直接放入合适的背包槽位。
- 背包满或拾取失败时，物品会保留在世界中。
- 支持装有液体的烧瓶/容器。

### 天赋
- **ADD：** 左键生成普通天赋拾取物；右键直接应用。
- **REMOVE：** 左键移除一层；右键尝试全部移除。
MCM 会记录许多属于天赋的实体、组件和值，以便安全逆转，并尽量不覆盖其他模组/系统的变化。若无法确定安全逆操作，MCM 宁可拒绝危险移除。

### 搜索
大型目录支持按本地化名称、ID 和/或描述搜索。

### 生物、对象与形态
- **左键：** 生成。
- **右键：** 变形。
- **TAB：** 返回人类。

兼容性按精确 XML 路径记录，而不是用宽泛文件名黑名单。少量已知危险的 placement wrapper 仅在变形时会路由到安全 canonical target。玩家形态会尽量保留可用的原生攻击、移动、外观和物理，同时关闭与玩家控制冲突的 AI。复杂实体可能使用近似适配器。

### 人类恢复与形态死亡
普通 TAB 返回首先使用 Noita 原生 polymorph 生命周期。MCM 还通过 NoitaPatcher 保存序列化的人类备份。

受到致命伤害时，**death handoff** 会尝试让当前生物身体正常死亡，同时把玩家控制权交还给恢复的人类身体，从而避免“形态死亡 = 整个 run 结束”。

### 占据
瞄准兼容生物并按 **G**。MCM 使用该目标的兼容形态，并退役/移除原目标，避免仅在旁边生成一个复制体。

### PLAYER 同伴
`PLAYER` 项目可生成类似玩家的友军。具备所需 NoitaPatcher 功能时，同伴可以更接近真实玩家地使用复制的法杖。

### 效果
可应用状态/限时效果，在支持时选择持续时间，并通过编辑器移除效果，同时尽量保留不属于编辑器的内部/天赋状态。

### 天气
时间预设：早晨、白天、傍晚、夜晚。天气预设：晴朗、多云、雾、暴风雨。高级模式可修改受支持的时间、云量、雾、风、风速、雨和雷电参数。**RELEASE** 会停止 MCM 持续维持天气 override。

### 世界规则
世界规则是**可逆 override**。`NATIVE`/RESET 会恢复 MCM 捕获的原始 baseline；关键规则使用持久 recovery 记录。

当前规则：

- 生物关系
- 金币不消失
- 无限法术次数
- 揭开战争迷雾
- 花式击杀血钱
- 治疗掉落几率
- 友好老鼠
- 血腥程度
- 花式击杀金币
- 受伤闪光
- 污渍脱落
- 世界重力
- 物理阻尼
- 血液量
- 踢击力量
- 关节强度
- 昼夜循环速度

物理规则作用于已加载/附近的实体与物理体，并不会瞬间修改整个无限世界中尚未加载的所有对象。

## 单人与 Entangled Worlds

**单人模式不需要 Entangled Worlds。** MCM 自带 NoitaPatcher 和本地 Base64 编解码器。

启用 `quant.ew` 后，会开启实验性的物品、天赋、天气、世界规则、形态/占据、同伴与兼容修补同步层。如果 EW 已发布兼容的 NoitaPatcher API，MCM 可以复用它。

多人支持仍为**实验/部分支持**。目标是 host 与 client 拥有相同的 MCM 用户权限，但无法保证所有 Noita/EW 极端情况。所有玩家应使用相同 MCM 版本。

## 故障排除与反馈

- 菜单打不开：检查路径和模组是否启用。
- 缺少高级功能：启用 Unsafe mods，并确认 `NoitaPatcher/noitapatcher.dll` 存在。
- 某个形态有问题：提供准确名称/XML，并说明是 TAB 返回还是死亡返回失败。
- EW 问题：提供 MCM 与 EW 版本。

请在 [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) 提交问题，并附上版本、复现步骤和可用日志。

## 第三方依赖与致谢

MCM 内含 **NoitaPatcher**（dextercd）和 **lbase64**（Ilya Kolbin），并可选集成 **Noita Entangled Worlds**（IntQuant 与贡献者）。完整路径、用途和许可证/状态说明见 [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md)。

## 链接

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

## 开发

可玩的模组目录为 `metamorph_creative_menu/`；测试与架构/行为契约在 `metamorph_creative_menu/tests/`。MCM 原创代码目前尚未选择仓库级统一许可证。
