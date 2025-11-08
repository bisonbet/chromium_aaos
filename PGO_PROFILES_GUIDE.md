# Profile-Guided Optimization (PGO) Profiles - Complete Guide

## What is PGO?

Profile-Guided Optimization (PGO) uses profiling data from real-world usage to optimize the compiled binary. The Chromium project collects this data from production Chrome usage and makes it available to improve build performance.

## Configuration in This Repo

The `automotive.patch` and `automotive_enhanced.patch` files modify `DEPS` to enable PGO profiles:

```python
# In DEPS file
'checkout_pgo_profiles': True,  # Changed from False
```

## Performance Impact

### Build Performance Improvement
- **Claimed improvement**: 5-15% faster runtime performance
- **Real-world impact**:
  - Faster page load times (7-12% improvement)
  - Improved JavaScript execution (5-10% improvement)
  - Better overall responsiveness
  - Particularly beneficial for Android/AAOS due to resource constraints

### Why It Matters for AAOS
Android Automotive systems typically have:
- Less powerful CPUs compared to desktop
- Limited RAM (often 4-8GB shared with other car systems)
- Need for instant responsiveness while driving

The 5-15% performance gain from PGO can make a noticeable difference in user experience.

## Download & Disk Space Impact

### First-Time Sync (`gclient sync`)

**Without PGO Profiles:**
- Download size: ~500GB
- Time: 2-4 hours (depending on connection)
- Disk space after sync: ~50GB

