#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)

. /etc/profile

set_kill set "-9 melonDS"

#load gptokeyb support files
control-gen_init.sh
source /storage/.config/gptokeyb/control.ini
get_controls

CONF_DIR="/storage/.config/melonDS"
MELONDS_INI="melonDS.ini"

if [ ! -d "${CONF_DIR}" ]; then
	cp -r "/usr/config/melonDS" "/storage/.config/"
fi

if [ ! -d "/storage/roms/savestates/nds" ]; then
	mkdir -p "/storage/roms/savestates/nds"
fi

#Make sure melonDS gptk config exists
if [ ! -f "${CONF_DIR}/melonDS.gptk" ]; then
	cp -r "/usr/config/melonDS/melonDS.gptk" "${CONF_DIR}/melonDS.gptk"
fi

#Emulation Station Features
GAME=$(echo "${1}" | sed "s#^/.*/##")
PLATFORM=$(echo "${2}"| sed "s#^/.*/##")
GRENDERER=$(get_setting graphics_backend "${PLATFORM}" "${GAME}")
SORIENTATION=$(get_setting screen_orientation "${PLATFORM}" "${GAME}")
SLAYOUT=$(get_setting screen_layout "${PLATFORM}" "${GAME}")
SWAP=$(get_setting screen_swap "${PLATFORM}" "${GAME}")
SROTATION=$(get_setting screen_rotation "${PLATFORM}" "${GAME}")
SHOWFPS=$(get_setting show_fps "${PLATFORM}" "${GAME}")
VSYNC=$(get_setting vsync "${PLATFORM}" "${GAME}")

#Set the cores to use
CORES=$(get_setting "cores" "${PLATFORM}" "${GAME}")
unset EMUPERF
[ "${CORES}" = "little" ] && EMUPERF="${SLOW_CORES}"
[ "${CORES}" = "big" ] && EMUPERF="${FAST_CORES}"

#Graphics Backend
if [ "$GRENDERER" = "1" ]; then
	sed -i '/^ScreenUseGL=/c\ScreenUseGL=1' "${CONF_DIR}/${MELONDS_INI}"
else
	sed -i '/^ScreenUseGL=/c\ScreenUseGL=0' "${CONF_DIR}/${MELONDS_INI}"
fi

#Screen Orientation
if [ "$SORIENTATION" ] > "0"; then
	sed -i "/^ScreenLayout=/c\ScreenLayout=$SORIENTATION" "${CONF_DIR}/${MELONDS_INI}"
else
	sed -i '/^ScreenLayout=/c\ScreenLayout=2' "${CONF_DIR}/${MELONDS_INI}"
fi

#Screen Layout
if [ "$SLAYOUT" ] > "0"; then
	sed -i "/^ScreenSizing=/c\ScreenSizing=$SLAYOUT" "${CONF_DIR}/${MELONDS_INI}"
else
	sed -i '/^ScreenSizing=/c\ScreenSizing=0' "${CONF_DIR}/${MELONDS_INI}"
fi

#Screen Swap
if [ "$SWAP" = "1" ]; then
	sed -i '/^ScreenSwap=/c\ScreenSwap=1' "${CONF_DIR}/${MELONDS_INI}"
else
	sed -i '/^ScreenSwap=/c\ScreenSwap=0' "${CONF_DIR}/${MELONDS_INI}"
fi

#Screen Rotation
if [ "$SROTATION" ] >"0"; then
	sed -i "/^ScreenRotation=/c\ScreenRotation=$SROTATION" "${CONF_DIR}/${MELONDS_INI}"
else
	sed -i '/^ScreenRotation=/c\ScreenRotation=0' "${CONF_DIR}/${MELONDS_INI}"
fi

#Vsync
if [ "$VSYNC" = "1" ]; then
	sed -i '/^ScreenVSync=/c\ScreenVSync=1' "${CONF_DIR}/${MELONDS_INI}"
else
	sed -i '/^ScreenVSync=/c\ScreenVSync=1' "${CONF_DIR}/${MELONDS_INI}"
fi

#Show FPS
if [ "$SHOWFPS" = "1" ]; then
	export GALLIUM_HUD="simple,fps"
fi

# Extract archive to /tmp/melonds
TEMP="/tmp/melonds"
rm -rf "${TEMP}"
mkdir -p "${TEMP}"
if [[ "${1}" == *.zip ]]; then
    unzip -o "${1}" -d "${TEMP}"
    ROM=$(find "${TEMP}" -maxdepth 1 -type f -name "*.nds" | head -n 1)
elif [[ "${1}" == *.7z ]]; then
    7z x -y -o"${TEMP}" "${1}"
    ROM=$(find "${TEMP}" -maxdepth 1 -type f -name "*.nds" | head -n 1)
else
    ROM="${1}"
fi

#Set QT Platform to Wayland
export QT_QPA_PLATFORM=wayland
@PANFROST@
@HOTKEY@
@LIBMALI@

#Generate a new MelonDS.toml each run (temporary hack)
rm -rf "${CONF_DIR}/melonDS.toml"

#Run MelonDS emulator
$GPTOKEYB "melonDS" -c "${CONF_DIR}/melonDS.gptk" &
${EMUPERF} /usr/bin/melonDS -f "${ROM}"
kill -9 "$(pidof gptokeyb)"
