# SleimGunnerHUD

![vlcsnap-2022-08-20-00h43m18s074](https://user-images.githubusercontent.com/41690269/185805311-6fa58eec-17f0-4b03-b687-9355ded28cea.png)

## Features:
- Weapon Widgets Groups
- Radar with enemy and friendly filter
	- 3 Letter easy Identification
	- 'Alt+C' to toggle Radar widget (Enemy/Friendly)
- 3 Letter search for targets in lua chat displayed in seperate Radar-Widget

![weapon_radar](https://user-images.githubusercontent.com/41690269/187029911-d8237fc8-4b73-4830-a33d-e78e1441b7b8.png)


- Info about selected Target:
	- Hitchance
	- Speed
	- Distance
	- Dmg done
	- Own DPS
	- Estimated time to 10mil dmg (L-Shield)

![damage_info](https://user-images.githubusercontent.com/41690269/187029845-d1d98159-3a41-4a32-b641-5c234b8ffc3f.png)


- Mini-Shield-Screen:
	- Clickable to adjust and set resistances
	- Enemy-DPS
	- Estimated time till own shield is down

![shield_screen](https://user-images.githubusercontent.com/41690269/187029945-6769c270-c482-4924-99a8-3a0673ac600a.png)


- Detailed Info about allies (ships with same transponder tag) and Threats
- Info about new Radar contacts
- Own Id, 3 Letter + ShipName displayed
- Augmented-Reality:
	- toggle with 'L-Shift'
	- Planets
	- Alien-Cores
	- Allies with owner
	- custom waypoints
- 'Drift'-Mode:
	- Alt + G to toggle
	- disables inertia dampening to keep turning
- custom voice pack

## How to install:
1. Download the 'SleimGunnerHUD.conf' and 'SleimRemoteHud.conf' file
2. Place them in the DU custom folder inside the DU installation: 'Dual Universe\Game\data\lua\autoconf\custom'
3. Ingame connect to Gunner Module:
	- Space Radar
	- Weapons
	- (Optional and not recommended when using with the remote script) Shield generator
	- (Optional and only after Space Radar!) Atmo Radar
4. Make sure your ship has a shield and warp drive if you want to use the Remote script
	- no manual connecting to remote needed
5. Only after download of new config:
	- Rightclick Gunner Module -> Advanced -> Update custom autoconf list
6. Rightclick Gunner Module -> Advanced -> Run custom autoconfigure -> SleimGunneerHUD_v1.*
7. Rightclick Remote Controller -> Advanced -> Run custom autoconfigure -> SleimRemoteHud


## Hotkeys:
- Alt + 1 to toggle shield
- Alt + 2 to start/stop shield vent
- LShift to toggle AR display
- Alt + G to start/stop drift mode (disable inertia dampening)
- Alt + C switch radar widget friendly/enemy mode
- Alt + 5 activates AutoTargets, required Heartbeats external program


