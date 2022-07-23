# unclechu’s bash config

## Usage

### Nix

#### Try it in a `nix-shell`

``` sh
nix-shell --run wenzels-bash
```

#### As a NixOS system dependency

``` nix
{ pkgs, ... }:
let
  wenzels-bash = pkgs.callPackage (pkgs.fetchFromGitHub {
    owner = "unclechu";
    repo = "bashrc";
    rev = "ffffffffffffffffffffffffffffffffffffffff"; # Git commit hash
    sha256 = "0000000000000000000000000000000000000000000000000000";
  }) {};
in
{
  environment.shells         = [ wenzels-bash.wenzels-bash ];
  environment.systemPackages = [ wenzels-bash.wenzels-bash ];
  users.users.john.shell     =   wenzels-bash.wenzels-bash  ;
}
```

##### Customizations

See the [misc/](misc) directory for setup scripts and aliases.
You could use `miscSetups` and `miscAliases` Nix attributes
to add them to the final configuration. An example:

``` nix
{ pkgs, lib, ... }:
let
  wenzels-bashrc-src = pkgs.fetchFromGitHub {
    owner = "unclechu";
    repo = "bashrc";
    rev = "ffffffffffffffffffffffffffffffffffffffff"; # Git commit hash
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };

  skim-shell-scripts =
    pkgs.callPackage
      "${wenzels-bashrc-src}/nix/integrations/skim-shell-scripts.nix"
      {};

  wenzels-bash = pkgs.callPackage wenzels-bashrc-src {
    miscSetups = dirEnvVarName: ''
      . "''$${dirEnvVarName}/misc/setups/fuzzy-finder.bash"
      . ${lib.escapeShellArg skim-shell-scripts}/completion.bash
      . ${lib.escapeShellArg skim-shell-scripts}/key-bindings.bash
    '';

    miscAliases = dirEnvVarName: ''
      . "''$${dirEnvVarName}/misc/aliases/skim.bash"
      . "''$${dirEnvVarName}/misc/aliases/fuzzy-finder.bash"
      . "''$${dirEnvVarName}/misc/aliases/tmux.bash"
      . "''$${dirEnvVarName}/misc/aliases/gpg.bash"
    '';
  };
in
{
  environment.shells         = [ wenzels-bash.wenzels-bash ];
  environment.systemPackages = [ wenzels-bash.wenzels-bash ];
  users.users.john.shell     =   wenzels-bash.wenzels-bash  ;
}
```

##### Use with my Neovim config

See https://github.com/unclechu/neovimrc

``` nix
{ pkgs, ... }:
let
  wenzels-neovim-src = pkgs.fetchFromGitHub {
    owner = "unclechu";
    repo = "neovimrc";
    rev = "ffffffffffffffffffffffffffffffffffffffff"; # Git commit hash
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };

  wenzels-neovim =
    pkgs.callPackage "${wenzels-neovim-src}/nix/apps/neovim.nix" {
      bashEnvFile = "${wenzels-bash.dir}/.bash_aliases";
    };

  wenzels-bash = pkgs.callPackage (pkgs.fetchFromGitHub {
    owner = "unclechu";
    repo = "bashrc";
    rev = "ffffffffffffffffffffffffffffffffffffffff"; # Git commit hash
    sha256 = "0000000000000000000000000000000000000000000000000000";
  }) {};
in
{ environment.systemPackages = [ wenzels-bash.wenzels-bash wenzels-neovim ]; }
```

##### Also the scripts

```sh
nix-shell -E 'with import <nixpkgs> {}; mkShell {buildInputs=[(callPackage nix/scripts/timer.nix {})];}' --run 'timer --help'
```

```sh
nix-shell -E 'with import <nixpkgs> {}; mkShell {buildInputs=[(callPackage nix/scripts/hsc2hs-pipe.nix {})];}' --run 'hsc2hs-pipe --help'
```

### Other GNU/Linux distributions

1. Clone this repo:

   ``` sh
   git clone --recursive https://github.com/unclechu/bashrc.git ~/.config/bashrc
   ```

2. Create `~/.bashrc` with this content:

   ``` sh
   if [[ -z $PS1 ]]; then return; fi
   . "$HOME/.config/bashrc/.bashrc"
   ```

3. Create `~/.bash_aliases` with this content:

   ``` sh
   . "$HOME/.config/bashrc/.bash_aliases"
   ```

#### Customizations

See the [misc/](misc) directory for setup scripts and aliases.
You could just import those scripts from `~/.bashrc` and `~/.bash_aliases`.
Here is an example:

- `~/.bashrc` file:

  ``` sh
  if [[ -z $PS1 ]]; then return; fi
  . "$HOME/.config/bashrc/.bashrc"

  . "$HOME/.config/bashrc/misc/setups/fuzzy-finder.bash"
  . /path/to/skim/shell/completion.bash
  . /path/to/skim/shell/key-bindings.bash
  ```

- `~/.bash_aliases` file:

  ``` sh
  . "$HOME/.config/bashrc/.bash_aliases"

  . "$HOME/.config/bashrc/misc/aliases/skim.bash"
  . "$HOME/.config/bashrc/misc/aliases/fuzzy-finder.bash"
  . "$HOME/.config/bashrc/misc/aliases/tmux.bash"
  . "$HOME/.config/bashrc/misc/aliases/gpg.bash"
  ```

## Known issues

### NixOS

In order to prevent loss of the command history this config uses different
history file (by default `~/.wenzels_bash_history` instead of
`~/.bash_history`).

If you want vanilla Bash sessions to use that history file don’t just override
`HISTFILE` or you can loose some of your commands history due to smaller history
size in Bash defaults. Instead evaluate
[history-settings.bash] in those Bash sessions. It will both override `HISTFILE`
and other command history settings such history size.

You can use [Home Manager] in order to include [history-settings.bash] in your
`~/.bashrc`. Like this in your `configuration.nix`:

```nix
{ pkgs, lib, ... }:
let
  home-manager = fetchTarball {
    # Branch: release-22.05
    # Date: 2022-06-25
    url = "https://github.com/nix-community/home-manager/archive/4a3d01fb53f52ac83194081272795aa4612c2381.tar.gz";
    sha256 = "0sdirpwqk61hnq8lvz4r2j60fxpcpwc8ffmicail2n4h6zifcn9n";
  };

  wenzels-bash = pkgs.callPackage (pkgs.fetchFromGitHub {
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
    . ${lib.escapeShellArg wenzels-bash.history-settings-file-path}
  '';
}
```

#### Entering `nix-shell`

When you enter `nix-shell` is uses its default Bash session. If you want to
enter some `nix-shell` and to keep your current `$SHELL` you can use `--command`
in order to inherit your `$SHELL` inside new session:

``` sh
nix-shell -p hello --command 'export SHELL='"'${SHELL//\'}'"' && "$SHELL"'
```

In fact this Bash config provides `nsh` alias in [.bash_aliases] that does it
for you. So just replace `nix-shell` with `nsh` and your `$SHELL` is inherited.

## Author

Viacheslav Lotsmanov

## License

[MIT] — For the code of this repository.
Some third-party dependencies may have different licenses.

[Home Manager]: https://github.com/rycee/home-manager

[MIT]: LICENSE
[history-settings.bash]: history-settings.bash
[.bash_aliases]: .bash_aliases