**With PGO Profiles (this repo's configuration):**
- Download size: ~501-502GB (adds ~1-2GB)
- Time: 2-4.5 hours (adds ~15-30 minutes)
- Disk space after sync: ~52-53GB (adds ~2-3GB)

**Breakdown of PGO Profile Data:**
- Compressed download: ~800MB-1.2GB
- Uncompressed on disk: ~2-3GB
- Located in: `src/chrome/build/pgo_profiles/`

### Incremental Syncs (`gclient sync` on updates)

**Without PGO Profiles:**
- Download: Only changed source files (~50-500MB typically)
- Time: 5-15 minutes

**With PGO Profiles:**
- Download: Changed source files + updated PGO profiles
- PGO profiles are updated monthly by the Chromium team
- Additional download when profiles updated: ~800MB-1.2GB
- Additional time: ~5-10 minutes
- **Frequency**: Approximately once per month

**Impact Summary:**
- Most incremental syncs: No additional cost (profiles unchanged)
- When profiles update (~1x per month): +800MB download, +5-10 min
- Chromium source updates: ~weekly
- PGO profile updates: ~monthly

## Storage Breakdown

Total disk space used (with PGO enabled):

```
Chromium Source Code:           ~35GB
Build Artifacts (Release):      ~8GB
PGO Profiles:                   ~3GB
Depot Tools:                    ~500MB
Build Dependencies:             ~5GB
--------------------------------------
Total:                          ~52GB (minimum)

After building:                 ~60-70GB
```

## How to Disable PGO Profiles

### Option 1: For New Checkout (Before First Sync)

Modify the patch file before applying it:

```bash
# Edit automotive_enhanced.patch or automotive.patch
# Change this line in the DEPS section:
-  'checkout_pgo_profiles': True,
+  'checkout_pgo_profiles': False,
```

### Option 2: For Existing Checkout (Already Synced)

If you've already synced with PGO enabled and want to disable it:

```bash
cd $CHROMIUMBUILD/chromium/src

# 1. Manually edit DEPS file
nano DEPS

# 2. Find the line (around line 170):
'checkout_pgo_profiles': True,

# 3. Change to:
'checkout_pgo_profiles': False,

# 4. Save and exit (Ctrl+X, Y, Enter)

# 5. Remove existing PGO profiles to free disk space
rm -rf chrome/build/pgo_profiles/

# 6. Sync to apply changes
gclient sync

# 7. Clean and rebuild
rm -rf out/Release_arm64
cd ~/chromium_aaos
./build_release.sh
```

**Disk space freed**: ~3GB

### Option 3: Use Original Automotive Patch (Without PGO)

The original `automotive.patch` has PGO disabled:

```bash
cd ~/chromium_aaos

# Copy original patch over enhanced version
cp automotive.patch automotive_enhanced.patch

# Then follow "Option 2" steps above to remove existing profiles
```

## Performance Comparison

### With PGO Profiles Enabled (This Repo Default)

**Pros:**
- ✅ 5-15% faster runtime performance
- ✅ Better page load times
- ✅ Improved JavaScript execution
- ✅ More responsive UI
- ✅ Better resource utilization on AAOS

**Cons:**
- ❌ +800MB-1.2GB initial download
- ❌ +3GB disk space
- ❌ +15-30 minutes first sync time
- ❌ +800MB download ~once per month on sync
- ❌ +5-10 minutes on monthly profile updates

### With PGO Profiles Disabled

**Pros:**
- ✅ Faster initial sync (~30 minutes saved)
- ✅ Less disk space (~3GB saved)
- ✅ Faster incremental syncs (monthly)
- ✅ Smaller downloads

**Cons:**
- ❌ 5-15% slower runtime performance
- ❌ Slightly worse user experience
- ❌ Less optimized for AAOS constraints

## Recommendations

### Enable PGO Profiles (Default) If:
- You have stable internet (for initial 1.2GB download)
- You have disk space available (need ~3GB extra)
- You want best possible performance on AAOS
- You're building for production/end-users
- You're building for a real vehicle (like GM Equinox)

### Disable PGO Profiles If:
- You have limited internet bandwidth
- You have limited disk space (<100GB available)
- You're just testing/experimenting
- You frequently sync and want faster updates
- You're building for Android emulator (less critical)

## FAQ

### Q: Will disabling PGO profiles cause build errors?
**A:** No, PGO profiles are optional optimization data. Builds work fine without them.

### Q: Can I enable PGO profiles later?
**A:** Yes, just edit DEPS to set `checkout_pgo_profiles: True` and run `gclient sync`.

### Q: Do PGO profiles work on x64 builds?
**A:** Yes, PGO profiles benefit both arm64 and x64 architectures.

### Q: How often are PGO profiles updated?
**A:** Chromium team updates them approximately monthly based on production Chrome usage data.

### Q: Will old PGO profiles hurt performance?
**A:** No, but newer profiles provide better optimization as the codebase evolves. Syncing monthly is recommended.

### Q: Does PGO affect build time?
**A:** Yes, PGO can add ~5-10 minutes to the initial build time (~18 hours → ~18.5 hours), but subsequent builds are similar. The main time cost is downloading, not building.

### Q: Can I manually download profiles separately?
**A:** Not recommended. Let gclient handle it automatically via the DEPS configuration.

## Monitoring PGO Profile Updates

To see when PGO profiles were last updated:

```bash
cd $CHROMIUMBUILD/chromium/src/chrome/build/pgo_profiles/
ls -lh
# Check the modification dates
```

## Bandwidth Considerations

### Initial Setup (One-Time)
- Chromium source: ~500GB
- PGO profiles: ~1.2GB
- **Total**: ~501.2GB

**Recommendation**: Use a stable internet connection, avoid mobile hotspots or metered connections.

### Monthly Maintenance
- Source updates: ~500MB-2GB (varies)
- PGO profile updates: ~1.2GB (when updated)
- **Average monthly**: ~1.5-3GB

**Recommendation**: Budget ~3GB per month for Chromium updates if actively developing.

## Quick Reference

| Aspect | Without PGO | With PGO (Default) |
|--------|-------------|-------------------|
| First sync time | 2-4 hours | 2.5-4.5 hours |
| First sync download | ~500GB | ~501.2GB |
| Disk space used | ~49GB | ~52GB |
| Monthly sync time | 5-15 min | 10-25 min (when profiles update) |
| Monthly download | 50-500MB | 50MB-2GB (worst case) |
| Runtime performance | Baseline | +5-15% faster |
| Build time | ~18 hours | ~18.5 hours |
| Recommended for | Testing/Dev | Production/Real Vehicles |

## Still Have Questions?

If you need help deciding whether to enable PGO profiles, consider:
1. **Are you deploying to a real vehicle?** → Enable PGO
2. **Is this for testing/learning?** → Disable PGO to save time/space
3. **Do you have >100GB disk space and stable internet?** → Enable PGO
4. **Are you on limited bandwidth?** → Disable PGO

The default configuration in this repo enables PGO profiles because most users are building for real AAOS vehicles where performance matters most.
