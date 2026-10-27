# Reboot to Linux (Android side)

Reboot an Android phone straight into Linux when both start from the
[Canoe](https://github.com/1vivy/gbl_root_canoe) boot manager: Android is
Canoe's default entry, Linux another one (e.g. Mu-Silicium + systemd-boot).
Canoe has a boot-once record, `canoe-once:<entry>` in the command field of the
bootloader control block (first 32 bytes of `misc`), which it clears before
launching that entry. These modules write it and reboot.

Made for and tested on the Nubia RedMagic 11 Pro (NX809J) with EvolutionX,
KernelSU and Vector (LSPosed); see
[nx809j-mainline](https://github.com/Reixo0/nx809j-mainline) for the Linux port
and its Canoe setup.

| Directory | What it is |
|---|---|
| `ksu-module/` | KernelSU (or Magisk) module. Its **Action** button arms the record and reboots; `action.sh arm` only arms it |
| `lsposed/` | LSPosed/Vector module for System UI: adds **Linux** (Tux icon) after **Bootloader** in the advanced restart menu |

## Configuration

The Canoe entry is `linux`. Another one goes into
`/data/adb/reboot-to-linux.conf`:

```
entry=arch
```

A `canoe.cfg` entry id or `bls:<stem>`, at most 20 characters. If `misc` holds
any other command than a stale `bootonce-bootloader` (e.g. a pending
recovery request), nothing is written and the phone does not reboot.

## Building

```bash
./build-ksu-module.sh
```

```bash
EVO=~/aosp lsposed/build.sh
```

The LSPosed module is built without Gradle, from an AOSP/LineageOS tree's
prebuilts (`EVO`, default `~/evo12`): JDK 21, `android.jar` (API 36), aapt2,
d8, zipalign and apksigner. It compiles against stubs of the Xposed API in
`lsposed/stubs/`, which are not packaged. The signing key is created once in
`out/lsposed/key.p12`; keep it, updates need the same key.

## Installing

1. Install `out/reboot-to-linux-ksu.zip` in KernelSU and reboot.
2. Install `out/lsposed/reboot-linux-lsposed.apk`, enable it in Vector/LSPosed
   with the scope **System UI**, restart System UI.
3. In KernelSU → Superuser, grant root to **Reboot to Linux**. It only runs the
   module's `action.sh arm`, then `svc power reboot`.

Advanced restart has to be on (the LineageOS "advanced restart" setting;
the menu then shows Recovery, Bootloader and so on under Restart).

## How the power menu item works

System UI is a Pixel-based `SystemUIGoogle` on EvolutionX, built with R8: the
reboot-reason items are merged into one class (`RestartDownloadAction(dialog,
icon, label, classId)`) and some methods are gone. So the hook finds the
Bootloader item by its label resource, `global_action_restart_bootloader`,
and builds a copy with whatever constructor that class has. Pressing it calls
the dialog's own `rebootAction()` with a private reason, so a secure lock
screen is dismissed first, as for the other restart items; at the end of that
path `GlobalActionsComponent.reboot()` sends the module's receiver a broadcast
for that reason instead of rebooting. The receiver only accepts it from
holders of `STATUS_BAR_SERVICE` (System UI). If anything fails, the item does
nothing; it never falls through to the Bootloader action.

## License

GPL-2.0. The Tux icon is the "Linux" icon of [Simple Icons](https://simpleicons.org)
(CC0-1.0).
