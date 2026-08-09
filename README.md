# Extra Linux support for CF-SR4

> [!CAUTION]
> **NOT AN OFFICIAL DRIVER** This software has been tested, but is experimental and comes with no warranty. Not affiliated with Panasonic in any way.

Primarily to host the modified ```drivers/platform/x86/panasonic-laptop.c``` code

This driver allows lock and unlock of firmware TDP. Uncaps between ~30-40% of available power to the processor in Linux.

For the SR4, it adds cool (firmware default), quiet and performance modes.

## Supported Models

DMI Product Name | DMI Vendor | Profiles
--- | --- | ---
"CFSR4-1" | "Panasonic Connect Co., Ltd." | "cool, quiet, performance"
"CFQV9-1" | "Panasonic Corporation" | "balanced, performance"
"CFSV8-2" | "Panasonic Corporation" | "balanced, performance"
"CFRZ6-2" | "Panasonic Corporation" | "balanced, performance"

## Usage

```
$ cat /sys/firmware/acpi/platform_profile_choices
cool quiet performance
```

## Other notes

```
Test results:
================
(CPU PkgWatt: peak / sustained)
(Sysbench CPU: all available threads)

CF-RZ6: (i5-7Y57, Startup default: Balanced)

 Platform Profile |  CPU PkgWatt    |  Sysbench CPU  | Stress Temp (CPU)
+-----------------+-----------------+----------------+-------------------+
 BALANCED         |  10.0W / 9.0W   |    19712       |   57C
 PERFORMANCE      |  18.9W / 14.9W  |    29132       |   72C

CF-SV8: (i5-8365U, Startup default: Balanced)

 Platform Profile |  CPU PkgWatt     |  Sysbench CPU  | Stress Temp (CPU)
+-----------------+------------------+----------------+-------------------+
 BALANCED         |  9.9W  / 9.9W    |    44695       |   58C
 PERFORMANCE      |  29.0W / 19.9W   |    71747       |   81C

CF-QV9: (i5-10310U, Startup default: Balanced)

 Platform Profile |  CPU PkgWatt     |  Sysbench CPU  | Stress Temp (CPU)
+-----------------+------------------+----------------+-------------------+
 BALANCED         |  10.0W / 9.9W    |    46545       |   59C
 PERFORMANCE      |  18.9W / 14.9W   |    57416       |   70C

CF-SR4: (i5-1345U, Startup default: Cool)

 Platform Profile |  CPU PkgWatt     |  Sysbench CPU  | Stress Temp (CPU)
+-----------------+------------------+----------------+-------------------+
 COOL             |  12.0W / 12.0W   |    177139      |   66C
 QUIET            |  12.0W / 12.0W   |    176315      |   73C-75C
 PERFORMANCE      |  29.6W / 21.3W   |    247602      |   98C-100C

CF-SR4 Notes:
 - QUIET: downclock/throttle at 75C, no increase in package_throttle_count
 - PERFORMANCE: stable boost clock, package_throttle_count increase
```
