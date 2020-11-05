#!/bin/bash
cd /volume1/Data/manual-connections-1.0.0
/bin/touch ./port.txt
/bin/touch ./output.txt
PIA_USER={pia username} PIA_PASS={pia password} PIA_PF=true PIA_AUTOCONNECT=manual ./get_token.sh > ./output.txt 2>&1
exit 0