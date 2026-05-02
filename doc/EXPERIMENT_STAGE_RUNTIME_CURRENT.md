定义:
- `encode_time = frontend_prune + frontend_translate + python_harness_emit`
- `run_time = 模型检查器时间`
  - wraparound case: 使用已认证 `stage1(entry)+stage2(confirm)+stage3(closure)` 合计
  - 非 wraparound case: 从 `out_dir/gemcutter.log` 提取 `OverallTime`（缺失时回退到 `wall_s`）
- `total_time = encode_time + run_time`
- 说明: 按你的要求，wraparound 的额外后端编码开销不单列。

| system | spec | encode slicing(s) | run slicing(s) | total slicing(s) | encode noslicing(s) | run noslicing(s) | total noslicing(s) | total speedup(noslicing/slicing) | wrap stages slicing(e/c/cl) | wrap stages noslicing(e/c/cl) |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| `ATP` | `Procurator/argo/code/spec/bench/atp_bug.prop` | 5.027 | 20.900 | 25.927 | 4.125 | 34.300 | 38.425 | 1.482 | `-` | `-` |
| `ATP` | `Procurator/argo/code/spec/bench/atp_count_mismatch_bug.prop` | 4.676 | 40.500 | 45.176 | 3.914 | 90.000 | 93.914 | 2.079 | `-` | `-` |
| `Cheetah` | `Procurator/argo/code/spec/bench/cheetah_slot_index_collision_bug.prop` | 2.304 | 35.700 | 38.004 | 2.148 | 81.700 | 83.848 | 2.206 | `-` | `-` |
| `DDOSD` | `Procurator/argo/code/spec/bench/ddosd_window_label_collision_bug.prop` | 4.128 | 62.400 | 66.528 | 1.950 | 1665.400 | 1667.350 | 25.062 | `-` | `-` |
| `DistCache` | `Procurator/argo/code/spec/bench/distcache_cm34_write_bug.prop` | 12.215 | 14.900 | 27.115 | 10.235 | 149.000 | 159.235 | 5.873 | `-` | `-` |
| `DistCache` | `Procurator/argo/code/spec/bench/distcache_leaf_pktloss_clone_drop_bug.prop` | 13.043 | 84.900 | 97.943 | 10.578 | NA | NA | 9.476 | `-` | `-` |
| `DistCache` | `Procurator/argo/code/spec/bench/distcache_p2c_spineload_wraparound_bug.prop` | 1.521 | 709.939 | 711.460 | 1.319 | 861.021 | 862.340 | 1.212 | `32.451/571.206/106.282` | `21.200/509.982/329.840` |
| `DistCache` | `Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop` | 1.654 | 445.787 | 447.441 | 1.327 | 540.773 | 542.100 | 1.212 | `80.437/211.613/153.737` | `72.067/343.788/124.919` |
| `DistCache` | `Procurator/argo/code/spec/bench/distcache_spine_cache_frequency_idx_bug.prop` | 7.636 | 54.400 | 62.036 | 7.200 | 244.400 | 251.600 | 4.056 | `-` | `-` |
| `FissLock` | `Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop` | 4.994 | 618.146 | 623.140 | 6.798 | 654.068 | 660.866 | 1.061 | `26.333/441.886/149.928` | `29.363/414.998/209.707` |
| `FRR` | `Procurator/argo/code/spec/bench/frr_bug1_unexpected_mirror.prop` | 3.384 | 11.800 | 15.184 | 2.995 | 15.500 | 18.495 | 1.218 | `-` | `-` |
| `FRR` | `Procurator/argo/code/spec/bench/frr_bug2_state_inconsistency.prop` | 2.993 | 127.200 | 130.193 | 2.292 | 558.900 | 561.192 | 4.310 | `-` | `-` |
| `Gecko` | `Procurator/argo/code/spec/bench/gecko_bug1_timer_loss.prop` | 5.284 | 310.600 | 315.884 | 2.701 | 405.600 | 408.301 | 1.293 | `-` | `-` |
| `Gecko` | `Procurator/argo/code/spec/bench/gecko_bug2_concurrency.prop` | 4.169 | 346.100 | 350.269 | 2.864 | 375.100 | 377.964 | 1.079 | `-` | `-` |
| `Gecko` | `Procurator/argo/code/spec/bench/gecko_bug3_timer_init.prop` | 4.099 | 36.500 | 40.599 | 2.585 | 53.800 | 56.385 | 1.389 | `-` | `-` |
| `NetChain` | `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop` | 3.304 | 374.063 | 377.367 | 3.236 | 787.894 | 791.130 | 2.096 | `18.458/73.553/282.052` | `33.352/242.564/511.977` |
| `NetLock` | `Procurator/argo/code/spec/bench/netlock_pkt_type_bug.prop` | 8.279 | 17.500 | 25.779 | 6.211 | 242.800 | 249.011 | 9.659 | `-` | `-` |
| `NetLock` | `Procurator/argo/code/spec/bench/netlock_pushback_length_in_server_underflow_bug.prop` | 8.502 | 93.500 | 102.002 | 6.075 | 268.600 | 274.675 | 2.693 | `-` | `-` |
| `NetLock` | `Procurator/argo/code/spec/bench/netlock_release_counter_underflow_bug.prop` | 8.806 | 69.800 | 78.606 | 5.880 | 85.300 | 91.180 | 1.160 | `-` | `-` |
| `NetLock` | `Procurator/argo/code/spec/bench/netlock_release_empty_queue_head_bug.prop` | 8.770 | 61.700 | 70.470 | 5.689 | 82.200 | 87.889 | 1.247 | `-` | `-` |
| `NetLock` | `Procurator/argo/code/spec/bench/netlock_release_empty_slots_overflow_bug.prop` | 8.656 | 161.200 | 169.856 | 6.044 | 168.000 | 174.044 | 1.025 | `-` | `-` |
| `P4DB` | `Procurator/argo/code/spec/bench/p4db_damper_threshold_off_by_one_bug.prop` | 1.839 | 10.500 | 12.339 | 2.033 | 17.500 | 19.533 | 1.583 | `-` | `-` |
| `P4DB` | `Procurator/argo/code/spec/bench/p4db_router_ttl_expiry_bug.prop` | 1.807 | 7.600 | 9.407 | 1.611 | 14.300 | 15.911 | 1.691 | `-` | `-` |
| `P4NIS` | `Procurator/argo/code/spec/bench/p4nis_bug1_forwarding_sequence_desync.prop` | 1.796 | 2.700 | 4.496 | 1.750 | 4.500 | 6.250 | 1.390 | `-` | `-` |
| `P4NIS` | `Procurator/argo/code/spec/bench/p4nis_bug2_tunnel_state_leakage.prop` | 1.666 | 11.100 | 12.766 | 1.586 | 14.500 | 16.086 | 1.260 | `-` | `-` |
| `P4xos` | `Procurator/argo/code/spec/bench/p4xos_bug.prop` | 7.281 | 36.100 | 43.381 | 7.035 | NA | NA | 5.656 | `-` | `-` |
| `P4xos` | `Procurator/argo/code/spec/bench/p4xos_dropflag_bug.prop` | 1.367 | 41.900 | 43.267 | 1.260 | 47.400 | 48.660 | 1.125 | `-` | `-` |
| `P4xos` | `Procurator/argo/code/spec/bench/p4xos_majority_quorum_bug.prop` | 1.311 | 948.800 | 950.111 | 1.329 | 786.500 | 787.829 | 0.829 | `-` | `-` |

Raw summary json: `.tmp/procurator/compile_runtime_totaltime_summary.json`
