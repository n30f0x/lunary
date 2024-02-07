{ config, lib, pkgs, ... }:
let keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpRPEzQhTksrwvYMxvOLCt9Owj+NuXgtNPNai4zhl8twg2KBZpHFmIu6Isx3bykY1T7iyat4fazhZK9gMmAjFRZwktv74SSAgxqNZhpFmi2jP4XuFwZZTmL1oIPfnvFgB/Q2MWAiocraWBIzVkQ7DIaaHlD/6CaDgMNuN0+ruZC1QZ+o8VpUWEQ/EbPw9hcER2kl007lAUyHg9RMx/QpMGhIc/M3j7n2F2hQZ4eONpXS0XmYVLtPEJ3iW3f/MpdmjZpgjgCLlpixcZ5PyRFFks5vqMrFLzSDxnsHlfwL2Lr5MaQve9kNd3xdqjNf2Go+yJ+tSkepToyAIndPI0eNPWw+R0JsP9wGn3rc70LsL2uywojzPl5gKx2kNkozSvNW3pmsgMmSEpKyNZk2PdRLjexTSrSSDNsezyBAinTsjduohUmrV1nLn3yTqIc58CK7dXsIEhFq5spM9QNPSxV0vfm1+Hybb79EEsmpFLaNO0ipl3qCnv67sM4WVC39HyYTU= n30f0x@foxy-laptop.local"
];
protokeys = [
  # ""
];  
   in
{

  main = {
    services.openssh = {
      enable = true;
      settings = { PasswordAuthentication = false; };
    };
    users.users."${config._.user}".openssh.authorizedKeys.keys = keys;

    programs.gnupg.agent = {
       enableSSHSupport = true;
    };
    
  };

  prototype = {
    services.openssh = {
      settings = { 
        enable = true;
        PasswordAuthentication = true; 
        PermitRootLogin = "yes";
        AllowUsers = ["root" "${config._.user}"];
      };
    users.users.root.openssh.authorizedKeys.keys = keys;
    users.users."${config._.user}".openssh.authorizedKeys.keys = keys;

    programs.gnupg.agent = {
       enableSSHSupport = true;
    };
    };
  };
}

