# Core 28 Casewise Reproduction Evidence (2026-07-04)

## Scope

This file records the 2026-07-04 reproduction pass for the 28 curated E2E benchmarks. Each benchmark was run case by case and mode by mode: `slicing` first, then `noslicing`. The combined checker input was assembled from the per-case JSON files; `artifact/scripts/run_core_28.sh` was not used to launch all cases together.

Fail-closed rule: `TIMEOUT`, `UNKNOWN`, OOM, toolchain `ERROR`, missing witness, and unverified `SAFE` are inconclusive and are not counted as bug absence. No such inconclusive result appears in this pass.

## Verification

- Source checkout: recorded in the archived actual JSON and result manifest
- Python: `.venv-wsl/bin/python3`
- Ultimate: pinned GemCutter runtime installed by `artifact/scripts/setup_gemcutter.sh`
- Archived evidence root: `artifact/results/core_28/e/`
- Archived result manifest: `artifact/results/core_28/MANIFEST.json`
- Archived per-case actual JSON root: `artifact/results/core_28/cases/`
- Archived combined checker input: `artifact/results/core_28/core_28.casewise.actual.json`
- Checker command: `PYTHONPATH=src:src/p4b/python .venv-wsl/bin/python3 artifact/scripts/check_expected.py --expected artifact/expected/core_28.expected.json --actual artifact/results/core_28/core_28.casewise.actual.json`
- Checker result: `expected check passed`

## Summary

- Curated benchmarks: `28`
- Required modes per benchmark: `slicing`, `noslicing`
- Actual result files checked: `56`
- Missing result files: `0`
- Non-UNSAFE / inconclusive modes: `0`

## Case Table

