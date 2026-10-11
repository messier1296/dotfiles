# dotfiles

Ubuntu / WSL 向けの fish・Neovim・Starship 設定。chezmoi で配置する。

## 管理するもの

- fish の設定、自作関数、コミットを固定した `fish_plugins`。
- Starship の `starship.toml`。
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

ツール本体、Node.js、フォント、ログインシェルの変更はこのリポジトリでは自動化していない。
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
| fd / fd-find、bat / batcat、eza、ripgrep | パス候補・プレビュー・検索 |
| Python 3、Node.js / nvm、Rust / Cargo | bass、Nvim の一部機能、自作コマンド |
| Nerd Font | ターミナル側で設定。Starship / Nvim のアイコン表示 |

fzf の追加キーバインドは読み込まない。Tab は fifc が担当し、prompt は Starship を使う。

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
