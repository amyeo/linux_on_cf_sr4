# Extra Linux support for CF-SR4

> [!CAUTION]
> **NOT AN OFFICIAL DRIVER** This software has been tested, but is experimental and comes with no warranty. Not affiliated with Panasonic in any way.

Primarily to host the modified ```drivers/platform/x86/panasonic-laptop.c``` code

This driver allows lock and unlock of firmware TDP. Uncaps between ~30-40% of available power to the processor in Linux.

For the SR4, it adds cool (firmware default), quiet and performance modes.

## Supported Models

DMI Product Name | DMI Vendor
--- | ---
"CFSR4-1" | "Panasonic Connect Co., Ltd."
"CFQV9-1" | "Panasonic Corporation"
"CFSV8-2" | "Panasonic Corporation"
"CFRZ6-2" | "Panasonic Corporation"

## Usage

```
$ cat /sys/firmware/acpi/platform_profile_choices
cool quiet performance
```
