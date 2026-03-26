more auto_speed_TR.sh 
  found=0
  computers=$HOME/computers.txt

  for ip in `cat $computers`; do ping -c 1 $ip>/dev/null; [ $? -eq 0 ] && echo "$ip UP" &&   found=1 && break || echo "$ip DOWN" ; done

  if [ $found -eq 1 ] 
  then
    echo "Transmission speed down" >> /var/messages;
    /usb/hd1/transmission-remote localhost:9091 -n admin:pass -d 10 -u 10

  else
       echo "Transmission speed up" >> /var/messages
       /usb/hd1/transmission-remote localhost:9091 -n admin:pass -D -U
  fi;