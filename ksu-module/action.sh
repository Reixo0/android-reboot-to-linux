#!/system/bin/sh
# Reboot to Linux: arms the Canoe boot manager's boot-once record
# ("canoe-once:<entry>") in the bootloader control block's command field
# (first 32 bytes of misc), then reboots. Canoe clears the record before it
# launches the entry. The entry is "linux" unless /data/adb/reboot-to-linux.conf
# says otherwise ("entry=<canoe.cfg entry id>" or "entry=bls:<stem>").
# A stale "bootonce-bootloader" is replaced, any other pending command is
# left alone. "action.sh arm" only writes the record (the LSPosed power menu
# item reboots through Android afterwards).
entry=linux
conf=/data/adb/reboot-to-linux.conf
[ -r $conf ] && entry=$(sed -n 's/^entry=//p' $conf | tail -n 1)
case $entry in
'' | *[!A-Za-z0-9._:-]*) echo "bad entry \"$entry\" in $conf"; exit 1 ;;
esac
record=canoe-once:$entry
# 11-byte prefix + NUL leave 20 bytes for the entry (Canoe's limit)
[ ${#record} -le 31 ] || { echo "entry \"$entry\" is too long"; exit 1; }
misc=/dev/block/by-name/misc
cmd=$(head -c 32 $misc | tr -d '\000')
case $cmd in
'' | canoe-once:* | bootonce-bootloader) ;;
*) echo "misc already holds \"$cmd\", not touching it"; exit 1 ;;
esac
printf '%s' "$record" | dd of=$misc bs=32 count=1 conv=sync,notrunc 2>/dev/null
sync
if [ "$(head -c 32 $misc | tr -d '\000')" != "$record" ]; then
	echo "writing the boot-once record failed"
	exit 1
fi
[ "${1:-}" = arm ] && exit 0
echo "Rebooting to $entry."
sleep 1
/system/bin/reboot
