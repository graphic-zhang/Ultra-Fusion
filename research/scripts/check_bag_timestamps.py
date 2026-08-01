#!/usr/bin/env python3
"""
Print per-topic message counts and timestamp coverage of a ROS2 bag,
highlighting gaps > 0.05 s.

Usage: python3 check_bag_timestamps.py <ros2_bag_dir>
"""

import sys
from pathlib import Path

from rosbags.rosbag2 import Reader


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    bag = Path(sys.argv[1])
    stamps: dict[str, list[int]] = {}
    with Reader(bag) as reader:
        for conn in reader.connections:
            print(f"topic {conn.topic} ({conn.msgtype})")
        for conn, ts, _ in reader.messages():
            stamps.setdefault(conn.topic, []).append(ts)

    print()
    for topic, arr in sorted(stamps.items()):
        arr.sort()
        span = (arr[-1] - arr[0]) / 1e9
        rate = len(arr) / span if span > 0 else 0
        gaps = [
            (arr[i + 1] - arr[i]) / 1e9
            for i in range(len(arr) - 1)
            if arr[i + 1] - arr[i] > 50_000_000
        ]
        print(
            f"{topic}\n"
            f"  count={len(arr)} first={arr[0]/1e9:.3f}s last={arr[-1]/1e9:.3f}s "
            f"span={span:.3f}s avg_rate={rate:.1f}Hz\n"
            f"  gaps>0.05s: {len(gaps)} -> {[f'{g:.2f}' for g in gaps[:8]]}"
        )


if __name__ == "__main__":
    main()
