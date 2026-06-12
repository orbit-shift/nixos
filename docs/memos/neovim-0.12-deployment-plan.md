# NixOS 下 Neovim 0.12 "软硬分离"标准配置模板

> **状态**: 初始框架（待补充）
> **创建时间**: 2026-06-12
> **目标**: 实现 Neovim 0.12 + Neovide 的终极部署方案，彻底告别 Mason 和配置污染

---

## 一、核心设计哲学

### 1.1 软硬分离原则

**硬件层（NixOS 管理）**：
- 安装 Neovim 0.12 纯净核心
- 注入所有 LSP 工具链（rust-analyzer、pyright、gopls、nil）
- 提供基础动态工具（git、ripgrep、fd）
- 安装 Neovide GUI 驱动
- **绝不干涉配置**

**软件层（本地管理）**：
- 独立的 `~/.config/nvim/` 目录
- 纯 Lua 声明式配置
- 使用 Neovim 0.12 原生包管理器（`vim.pack`）
- 消费 NixOS 注入的全局工具，不重复安装

### 1.2 反模式清单

**拒绝以下做法**：
- ❌ 使用 Mason 安装 LSP（动态链接问题、版本冲突）
- ❌ 在 NixOS 配置中硬编码 Neovim 插件配置
- ❌ 使用 nvim-cmp 等第三方补全插件（0.12 已内置原生补全）
- ❌ 状态栏插件（laststatus=0，追求极致信息密度）
- ❌ 花哨的 GUI 主题（纯文本矩阵，拒绝视觉污染）

---

## 二、第一步：NixOS 硬件底座配置

### 2.1 Home-Manager 配置模板

```nix
# home.nix 或 configuration.nix
{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;  # 0.12 纯净核心
    defaultEditor = true;

    # 极简声明：让 Home-Manager 将你独立的本地配置目录以"符号链接"形式挂载
    # 这样既能纳入 Nix 的大一统管理，又保持了本地动态修改的自由度
    # 假设你的纯 Lua 配置托管在系统配置目录的 ./dotfiles/nvim
    # xdg.configFile."nvim".source = ./dotfiles/nvim;
  };

  # ⚙️ 核心审计工具链：由 NixOS 100% 保证纯净性，彻底告别 Mason！
  environment.systemPackages = [
    # 1. Neovide 顶级 GUI 驱动
    pkgs.neovide

    # 2. 你的核心审计语言 LSP / 工具链 (根据你的审计对象按需添加)
    pkgs.nil                    # Nix LSP
    pkgs.gopls                  # Go LSP
    pkgs.nodePackages.pyright   # Python LSP
    pkgs.rust-analyzer          # Rust LSP

    # 3. 基础动态工具
    pkgs.git
    pkgs.ripgrep                # 用于 Neovim 内部大范围代码检索
    pkgs.fd                     # 极其快速的文件发现，Neo-tree 依赖
  ];
}
```

### 2.2 配置要点说明

**为什么用 `pkgs.neovim-unwrapped`？**
- 纯净核心，不带任何 HM 包装的插件配置
- 避免 HM 的 `extraConfig` 污染你的独立配置

**为什么不用 Mason？**
- Mason 在 NixOS 下会遭遇动态链接地狱（glibc 版本不匹配）
- NixOS 已经全局注入了正确版本的 LSP，Mason 纯属多余
- 减少一层抽象，降低故障点

**符号链接策略**：
- 通过 `xdg.configFile."nvim".source` 将本地配置目录链接到 `~/.config/nvim`
- 保持 Nix 的大一统管理，同时允许本地动态修改

---

## 三、第二步：独立的 `~/.config/nvim/` 纯 Lua 配置

### 3.1 init.lua 完整模板

```lua
-- ~/.config/nvim/init.lua
-- Neovim 0.12 "软硬分离"标准配置

-- ═══════════════════════════════════════════════════════════
-- 1. 声明式配置 0.12 原生包管理器
-- ═══════════════════════════════════════════════════════════
vim.pack.setup({
  lockfile = vim.fn.stdpath("config") .. "/nvim-lock.json"
})

-- ═══════════════════════════════════════════════════════════
-- 2. 批量注册插件（极简主义，只装必要的）
-- ═══════════════════════════════════════════════════════════
local plugins = {
  "nvim-neo-tree/neo-tree.nvim",      -- 目录树（纯文本风格）
  "nvim-lua/plenary.nvim",            -- neo-tree 依赖
  "tpope/vim-fugitive",               -- 纯文本流 Git 审计
  "neovim/nvim-lspconfig",            -- 仅仅用来连接 Nix 注入的 LSP
}

for _, plugin in ipairs(plugins) do
  vim.pack.add(plugin)
end

-- ═══════════════════════════════════════════════════════════
-- 3. 激活 0.12 原生极简特性
-- ═══════════════════════════════════════════════════════════
vim.opt.autocomplete = true           -- 原生纯 C 异步补全，彻底丢弃 nvim-cmp
vim.opt.laststatus = 0                -- 彻底干掉状态栏，极致信息密度
vim.opt.number = true                 -- 行号（可选）
vim.opt.relativenumber = true         -- 相对行号（可选）

-- ═══════════════════════════════════════════════════════════
-- 4. 纯文本消费 NixOS 注入的全局 LSP
-- ═══════════════════════════════════════════════════════════
local lspconfig = require("lspconfig")

-- 直接启动，它们会自动寻找到 Nix 注入到 $PATH 中的二进制文件
-- 不需要 Mason，永远不会崩溃
lspconfig.rust_analyzer.setup({})
lspconfig.pyright.setup({})
lspconfig.gopls.setup({})
lspconfig.nil_ls.setup({})            -- Nix LSP

-- ═══════════════════════════════════════════════════════════
-- 5. 载入 Neo-tree 配置（纯文本风格）
-- ═══════════════════════════════════════════════════════════
-- require("config.neotree")

-- ═══════════════════════════════════════════════════════════
-- 6. 快捷键映射（极简主义）
-- ═══════════════════════════════════════════════════════════
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle Neo-tree" })
vim.keymap.set("n", "<leader>g", ":Git<CR>", { desc = "Open Fugitive" })
```

