.PHONY: hostname/%

hostname/%:
	echo `./scripts/hostname.sh $*`

toplevel = ".\#nixosConfigurations.$*.config.system.build.toplevel"
host = $(shell ./scripts/hostname.sh $(*))
remote_store = ssh-ng://root@$(host)

.PHONY: remote-build/%
remote-build/%:
	nix copy --derivation $(toplevel) -Lv --to $(remote_store) --option substitute true --offline --eval-cache
	nix build $(toplevel) -Lv --store $(remote_store) --print-out-paths --offline > .system-link-$*

.PHONY: remote-switch/%
remote-switch/%: 
	$(MAKE) remote-build/$* 
	$(MAKE) send-secrets/$*
	ssh root@$(host) nix build --profile /nix/var/nix/profiles/system `cat .system-link-$(*)`
	$(warn Switching over to `cat.system-link-$(*)`)
	ssh root@$(host) /nix/var/nix/profiles/system/bin/switch-to-configuration switch
	# nixos-rebuild switch -v --flake .'#'$* --use-substitutes --target-host root@`./scripts/hostname.sh $*`
	
.PHONY: send-secrets/%
send-secrets/%:
	echo 'nothing'
	# YOLO=YES scripts/send-secrets.sh $*

.PHONY: system-gc/%
system-gc/%:
	ssh root@$(host) nix-collect-garbage
	nix-collect-garbage

.PHONY: home-gc/%
home-gc/%:
	ssh root@$(host) home-manager expire-generations -30days

.PHONY: flake-enable/%
flake-enable/%:
	ssh root@$(host) echo "nix.settings.experimental-features = [ "nix-command" "flakes" ];" >> /etc/nixos/configuration.nix

.PHONY: doctor/%
doctor/%:
	nix-store --verify --check-contents --repair

.PHONY: sboot-make/%
sboot-make/%:
	ssh root@$(host) sbctl create-keys && sbctl verify

.PHONY: sboot-enroll-microsoft/%
sboot-enroll-microsoft/%:
	ssh root@$(host) sbctl enroll-keys --microsoft

.PHONY: sboot-enroll-/%
sboot-enroll-microsoft/%:
	ssh root@$(host) sbctl enroll-keys --microsoft
