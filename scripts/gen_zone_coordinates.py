#!/usr/bin/env python3
"""Regenerates lib/services/zone_coordinates.dart from the system tz database.

Each IANA zone gets the coordinates of its principal city from zone1970.tab;
link names (old aliases devices still report) map to their target's city.
"""
import os
import re

ZONEINFO = '/usr/share/zoneinfo'


def iso6709(s):
    sign = -1 if s[0] == '-' else 1
    s = s[1:]
    if len(s) in (4, 5):
        d = len(s) - 2
        deg, mins, sec = int(s[:d]), int(s[d:]), 0
    else:
        d = len(s) - 4
        deg, mins, sec = int(s[:d]), int(s[d:d + 2]), int(s[d + 2:])
    return sign * (deg + mins / 60 + sec / 3600)


rows = {}
for line in open(os.path.join(ZONEINFO, 'zone1970.tab')):
    if line.startswith('#'):
        continue
    _, coord, tz = line.rstrip('\n').split('\t')[:3]
    m = re.match(r'([+-]\d+)([+-]\d+)$', coord)
    rows[tz] = (round(iso6709(m.group(1)), 2), round(iso6709(m.group(2)), 2))

zi = os.path.join(ZONEINFO, 'tzdata.zi')
if os.path.exists(zi):
    for line in open(zi):
        if line.startswith('L '):
            _, target, name = line.split()
            if target in rows and name not in rows and '/' in name:
                rows[name] = rows[target]

out = [
    "// GENERATED from the tz database's zone1970.tab (and its links) by",
    "// scripts/gen_zone_coordinates.py. Do not edit by hand.",
    "",
    "/// Representative coordinates (latitude, longitude) for IANA time zones,",
    "/// used as the default location for sunrise and sunset times.",
    "const zoneCoordinates = <String, (double, double)>{",
]
out += [f"  '{tz}': ({lat}, {lon})," for tz, (lat, lon) in sorted(rows.items())]
out.append('};')
here = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(here, '..', 'lib', 'services', 'zone_coordinates.dart'), 'w') as f:
    f.write('\n'.join(out) + '\n')
print(f'{len(rows)} zones')
