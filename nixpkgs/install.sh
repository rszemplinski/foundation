# Where first arg is directory under machines (macos)
mkdir -p $HOME/.config
ln -s $(pwd) $HOME/.config/nixpkgs 
ln -s $(pwd)/machines/$1/home.nix $HOME/.config/nixpkgs/home.nix
ln -s $(pwd)/machines/$1/config.nix $HOME/.config/nixpkgs/config.nix