#!/bin/bash

#########################

# Change these variables for your use

CALLSIGN=N0CALL             
DW_SSID=10                  #Direwolf SSID
NODE_SSID=5                 #LinBPQ Node SSID (NODE_SSID and RMS_SSID *CANNOT MATCH*)
RMS_SSID=10                 #RMS Gateway SSID (Used by Winlink clients to connect)
LOCATOR=XXNNXX              #6 character gridsquare
WLNK_USER=CMSCALL           #CMS User (Must have authorization from Winlink team)
WLNK_PASS=**********        #Super secret Winlink password
BPQ_SYSOP_PASS=**********   #BPQ SYSOP Password (SYSOP username is the callsign, in lowercase)
FREQ=NNN.NNN                #Frequency for the gateway
LAT=NN.NNNNN                #Latitude (negative for south)
LON=NN.NNNNN                #Longitude (negative for west)
NEW_HOSTNAME=new-hostname   #Hostname for the machine

#########################

# Comment out CD-ROM repository
sudo sed -i 's/^deb cdrom:/#&/' /etc/apt/sources.list

# Add access to i386 packages
sudo dpkg --add-architecture i386

# Update package lists
sudo apt update

# Install packages
sudo apt install -y git unzip gcc g++ make cmake libasound2-dev libudev-dev libavahi-client-dev libhamlib-dev libgps-dev zlib1g:i386 alsa-utils tmux tor avahi-daemon timeshift

# Add user to the "dialout" group
sudo usermod -aG dialout $USER

# Enable linger for user's services
sudo loginctl enable-linger $USER

#########################

# Digirig udev rule (creates /dev/digirig --> /dev/ttyUSBN)
cat <<EOF > /tmp/digirig.rules
SUBSYSTEM=="tty", GROUP="dialout", MODE="0660", ATTRS{product}=="CP2102N USB to UART Bridge Controller", SYMLINK+="digirig"
EOF
sudo cp /tmp/digirig.rules /etc/udev/rules.d/digirig.rules
rm /tmp/digirig.rules

#########################

# Alsa configs to force digirig to Card #5 and use digirig-rx/digirig-tx
cat <<EOF > /tmp/alsa-base.conf
options snd-usb-audio index=5
EOF
sudo cp /tmp/alsa-base.conf /etc/modprobe.d/alsa-base.conf
rm /tmp/alsa-base.conf

cat <<EOF > /tmp/asound.conf
pcm_slave.digirig {
   pcm {
      type hw
      card 5
   }
   period_time 0
   buffer_size 8192
   rate 44100
}

pcm.digirig-dmix {
   type dmix
   ipc_key 2023041901
   slave "digirig"
   bindings.0 0
}

pcm.digirig-dsnoop {
   type dsnoop
   ipc_key 2023041902
   slave "digirig"
   bindings.0 0
}

pcm.digirig-rx {
   type plug
   slave.pcm "digirig-dsnoop"
   hint.description "digirig RX audio plug"
}

pcm.digirig-tx {
   type plug
   slave.pcm "digirig-dmix"
   hint.description "digirig TX audio plug"
}
EOF
sudo cp /tmp/asound.conf /etc/asound.conf
rm /tmp/asound.conf

#########################

# Direwolf (1.7 required to fix hearing own packets on TX)
rm -rf $HOME/DIREWOLF
mkdir -p $HOME/DIREWOLF
cd $HOME/DIREWOLF
git clone https://github.com/wb2osz/direwolf
cd direwolf
git checkout 1.7
mkdir build && cd build
cmake ..
make -j4
sudo make install

cat <<EOF > $HOME/DIREWOLF/direwolf.conf
MYCALL $CALLSIGN-$DW_SSID
ADEVICE digirig-rx digirig-tx
TXDELAY 50
PTT /dev/digirig RTS
CDIGIPEAT 0 0
DIGIPEAT 0 0 ^WIDE1-1$ ^WIDE1-1$
PBEACON DELAY=0:10 EVERY=30 COMMENT="$CALLSIGN-$DW_SSID Winlink RMS Gateway + Winlink P2P & APRS Digipeater" SYMBOL="DIGI" OVERLAY="W" LAT=$LAT LONG=$LON
EOF

