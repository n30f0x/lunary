{
  nixpkgs,
  hostname,
  ...
}: let
in rec {
  inherit hostname;
  # unfree packages that i explicitly use
  allowBroken = true;
  extraExtraSpecialArgs = {};
  extraSpecialArgs = {};
  additionalOverlays = [];
  packageSelections = {
        linuxKernel =
          original.linuxKernel
          // {
            kernels =
              original.linuxKernel.kernels
              // {
                inherit (unstable) linux_xanmod_latest;
              };
          };
      };
  unstableOverrides = {
    name = "unstable";
    additionalOverlays = let
      kernel = import ./hardware/kernels/lib/kernel-overlay.nix {
        inherit override hostname;
        baseKernelSuffix = "xanmod_latest";
        kernelConfig = ./hardware/kernels/6_2.nix;
      };
    in [
      # kernel
    ];
  };
}
