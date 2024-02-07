{ pkgs }:

# services.tor.relay.enable = false;
# services.tor.controlSocket.enable = true;
let 
 tor_service = pkgs.writeShellScript "tor-background-service" 
   ''
   tor --runasdaemon 1 --controlport 9051
   '';
in
 # outputs = inputs:
{
 pwn_web = pkgs.mkShell {
 name = "pwn_web";
 packages = with pkgs; 
  [
  whois nuclei nmap sqlmap
  tor torsocks onionshare nyx 
  ligolo-ng chisel
  # proxychains 
  ]; 
 shellHook = ''
        # ${tor_service} &
        # TOR_BG=$!

        trap "pkill tor" EXIT
 '';
 # VARIABLE_EXAMPLE = "Hey hey change me";
 };



 pwn_reverse = pkgs.mkShell {
 name = "pwn_reverse";
 packages = with pkgs; 
  [
  binwalk rizin gef
  ]; 

 shellHook = ''
 '';
 # VARIABLE_EXAMPLE = "Hey hey change me";
 };

}

