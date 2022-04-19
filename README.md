## A simple home-manager starter using flakes, building in github actions, and automatic updates to the repo

```
nix run .#hm -- --help
# test your configuration
nix run .#build # alias to nix run .#hm build
# switch to your configuration
nix run .#switch # alias to nix run .#hm switch
```

The main file is `flake.nix`. Update the `username`, `homeDirectory`, and `configuration` to suit your needs.

To receive pull request updates to this repo, you need to create a repository
secret named `PERSONAL_ACCESS_TOKEN` as described
[here](https://github.com/peter-evans/create-pull-request/blob/main/docs/concepts-guidelines.md#workarounds-to-trigger-further-workflow-runs)

To have those pull requests be automatically merged, you must satisfy the
conditions [here](https://github.com/peter-evans/enable-pull-request-automerge#conditions)