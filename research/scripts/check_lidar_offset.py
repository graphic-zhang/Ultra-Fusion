#!/usr/bin/env python3
"""
Compare the recording timestamp vs the Livox CustomMsg header stamp for the
first lidar messages of an M3DGR ROS1 bag (checks the converter's time base).

Usage: python3 check_lidar_offset.py <Occlusion01.bag>
"""

import sys
from pathlib import Path

from rosbags.highlevel import AnyReader


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    path = Path(sys.argv[1])
    topic = "/livox/mid360/lidar"
    start_ts: int | None = None
    count = 0
    with AnyReader([path]) as reader:
        for conn, ts, raw in reader.messages():
            if conn.topic != topic:
                continue
            if start_ts is None:
                start_ts = ts
            msg = reader.deserialize(raw, conn.msgtype)
            header_ns = int(msg.header.stamp.sec) * 1_000_000_000 + int(
                msg.header.stamp.nanosec
            )
            diff = (ts - header_ns) / 1e9
            rel = (ts - start_ts) / 1e9
            if count < 5 or 9.5 < rel < 10.5 or rel > 29.0:
                print(
                    f"record={ts/1e9:.6f} header={header_ns/1e9:.6f} "
                    f"diff(record-header)={diff:+.6f}s rel={rel:.2f}s"
                )
            count += 1
            if rel > 30:
                break


if __name__ == "__main__":
    main()