### 3.2 配置要点说明

**为什么用 `vim.pack`？**
- Neovim 0.12 原生包管理器，纯 C 实现，性能碾压 Lua 插件
- 声明式配置，lockfile 保证可重现性
- 不需要 Packer、Lazy 等第三方插件管理器

**为什么不用 nvim-cmp？**
- 0.12 已内置原生纯 C 异步补全（`vim.opt.autocomplete = true`）
- 第三方补全插件是历史包袱，性能不如原生

**为什么 `laststatus = 0`？**
- 彻底干掉状态栏，追求极致信息密度
- 所有信息都在文本矩阵中，没有视觉污染

**LSP 配置为什么这么简单？**
- NixOS 已经全局注入了正确版本的 LSP 二进制
- `lspconfig` 只是建立连接，不需要额外安装
- 自动从 `$PATH` 中找到工具，永远不会崩溃

---

## 四、待补充内容清单

### 4.1 NixOS 配置细节

- [ ] 确认 `pkgs.neovim-unwrapped` 是否已包含 0.12 版本
- [ ] 测试 `xdg.configFile."nvim".source` 的符号链接策略
- [ ] 补充 K8s 节点（无 GUI）的精简配置模板
- [ ] 补充桌面节点（有 Neovide）的完整配置模板

### 4.2 Neovim 配置细节

- [ ] Neo-tree 纯文本风格配置（拒绝圆角、图标）
- [ ] Fugitive 快捷键映射（Git 审计工作流）
- [ ] 内置 `:terminal` 分屏配置（右侧常驻 Shell）
- [ ] LSP 快捷键映射（跳转、重命名、诊断）
- [ ] Treesitter 配置（增量选择、语法高亮）

### 4.3 审计工作流

- [ ] 代码审计标准流程（打开文件 → LSP 诊断 → Git blame → 终端运行）
- [ ] 多文件对比工作流（分屏 + Fugitive diff）
- [ ] 大项目导航工作流（Neo-tree + ripgrep + fd）

### 4.4 性能优化

- [ ] 启动时间优化（延迟加载策略）
- [ ] 内存占用优化（ Treesitter 增量解析）
- [ ] Neovide 渲染优化（亚像素、动画参数）

---

## 五、实施步骤

### 阶段 1：基础设施搭建（1-2 小时）

1. 在 `~/Configuration/nixos/modules/desktop/units/neovim.nix` 中创建硬件底座配置
2. 在 K8s 节点配置中创建精简版本（无 Neovide）
3. 运行 `nh os switch` 验证安装

### 阶段 2：Lua 配置迁移（2-3 小时）

1. 备份现有 `~/.config/nvim/` 配置
2. 创建新的 `init.lua`，使用上述模板
3. 逐步迁移必要的插件配置（Neo-tree、Fugitive）
4. 测试 LSP 连接（rust-analyzer、pyright、gopls）

### 阶段 3：工作流验证（1-2 小时）

1. 在一个真实项目中测试审计工作流
2. 验证 Neo-tree 纯文本风格
3. 验证 Fugitive Git 审计
4. 验证内置终端分屏

### 阶段 4：性能调优（可选）

1. 测量启动时间（目标 < 100ms）
2. 测量内存占用（目标 < 200MB）
3. 调整 Neovide 渲染参数

---

## 六、注意事项

### 6.1 NixOS 陷阱

**陷阱 1：`neovim-unwrapped` vs `neovim`**
- `neovim` 是 HM 包装版本，可能注入额外配置
- `neovim-unwrapped` 是纯净核心，推荐使用

**陷阱 2：符号链接冲突**
- 如果 `~/.config/nvim/` 已存在，`xdg.configFile` 会报错
- 解决方案：先备份现有配置，或删除后让 NixOS 重建

**陷阱 3：LSP 路径问题**
- NixOS 注入的 LSP 在 `/run/current-system/sw/bin/`
- 确保 `$PATH` 包含该路径（NixOS 默认已包含）

### 6.2 Neovim 0.12 陷阱

**陷阱 1：`vim.pack` API 变化**
- 0.12 的 `vim.pack` 是实验性 API，可能有变化
- 建议锁定 nixpkgs 版本，避免升级导致配置失效

**陷阱 2：原生补全功能限制**
- `vim.opt.autocomplete` 功能可能不如 nvim-cmp 完善
- 如果遇到问题，可以临时回退到 nvim-cmp

**陷阱 3：插件兼容性**
- 部分老插件可能不兼容 0.12 的新 API
- 优先使用维护活跃的插件（Neo-tree、Fugitive）

---

## 七、参考资源

- [Neovim 0.12 Release Notes](https://github.com/neovim/neovim/releases/tag/v0.12.0)
- [Neovide 官方文档](https://neovide.dev/)
- [vim.pack 官方文档](https://neovim.io/doc/user/packages.html)
- [NixOS Neovim 模块](https://nixos.org/manual/nixos/stable/#opt-programs.neovim.enable)

---

## 八、版本历史

- **2026-06-12**: 初始框架创建（待补充）
