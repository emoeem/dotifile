# --------------------------------------------
# 1. 核心提示符与历史工具（保持原有）
# --------------------------------------------

if type -q starship
    starship init fish | source
end

if type -q atuin
    atuin init fish | source
end

if type -q zoxide
    zoxide init fish | source
end


# --------------------------------------------
# 2. 基础环境变量
# --------------------------------------------

# 默认编辑器（sudoedit、git、kubectl 等工具会读取）
set -gx EDITOR nvim
set -gx VISUAL $EDITOR

# less 优化：保留颜色、退出不清屏、内容少于一屏时自动退出、搜索忽略大小写
set -gx LESS "--RAW-CONTROL-CHARS --no-init --quit-if-one-screen --ignore-case"

# bat 美化配置
set -gx BAT_THEME "Dracula"
set -gx BAT_STYLE "numbers,changes,header"

# atuin 历史过滤：按当前目录过滤，同目录下的命令优先
set -gx ATUIN_FILTER_MODE "directory"


# --------------------------------------------
# 3. fzf 模糊查找集成
# --------------------------------------------
# 快捷键说明：
#   Ctrl+T = 当前目录下模糊搜索文件，选中后插入路径
#   Ctrl+R = 搜索历史命令（注：若已安装 Atuin，Atuin 会覆盖此键，体验更优）
#   Alt+C  = 模糊搜索目录，选中后直接 cd 进入

if type -q fzf
    # 检测 fzf 版本，新版用 --fish，旧版回退
    if fzf --fish >/dev/null 2>&1
        fzf --fish | source
    else if test -f /usr/share/fish/vendor_functions.d/fzf_key_bindings.fish
        fzf_key_bindings
    end

    # 用 fd 替代 find（更快、避免 node_modules 等重目录）
    if type -q fd
        set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude .cache --exclude target --exclude build --exclude .local --exclude .npm --exclude .cargo --exclude __pycache__ --exclude .mozilla --exclude .gradle"
        set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
        set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --max-depth 8 --exclude .git --exclude node_modules --exclude .cache --exclude target"
    end

    # 预览配置：右侧窗口实时预览文件/目录内容（限制预览行数减轻负载）
    set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --line-range :100 {}' --preview-window right:60%:wrap"
    set -gx FZF_ALT_C_OPTS "--preview 'eza -T --level=2 --color=always {} | head -200' --preview-window right:60%:wrap"

    # 全局外观：80% 高度、输入框置底、带边框、循环选择、预览区上下翻动
    set -gx FZF_DEFAULT_OPTS "--height 80% --layout=reverse --border --inline-info --cycle --bind alt-k:preview-up,alt-j:preview-down"
end


# --------------------------------------------
# 4. 智能工具钩子
# --------------------------------------------

# direnv：进入目录自动加载 .envrc，离开自动卸载
# 用法：在项目根目录执行 `echo "export KEY=val" > .envrc && direnv allow`
if type -q direnv
    direnv hook fish | source
end

# pay-respects：命令纠错（上条命令报错后按 `f` 自动修正并执行）
# 比 thefuck 快 10 倍，Rust 编写零依赖
# 如需改为 `fuck` 触发，取消下行注释：set -gx PAY_RESPECTS_ALIAS "fuck"
if type -q pay-respects
    pay-respects fish | source
end


# --------------------------------------------
# 5. 交互式缩写（abbr）
# Fish 独有特性：输入时自动展开，历史记录保存完整命令
# 与 alias 共存：alias 保证脚本兼容，abbr 优化交互体验
# --------------------------------------------

# Git 工作流
abbr -a -- gs  'git status'
abbr -a -- ga  'git add'
abbr -a -- gaa 'git add --all'
abbr -a -- gc  'git commit'
abbr -a -- gcm 'git commit -m'
abbr -a -- gca 'git commit --amend'
abbr -a -- gp  'git push'
abbr -a -- gpf 'git push --force-with-lease'
abbr -a -- gpl 'git pull'
abbr -a -- gco 'git checkout'
abbr -a -- gcb 'git checkout -b'
abbr -a -- gb  'git branch'
abbr -a -- gd  'git diff'
abbr -a -- gds 'git diff --staged'
abbr -a -- gl  'git log --oneline --graph -15'
abbr -a -- grh 'git reset --hard'
abbr -a -- grs 'git restore --staged'

# 目录导航
abbr -a -- ..   'cd ..'
abbr -a -- ...  'cd ../..'
abbr -a -- .... 'cd ../../..'
abbr -a -- ..... 'cd ../../../..'

# Pacman / 系统管理
abbr -a -- update  'sudo pacman -Syu'
abbr -a -- cleanup 'sudo pacman -Rns (pacman -Qtdq)'
abbr -a -- mirror  'sudo cachyos-rate-mirrors'
abbr -a -- jctl    'journalctl -p 3 -xb'
abbr -a -- fixpacman 'sudo rm /var/lib/pacman/db.lck'
abbr -a -- grubup  'sudo grub-mkconfig -o /boot/grub/grub.cfg'

