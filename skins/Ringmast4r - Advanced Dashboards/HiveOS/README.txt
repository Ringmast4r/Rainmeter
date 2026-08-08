====================================
THE FORGE - LOCAL MINING MONITOR
====================================

This skin monitors "The Forge" mining rig via LOCAL NETWORK.

** WORKS WITH FREE HIVEOS ACCOUNTS **
(API tokens require paid HiveOS subscription)

------------------------------------
HOW IT WORKS
------------------------------------

The skin uses PING to check if your rig is online:
- IP Address: 10.0.0.246
- Updates every 3 seconds
- Shows: MINING (green) when online, OFFLINE (red) when not

------------------------------------
FEATURES
------------------------------------

- Online/Offline status indicator (big green/red box)
- Network info: IP address, MAC address, latency
- Mining stats: Hashrate, Power, GPU count
- Quick buttons:
  * WEB INTERFACE - Opens local HiveOS web (http://10.0.0.246)
  * CLOUD DASHBOARD - Opens HiveOS cloud dashboard

------------------------------------
UPDATING STATS
------------------------------------

Since this uses FREE HiveOS (no API access), stats are MANUAL.
To update hashrate and power:

1. Right-click the skin > Edit skin
2. Find the [Variables] section at the top
3. Update these values:

   manualHashrate=796.8    (change to current MH/s)
   manualPower=675         (change to current watts)
   manualGPUs=5            (number of GPUs)

4. Save and refresh the skin

------------------------------------
TROUBLESHOOTING
------------------------------------

Problem: Shows OFFLINE but rig is on
Solution:
- Check if rig IP is still 10.0.0.246 (might have changed)
- Make sure rig and PC are on same network
- Try pinging manually: cmd > ping 10.0.0.246

Problem: Want real-time stats without manual updates
Solution:
- Upgrade to paid HiveOS account ($3/month per rig)
- Then API integration will work for live stats

Problem: Need to change rig IP
Solution:
- Right-click skin > Edit skin
- Change: rigIP=10.0.0.246 to new IP

------------------------------------
TECH DETAILS
------------------------------------

Rig: The Forge
IP: 10.0.0.246
MAC: 00:E0:0C:A6:04:80
GPUs: 5x GeForce RTX 3070
Hashrate: ~797 MH/s
Power: ~675W

Farm ID: 4384471
Worker ID: 10389236
Cloud URL: https://the.hiveos.farm/farms/4384471/workers/10389236/

====================================
ringmast4r v3.0 - The Forge Monitor
====================================