cat <<EOF > $HOME/DIREWOLF/start-direwolf.sh
amixer -c 5 sset "Auto Gain Control" mute
mkdir -p $HOME/DIREWOLF/logs
direwolf -c $HOME/DIREWOLF/direwolf.conf -t 0 | tee $HOME/DIREWOLF/logs/direwolf.log
EOF
chmod +x $HOME/DIREWOLF/start-direwolf.sh

#########################

# LinBPQ
rm -rf $HOME/LINBPQ
mkdir -p $HOME/LINBPQ
cd $HOME/LINBPQ
wget -nv http://cantab.net/users/john.wiseman/Downloads/Beta/linbpq
chmod +x $HOME/LINBPQ/linbpq
rm -rf $HOME/LINBPQ/HTML
mkdir -p $HOME/LINBPQ/HTML
cd $HOME/LINBPQ/HTML
wget -nv http://cantab.net/users/john.wiseman/Downloads/Beta/HTMLPages.zip
unzip HTMLPages.zip
rm HTMLPages.zip
rm background.jpg

cat <<EOF > $HOME/LINBPQ/bpq32.cfg
SIMPLE ; This sets many parameters to reasonable defaults

LOCATOR=$LOCATOR ; Set to your Grid Square to send reports to the BPQ32 Node Map system
NODECALL=$CALLSIGN-$NODE_SSID
IDINTERVAL=0
INFOMSG:
$CALLSIGN's RMS Gateway
***

PORT
 ID=Telnet Server
 DRIVER=TELNET
 CONFIG
 LOGGING=1
 CMS=1 ; Enable CMS Gateway
 CMSCALL=$WLNK_USER ; CMS Gateway Call for Secure CMS Access(normally same as NODECALL)
 CMSPASS=$WLNK_PASS ; Secure CMS Password
 HTTPPORT=8080 ; Port used for Web Management
 TCPPORT=8010 ; Port for Telnet Access
 FBBPORT=8011 ; Not required, but allows monitoring using BPQTermTCP
 MAXSESSIONS=10
 CloseOnDisconnect=1 ; Close Telent Session when Node disconnects
 USER=$(echo $CALLSIGN | tr '[:upper:]' '[:lower:]'),$BPQ_SYSOP_PASS,$CALLSIGN,"",SYSOP
 
 ENDPORT
 
 ; Add Radio Port(s) Here
PORT
 ID=1200 Baud $FREQ
 TYPE=ASYNC
 PROTOCOL=KISS
 CHANNEL=A
 IPADDR=127.0.0.1
 TCPPORT=8001
 MAXFRAME=4
 FRACK=8000
 RESPTIME=1500
 RETRIES=10
 PACLEN=120
 TXDELAY=300
 SLOTTIME=100
 PERSIST=64
 
 WL2KREPORT PUBLIC, www.winlink.org, 8778, $CALLSIGN-$RMS_SSID, $LOCATOR, 00-23, $(echo $FREQ.000 | sed 's/\.//g'), PKT1200, 10, 100, 5, 0

ENDPORT
 
 APPLICATION 1,RMS,C 1 CMS,$CALLSIGN-$RMS_SSID
EOF

cat <<EOF > $HOME/LINBPQ/start-linbpq.sh
cd $HOME/LINBPQ
$HOME/LINBPQ/linbpq -c $HOME/LINBPQ -l $HOME/LINBPQ -d $HOME/LINBPQ
EOF
chmod +x $HOME/LINBPQ/start-linbpq.sh

#########################

# SystemD services for Direwolf and LinBPQ
mkdir -p $HOME/.config/systemd/user

