# dotfiles

Ubuntu / WSL 向けの fish・Neovim・Starship と、Windows Terminal・WezTerm の設定。
Linux 側は chezmoi、Windows 側は専用スクリプトで配置する。

## 管理するもの

- fish の設定、自作関数、コミットを固定した `fish_plugins`。
- Starship の `starship.toml`。
- WezTerm の表示・Copy Mode・クリップボード設定。Windows では既定の WSL を開く。
- 普段の WSL Ubuntu は Windows Terminal を使用し、Ubuntu プロファイルのフォントを管理する。
- Neovim は既存の [nvim_110](https://github.com/messier1296/nvim_110) を
  `.config/nvim` に clone する。既存の Git 履歴と `lazy-lock.json` を維持する。
  既にある場合は `git pull --ff-only` で取得し、最大 1 週間キャッシュする。
- Bash の nvm を fish から使う bass。固定したコミット、SHA256、MIT ライセンスを参照する。

`.chezmoiroot` で `home/` だけを配布する。README・テスト・スクリプトはホーム直下に配置されない。

## 新しい PC での復元

まず Git、curl、sha256sum、Python 3、fish と
[chezmoi](https://www.chezmoi.io/install/) をインストールする。
以下の URL は自分の dotfiles リポジトリに置き換える。

```sh
git clone https://github.com/YOUR_ACCOUNT/dotfiles.git "$HOME/dotfiles"
chezmoi --source "$HOME/dotfiles" diff
chezmoi --source "$HOME/dotfiles" apply
sh "$HOME/dotfiles/scripts/restore-fish-plugins.sh"
```

Neovim は初回起動時に lazy.nvim を取得する。`:Lazy restore` で lockfile の
バージョンを復元できる。Mason のツールは Nvim 側の設定に従って取得される。
各言語のランタイムやビルド依存関係は別途必要。

Windows 版 WezTerm と Moralerspace 以外のツール本体、Node.js、ログインシェルの変更は
このリポジトリでは自動化していない。
設定とツール本体を別々に管理し、対応する OS / CPU の公式配布物をインストールする。

| ツール | 現環境で確認したバージョン / 用途 |
| --- | --- |
| [fish](https://github.com/fish-shell/fish-shell/releases) | 4.9.3 |
| [Neovim](https://github.com/neovim/neovim/releases) | 0.12.0。AstroNvim の要件を満たす版が必要 |
| [Starship](https://github.com/starship/starship/releases) | 1.24.2 |
| [fzf](https://github.com/junegunn/fzf/releases) | 0.74.4。fifc の候補選択 |
| [zoxide](https://github.com/ajeetdsouza/zoxide/releases) | 0.10.0。`z` / `zi` で移動 |
| [Carapace](https://github.com/carapace-sh/carapace-bin/releases) | 1.8.0。補完候補の生成 |
| [procs](https://github.com/dalance/procs/releases) | 0.14.12。プロセスのプレビュー |
| [WezTerm](https://wezterm.org/install/windows.html) | Windows 版 20240203-110809-5046fc22。ターミナル表示・Copy Mode |
| fd / fd-find、bat / batcat、eza、ripgrep | パス候補・プレビュー・検索 |
| Python 3、Node.js / nvm、Rust / Cargo | bass、Nvim の一部機能、自作コマンド |
| Nerd Font | ターミナル側で設定。Starship / Nvim のアイコン表示 |

fzf の追加キーバインドは読み込まない。Tab は fifc が担当し、prompt は Starship を使う。

## 普段の WSL Ubuntu（Windows Terminal）

Moralerspace Neon HW を Windows のユーザーフォントに登録し、Windows Terminal の
Ubuntu プロファイルへ設定する。WSL 側のチェックアウトから実行:

```sh
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$HOME/dotfiles/scripts/install-moralerspace-windows.ps1")"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$HOME/dotfiles/scripts/deploy-windows-terminal.ps1")"
```

フォントは `%LOCALAPPDATA%\Microsoft\Windows\Fonts\moralerspace-neon-hw-v2.0.0` に配置し、
HKCU の Fonts に登録する。管理者権限は不要。
Windows Terminal は Ubuntu プロファイルの `font.face` だけを変更する。
サイズ・配色・背景・他のプロファイルは保持し、変更前の settings.json をバックアップする。
個人パスなどを含む settings.json 全体は Git に保存しない。

別名のディストリビューションには `-ProfileName Ubuntu-24.04` などを指定する。
設定ファイルの自動検出は通常版、Preview、非 Store 版の順。別のファイルには `-SettingsPath` を指定する。
PowerShell が解析できない JSON は変更せず終了する。手編集したコメント入り JSON などは
Windows Terminal の設定画面から一度保存するか、手動で `font.face` を設定する。
反映されない場合は、作業を保存してから Windows Terminal を起動し直す。
参照: [Windows Terminal のフォント設定](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance#font-face)。

## Copy Mode 用の Windows 版 WezTerm

Copy Mode は WezTerm 内で実行したコマンドの出力を対象にする。
Windows Terminal のスクロールバックを WezTerm から開くことはできない。

WSL 側のこのチェックアウトから Windows 本体と設定を配置する:

```sh
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$HOME/dotfiles/scripts/install-wezterm-windows.ps1")"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$HOME/dotfiles/scripts/install-moralerspace-windows.ps1")"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$HOME/dotfiles/scripts/deploy-wezterm-windows.ps1")"
```

公式の安定版 ZIP を SHA256 検証後、
`%LOCALAPPDATA%\Programs\WezTerm\20240203-110809-5046fc22` に展開する。
管理者権限は不要。Windows ユーザーの PATH とスタートメニューに登録する。
新しい PowerShell から `wezterm --version` で確認できる。
削除する場合は、このディレクトリ、ユーザー PATH の該当項目、
スタートメニューの `WezTerm.lnk` を削除する。
更新時はスクリプトの版と公式 SHA256 を一緒に更新する。
以前このスクリプトが登録した版の PATH は新しい版に置き換える。
既存ショートカットのリンク先を変更する場合はバックアップを保存する。

Windows 側に clone した場合は PowerShell から
`& .\scripts\install-wezterm-windows.ps1`、
`& .\scripts\install-moralerspace-windows.ps1`、
`& .\scripts\deploy-wezterm-windows.ps1` を実行してもよい。
配置先は `%USERPROFILE%\.config\wezterm\wezterm.lua`。
既存ファイルと内容が違う場合は、同じディレクトリにバックアップを保存する。
`-WhatIf` で配置予定を確認できる。

Windows 版は WSL 側の `~/.config/wezterm` を自動では読まない。
設定更新後もこのスクリプトを再実行する。Windows 全体の ExecutionPolicy は変更しない。
chezmoi では同じ設定を Linux の `~/.config/wezterm/wezterm.lua` に配置する。

WezTerm をスタートメニューから起動すると、Windows の既定 WSL ディストリビューションを
ホームディレクトリで開く。シェルはその WSL ユーザーのログインシェルに従う。
`wsl.exe --list --verbose` で既定を確認できる。
Zellij は fish から `zellij` で起動し、pane・tab・session を管理する。
WezTerm のタブバーは非表示にしている。

| 操作 | キー |
| --- | --- |
| Copy Mode に入る | `Ctrl+Shift+X` |
| Copy Mode 内の移動・選択 | `hjkl` / `v`。行選択は `Shift+V` |
| Copy Mode 内でコピーして終了 | `y` |
| Copy Mode を終了 | `Esc` |
| 選択範囲をコピー / 貼り付け | `Ctrl+Shift+C` / `Ctrl+Shift+V` |

フォントは **Moralerspace Neon HW v2.0.0** を利用する。
導入スクリプトは [公式 HW 版 ZIP](https://github.com/yuru7/moralerspace/releases/tag/v2.0.0)
を SHA256 検証し、Regular・Bold・Italic・BoldItalic の 4 ファイルだけを
`%USERPROFILE%\.config\wezterm\fonts\moralerspace-neon-hw-v2.0.0` に配置する。
同じスクリプトで Windows ユーザー用フォントにも登録する。再実行時は同じファイルを保持する。
フォント本体は Git に含めない。Nerd Font Symbols と絵文字は WezTerm 同梱の fallback を使う。
更新時はスクリプトの版・SHA256 と `wezterm.lua` の `font_dirs` を一緒に更新する。

Linux 側で WezTerm を使う場合も、同じ公式 ZIP の `MoralerspaceNeonHW-*.ttf` を
`~/.config/wezterm/fonts/moralerspace-neon-hw-v2.0.0` に配置する。
設定を反映した後、`wezterm ls-fonts` で Moralerspace Neon HW が選ばれているか確認できる。
開いている WezTerm では `Ctrl+Shift+R` で設定を再読み込みする。
参照: [設定ファイルの場所](https://wezterm.org/config/files.html)、
[Copy Mode](https://wezterm.org/copymode.html)、[フォント](https://wezterm.org/config/fonts.html)。

## PC 固有の設定

`examples/local.fish.example` を `~/.config/fish/local.fish` にコピーして編集する。
実際の `local.fish` は Git 管理外で、chezmoi も配布・上書きしない。

```fish
set -gx DOTFILES_DOWNLOADS "$HOME/Downloads"
set -gx DOTFILES_PRUN_SCRIPT "$HOME/projects/contest/scripts/run.sh"
```

WSL の Windows ユーザー名や個別のプロジェクトパスはこのファイルに置く。
`cdwd` はローカルの Downloads 設定を使用し、`prun` は設定した実行可能なスクリプトを呼ぶ。
未設定の `prun` は説明を表示して終了する。

通常の設定では `$HOME` を使う。存在しない任意ツールのパスは追加せず、
eza / bat がない PC では標準の ls / cat をそのまま利用できる。

## 設定の更新

このチェックアウトの `home/` を編集し、差分を確認して適用する。

```sh
chezmoi --source "$HOME/dotfiles" diff
chezmoi --source "$HOME/dotfiles" apply
git -C "$HOME/dotfiles" add home
git -C "$HOME/dotfiles" commit -m "Update configuration"
git -C "$HOME/dotfiles" push
```

別 PC では `git pull --ff-only` 後に同じ diff / apply を実行する。
fish プラグインは `fish_plugins` の `@コミット` を変更して適用し、復元スクリプトを再実行する。
Fisher 自体を更新する場合は、復元スクリプト中の SHA256 も新しいファイルに合わせて更新する。

Nvim の編集・commit・push は引き続き `~/.config/nvim` のリポジトリで行う。
作成時のこの PC の Nvim は `962fb62595b98c0668873a7b6bb601e48cc2c390`、
GitHub の main は 1 コミット先の `96b49627670f6510dc0c6fa46b3b456042c8408c` だった。
新規復元では GitHub の main を取得する。この PC の Nvim は変更していない。
Nvim の main は独立して更新されるため、上記コミットに固定して復元する設定ではない。

## 保存しないもの

履歴、`fish_variables`、キャッシュ、プラグイン本体、バイナリ、SSH 鍵、
API キー、認証情報、PC 固有の設定は含めない。
共有したい universal variable の設定は `config.fish` に明記する。
Fisher のファイルは Fisher、Nvim のファイルは既存 Nvim リポジトリが管理する。

## 検証

```sh
python3 -m unittest discover -s tests -v
git diff --check
```

実際の配置は一時ディレクトリを指定して試せる。既存のホーム設定は変更しない。

```sh
test_destination=$(mktemp -d)
chezmoi --source "$PWD" --destination "$test_destination" apply
XDG_CONFIG_HOME="$test_destination/.config" sh scripts/restore-fish-plugins.sh
```

参照: [chezmoi quick start](https://www.chezmoi.io/quick-start/)、
[external files](https://www.chezmoi.io/reference/special-files/chezmoiexternal-format/)、
[Fisher](https://github.com/jorgebucaran/fisher)。
