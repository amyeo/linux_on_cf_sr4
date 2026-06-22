# Extra Linux support for CF-SR4 (Arch Linux)

Primarily to host the modified ```drivers/platform/x86/panasonic-laptop.c``` code

For config files, driver modifications and notes.

Property | Value
--- | ---
DMI_SYS_VENDOR | "Panasonic Connect Co., Ltd."
DMI_PRODUCT_NAME | "CFSR4-1"

## Fan Control

**WARNING: STILL IN TESTING**

Fan control by default is handled by the EC but the minimum speed is too aggressive to be usable.

When booting Windows 10 or Windows 11 the vendor driver uses OSPM in order to control the fan from Windows. Considering this happens on a plain Windows install without installing additional drivers (Windows update provides additional drivers automatically), this appears to be the intended way the fan is supposed to be used.

On Linux, it seems the most straightforward way of replicating this is via thermald. Unfortunately, this cannot be the case out of the box since the vendor put the ACPI functions for fan control in non-standard locations.

Fan control as the manufacturer intended can be replicated on Linux but with driver modifications.
So what will need to be done is a modified kernel driver to expose the non-standard fan and a thermald XML config file that will adjust the fan accordingly.

### Usage
The fan should appear if the sensors (lm-sensors) command is executed.

This is what it looks like if the computer is still in EC/auto mode:
```
panasonic_pwm_fan-isa-0000
Adapter: ISA adapter
pwm1:              N/A
```

SEFM needs to be run in order for the OS to take control of the fan. _FSL is then executed with a value from 0-100 to set speed. A speed of 0 makes the fan stop spinning completely.

I use thermald to apply fan control automatically. When the computer starts up, it looks like this on my machine:
```
panasonic_pwm_fan-isa-0000
Adapter: ISA adapter
pwm1:              0%  MANUAL CONTROL
```

When fan speed is set via hwmon or thermal, the enable or manual mode (via SEFM) is automatically executed.

Note: There is a division bug with the sensors command so 100% may show up as 127.5 or 128%

Hwmon control is from 0-255 while thermal control is from 0-100. The maximum value is specified with thermal so tools like thermald should work as long as the cooling device type is specified.

#### Manual Control
```
#read
$ cat "/sys/devices/platform/MAT0019:00/hwmon/hwmon6/pwm1_enable"
1

$ cat "/sys/devices/platform/MAT0019:00/hwmon/hwmon6/pwm1"
0

#write/set
$ echo 0 | sudo tee "/sys/devices/platform/MAT0019:00/hwmon/hwmon6/pwm1" # off
$ echo 255 | sudo tee "/sys/devices/platform/MAT0019:00/hwmon/hwmon6/pwm1" # max speed
$ echo 0 | sudo tee "/sys/devices/platform/MAT0019:00/hwmon/hwmon6/pwm1_enable" # hand back control to EC
```

## Strategy

Ideally to adapt as much of the hardware quirks to use standard interfaces/controls.

## Safety

I have confirmed on my machine that if fan control is set to manual PWM mode and then turned off, the EC will intervene if the processor gets to hot (around 90C).

## Driver Modifications
### Quirks

```
struct quirk_entry {
	bool has_ospm_pwm_fan;
};

static struct quirk_entry *quirks;

static struct quirk_entry quirk_cf_sr4 = {
	.has_ospm_pwm_fan = true,
};

/* Based on asus-nb-wmi.c */
static int dmi_matched(const struct dmi_system_id *dmi)
{
	pr_info("Identified laptop model '%s'\n", dmi->ident);
	quirks = dmi->driver_data;
	return 1;
}

static const struct dmi_system_id pcc_quirks[] = {
	{
		.callback = dmi_matched,
		.ident = "Panasonic Connect Co., Ltd. CFSR4-1",
		.matches = {
			DMI_MATCH(DMI_SYS_VENDOR, "Panasonic Connect Co., Ltd."),
			DMI_MATCH(DMI_PRODUCT_NAME, "CFSR4-1"),
		},
		.driver_data = &quirk_cf_sr4,
	},
	{},
};
```
The following structs, functions and variable declarations were added.

The following was also added to the probe function:
```
const struct dmi_system_id *dmi_id;
/*
* Perform quirk detection
*/
dmi_id = dmi_first_match(pcc_quirks);
if (dmi_id) {
	pcc->quirks = dmi_id->driver_data;
	pr_info("Quirk detect: Enabled quirks for %s\n", dmi_id->ident);
} else {
	pcc->quirks = NULL; /* probably not needed */
}
/* has_ospm_pwm_fan */
if (pcc->quirks->has_ospm_pwm_fan) {
	pr_info("OSPM PWN fan quirk: applying hwmon for for %s\n", dmi_id->ident);
	hwmon_dev = devm_hwmon_device_register_with_info(
		&pdev->dev, "panasonic_pwm_fan", NULL,
		&pcc_pwm_fan_hwmon_chip_info, NULL);
	if (IS_ERR(hwmon_dev)) {
		pr_err("PCC PWM Fan: Failed to register hwmon device\n");
		return PTR_ERR(hwmon_dev);
	}

	pr_info("OSPM PWN fan quirk: applying thermal for for %s\n", dmi_id->ident);
	cdev = thermal_cooling_device_register(
		"Panasonic_PWM_Fan", NULL, &pcc_pwm_fan_cdev_ops);
	if (IS_ERR(cdev)) {
		pr_warn("PCC: Failed to register cdev!\n");
	}
}
```
This makes sure that the code only runs for a specific model.