| # | benchmark | mode | category | status | sanity | wall_s | run_id | evidence |
|---:|---|---|---|---|---|---:|---|---|
| 1 | `netchain_wraparound_bug` | `slicing` | `wraparound` | `UNSAFE` | `OK` | 100.7 | `20260704-071632-dee1` | `artifact/results/core_28/e/netchain_wraparound_bug/20260704-071632-dee1` |
| 1 | `netchain_wraparound_bug` | `noslicing` | `wraparound` | `UNSAFE` | `OK` | 271.3 | `20260704-071815-3352` | `artifact/results/core_28/e/netchain_wraparound_bug/20260704-071815-3352` |
| 2 | `distcache_p2c_spineload_wraparound_bug` | `slicing` | `wraparound` | `UNSAFE` | `OK` | 720.4 | `20260704-072244-0a31` | `artifact/results/core_28/e/distcache_p2c_spineload_wraparound_bug/20260704-072244-0a31` |
| 2 | `distcache_p2c_spineload_wraparound_bug` | `noslicing` | `wraparound` | `UNSAFE` | `OK` | 1711.6 | `20260704-075603-a400` | `artifact/results/core_28/e/distcache_p2c_spineload_wraparound_bug/20260704-075603-a400` |
| 3 | `distcache_p2c_wraparound_bug` | `slicing` | `wraparound` | `UNSAFE` | `OK` | 174.6 | `20260704-082337-6391` | `artifact/results/core_28/e/distcache_p2c_wraparound_bug/20260704-082337-6391` |
| 3 | `distcache_p2c_wraparound_bug` | `noslicing` | `wraparound` | `UNSAFE` | `OK` | 219.2 | `20260704-082633-cdbf` | `artifact/results/core_28/e/distcache_p2c_wraparound_bug/20260704-082633-cdbf` |
| 4 | `fisslock_notification_cnt_wraparound_bug` | `slicing` | `wraparound` | `UNSAFE` | `OK` | 223.3 | `20260704-083014-0068` | `artifact/results/core_28/e/fisslock_notification_cnt_wraparound_bug/20260704-083014-0068` |
| 4 | `fisslock_notification_cnt_wraparound_bug` | `noslicing` | `wraparound` | `UNSAFE` | `OK` | 322.9 | `20260704-083359-8d58` | `artifact/results/core_28/e/fisslock_notification_cnt_wraparound_bug/20260704-083359-8d58` |
| 5 | `atp_bug` | `slicing` | `implementation` | `UNSAFE` | `OK` | 19.9 | `20260704-083932-6be3` | `artifact/results/core_28/e/atp_bug/20260704-083932-6be3` |
| 5 | `atp_bug` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 48.5 | `20260704-084006-ceee` | `artifact/results/core_28/e/atp_bug/20260704-084006-ceee` |
| 6 | `atp_count_mismatch_bug` | `slicing` | `functional` | `UNSAFE` | `OK` | 26.0 | `20260704-084101-c6ef` | `artifact/results/core_28/e/atp_count_mismatch_bug/20260704-084101-c6ef` |
| 6 | `atp_count_mismatch_bug` | `noslicing` | `functional` | `UNSAFE` | `OK` | 95.0 | `20260704-084139-fd0e` | `artifact/results/core_28/e/atp_count_mismatch_bug/20260704-084139-fd0e` |
| 7 | `distcache_leaf_pktloss_clone_drop_bug` | `slicing` | `functional` | `UNSAFE` | `OK` | 7.2 | `20260704-084321-6ab1` | `artifact/results/core_28/e/distcache_leaf_pktloss_clone_drop_bug/20260704-084321-6ab1` |
| 7 | `distcache_leaf_pktloss_clone_drop_bug` | `noslicing` | `functional` | `UNSAFE` | `OK` | 23.1 | `20260704-084336-79db` | `artifact/results/core_28/e/distcache_leaf_pktloss_clone_drop_bug/20260704-084336-79db` |
| 8 | `distcache_cm34_write_bug` | `slicing` | `implementation` | `UNSAFE` | `OK` | 8.6 | `20260704-084409-fa2b` | `artifact/results/core_28/e/distcache_cm34_write_bug/20260704-084409-fa2b` |
| 8 | `distcache_cm34_write_bug` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 66.6 | `20260704-084427-4de3` | `artifact/results/core_28/e/distcache_cm34_write_bug/20260704-084427-4de3` |
| 9 | `distcache_spine_cache_frequency_idx_bug` | `slicing` | `implementation` | `UNSAFE` | `OK` | 2.5 | `20260704-084542-7984` | `artifact/results/core_28/e/distcache_spine_cache_frequency_idx_bug/20260704-084542-7984` |
| 9 | `distcache_spine_cache_frequency_idx_bug` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 11.8 | `20260704-084556-bc3b` | `artifact/results/core_28/e/distcache_spine_cache_frequency_idx_bug/20260704-084556-bc3b` |
| 10 | `ddosd_window_label_collision_bug` | `slicing` | `implementation` | `UNSAFE` | `OK` | 1.7 | `20260704-084616-20a8` | `artifact/results/core_28/e/ddosd_window_label_collision_bug/20260704-084616-20a8` |
| 10 | `ddosd_window_label_collision_bug` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 1.8 | `20260704-084903-e316` | `artifact/results/core_28/e/ddosd_window_label_collision_bug/20260704-084903-e316` |
| 11 | `frr_bug1_unexpected_mirror` | `slicing` | `implementation` | `UNSAFE` | `OK` | 23.2 | `20260704-084919-7dda` | `artifact/results/core_28/e/frr_bug1_unexpected_mirror/20260704-084919-7dda` |
| 11 | `frr_bug1_unexpected_mirror` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 25.3 | `20260704-084948-8bc9` | `artifact/results/core_28/e/frr_bug1_unexpected_mirror/20260704-084948-8bc9` |
| 12 | `frr_bug2_state_inconsistency` | `slicing` | `interleaving` | `UNSAFE` | `OK` | 51.1 | `20260704-085020-caa5` | `artifact/results/core_28/e/frr_bug2_state_inconsistency/20260704-085020-caa5` |
| 12 | `frr_bug2_state_inconsistency` | `noslicing` | `interleaving` | `UNSAFE` | `OK` | 174.9 | `20260704-085117-2323` | `artifact/results/core_28/e/frr_bug2_state_inconsistency/20260704-085117-2323` |
| 13 | `p4nis_bug1_forwarding_sequence_desync` | `slicing` | `interleaving` | `UNSAFE` | `OK` | 0.6 | `20260704-085410-e9e4` | `artifact/results/core_28/e/p4nis_bug1_forwarding_sequence_desync/20260704-085410-e9e4` |
| 13 | `p4nis_bug1_forwarding_sequence_desync` | `noslicing` | `interleaving` | `UNSAFE` | `OK` | 0.7 | `20260704-085420-f905` | `artifact/results/core_28/e/p4nis_bug1_forwarding_sequence_desync/20260704-085420-f905` |
| 14 | `p4nis_bug2_tunnel_state_leakage` | `slicing` | `functional` | `UNSAFE` | `OK` | 20.6 | `20260704-085429-61ea` | `artifact/results/core_28/e/p4nis_bug2_tunnel_state_leakage/20260704-085429-61ea` |
| 14 | `p4nis_bug2_tunnel_state_leakage` | `noslicing` | `functional` | `UNSAFE` | `OK` | 24.7 | `20260704-085457-2f18` | `artifact/results/core_28/e/p4nis_bug2_tunnel_state_leakage/20260704-085457-2f18` |
| 15 | `gecko_bug1_timer_loss` | `slicing` | `functional` | `UNSAFE` | `OK` | 267.3 | `20260704-085532-bf1f` | `artifact/results/core_28/e/gecko_bug1_timer_loss/20260704-085532-bf1f` |
| 15 | `gecko_bug1_timer_loss` | `noslicing` | `functional` | `UNSAFE` | `OK` | 313.9 | `20260704-085958-40ae` | `artifact/results/core_28/e/gecko_bug1_timer_loss/20260704-085958-40ae` |
| 16 | `gecko_bug2_concurrency` | `slicing` | `interleaving` | `UNSAFE` | `OK` | 162.9 | `20260704-090503-47c8` | `artifact/results/core_28/e/gecko_bug2_concurrency/20260704-090503-47c8` |
| 16 | `gecko_bug2_concurrency` | `noslicing` | `interleaving` | `UNSAFE` | `OK` | 181.5 | `20260704-090752-9393` | `artifact/results/core_28/e/gecko_bug2_concurrency/20260704-090752-9393` |
| 17 | `gecko_bug3_timer_init` | `slicing` | `implementation` | `UNSAFE` | `OK` | 4.7 | `20260704-091055-9e1c` | `artifact/results/core_28/e/gecko_bug3_timer_init/20260704-091055-9e1c` |
| 17 | `gecko_bug3_timer_init` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 4.1 | `20260704-091108-69bb` | `artifact/results/core_28/e/gecko_bug3_timer_init/20260704-091108-69bb` |
| 18 | `p4xos_bug` | `slicing` | `implementation` | `UNSAFE` | `OK` | 41.6 | `20260704-091121-9221` | `artifact/results/core_28/e/p4xos_bug/20260704-091121-9221` |
| 18 | `p4xos_bug` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 124.4 | `20260704-091208-4480` | `artifact/results/core_28/e/p4xos_bug/20260704-091208-4480` |
| 19 | `p4xos_dropflag_bug` | `slicing` | `implementation` | `UNSAFE` | `OK` | 45.4 | `20260704-091416-d085` | `artifact/results/core_28/e/p4xos_dropflag_bug/20260704-091416-d085` |
| 19 | `p4xos_dropflag_bug` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 55.0 | `20260704-091510-8dac` | `artifact/results/core_28/e/p4xos_dropflag_bug/20260704-091510-8dac` |
| 20 | `p4xos_majority_quorum_bug` | `slicing` | `interleaving` | `UNSAFE` | `OK` | 948.7 | `20260704-091611-52a8` | `artifact/results/core_28/e/p4xos_majority_quorum_bug/20260704-091611-52a8` |
| 20 | `p4xos_majority_quorum_bug` | `noslicing` | `interleaving` | `UNSAFE` | `OK` | 986.3 | `20260704-093126-b6c5` | `artifact/results/core_28/e/p4xos_majority_quorum_bug/20260704-093126-b6c5` |
| 21 | `cheetah_slot_index_collision_bug` | `slicing` | `implementation` | `UNSAFE` | `OK` | 1.1 | `20260704-094720-bf43` | `artifact/results/core_28/e/cheetah_slot_index_collision_bug/20260704-094720-bf43` |
| 21 | `cheetah_slot_index_collision_bug` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 0.9 | `20260704-094728-f620` | `artifact/results/core_28/e/cheetah_slot_index_collision_bug/20260704-094728-f620` |
| 22 | `netlock_pkt_type_bug` | `slicing` | `implementation` | `UNSAFE` | `OK` | 50.4 | `20260704-094738-9572` | `artifact/results/core_28/e/netlock_pkt_type_bug/20260704-094738-9572` |
| 22 | `netlock_pkt_type_bug` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 46.7 | `20260704-094838-9bd9` | `artifact/results/core_28/e/netlock_pkt_type_bug/20260704-094838-9bd9` |
| 23 | `netlock_pushback_length_in_server_underflow_bug` | `slicing` | `implementation` | `UNSAFE` | `OK` | 35.6 | `20260704-094932-6705` | `artifact/results/core_28/e/netlock_pushback_length_in_server_underflow_bug/20260704-094932-6705` |
| 23 | `netlock_pushback_length_in_server_underflow_bug` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 88.5 | `20260704-095014-411a` | `artifact/results/core_28/e/netlock_pushback_length_in_server_underflow_bug/20260704-095014-411a` |
| 24 | `netlock_release_counter_underflow_bug` | `slicing` | `implementation` | `UNSAFE` | `OK` | 2.8 | `20260704-071019-82dd` | `artifact/results/core_28/e/netlock_release_counter_underflow_bug/20260704-071019-82dd` |
| 24 | `netlock_release_counter_underflow_bug` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 5.4 | `20260704-071005-23ea` | `artifact/results/core_28/e/netlock_release_counter_underflow_bug/20260704-071005-23ea` |
| 25 | `netlock_release_empty_queue_head_bug` | `slicing` | `functional` | `UNSAFE` | `OK` | 2.7 | `20260704-071201-e320` | `artifact/results/core_28/e/netlock_release_empty_queue_head_bug/20260704-071201-e320` |
| 25 | `netlock_release_empty_queue_head_bug` | `noslicing` | `functional` | `UNSAFE` | `OK` | 5.5 | `20260704-071213-cb25` | `artifact/results/core_28/e/netlock_release_empty_queue_head_bug/20260704-071213-cb25` |
| 26 | `netlock_release_empty_slots_overflow_bug` | `slicing` | `implementation` | `UNSAFE` | `OK` | 2.5 | `20260704-071228-c3fa` | `artifact/results/core_28/e/netlock_release_empty_slots_overflow_bug/20260704-071228-c3fa` |
| 26 | `netlock_release_empty_slots_overflow_bug` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 5.3 | `20260704-071239-ef78` | `artifact/results/core_28/e/netlock_release_empty_slots_overflow_bug/20260704-071239-ef78` |
| 27 | `p4db_router_ttl_expiry_bug` | `slicing` | `implementation` | `UNSAFE` | `OK` | 0.5 | `20260704-071254-01c5` | `artifact/results/core_28/e/p4db_router_ttl_expiry_bug/20260704-071254-01c5` |
| 27 | `p4db_router_ttl_expiry_bug` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 0.5 | `20260704-071301-74f9` | `artifact/results/core_28/e/p4db_router_ttl_expiry_bug/20260704-071301-74f9` |
| 28 | `p4db_damper_threshold_off_by_one_bug` | `slicing` | `implementation` | `UNSAFE` | `OK` | 0.6 | `20260704-071315-ec44` | `artifact/results/core_28/e/p4db_damper_threshold_off_by_one_bug/20260704-071315-ec44` |
| 28 | `p4db_damper_threshold_off_by_one_bug` | `noslicing` | `implementation` | `UNSAFE` | `OK` | 0.8 | `20260704-071326-f6f7` | `artifact/results/core_28/e/p4db_damper_threshold_off_by_one_bug/20260704-071326-f6f7` |

## Notes

- Wraparound cases are counted only when their per-case validator accepted the wraparound certification manifest.
- Bounded DSL replay rows are under-approximate `UNSAFE` evidence only for the violated final guard recorded in their textual replay log.
- Profile overrides such as `ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf` remain in the per-case actual JSON command records.
