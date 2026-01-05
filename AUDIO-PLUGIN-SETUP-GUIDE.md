# Audio Plugin Setup Guide for REAPER with Wine

This guide covers installing Windows VST plugins (Amplitube 5, SSD5) with copy protection (iLok, IK Product Manager) on NixOS with yabridge.

## System Status

- ✅ Wine 9.20 (Staging) - Correctly configured
- ✅ WINEPREFIX: `~/.wine-audio`
- ✅ Yabridge 5.1.1 - Installed and configured
- ✅ DXVK - Installed
- ✅ DirectX dependencies - Installed
- ✅ Visual C++ runtimes - Installed
- ✅ .NET Framework 4.8 - Installed

## Current Plugin Status

### Amplitube 5
- **Location**: `~/.wine-audio/drive_c/Program Files/Common Files/VST3/AmpliTube 5.vst3`
- **Yabridge**: Synced ✅
- **REAPER**: Shows up but crashes ❌
- **Issue**: Missing IK Product Manager authorization
- **Solution**: Install IK Product Manager and authorize

### SSD5 (Steven Slate Drums)
- **Location**: `~/.wine-audio/drive_c/Program Files/Common Files/VST3/SSDSampler5.vst3`
- **Yabridge**: Synced ✅
- **REAPER**: Not showing up ❌
- **Issue**: Missing iLok License Manager or not authorized
- **Solution**: Install iLok License Manager and authorize

## Step-by-Step Installation

### 1. Install iLok License Manager (for SSD5)

```bash
# Download from https://www.ilok.com/#!license-manager
# Get the Windows version

# Install with audio-wine helper
audio-wine ~/Downloads/iLok_License_Manager_Installer_*.exe

# Follow the installer prompts
# Important: Use default installation path

# After installation, run iLok License Manager
audio-wine ~/.wine-audio/drive_c/Program\ Files/PACE\ Anti-Piracy/iLok\ License\ Manager/iLok\ License\ Manager.exe

# Login with your iLok account and activate SSD5 license
```

**Troubleshooting iLok**:
- If cloud authorization fails, use a **physical iLok USB dongle** (more reliable)
- iLok v4.x works better than v5.x in Wine
- Make sure iLok service is running: check in Task Manager

### 2. Install IK Product Manager (for Amplitube 5)

```bash
# Download from https://www.ikmultimedia.com/products/productmanager/
# Get the Windows version

# Install with audio-wine helper
audio-wine ~/Downloads/IK_Product_Manager_*.exe

# Follow the installer prompts
# Important: Use default installation path

# After installation, run IK Product Manager
audio-wine ~/.wine-audio/drive_c/Program\ Files\ \(x86\)/IK\ Multimedia/IK\ Product\ Manager/IK\ Product\ Manager.exe

# Login with your IK Multimedia account
# Authorize Amplitube 5
```

**IK Product Manager Notes**:
- May need to install plugins through Product Manager
- Product Manager installs licensing DLLs that Amplitube needs
- If it crashes, try: `audio-winetricks msxml3 msxml4`

### 3. Re-sync Yabridge

After installing authorization software:

```bash
# Sync yabridge
yabridgectl sync

# Check status
yabridgectl status

# Verify plugins show up
ls -la ~/.vst/yabridge/SSD*.so
ls -la ~/.vst3/yabridge/SSD*.vst3
ls -la ~/.vst3/yabridge/AmpliTube*.vst3
```

### 4. Configure REAPER

1. **Open REAPER**
2. **Go to**: Options → Preferences → Plug-ins → VST
3. **Ensure these paths are scanned**:
   - `~/.vst`
   - `~/.vst3`
4. **Click**: "Re-scan" or "Clear cache and re-scan"
5. **Wait** for scan to complete

### 5. Test Plugins

```bash
# Test with debug output
YABRIDGE_DEBUG_LEVEL=1 reaper
```

**Expected output for working plugin**:
```
[PluginName-XXXXX] Initializing yabridge version 5.1.1
[PluginName-XXXXX] wine version: '9.20 (Staging)'
[PluginName-XXXXX] Finished initializing
```

**If you see errors**:
- `LoadLibrary failed: Module not found` → Missing authorization software
- `version mismatch` → Run `wineserver -k` and try again
- Plugin crashes → Check authorization status in iLok/IK Product Manager

## Common Issues & Solutions

### Issue: "Module not found" error

