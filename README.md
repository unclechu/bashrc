# unclechu’s bash config

## Usage

### Nix

#### Try it in a `nix-shell`

```sh
nix-shell --run wenzels-bash
```

#### As a NixOS system dependency

```nix
let
  pkgs = import <nixpkgs> {};

  wenzels-bash = import (pkgs.fetchFromGitHub {
    owner = "unclechu";
    repo = "bashrc";
    rev = "ffffffffffffffffffffffffffffffffffffffff"; # Git commit hash
    sha256 = "0000000000000000000000000000000000000000000000000000";
  }) {};
in
{
  environment.shells         = [ wenzels-bash ];
  environment.systemPackages = [ wenzels-bash ];
  users.users.john.shell     =   wenzels-bash  ;
}
```

##### Use with my Neovim config

See https://github.com/unclechu/neovimrc

```nix
let
  pkgs = import <nixpkgs> {};

  wenzels-neovim-src = pkgs.fetchFromGitHub {
    owner = "unclechu";
    repo = "neovimrc";
    rev = "ffffffffffffffffffffffffffffffffffffffff"; # Git commit hash
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };

  wenzels-neovim = import "${wenzels-neovim-src}/nix/apps/neovim.nix" {
    bashEnvFile = "${wenzels-bash.dir}/.bash_aliases";
  };

  wenzels-bash = import (pkgs.fetchFromGitHub {
    owner = "unclechu";
    repo = "bashrc";
    rev = "ffffffffffffffffffffffffffffffffffffffff"; # Git commit hash
    sha256 = "0000000000000000000000000000000000000000000000000000";
  }) {};
in
{ environment.systemPackages = [ wenzels-bash wenzels-neovim ]; }
```

##### Also the scripts

```sh
nix-shell -E '(import <nixpkgs> {}).mkShell {buildInputs=[(import nix/scripts/timer.nix {})];}' --run 'timer --help'
```

```sh
nix-shell -E '(import <nixpkgs> {}).mkShell {buildInputs=[(import nix/scripts/hsc2hs-pipe.nix {})];}' --run 'hsc2hs-pipe --help'
```

### Other GNU/Linux distributions

1. Clone this repo:

   ```sh
   git clone --recursive https://github.com/unclechu/bashrc.git ~/.config/bashrc
   ```

2. Create `~/.bashrc` with this content:

   ```sh
   if [[ -z $PS1 ]]; then return; fi
   "$HOME/.config/bashrc/.bashrc"
   ```

3. Create `~/.bash_aliases` with this content:

   ```sh
   "$HOME/.config/bashrc/.bash_aliases"
   ```

## Known issues

### NixOS

If you happen to run a regular Bash (e.g. by just running `nix-shell`, it will
run default Bash) you may loose a lot of your `~/.bash_history` because of the
default Bash history settings.

In order to avoid this you may either run `nix-shell` with this `--command`
option (in order to inherit your `$SHELL`):

```sh
nix-shell -p bash --command 'export SHELL='"'${SHELL//\'}'"' && "$SHELL"'
```

Or you can use the [Home Manager] in order to include [history-settings.bash] in
your `.bashrc`. Like this in your `configuration.nix`:

```nix
let
  pkgs = import <nixpkgs> {};

  home-manager =
    let
      # ref "release-20.03", 5 July 2020
      commit = "318bc0754ed6370cfcae13183a7f13f7aa4bc73f";
    in
      fetchTarball {
        url = "https://github.com/rycee/home-manager/archive/${commit}.tar.gz";
        sha256 = "0hgn85yl7gixw1adjfa9nx8axmlpw5y1883lzg3zigknx6ff5hsr";
      };

  wenzels-bash = import (pkgs.fetchFromGitHub {
    owner = "unclechu";
    repo = "bashrc";
    rev = "ffffffffffffffffffffffffffffffffffffffff"; # Git commit hash
    sha256 = "0000000000000000000000000000000000000000000000000000";
  }) {};
in
{
  imports = [
    (import "${home-manager}/nixos")
  ];

  # … Other stuff in your "configuration.nix" …

  home-manager.users.john.home.file.".bashrc".text = ''
    . ${pkgs.lib.escapeShellArg wenzels-bash.history-settings-file-path}
  '';
}
```

## Author

Viacheslav Lotsmanov (2013–2020)

[Home Manager]: https://github.com/rycee/home-manager
[history-settings.bash]: history-settings.bash
