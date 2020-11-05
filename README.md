#  PIA Port forwaded VPN Connections on Synology

This repository is a fork of https://github.com/pia-foss/manual-connections but with the scripts edited to allow port forwarding on a Synology NAS that uses the OpenVPN config in the DiskStation GUI.

I run these on "route-up" of the OpenVPN connection to have the connection do this automatically for you, you will need to ssh into your NAS and add a line to call the caller_script.sh. You want to keep this short because the VPN will wait while this script runs.

the call on line 5 of running_script.sh calls the modified PIA scripts and sets up the port forward and continues to run so that the port will be continually bound too. When being called by the system (rather than being run by you in a terminal) its best if it is run in the background, I also like to pipe the output to a text file to check on the connection

### Lets get started

1. ssh into your NAS
2. gain root access by 'sudo su -' and entering your password
3. copy your route up script to one of your volumes mine was located here /usr/syno/etc.defaults/synovpnclient/scripts/route-up
4. open the route-up script in a text editor and add absolute directions to your caller_script.sh. I added it in the middle. The absolute path will be something like /volume1/{volume name}/caller_script.sh
5. save the file and using the terminal copy it back to its orginal directory e.g. /usr/syno/etc.defaults/synovpnclient/scripts/route-up
6. next time the connection is created the script will be called. It looks like Synology has only one script for route-up if you only want to run these scripts for PIA VPN connections you will have to do some modifications

### Testing your new PF

To test that it works, you can tcpdump on the port you received:

```
bash-5.0# tcpdump -ni any port 47047
```

After that, use curl on the IP of the traffic server and the port specified in the payload which in our case is `47047`:
```bash
$ curl "http://178.162.208.237:47047"
```

and you should see the traffic in your tcpdump:
```
bash-5.0# tcpdump -ni any port 47047
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on any, link-type LINUX_SLL (Linux cooked v1), capture size 262144 bytes
22:44:01.510804 IP 81.180.227.170.33884 > 10.4.143.34.47047: Flags [S], seq 906854496, win 64860, options [mss 1380,sackOK,TS val 2608022390 ecr 0,nop,wscale 7], length 0
22:44:01.510895 IP 10.4.143.34.47047 > 81.180.227.170.33884: Flags [R.], seq 0, ack 906854497, win 0, length 0
```

## License
This project is licensed under the [MIT (Expat) license](https://choosealicense.com/licenses/mit/), which can be found [here](/LICENSE).
