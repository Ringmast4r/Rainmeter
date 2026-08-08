import requests
import re
import sys
import json

def get_github(username):
    try:
        r = requests.get(f"https://api.github.com/users/{username}", timeout=10)
        if r.status_code == 200:
            return r.json().get("followers", 0)
    except:
        pass
    return "--"

def get_instagram(username):
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        r = requests.get(f"https://www.instagram.com/{username}/", headers=headers, timeout=10)
        if r.status_code == 200:
            # Try to find follower count in page
            match = re.search(r'"edge_followed_by":\s*\{\s*"count":\s*(\d+)', r.text)
            if match:
                return match.group(1)
            # Alternative pattern
            match = re.search(r'followers_count["\s:]+(\d+)', r.text)
            if match:
                return match.group(1)
    except:
        pass
    return "--"

def get_twitter(username):
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        # Try nitter instance (Twitter mirror)
        r = requests.get(f"https://nitter.net/{username}", headers=headers, timeout=10)
        if r.status_code == 200:
            match = re.search(r'followers.*?(\d[\d,]*)', r.text, re.IGNORECASE)
            if match:
                return match.group(1).replace(",", "")
    except:
        pass
    return "--"

def get_reddit(username):
    try:
        headers = {"User-Agent": "Rainmeter/1.0"}
        r = requests.get(f"https://www.reddit.com/user/{username}/about.json", headers=headers, timeout=10)
        if r.status_code == 200:
            data = r.json().get("data", {})
            return data.get("total_karma", 0)
    except:
        pass
    return "--"

def get_youtube(channel_id, api_key):
    if api_key == "YOUR_API_KEY_HERE" or not api_key:
        return "--"
    try:
        r = requests.get(
            f"https://www.googleapis.com/youtube/v3/channels?part=statistics&id={channel_id}&key={api_key}",
            timeout=10
        )
        if r.status_code == 200:
            items = r.json().get("items", [])
            if items:
                return items[0].get("statistics", {}).get("subscriberCount", "--")
    except:
        pass
    return "--"

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("--")
        sys.exit(1)

    platform = sys.argv[1].lower()
    username = sys.argv[2]

    if platform == "github":
        print(get_github(username))
    elif platform == "instagram":
        print(get_instagram(username))
    elif platform == "twitter":
        print(get_twitter(username))
    elif platform == "reddit":
        print(get_reddit(username))
    elif platform == "youtube":
        api_key = sys.argv[3] if len(sys.argv) > 3 else ""
        print(get_youtube(username, api_key))
    else:
        print("--")
