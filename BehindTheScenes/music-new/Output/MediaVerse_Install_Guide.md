# MediaVerse Installation Guide

## What You Need

- **MediaVerseSetup.exe** (this folder)
- **W: drive** mapped to your TrueNAS server (same share on all machines)
- **JRiver Media Center 35** installed separately
- **sqlCreds.env** with the correct MySQL IP address for your network

---

## Installing on This Machine

1. Double-click **MediaVerseSetup.exe**
2. Follow the prompts — default location is `C:\Users\<you>\AppData\Local\MediaVerse\`
3. No admin rights required
4. A desktop shortcut is created automatically

---

## Installing on Other Machines

### Step 1: Copy the installer

Copy `MediaVerseSetup.exe` to the target machine via USB, network share, or any method.

### Step 2: Run the installer

Double-click and follow prompts. Same as above — installs to the user's AppData folder.

### Step 3: Copy sqlCreds.env

The installer does NOT include database credentials. You must manually copy `sqlCreds.env` to the install folder:

```
C:\Users\<username>\AppData\Local\MediaVerse\_internal\sqlCreds.env
```

The file contains your MySQL connection details and AI key:

```
MYSQL_HOST=<your TrueNAS IP>
MYSQL_USER=root
MYSQL_PASSWORD=<your password>
MYSQL_DB=MediaManager
MM2_HOST=<your TrueNAS IP>
MM2_USER=root
MM2_PASSWORD=<your password>
MM2_DB=MediaManager2
GOOGLE_AI_KEY=<your key>
```

Update the IP addresses to match your current router configuration.

### Step 4: Verify W: drive mapping

MediaVerse reads movie files, images, and collections from the W: drive. On each machine, ensure W: is mapped to your TrueNAS share:

```
W:\ --> \\<TrueNAS IP>\<share name>
```

If W: is not mapped, the app will start but show a notification that the server is unreachable.

### Step 5: Verify Config.json

The config file is at:

```
C:\Users\<username>\AppData\Local\MediaVerse\_internal\Assets\Config.json
```

Check that `LibraryRoot` and `JRiverPort` are correct for the target machine. These are usually the same across all machines unless JRiver uses a different port.

---

## After Installation

On first launch, MediaVerse will:

1. Connect to the TrueNAS server via W: drive
2. Build a local image cache (display, thumbnail, carousel) — this takes a few minutes the first time
3. Sync movie metadata from JRiver XML sidecar files
4. Subsequent launches are fast — cache only rebuilds when the library changes

---

## Updating an Existing Install

Simply run `MediaVerseSetup.exe` again on the same machine. It overwrites the previous version in place. Your `sqlCreds.env`, `Config.json`, and local cache are preserved.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| App won't start | Check `~/MediaVerse_crash_log.txt` and `~/MediaVerse_output.log` |
| "Can't connect to MySQL" | Verify IP in `sqlCreds.env` matches your TrueNAS server |
| No movie images | Ensure W: drive is mapped and accessible |
| Collections empty | Check W:\MediaVerse\Collections\ is reachable |
| JRiver not found | Verify JRiver is installed and path is correct in Config.json |

Log files are written to your home folder:

- **Crash log:** `C:\Users\<you>\MediaVerse_crash_log.txt`
- **Runtime log:** `C:\Users\<you>\MediaVerse_output.log`

---

## File Locations Summary

| What | Where |
|------|-------|
| App executable | `C:\Users\<you>\AppData\Local\MediaVerse\MediaVerse.exe` |
| App internals | `C:\Users\<you>\AppData\Local\MediaVerse\_internal\` |
| Config | `..\_internal\Assets\Config.json` |
| Credentials | `..\_internal\sqlCreds.env` |
| Local cache | `..\_internal\cacheV2\images\` |
| Movie metadata | `..\_internal\Assets\xml_collection_data.json` |
| Server manifest | `W:\MediaVerse\manifest\manifest.json` |
| Collections | `W:\MediaVerse\Collections\Movies_Collections_v2.json` |
| Movie files | `W:\Collection\` |