cat <<EOF > $HOME/.config/systemd/user/direwolf.service
[Unit]
Description=Direwolf Service
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/tmux new-session -d -s direwolf '$HOME/DIREWOLF/start-direwolf.sh'
Restart=always

[Install]
WantedBy=default.target
EOF

cat <<EOF > $HOME/.config/systemd/user/linbpq.service
[Unit]
Description=LinBPQ Service
After=direwolf.service

[Service]
Type=simple
ExecStartPre=/usr/bin/sleep 5
ExecStart=/usr/bin/tmux new-session -d -s linbpq '$HOME/LINBPQ/start-linbpq.sh'
Restart=always

[Install]
WantedBy=default.target
EOF

systemctl --user enable direwolf.service
systemctl --user enable linbpq.service

#########################

# Start/stop/monitor scripts for services
mkdir -p $HOME/bin
if ! grep "export PATH" $HOME/.bashrc > /dev/null; then
   echo "export PATH=$PATH:$HOME/bin" >> $HOME/.bashrc
fi

cat <<EOF > $HOME/bin/start-services
#!/bin/bash
# DIREWOLF
systemctl --user start direwolf.service
# LINBPQ
systemctl --user start linbpq.service
EOF
chmod +x $HOME/bin/start-services

cat <<EOF > $HOME/bin/stop-services
#!/bin/bash
# LINBPQ
systemctl --user stop linbpq.service
# DIREWOLF
systemctl --user stop direwolf.service
EOF
chmod +x $HOME/bin/stop-services

cat <<EOF > $HOME/bin/monitor-services
#!/bin/bash

SESSION=monitor-services
WINDOW=$SESSION:0

if ! tmux ls | grep $SESSION; then
	tmux new-session -s $SESSION -d
	tmux split-window -v -t $SESSION
	tmux split-window -h -t $SESSION
	tmux split-window -h -t $SESSION
	tmux split-window -h -t $SESSION
	tmux select-layout tiled

	tmux send-keys -t $WINDOW.0 "top" Enter
	tmux send-keys -t $WINDOW.1 "watch -t 'free -mh; echo; df -h'" Enter
	tmux send-keys -t $WINDOW.2 "clear; tail -f $HOME/DIREWOLF/logs/direwolf.log" Enter
	tmux send-keys -t $WINDOW.3 "clear; tail -f $HOME/LINBPQ/CMSAccessLatest.log" Enter

	tmux attach -t $SESSION
else
	tmux attach -t monitor-services
fi
EOF
chmod +x $HOME/bin/monitor-services

#########################

# Log rotation/cleanup
cat <<EOF > /tmp/direwolf
$HOME/DIREWOLF/logs/direwolf.log
{
  su $USER $USER
  missingok
  daily
  copytruncate
  rotate 30
  dateext
  dateformat _%Y%m%d
}
EOF
sudo cp /tmp/direwolf /etc/logrotate.d/direwolf
rm /tmp/direwolf

cat <<EOF > $HOME/LINBPQ/log-cleanup.sh
find $HOME/LINBPQ/logs/ -name *.log -mtime +30 -delete
EOF
chmod +x $HOME/LINBPQ/log-cleanup.sh
echo "00 02 * * * $USER $HOME/LINBPQ/log-cleanup.sh" | sudo tee /etc/crontab

#########################

# Configure Tor for remote SSH access
cat <<EOF > /tmp/torrc
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 22 127.0.0.1:22
HiddenServicePort 80 127.0.0.1:8073
EOF
sudo cp /tmp/torrc /etc/tor/torrc
rm /tmp/torrc
sudo systemctl restart tor.service

#########################

# Set hostname
OLD_HOSTNAME=$(cat /etc/hostname)
sudo sed -i "s/$OLD_HOSTNAME/$NEW_HOSTNAME/" /etc/hosts
sudo hostnamectl set-hostname $NEW_HOSTNAME

#########################
# Reboot
#sudo reboot
