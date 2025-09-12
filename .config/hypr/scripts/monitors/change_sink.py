#!/usr/bin/env python3
import subprocess
import logging
import asyncio

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s: %(message)s"
)

def get_cards():
    result = subprocess.run(
        ["pactl", "list", "cards"],
        capture_output=True, text=True, check=True
    )
    cards = []
    current = {}
    for line in result.stdout.splitlines():
        if line.startswith("Card #"):
            if current:
                cards.append(current)
            current = {"Name": None, "Profiles": []}
        elif "Name:" in line and current.get("Name") is None:
            current["Name"] = line.split(":", 1)[1].strip()
        elif "output:" in line and "available" in line:
            profile = line.split(":")[0].strip()
            current["Profiles"].append(profile)
    if current:
        cards.append(current)
    return cards

def detect_card():
    cards = get_cards()
    for c in cards:
        if any("hdmi" in p.lower() for p in c["Profiles"]):
            return c["Name"], c["Profiles"]
    return (cards[0]["Name"], cards[0]["Profiles"]) if cards else (None, [])

CARD, PROFILES = detect_card()
logging.info(f"Using card: {CARD}")
logging.info(f"Profiles: {PROFILES}")

def profile_for_monitor(monitor: str) -> str:
    monitor = monitor.lower()
    if "hdmi" in monitor:
        for p in PROFILES:
            if "hdmi" in p.lower():
                return p
    return "output:analog-stereo+input:analog-stereo"

def switch_profile(profile, monitor, last_profile):
    if not CARD:
        return last_profile
    if profile == last_profile:
        return last_profile
    try:
        subprocess.run(
            ["pactl", "set-card-profile", CARD, profile],
            check=True
        )
        logging.info(f"Switched to {profile} because workspace moved to {monitor}")
        subprocess.run([
            "notify-send",
            "-i", "audio-speakers",
            f"Audio switched",
            f"→ {profile} (workspace on {monitor})"
        ])
        return profile
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to switch profile: {e}")
        return last_profile

async def get_active_monitor():
    try:
        result = subprocess.run(
            ["hyprctl", "activeworkspace", "-j"],
            capture_output=True, text=True, check=True
        )
        import json
        data = json.loads(result.stdout)
        return data.get("monitor")
    except Exception as e:
        logging.error(f"Failed to get active monitor: {e}")
        return None

async def main():
    last_monitor = None
    last_profile = None
    while True:
        monitor = await get_active_monitor()
        if monitor and monitor != last_monitor:
            last_monitor = monitor
            profile = profile_for_monitor(monitor)
            last_profile = switch_profile(profile, monitor, last_profile)
        await asyncio.sleep(1)  # very low CPU usage

if __name__ == "__main__":
    asyncio.run(main())

