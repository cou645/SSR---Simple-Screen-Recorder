#!/bin/sh
# Simple Screen Recorder by stemsee
# Copyright (C) 2025 stemsee
# 

if [[ $(id -u) -ne 0 ]]; then
	[[ "$DISPLAY" ]] && exec gtksu "hashtext" "$0" "$@" || exec su -c "$0 $*"
fi
[ ! -f /tmp/timer ] && cp $(type -p yad) /tmp/timer

function recordfn {
. /tmp/ssrvars
	case "$1" in
end) killall timer
kill $(pgrep -n ffmpeg)
kill $(pgrep -n arecord)
rm -f /tmp/temp.mp3
rm -f ffmpeg-*.log
rm -f /tmp/ssrvars
sleep 1
;;
pause) pkill -STOP ffmpeg;;
cont) pkill -CONT ffmpeg;;
start) [ ! -p /tmp/arec ] && mkfifo /tmp/arec
exec 8<>/tmp/arec
IFS='+' read -r O P Q <<<"$(xrectsel)"

arecord -D"$device" -c2 -f"$qual" -twav /tmp/temp.mp3 2>/tmp/arec &

[[ -z "$(xwininfo -name 'SSR reporting' 2>/dev/null)" ]] && /tmp/timer --no-buttons --title="SSR reporting" --text-info --listen --tail --geometry=378x109-0+700 <&8 &

while [ ! -f /tmp/temp.mp3 ]; do
sleep 0.1
done
DATE=$(date +%Y%m%d%H%M%S)
ffmpeg -hide_banner -nostats -loglevel 0 -report -re -i /tmp/temp.mp3 -f x11grab  -thread_queue_size 1024 -video_size "${O}" \
-framerate "$framerate" -i :0.0+"${P}","${Q}" -preset ultrafast -c:v libx264 -acodec aac -ab 128k -bufsize 128k -async 2 -vf scale="$width":-1 "$loc"/grab-"$DATE".mp4 2>/tmp/arec &
while [ ! -f "$loc"/grab-"$DATE".mp4 ]; do
sleep 0.1
done
if [[ -f /tmp/temp.mp3 && "$loc"/grab-"$DATE".mp4 ]]; then
( cnt=2;while sleep 1;do echo -e '\f';echo "$cnt"; cnt=$((cnt + 1));done ) | /tmp/timer --no-buttons --geometry=377x109-0+607 --skip-taskbar --text-info --on-top --no-buttons --undecorated --geometry=135x60-2+1 --fore=green --back=red --fontname="sans bold 38" &
fi;;
esac
};export -f recordfn

function togiffn {
	FILE=$(yad --item-separator='~' --form --field="Select Video":fl "" --field="Options":cb "1~2~3~4~5~6~7" --title="Make a Gif" --text="Options Are 1=fps10, scale 400\n2=fps12, scale=400\n3=fps8, scale=400 - 4,5,6 are @ 600, and 7 is @ fps10 scale=800")
	IFS='|' read -r vid options<<<"$FILE"
	[[ -z "$vid" ]] && exit
	if [[ ! -f "$vid".gif ]]; then
	case "$options" in
	1) ffmpeg -i "$vid" -loop 0 -filter_complex "fps=10, scale=400:-1" -preset ultrafast "$vid".gif 2>/tmp/arec;;
	2) ffmpeg -i "$vid" -loop 0 -filter_complex "fps=12, scale=400:-1" -preset ultrafast "$vid".gif 2>/tmp/arec;;
	3) ffmpeg -i "$vid" -loop 0 -filter_complex "fps=8, scale=400:-1" -preset ultrafast "$vid".gif 2>/tmp/arec;;
	4) ffmpeg -i "$vid" -loop 0 -filter_complex "fps=10, scale=600:-1" -preset ultrafast "$vid".gif 2>/tmp/arec;;
	5) ffmpeg -i "$vid" -loop 0 -filter_complex "fps=12, scale=600:-1" -preset ultrafast "$vid".gif 2>/tmp/arec;;
	6) ffmpeg -i "$vid" -loop 0 -filter_complex "fps=8, scale=600:-1" -preset ultrafast "$vid".gif 2>/tmp/arec;;
	7) ffmpeg -i "$vid" -loop 0 -filter_complex "fps=10, scale=800:-1" -preset ultrafast "$vid".gif 2>/tmp/arec;;
	esac	
	fi
	yad --picture --filename="${vid}.gif" --size=orig --width=600 --height=500 --title="$vid".gif
};export -f togiffn

export devices=$(arecord -L | grep -e 'CARD' | tr '\n' '~')

yad --title="Simple Screen Recorder" --form --text="           Click Record Button
	         Press left mouse button
	 drag the Crosshairs over a screen area "  --item-separator='~' --field="Output Path":cbe "/root~/tmp~/mnt/sdb2)" --field="Frame Rate":cbe "25~18~20~22~24~26"  --field="Scale Width":cbe "640~160~320~480~640~800~960~1024~1280~1600~1920" \
--field="Audio Device":cb "sysdefault:CARD=Audio~$devices" --field="Audio Quality":cb "cd~dat" \
--field="Record":fbtn "bash -c \"echo 'loc="%1"' > /tmp/ssrvars;echo 'framerate="%2"' >> /tmp/ssrvars;echo 'qual="%5"' >> /tmp/ssrvars;echo 'device="%4"' >> /tmp/ssrvars;echo 'width="%3"' >> /tmp/ssrvars;recordfn start \"" \
--field="Stop":fbtn "bash -c 'recordfn end'" --field="Pause":fbtn "bash -c 'recordfn pause'" \
--field="Continue":fbtn "bash -c 'recordfn cont'" --field="Make gif":fbtn "bash -c 'togiffn'" --no-buttons --geometry=377x513-0+69 &

ret=$?
wait $!
case $? in
*) recordfn end;;
esac
