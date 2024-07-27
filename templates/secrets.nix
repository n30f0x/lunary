deployment.keys.example = {
  text = "this is a super sekrit value :)";
  user = "example";
  group = "keys";
  permissions = "0400";
}; # This will create a new secret in /run/keys that will contain our super secret value.

# Mara is hmm
# <Mara> Wait, isn't /run an ephemeral filesystem? What happens when the system reboots?
# Let's make an example system and find out! So let's say we have that example secret from earlier and want to use it in a job. The job definition could look something like this:

# create a service-specific user
users.users.example.isSystemUser = true;

# without this group the secret can't be read
users.users.example.extraGroups = [ "keys" ];

systemd.services.example = {
  wantedBy = [ "multi-user.target" ];
  after = [ "example-key.service" ];
  wants = [ "example-key.service" ];

  serviceConfig.User = "example";
  serviceConfig.Type = "oneshot";

  script = ''
    stat /run/keys/example
  '';
};
# This creates a user called example and gives it permission to read deployment keys. It also creates a systemd service called example.service and runs stat(1) to show the permissions of the service and the key file. It also runs as our example user. To avoid systemd thinking our service failed, we're also going to mark it as a oneshot.

# Altogether it could look something like this. Let's see what systemctl has to report:

# Mara is hacker
# <Mara> You can read secrets from files using something like
# deployment.keys.example.text = "${builtins.readFile ./secrets/example.env}"
# but it is kind of a pain to have to do that. It would be better to just reference the secrets by filesystem paths in the first place.
# On the other hand Morph gets this a bit better. It is sadly even less documented than NixOps is, but it offers a similar experience via deployment secrets. 
#The main differences that Morph brings to the table are taking paths to secrets and allowing you to run an arbitrary command on the secret being uploaded. Secrets are also able to be put anywhere on the disk, meaning that when a host reboots it will come back up with the most recent secrets uploaded to it.


let
  cfg = config.within.secrets;
  metadata = lib.importTOML ../../ops/metadata/hosts.toml;

  mkSecretOnDisk = name:
    { source, ... }:
    pkgs.stdenv.mkDerivation {
      name = "${name}-secret";
      phases = "installPhase";
      buildInputs = [ pkgs.age ];
      installPhase =
        let key = metadata.hosts."${config.networking.hostName}".ssh_pubkey;
        in ''
          age -a -r "${key}" -o $out ${source}
        '';
    };
# And then we can generate systemd oneshot jobs with something like this:

  mkService = name:
    { source, dest, owner, group, permissions, ... }: {
      description = "decrypt secret for ${name}";
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";

      script = with pkgs; ''
        rm -rf ${dest}
        ${age}/bin/age -d -i /etc/ssh/ssh_host_ed25519_key -o ${dest} ${
          mkSecretOnDisk name { inherit source; }
        }

        chown ${owner}:${group} ${dest}
        chmod ${permissions} ${dest}
      '';
    };
# And from there we just need some boring boilerplate to define a secret type. Then we declare the secret type and its invocation:

in {
  options.within.secrets = mkOption {
    type = types.attrsOf secret;
    description = "secret configuration";
    default = { };
  };

  config.systemd.services = let
    units = mapAttrs' (name: info: {
      name = "${name}-key";
      value = (mkService name info);
    }) cfg;
  in units;
}
# And we have ourself a NixOS module that allows us to:

# Trivially declare new secrets
# Make secrets in the Nix store useless without the key
# Make every secret be transparently decrypted on startup
# Avoid the use of GPG
# Roll back secrets like any other configuration change
# Declaring new secrets works like this (as stolen from the service definition for the website you are reading right now):

within.secrets.example = {
  source = ./secrets/example.env;
  dest = "/var/lib/example/.env";
  owner = "example";
  group = "nogroup";
  permissions = "0400";
};
