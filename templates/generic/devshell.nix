{ pkgs, recursiveMerge, agenix, ... }:
# { pkgs, runPkg, ... }:
  let 

    # cursed scripts
    # runPkg = pkgs: pkg: "${pkgs.${pkg}}/bin/${pkg}";
    # run = pkg: runPkg pkgs pkg;
    mapVar = map(x: x.name);  
    
    tui = with pkgs; {
      packages = [ gum ];
      scripts = [ ];
      envvars = {
        nix = {
          USERNAME = "root";
          HOST = "localhost";
          PROVISION_METHOD = "eval ssh $USERNAME@$HOST";
          REMOTE_STORE = "eval ssh-ng://$USERNAME@$HOST";
          # NIXOSCONFIG = "core";
          # HMCONFIG = "";
          NIXCONF = " --extra-experimental-features nix-command --extra-experimental-features flakes";
          TOPLEVEL = ".\#nixosConfigurations.$*.config.system.build.toplevel";
        };
        gum = {
          GUM_CHOOSE_ORDERED = true;
          GUM_CHOOSE_ITEM_FOREGROUND = "";
          GUM_CHOOSE_SELECTED_FOREGROUND = "212";
          GUM_CHOOSE_HEADER_FOREGROUND = "240";
          # GUM_CONFIRM_TIMEOUT = "5s"; 
          # GUM_CONFIRM_DEFAULT = 
          # GUM_CONFIRM_PROMPT_FOREGROUND = 212;
          GUM_INPUT_PLACEHOLDER = "";
          # BORDER = "normal";
          # MARGIN = "1";
          # PADDING = "1 2";
          FOREGROUND = "212";
        };
      };
      hook = {
        shellHook = ''
          clear
          trap "clear" EXIT
          gum style --border="normal" --padding "1 2" --margin 1 --align="center" "Hello!
          Welcome to $(gum style --border="none" --padding 1 --background 140 $DESCRIPTION) environment."
          if [ "$TUI_DEPLOY" == "1" ];
            then
              gum confirm --negative="local" --affirmative="remote" --default=0 "Select provision method:"
              # PROVISION_METHOD=$(gum input --placeholder="ssh root@localhost")
              # PROVISION_METHOD=$(gum choose "$PROVISION_LOCAL" "$PROVISION_REMOTE" )
              if [[ -n $PROVISION_METHOD ]];
                then
                  USERNAME=$(gum input --prompt="username > " --placeholder="root" --value="root")
                  HOST=$(gum input --prompt="hostname > " --placeholder="localhost" --value="localhost")
              fi
          fi
          if [[ -n $TUI_HOOK ]];
            then
              gum style "Press C-c to enter shell!"
              EXEC_NEXT=$(gum choose $TUI_HOOK --select-if-one)
              if [ -z $EXEC_NEXT ];
                then
                  gum style "Nothing was picked or environment is not available. Welcome to shell!" 
                  TUI_EXIT="0"
                else 
                  gum confirm --negative="Nay" --affirmative="YOLO!" --default=0 $EXEC_NEXT && gum spin "$($EXEC_NEXT)" || gum style Abort!
                  gum style --foreground 260 Done! 
                  gum spin "sleep 3"
              fi
            else
              gum style "Environment is not available. Welcome to shell!"
          fi
          if [ "$TUI_EXIT" == "1" ];
            then
              exit
          fi
        '';
      };
        main = with tui; ({packages = packages ++ scripts;}  // envvars.gum // envvars.nix // hook);
    };


    core = with pkgs; {  
      packages = [git openssh rsync ]; 
      scripts = [
      (writeShellScriptBin "core-send-secrets" ''
        set -e
        shopt -s dotglob
        $PROVISION_METHOD echo 'nothing'
      '')
       # rsync -avP secrets/'${1}'/. root@"$host":/secrets
      (writeShellScriptBin "core-remote-build" ''
      	nix copy --derivation $TOPLEVEL -Lv --to $REMOTE_STORE --option substitute true --offline --eval-cache
      	nix build $REMOTE_STORE -Lv --store $REMOTE_STORE --print-out-paths --offline > .system-link-$*
      '')
      (writeShellScriptBin "core-system-gc" ''
      	$PROVISION_METHOD nix-collect-garbage --delete-old
        $PROVISION_METHOD nix-store --optimize
        $PROVISION_METHOD nix store gc
      '')
      (writeShellScriptBin "core-home-gc" ''
      	$PROVISION_METHOD home-manager expire-generations -30days
      '')
      (writeShellScriptBin "core-doctor" ''
        $PROVISION_METHOD nix-store --verify --check-contents --repair
      '')
      ] ++ lib.optionals stdenv.isLinux [
        # exclusive linux scripts
      (writeShellScriptBin "core-host-nodemeta-linux" ''
      	core-remote-build 
      	core-send-secrets
        $PROVISION_METHOD nix build --profile /nix/var/nix/profiles/system `cat .system-link-$(*)`
      	# $(warn Switching over to `cat.system-link-$(*)`)
        $PROVISION_METHOD /nix/var/nix/profiles/system/bin/switch-to-configuration switch
      	# nixos-rebuild switch -v --flake .'#'$* --use-substitutes --target-host root@`./scripts/hostname.sh $*`
      '')
      ] ++ lib.optionals stdenv.isDarwin [
        # exclusive darwin scripts
      (writeShellScriptBin "core-host-nodemeta-darwin" ''
      	core-remote-build 
      	core-send-secrets
      	$PROVISION_METHOD nix build --profile /nix/var/nix/profiles/system `cat .system-link-$(*)`
      	# $(warn Switching over to `cat.system-link-$(*)`)
      	$PROVISION_METHOD /nix/var/nix/profiles/system/bin/switch-to-configuration switch
      	# darwin-rebuild switch -v --flake .'#'$* --use-substitutes --target-host root@`./scripts/hostname.sh $*`
      '')
      (writeShellScriptBin "core-flake-enable-darwin" ''
        $PROVISION_METHOD echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
      '')
      ];
      envvars = {
          DESCRIPTION = "Main shell";
          TUI_HOOK = mapVar core.scripts;
          TUI_DEPLOY = 1;
          TUI_EXIT = 1;
        }; 
      main = with core; ({packages = packages ++ scripts;} // envvars);
    };


    develop = with pkgs; {
      packages = [ 
        git gnupg zip unzip 
        helix niv nixpkgs-fmt nix-index superfile
        git-crypt git-lfs git-remote-gcrypt gpg-tui bitwarden-cli  
      ] ++ lib.optionals stdenv.isLinux [ 
        busybox 
      ];
      scripts = [];
      envvars = {
       DESCRIPTION = "prototyping";
       TUI_HOOK = mapVar develop.scripts;
      };
      main = with develop; ({packages = packages ++ scripts ++ superfile;} // envvars);
    };


 in  {

    core = pkgs.mkShellNoCC
    ( recursiveMerge [ core.main tui.main ] );

    develop = pkgs.mkShell
    ( recursiveMerge [ develop.main tui.main ] );
 }
