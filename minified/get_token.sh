#!/bin/bash
# Copyright (C) 2020 Private Internet Access, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This function allows you to check if the required tools have been installed.
function check_tool() {
  cmd=$1
  package=$2
  if ! command -v $cmd &>/dev/null
  then
    echo "$cmd could not be found"
    echo "Please install $package"
    exit 1
  fi
}
# Now we call the function to make sure we can use curl and jq.
check_tool curl curl
check_tool jq jq

echo "The ./get_token.sh script got started with PIA_USER and PIA_PASS,
so we will also use a meta service to get a new VPN token."

bestServer_meta_hostname=10.0.0.1

echo "Trying to get a new token by authenticating with the meta service..."
generateTokenResponse=$(curl -v -ks -u "$PIA_USER:$PIA_PASS" --max-time 10 "https://10.0.0.1/authv3/generateToken")
echo "$generateTokenResponse"

if [ "$(echo "$generateTokenResponse" | jq -r '.status')" != "OK" ]; then
  echo "Could not get a token. Please check your account credentials."
  echo
  echo "You can also try debugging by manually running the curl command:"
  echo $ curl -s -u "$PIA_USER:$PIA_PASS" --max-time 10 \
    https://$bestServer_meta_hostname/authv3/generateToken
  exit 1
fi

token="$(echo "$generateTokenResponse" | jq -r '.token')"
echo "This token will expire in 24 hours.
"

# just making sure this variable doesn't contain some strange string
if [ "$PIA_PF" != true ]; then
  PIA_PF="false"
fi

if [[ $PIA_AUTOCONNECT == wireguard ]]; then
  echo The ./get_region_and_token.sh script got started with
  echo PIA_AUTOCONNECT=wireguard, so we will automatically connect to WireGuard,
  echo by running this command:
  echo $ WG_TOKEN=\"$token\" \\
  echo WG_SERVER_IP=$bestServer_WG_IP WG_HOSTNAME=$bestServer_WG_hostname \\
  echo PIA_PF=$PIA_PF ./connect_to_wireguard_with_token.sh
  echo
  PIA_PF=$PIA_PF PIA_TOKEN="$token" WG_SERVER_IP=$bestServer_WG_IP \
    WG_HOSTNAME=$bestServer_WG_hostname ./connect_to_wireguard_with_token.sh
  exit 0
fi

if [[ $PIA_AUTOCONNECT == openvpn* ]]; then
  serverIP=$bestServer_OU_IP
  serverHostname=$bestServer_OU_hostname
  if [[ $PIA_AUTOCONNECT == *tcp* ]]; then
    serverIP=$bestServer_OT_IP
    serverHostname=$bestServer_OT_hostname
  fi
  echo The ./get_region_and_token.sh script got started with
  echo PIA_AUTOCONNECT=$PIA_AUTOCONNECT, so we will automatically
  echo connect to OpenVPN, by running this command:
  echo PIA_PF=$PIA_PF PIA_TOKEN=\"$token\" \\
  echo   OVPN_SERVER_IP=$serverIP \\
  echo   OVPN_HOSTNAME=$serverHostname \\
  echo   CONNECTION_SETTINGS=$PIA_AUTOCONNECT \\
  echo   ./connect_to_openvpn_with_token.sh
  echo
  PIA_PF=$PIA_PF PIA_TOKEN="$token" \
    OVPN_SERVER_IP=$serverIP \
    OVPN_HOSTNAME=$serverHostname \
    CONNECTION_SETTINGS=$PIA_AUTOCONNECT \
    ./connect_to_openvpn_with_token.sh
  exit 0
fi

if [[ $PIA_AUTOCONNECT == manual ]]; then
gateway_ip=$(ip route | head -1 | grep tun | awk '{ print $3 }')
serverHostname=uk-manchester.privacy.network
 echo The ./get_token.sh script got started with
  echo PIA_AUTOCONNECT=$PIA_AUTOCONNECT, so we will automatically
  echo connect to OpenVPN, by running this command:
  echo PIA_PF=$PIA_PF PIA_TOKEN=\"$token\" \\
  echo   OVPN_SERVER_IP=$serverIP \\
  echo   OVPN_HOSTNAME=$serverHostname \\
  echo   CONNECTION_SETTINGS=$PIA_AUTOCONNECT \\
  echo   ./port_forwarding.sh
  echo
  echo $bestServer_OU_hostname
  echo $gateway_ip
  PIA_TOKEN=$token \
  PF_GATEWAY=$gateway_ip \
  PF_HOSTNAME=$serverHostname \
  ./port_forwarding.sh

  exit 0
fi

echo If you wish to automatically connect to the VPN after detecting the best
echo region, please run the script with the env var PIA_AUTOCONNECT.
echo 'The available options for PIA_AUTOCONNECT are (from fastest to slowest):'
echo  - wireguard
echo  - openvpn_udp_standard
echo  - openvpn_udp_strong
echo  - openvpn_tcp_standard
echo  - openvpn_tcp_strong
echo - manual
echo You can also specify the env var PIA_PF=true to get port forwarding.
echo
echo Example:
echo $ PIA_USER=p0123456 PIA_PASS=xxx \
  PIA_AUTOCONNECT=wireguard PIA_PF=true ./get_region_and_token.sh
echo
echo You can also connect now by running this command:
echo $ WG_TOKEN=\"$token\" WG_SERVER_IP=$bestServer_WG_IP \
  WG_HOSTNAME=$bestServer_WG_hostname ./connect_to_wireguard_with_token.sh
