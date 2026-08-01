#!/usr/bin/env python3
"""
Print the first few message timestamps per topic of a ROS1 or ROS2 bag.

Usage: python3 check_bag_first_stamps.py <bag_path_or_dir>
"""

import sys
from pathlib import Path

from rosbags.highlevel import AnyReader


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    path = Path(sys.argv[1])

    seen: list[tuple[str, float]] = []
    with AnyReader([path]) as reader:
        for conn, ts, _ in reader.messages():
            seen.append((conn.topic, ts))
            if len(seen) >= 15:
                break

    print(f"{'topic':<45} {'stamp (s from epoch)':>22} {'t-bag0':>10}")
    t0 = seen[0][1] if seen else 0
    for topic, ts in seen:
        print(f"{topic:<45} {ts/1e9:>22.6f} {(ts-t0)/1e9:>10.3f}")


if __name__ == "__main__":
    main()
