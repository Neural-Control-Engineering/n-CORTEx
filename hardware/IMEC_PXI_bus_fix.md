# IMEC / NI PXI Host Bridge — Error 31 After BIOS Update

## Symptom

SpikeGLX (or Open Ephys) reports **error 31 / NO_SLOT**: acquisition software cannot detect a Neuropixels base station or IMEC module.

## Machine layout

| Slot | Hardware | PCIe |
|------|----------|------|
| PCIEX16_1 (CPU x16, PCIe 4.0) | NI PXI interface card | Bus 1 |
| PCIEX16_2/_3 (chipset x4, PCIe 3.0) | RTX 5070 | Bus 2 |

The NI PXI interface card contains a **PLX PEX 8632** PCIe switch (VEN_10B5 DEV_8632, NI subsystem 76501093). The SpikeGLX/IMEC slot numbering maps through this bridge.

## Root cause

After a BIOS update (or any BIOS reset to defaults), **Above 4G Decoding** is disabled. The PLX PEX 8632 requires a large 64-bit memory window (~256 MB) for the downstream NI PXI chassis. With Above 4G Decoding off, the BIOS can't allocate enough 32-bit MMIO space and the bridge fails to start.

Windows Device Manager confirms this:
- **Device**: PCI-to-PCI Bridge, `PCI\VEN_10B5&DEV_8632\...` at PCI bus 3, device 0, function 0
- **ConfigManagerErrorCode**: 31 (`CM_PROB_FAILED_START`)
- **ProblemStatus**: 0xC0000010 (`STATUS_DEVICE_NOT_READY` — resource allocation failed)
- **Parent**: IDT 8091 PCIe switch (VEN_111D DEV_8091, NI subsystem) — this one stays OK

The IMEC API's error 31 (`NO_SLOT`) is a direct consequence: with the NI PXI bridge down, SpikeGLX finds nothing at the configured slot index.

## Fix

1. Reboot → BIOS (Del key on ASUS TUF Z590-PLUS)
2. **Advanced → PCI Subsystem Settings → Above 4G Decoding → Enabled**
3. While there: verify PCIe slot 1 link speed is **Gen3** (it may have reset to Auto/Gen1)
4. F10 → Save & reboot

## Verification

After reboot, check in PowerShell:

```powershell
Get-WmiObject Win32_PnPEntity | Where-Object { $_.DeviceID -match 'VEN_10B5&DEV_8632' } |
    Select-Object Status, Name, DeviceID, ConfigManagerErrorCode
```

`Status: OK` and `ConfigManagerErrorCode: 0` = bridge is up. SpikeGLX should detect the IMEC hardware normally.

## Notes

- The RTX 5070 slot (PCIEX16_2) also needs its PCIe gen forced to **Gen3** in BIOS — it does not negotiate correctly on this chipset slot at Auto. See `Extraction/GPUKeepAlive/README.md` for the GPU bus-drop context.
- If the bridge still shows Error 31 after enabling Above 4G Decoding, the secondary suspect is **PCIe bus number allocation limit** — check that the BIOS isn't capping the number of downstream buses too tightly for the 4-bridge-deep NI PXI hierarchy.
