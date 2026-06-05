# Cookbook

NixOS 常用操作手册，涵盖日常维护、更新、清理以及运行外部二进制文件等实用技巧。

## flake.lock 说明

`flake.lock` 是 Nix Flakes 的**锁定文件**（类似 `package-lock.json`），记录每个输入依赖的精确 commit hash 和 narHash。

| 命令 | 作用 | 下载包？ | 验证配置？ |
|------|------|----------|------------|
| `nix flake lock` | 锁定输入版本到精确 commit | ❌ | ❌ |
| `nix flake update` | 更新所有输入到最新版本并重新锁定 | ❌ | ❌ |
| `nix flake check` | 检查 flake outputs 是否合法 | ✅ (仅检查用) | ✅ 基本语法 |
| `nixos-rebuild dry-build` | 模拟重建（不实际切换） | ✅ | ✅ 完整验证 |
| `nixos-rebuild switch` | 重建并切换到新配置 | ✅ | ✅ 完整验证 |

**重要：** `nix flake lock` 和 `nix flake update` **只解析依赖版本，不下载任何缓存包**，也**不验证你的 NixOS 配置是否正确**。

## 更新系统

### 标准更新流程

直接使用 `nh`：

```bash
nh os build/switch
```


## 切换世代与回滚

```bash
# 查看已安装的世代
nix-env --list-generations --profile /nix/var/nix/profiles/system

# 运行时回滚到上一世代
sudo nix-env --rollback --profile /nix/var/nix/profiles/system
```

## 清理垃圾

```bash
# 删除未被当前世代引用的包
sudo nix-collect-garbage -d

# 删除旧世代（保留最近 5 个）
sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system

# 优化 Nix Store
sudo nix optimise-store
```

## 搜索包

```bash
# 命令行搜索
nix search nixpkgs#<keyword>

# 或在线搜索：https://search.nixos.org/packages
```

## 安装常用工具（非 NixOS 环境）

在非 NixOS 系统上使用 Nix 时，可用 `nix profile` 永久安装工具到用户环境。

### 前置配置

确保已开启实验性功能（推荐永久配置，避免每次加 flag）：

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### 安装命令

```bash
# 安装 disko（磁盘分区管理）
nix profile add nixpkgs#disko

# 安装 nixos-install-tools（包含 nixos-install 等）
nix profile add nixpkgs#nixos-install-tools

# 查看已安装的工具
nix profile list

# 更新工具
nix profile upgrade nixpkgs#disko

# 卸载工具
nix profile remove nixpkgs#disko
```

> **注意：**
> - `nix profile add` 会将工具安装到 `~/.nix-profile`，永久可用。
> - 旧版命令 `install` 已被废弃，请使用 `add`。
> - 这与 `nix shell` 不同，后者仅创建临时环境，退出后工具不可用。

## Home Manager 更新

Home Manager 随 `nixos-rebuild` 自动更新。如需单独应用：

```bash
home-manager switch --flake .#master
```

## 运行外部二进制文件

NixOS 的动态链接器路径特殊，直接运行从外部下载或编译的二进制文件可能失败。以下是三种解决方案：

### 使用 `nix-ld`（推荐）

最通用的方法，允许动态链接的二进制文件使用系统的库。

```nix
# 在 NixOS 配置模块中添加：
programs.nix-ld.enable = true;
programs.nix-ld.libraries = with pkgs; [
  stdenv.cc.cc
  zlib
  openssl
  # 根据需要添加其他库
];
```

### 直接运行静态二进制文件

完全静态编译（使用 musl libc）的二进制文件不依赖系统库，可以直接运行。

```bash
chmod +x ./static-binary
./static-binary

# 验证是否为静态链接：
file ./binary  # 输出应包含 "statically linked"
ldd ./binary   # 输出应显示 "not a dynamic executable"
```

### 使用 `patchelf`

如果必须运行特定的动态二进制文件且不想全局配置 nix-ld，可以使用 `patchelf` 修改其解释器。

```bash
nix-shell -p patchelf
patchelf --set-interpreter "$(cat /nix/var/nix/profiles/system/sw/lib/ld-linux-x86-64.so.2)" ./binary
```