**Cause**: Missing authorization DLLs

**Solution**:
1. Install iLok License Manager (for iLok-protected plugins)
2. Install IK Product Manager (for IK Multimedia plugins)
3. Authorize plugins through respective managers
4. Re-sync yabridge

### Issue: Plugin doesn't show in REAPER

**Possible causes**:
1. REAPER hasn't scanned the plugin directories
2. Plugin failed to load during scan (check REAPER scan log)
3. Plugin not properly authorized

**Solution**:
```bash
# Check yabridge status
yabridgectl status

# Re-sync
yabridgectl sync

# Launch REAPER and check scan log
YABRIDGE_DEBUG_LEVEL=1 reaper

# In REAPER: Options → Preferences → Plug-ins → VST → View scan log
```

### Issue: Wine version mismatch

**Error**: `wine client error:0: version mismatch`

**Solution**:
```bash
# Kill all Wine processes
~/.wine-audio/dosdevices/c:/windows/system32/wineserver -k

# Or use the Wine 9.20 wineserver directly
/nix/store/77283s7aakc5b9ljm83mfa3ia5mfb9pf-wine-wow-staging-9.20/bin/wineserver -k

# Wait 10 seconds, then try again
```

### Issue: GUI doesn't render or is blank

**Cause**: Missing DXVK or GPU drivers

**Solution**:
```bash
# Verify DXVK is installed
audio-winetricks list-installed | grep dxvk

# If not installed:
audio-winetricks dxvk

# Verify Vulkan works
vulkaninfo | head -20
```

### Issue: Plugin crashes with "terminate called without an active exception"

**Cause**: Missing dependencies or authorization failure

**Solution**:
1. Check if authorization software is installed and running
2. Try installing additional dependencies:
```bash
audio-winetricks vcrun2015 vcrun2017
```

## Plugin-Specific Notes

### SSD5 (Steven Slate Drums)
- **Authorization**: iLok (cloud or USB dongle)
- **File type**: Legacy VST3 (single .vst3 file, not bundle)
- **Known issues**: None reported with proper iLok setup
- **Recommended**: Use physical iLok USB dongle for best reliability

### Amplitube 5
- **Authorization**: IK Product Manager (online activation)
- **File type**: VST3 bundle (directory structure)
- **Known issues**: Requires IK Product Manager to be installed FIRST
- **Dependencies**: IK authorization DLLs installed by Product Manager
- **Note**: Plugin will not load at all without Product Manager installed

## Debugging Commands

```bash
# Check Wine version
audio-wine --version

# Test Wine is working
audio-wine cmd /c echo Hello

# Check installed winetricks
audio-winetricks list-installed

# Kill all Wine processes
/nix/store/77283s7aakc5b9ljm83mfa3ia5mfb9pf-wine-wow-staging-9.20/bin/wineserver -k

# Check yabridge configuration
cat ~/.vst/yabridge/yabridge.toml
cat ~/.vst3/yabridge/yabridge.toml

# View yabridge status
yabridgectl status
```

## Environment Variables Reference

Set by the REAPER wrapper automatically:
- `WINELOADER`: Points to Wine 9.20 binary
- `WINESERVER`: Points to Wine 9.20 wineserver
- `WINEARCH`: win64
- `WINEFSYNC`: 1 (enable fsync)
- `DXVK_HUD`: 0 (disable overlay)

## Additional Resources

- **Yabridge Documentation**: https://github.com/robbert-vdh/yabridge
- **Yabridge Known Issues**: https://github.com/robbert-vdh/yabridge#known-issues-and-fixes
- **WineHQ**: https://www.winehq.org/
- **iLok Support**: https://www.ilok.com/support/
- **IK Multimedia Support**: https://www.ikmultimedia.com/support/

## Next Steps

1. ✅ Install iLok License Manager
2. ✅ Install IK Product Manager  
3. ✅ Authorize plugins through respective managers
4. ✅ Re-sync yabridge
5. ✅ Clear REAPER plugin cache and rescan
6. ✅ Test plugins in REAPER

---

**Note**: Copy protection software in Wine is notoriously unreliable. If authorization continues to fail:
- Use physical iLok USB dongle instead of cloud authorization
- Try older versions of authorization software (iLok v4.x)
- Consider testing plugins on a Windows machine first to verify licenses are valid
- Some plugins may simply not work in Wine due to anti-piracy measures