# 压缩解压
abbr -a -- tarnow 'tar -acf'
abbr -a -- untar  'tar -zxvf'

# 其他
abbr -a -- please 'sudo'
abbr -a -- hw     'hwinfo --short'
abbr -a -- mk 'mkdir -p'


# --------------------------------------------
# 6. 自定义函数
# --------------------------------------------

# yazi 文件管理器：退出后自动切换到当前所在目录
# 依赖：sudo pacman -S yazi
function yy
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end


# --------------------------------------------
# 7. PATH 配置
# --------------------------------------------

# pnpm
if test -d $HOME/.local/share/pnpm/bin
    if not contains -- $HOME/.local/share/pnpm/bin $PATH
        set -p PATH $HOME/.local/share/pnpm/bin
    end
end

# 用户本地 bin（部分发行版默认未添加）
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end


# --------------------------------------------
# 8. 加载 CachyOS Fish 预设
# 包含：done 通知、man 美化、alias、历史函数等
# 放在最后，确保本文件的配置优先加载
# --------------------------------------------

if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
    # 覆盖 CachyOS 预设中的 fish_greeting，禁止自动运行 fastfetch
    function fish_greeting; end
end


# --------------------------------------------
# 9. 可选增强（按需取消注释）
# --------------------------------------------

# delta 让 git diff 更美观，运行一次即可持久生效：
# git config --global core.pager delta
# git config --global interactive.diffFilter "delta --color-only"
# git config --global delta.line-numbers true
# git config --global delta.side-by-side true
# git config --global delta.syntax-theme TwoDark
#

# ============================================
# 无感集成：常用命令自动调用 fzf
# ============================================

# --- Ctrl+R: Atuin + fzf 历史搜索 ---
function _atuin_fzf_search
    set result (atuin history list --cmd-only 2>/dev/null | awk '!seen[$0]++' | \
        fzf --height 100% \
            --preview 'echo {}' \
            --preview-window 'right:60%:wrap' \
            --bind 'alt-k:preview-up,alt-j:preview-down' \
            --prompt "History> ")
    if test -n "$result"
        commandline -r -- $result
        commandline -f execute
    end
end
if type -q atuin; and type -q fzf
    bind \cr _atuin_fzf_search
end

# 禁掉 fish 自带的 Alt+r（history-token-search-backward），
# 避免和 Ctrl+r（fzf+atuin 历史搜索）功能重复
bind -e \er 2>/dev/null
bind -M insert -e \er 2>/dev/null

# --- tldr：man 的现代化替代 ---
# 优先用 tldr 查速查表，找不到再回退到传统 man
# 安装：sudo pacman -S tldr
if type -q tldr
    function man -d "优先 tldr，fallback 到系统 man"
        if count $argv >/dev/null
            # 只有一个参数时（如 man tar），先尝试 tldr
            if test (count $argv) -eq 1
                if tldr $argv[1] >/dev/null 2>&1
                    tldr $argv[1]
                    return 0
                end
            end
            # 多参数（如 man 3 printf）或 tldr 找不到时，用系统 man
            command man $argv
        else
            command man
        end
    end
end

# --- xh：现代化 HTTP 客户端 ---
# 安装：sudo pacman -S xh
# 用法：xh get http://api.example.com（比 curl 直观得多）
if type -q xh
    abbr -a -- req 'xh'
    abbr -a -- get 'xh GET'
    abbr -a -- post 'xh POST'
    abbr -a -- put 'xh PUT'
    abbr -a -- del 'xh DELETE'
    abbr -a -- patch 'xh PATCH'
end

# --- ouch：万能压缩解压 ---
# 安装：paru -S ouch
# 用法：ouch compress file1 dir1 archive.zip（自动识别格式）
#      ouch decompress archive.zip（自动识别格式）
#      ouch list archive.zip（预览内容）
if type -q ouch
    abbr -a -- compress 'ouch compress'
    abbr -a -- extract 'ouch decompress'
    abbr -a -- compress-list 'ouch list'
end


# --- procs：现代化进程查看 ---
# 安装：sudo pacman -S procs
# 用法：procs --tree（树状视图）/ procs --watch（实时刷新）
if type -q procs
    abbr -a -- pst 'procs --tree'
    abbr -a -- psw 'procs --watch'
end

# --- tokei：代码统计 ---
# 安装：sudo pacman -S tokei
# 用法：tokei（在项目根目录执行，按语言分类统计代码行数）
if type -q tokei
    abbr -a -- loc 'tokei'
end

# --- onefetch：Git 仓库信息展示 ---
# 安装：sudo pacman -S onefetch
# 用法：onefetch（在项目根目录执行，显示仓库语言、提交数、作者等）
if type -q onefetch
    abbr -a -- repo 'onefetch'
end
