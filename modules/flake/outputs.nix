{ inputs, ... }:
{
  # Let another flake reuse this home configuration without inheriting the
  # personal hosts. Include the external LazyVim module so consumers do not
  # need to know about the lazyvim special argument.
  flake.homeModules.default = {
    imports = [
      inputs.lazyvim.homeManagerModules.default
      (inputs.import-tree ../home)
    ];
  };
}
