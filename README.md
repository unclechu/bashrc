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
  wenzels-bash = fetchGit {
    url = "https://github.com/unclechu/bashrc.git";
    rev = "ffffffffffffffffffffffffffffffffffffffff"; # Git commit hash
    ref = "master";
  };
in
{
  environment.shells         = [ wenzels-bash ];
  environment.systemPackages = [ wenzels-bash ];
  users.users.john.shell     =   wenzels-bash  ;
}
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

## Author

Viacheslav Lotsmanov (2013–2020)
