# ADR-002: Overlay 策略 — 选项驱动，内聚模块

**日期**: 2026-06-01
**修订**: 2026-06-02
**状态**: 已采纳

### 问题

如何决定哪些节点应用自定义 overlay（如 nushell 0.113.0）？

### 历史方案（已废弃）

| 方案 | 描述 | 废弃原因 |
|------|------|----------|
| ~~Builder 隐式扫描~~ | `libs/nixos-builder.nix` 通过 `domainName` 判断 + 扫描 `modules/overlay/` | **AI 失控**：散落目录 = 垃圾场 |
| ~~域级 import 独立 overlay~~ | `hosts/<domain>/<name>-overlay.nix` 通过 `imports` 引入 | 仍然散落，和 vivaldi/wanxiang 模式不一致 |

### 真正原因（核心教训）

**不要让 AI 有一个可以自由撒落的目录。**

`modules/overlay/` 存在时，AI 遇到任何包覆盖需求就会本能地往里扔文件——不管这东西是否应该属于某个功能模块、是否应该由某个选项控制、是否应该内聚。

这不是 AI 的能力问题，是架构给错了自由度。消除散落目录、强制显式引入，是从结构上杜绝 AI 乱塞文件的唯一方式。

### 当前方案

**模块内聚到 `modules/system/units/`（或功能专属目录），host 文件只设选项值。**

```nix
# modules/system/units/nushell.nix — 模块定义逻辑
{ pkgs, lib, config, ... }:
{
  options.nushell.musl = {
    url    = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
    sha256 = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
  };

  config = let cfg = config.nushell.musl;
  in {
    nixpkgs.overlays = lib.optional (cfg.url != null && cfg.sha256 != null)
      (final: prev: { nushell = ...; });
  };
}
```

```nix
# hosts/workstations/nushell.nix — 只设选项值（和 vivaldi.nix 一个画风）
{ ... }: {
  nushell.musl.url    = "https://github.com/nushell/nushell/releases/download/...";
  nushell.musl.sha256 = "sha256-...";
}
```

- **没有指定选项** → overlay 关闭，用 nixpkgs 默认包
- **指定了选项** → overlay 开启，替换为自定义包

### 理由

1. **和 vivaldi/wanxiang 一致** — host 文件只写选项值，不碰逻辑
2. **模块内聚** — 逻辑在 `modules/system/units/` 中，由 `core.nix` 统一引入，所有节点默认加载模块定义
3. **选项驱动** — overlay 通过 `lib.optional (cfg != null)` 控制，未设置时零开销
4. **无散落目录** — AI 没有地方可以乱塞文件

### 后果

- `modules/overlay/` 目录已删除
- nushell 逻辑移至 `modules/system/units/nushell.nix`
- host 文件 `hosts/workstations/nushell.nix` 和 `vivaldi.nix`/`wanxiang.nix` 画风一致
