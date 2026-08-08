<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=0:0d1117,35:1b3a6b,70:2f64aa,100:00bcd4&height=230&section=header&text=RAINMETER&fontSize=80&fontColor=ffffff&animation=fadeIn&fontAlignY=34&desc=Live%20widgets%20on%20your%20desktop%20%7C%20drives%20%7C%20weather%20%7C%20system%20%7C%20dividers&descSize=17&descAlignY=54"/>

<div align="center">

[![Free](https://img.shields.io/badge/100%25-FREE-00bcd4?style=for-the-badge&labelColor=0d1117)](https://www.rainmeter.net/)
[![Open Source](https://img.shields.io/badge/OPEN-SOURCE-2f64aa?style=for-the-badge&labelColor=0d1117)](https://github.com/rainmeter/rainmeter)
[![Plain Text](https://img.shields.io/badge/PLAIN-TEXT%20SKINS-00e676?style=for-the-badge&labelColor=0d1117)](#write-a-skin-in-a-text-editor)
[![Low RAM](https://img.shields.io/badge/TINY-FOOTPRINT-ff5252?style=for-the-badge&labelColor=0d1117)](#why-rainmeter)
[![Windows](https://img.shields.io/badge/WINDOWS-7%20%E2%86%92%2011-ffc107?style=for-the-badge&labelColor=0d1117)](https://www.rainmeter.net/)

**Your desktop is the biggest screen you own and it is showing a wallpaper.**

Rainmeter puts live, clickable, always-there information on it instead.

**For Linux users:** → [Conky Configuration Repository](https://github.com/Ringmast4r/Conky)

</div>

<img width="100%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0d1117,35:1b3a6b,70:2f64aa,100:00bcd4&height=3&section=header"/>

## Why Rainmeter

Rainmeter has been around since 2001 and is still the best thing on Windows for this. It is free, open source, and about as light as software gets.

**It is just text.** A skin is an `.ini` file. No SDK, no compiler, no build step, no npm. Open it in Notepad, change a number, save, and the widget updates instantly. That is the whole loop.

**It reads anything.** CPU, RAM, disk, network throughput, battery, running processes, folder sizes, Windows performance counters, the registry, any file on disk, and any URL on the internet. If you can get data, you can put it on your desktop.

**It costs nothing to run.** These widgets sit at a few MB of RAM and effectively zero CPU between updates. It is not an Electron app.

**Everything is clickable.** Every element can run a program, open a folder, hit a URL, or fire off a script. Widgets and launchers are the same thing.

**Nothing phones home.** No account, no telemetry, no subscription, no ads. You download it, it runs.

<img width="100%" src="https://capsule-render.vercel.app/api?type=rect&color=0:1b3a6b,100:2f64aa&height=2&section=header"/>

## The Skins (18+ Collections)

| Folder | Description |
|:--|:--|
| **Dark - Weather & System Monitor** | Current weather, rain forecast, CPU/RAM rings, uptime |
| **Simplic - System Monitoring Suite** | Clean system widgets: CPU, RAM, disk, network, weather, time |
| **Illustro - Clean System Widgets** | Minimal system monitoring (clock, disk, network, system, recycle bin) |
| **Illustro Connected - Dashboard** | Unified dashboard experience |
| **World Clock - Global Time Zones** | 25+ city time zones (London, Tokyo, Sydney, New York, etc.) |
| **Divider - Screen Layout Rules (416 variants)** | 16 configs × 26 colors: thin rules for carving up your monitor |
| **Folder Sizes - Drive & Folder Monitor** | E-drive folder size tracker with Lua sorting |
| **Disc Drive Size - Compact Storage Monitor** | Compact list view of local and network drives |
| **Ringmast4r - Advanced Dashboards** | CyberOps dashboard, folder trackers, MAC OUI lookup, social media trackers |
| **Impact - Drive Space Monitor** | Drive usage with color-coded capacity |
| **Hit Me Punk - Drive Space Monitor** | Alternative drive space visualization |
| **Bloody - Drive Space Monitor** | Dark-themed drive space monitor |
| **Creepster - Drive & Network Monitor** | Drive and network status display |
| **SimpleDP - CPU & RAM Gauge** | CPU and RAM usage as rotating gauges |
| **@DriveData - Drive Backend Service** | Background service for drive monitoring (do not load directly) |
| **@Vault - Resource Library** | Shared resources and fonts for all skins |

<img width="100%" src="https://capsule-render.vercel.app/api?type=rect&color=0:2f64aa,100:00bcd4&height=2&section=header"/>

## Weather Widget

![No API key](https://img.shields.io/badge/No-API%20key-00e676?style=flat-square&labelColor=0d1117)
![wttr.in](https://img.shields.io/badge/source-wttr.in-2f64aa?style=flat-square&labelColor=0d1117)
![Colour coded](https://img.shields.io/badge/rain-colour%20coded-00bcd4?style=flat-square&labelColor=0d1117)

<img align="right" width="290" src="screenshots/weather.png"/>

Most weather skins tell you the temperature. The useful question is whether you need to bring a jacket, so this one answers that first.

`WILL IT RAIN TODAY` takes the highest chance of rain across the whole day and turns it into one word and one colour:

| Peak chance | Reads | Colour |
|:--|:--|:--|
| under 30% | STAYING DRY | green |
| 30 to 59% | RAIN POSSIBLE | amber |
| 60% and up | RAIN LIKELY | red |

Underneath, the day is split into **morning / afternoon / evening** so you can see *when* it is coming, each tinted on its own. Then high, low, UV index, humidity, wind, sunrise, sunset, and tomorrow's outlook.

It pulls the `j1` JSON feed from [wttr.in](https://wttr.in) — no API key, no signup, no account. One HTTP request every 30 minutes populates all 34 fields.

<img width="100%" src="https://capsule-render.vercel.app/api?type=rect&color=0:00bcd4,100:00e676&height=2&section=header"/>

## Drive Space Widget

<img align="right" width="330" src="screenshots/drive-space.png"/>

A ring per drive, four to a row, with CPU, RAM and the recycle bin on the end. Rings turn red past 85%. Click any ring to open that drive.

**There are no drive letters anywhere in this skin.** Live drives get packed into numbered slots in alphabetical order, and the skin reads its own geometry — positions, labels, colours, even the background height — out of a generated file. Re-letter a drive, plug in a USB stick, drop a network share, and the grid rebuilds itself with no edits.

The trick is the @DriveData backend:

```
Scheduled Task  →  driveinfo.ps1  →  DriveData.inc  →  @Include in the skins
   every 1 min       does the I/O      plain variables      instant, no I/O
```

A scheduled task runs `driveinfo.ps1` once a minute. It scans all drives, does all the blocking work off in its own process, and writes plain Rainmeter variables. The skins `@Include` that file and do zero drive I/O. Startup went from minutes of hanging to **1.2 seconds**.

<img width="100%" src="https://capsule-render.vercel.app/api?type=rect&color=0:1b3a6b,100:2f64aa&height=2&section=header"/>

## Divider Pack

![416 files](https://img.shields.io/badge/416-files-00bcd4?style=flat-square&labelColor=0d1117)
![26 colours](https://img.shields.io/badge/26-colours-ff5252?style=flat-square&labelColor=0d1117)
![Stackable](https://img.shields.io/badge/load-all%20at%20once-00e676?style=flat-square&labelColor=0d1117)

![Divider colours](screenshots/divider-colors.png)

Thin vertical and horizontal rules for carving a wide monitor into zones. 24 solid colours plus a full-spectrum **Rainbow** and an **RGB** sweep.

The trick is the folder layout. Rainmeter only allows one active `.ini` per config folder, so a single `Divider` folder means picking a colour *replaces* the divider you already had. Instead there are **16 separate configs** — `Vertical1` through `Vertical8` and `Horizontal1` through `Horizontal8` — each holding all 26 colours.

That means you can run eight vertical rules at once, each a different colour, and swap any one of them without touching the others.

<img width="100%" src="https://capsule-render.vercel.app/api?type=rect&color=0:00bcd4,100:00e676&height=2&section=header"/>

## System Monitoring

<p align="center">
  <img width="300" src="screenshots/system-info.png"/>
  <img width="300" src="screenshots/uptime.png"/>
</p>

CPU and RAM as rings, and time since boot broken into days, hours, minutes, seconds.

<p align="center">
  <img width="330" src="screenshots/disc-drive-size.png"/>
</p>

Compact drive list view with local and network drives.

## Install

```
1.  Install Rainmeter                    https://www.rainmeter.net/
2.  Copy everything in skins/ into       Documents\Rainmeter\Skins\
3.  Refresh Rainmeter (tray icon, right click, Refresh all)
4.  Right click the tray icon > Skins > pick what you want
```

<div align="center">

### Notes

Skins are plain text. Open one, change a colour, hit refresh, see it immediately. That is the entire appeal — start with one of these and make it yours.

</div>

<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=0:00bcd4,30:2f64aa,65:1b3a6b,100:0d1117&height=140&section=footer"/>
