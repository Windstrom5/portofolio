import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

import 'package:project_test/main.dart';

class LinuxStyleBootLogin extends StatefulWidget {
  const LinuxStyleBootLogin({super.key});

  @override
  State<LinuxStyleBootLogin> createState() => _LinuxStyleBootLoginState();
}

class _LinuxStyleBootLoginState extends State<LinuxStyleBootLogin> {
  int currentMessageIndex = 0;
  Timer? _bootTimer;
  Timer? _cursorTimer;
  String cursor = '█';
  bool bootFinished = false;
  bool showPasswordPrompt = false;
  bool simulateLogin = false;
  final ScrollController _scrollController = ScrollController();

  final List<String> bootMessages = [
    "[    0.000000] Booting Linux on physical CPU 0x0",
    "[    0.000000] Linux version 6.8.0-45-generic (buildd@lcy02-amd64-030) (x86_64-linux-gnu-gcc-13 (Ubuntu 13.2.0-23ubuntu4) 13.2.0, GNU ld (GNU Binutils for Ubuntu) 2.42) #45-Ubuntu SMP PREEMPT_DYNAMIC Fri Oct 18 15:25:05 UTC 2024 (Ubuntu 6.8.0-45.45-generic 6.8.12)",
    "[    0.000000] Command line: BOOT_IMAGE=/boot/vmlinuz-6.8.0-45-generic root=UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx ro quiet splash vt.handoff=7",
    "[    0.000000] KERNEL supported cpus:",
    "[    0.000000]   Intel GenuineIntel",
    "[    0.000000]   AMD AuthenticAMD",
    "[    0.000000]   Hygon HygonGenuine",
    "[    0.000000]   Centaur CentaurHauls",
    "[    0.000000]   zhaoxin   Shanghai  ",
    "[    0.000000] x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'",
    "[    0.000000] x86/fpu: Supporting XSAVE feature 0x002: 'SSE registers'",
    "[    0.000000] x86/fpu: Supporting XSAVE feature 0x004: 'AVX registers'",
    "[    0.000000] x86/fpu: xstate_offset[2]:  576, xstate_sizes[2]:  256",
    "[    0.000000] x86/fpu: Enabled xstate features 0x7, context size is 832 bytes, using 'compacted' format.",
    "[    0.000000] signal: max sigframe size: 1776",
    "[    0.000000] BIOS-provided physical RAM map:",
    "[    0.000000] BIOS-e820: [mem 0x0000000000000000-0x000000000009efff] usable",
    "[    0.000000] BIOS-e820: [mem 0x000000000009f000-0x00000000000fffff] reserved",
    "[    0.000000] BIOS-e820: [mem 0x0000000000100000-0x000000003fffffff] usable",
    "[    0.000000] NX (Execute Disable) protection: active",
    "[    0.000000] APIC: Static calls initialized",
    "[    0.000000] efi: EFI v2.8 by American Megatrends",
    "[    0.000000] efi: ACPI=0x7fe20000 ACPI 2.0=0x7fe20014 TPMFinalLog=0x7ff28000 SMBIOS=0xf0000 SMBIOS 3.0=0xf0020 ESRT=0x4d5a1b18 MEMATTR=0x4c0d4018 RNG=0x7ff1a018 TPMEventLog=0x3f701018 ",
    "[    0.000000] efi: Remove mem50: MMIO 0x00000000d0000000-0x00000000dfffffff",
    "[    0.000000] secureboot: Secure boot disabled",
    "[    0.000000] SMBIOS 3.6.0 present.",
    "[    0.000000] DMI: ASUS System Product Name/PRIME B550M-A WIFI II, BIOS 3607 03/19/2024",
    "[    0.000000] tsc: Fast TSC calibration using PIT",
    "[    0.000000] tsc: Detected 3792.940 MHz processor",
    "[    0.001034] e820: update [mem 0x00000000-0x00000fff] usable ==> reserved",
    "[    0.001036] e820: remove [mem 0x000a0000-0x000fffff] usable",
    "[    0.001040] last_pfn = 0x40000 max_arch_pfn = 0x400000000",
    "[    0.001101] MTRR map: 4 entries (3 fixed + 1 variable; max 19), built from 8 variable MTRRs",
    "[    0.001102] x86/PAT: Configuration [0-7]: WB  WC  UC- UC  WB  WP  UC- WT  ",
    "[    0.001368] found SMP MP-table at [mem 0x000fcce0-0x000fccef]",
    "[    0.001381] esrt: Reserving ESRT space from 0x000000004d5a1b18 to 0x000000004d5a1b50.",
    "[    0.001386] e820: update [mem 0x4d5a1000-0x4d5a1fff] usable ==> reserved",
    "[    0.001393] Using GB pages for direct mapping",
    "[    0.001815] Secure boot disabled",
    "[    0.001816] RAMDISK: [mem 0x33c61000-0x35e2ffff]",
    "[    0.001818] ACPI: Early table checksum verification disabled",
    "[    0.001820] ACPI: RSDP 0x000000007FE20014 000024 (v02 ALASKA)",
    "[    0.001823] ACPI: XSDT 0x000000007FE1F0E8 0000E4 (v01 ALASKA A M I    01072009 AMI  01000013)",
    "[    0.001827] ACPI: FACP 0x000000007FDF0000 000114 (v06 ALASKA A M I    01072009 AMI  00010013)",
    "[    0.001830] ACPI: DSDT 0x000000007FDE0000 00D1E9 (v02 ALASKA A M I    01072009 INTL 20120913)",
    "[    0.001832] ACPI: FACS 0x000000007FF1E000 000040",
    "[    0.001833] ACPI: SSDT 0x000000007FE0A000 001A58 (v02 AMD    AmdTable 00000002 MSFT 04000000)",
    "[    0.001835] ACPI: IVRS 0x000000007FE09000 0000C8 (v02 AMD    AmdTable 00000001 AMD  00000000)",
    "[    0.001837] ACPI: SSDT 0x000000007FE05000 003A21 (v01 AMD    AMD AOD  00000001 INTL 20120913)",
    "[    0.001839] ACPI: SSDT 0x000000007FE04000 000164 (v02 ALASKA CPUSSDT  01072009 AMI  01072009)",
    "[    0.001840] ACPI: FIDT 0x000000007FDD0000 00009C (v01 ALASKA A M I    01072009 AMI  00010013)",
    "[    0.001842] ACPI: MCFG 0x000000007FDC0000 00003C (v01 ALASKA A M I    01072009 MSFT 00010013)",
    "[    0.001844] ACPI: HPET 0x000000007FDB0000 000038 (v01 ALASKA A M I    01072009 AMI  00000005)",
    "[    0.001845] ACPI: FPDT 0x000000007FDA0000 000044 (v01 ALASKA A M I    01072009 AMI  01000013)",
    "[    0.001847] ACPI: BGRT 0x000000007FD90000 000038 (v01 ALASKA A M I    01072009 AMI  00010013)",
    "[    0.001849] ACPI: UEFI 0x000000007FF28000 000042 (v01 ALASKA A M I    00000002      01000013)",
    "[    0.001850] ACPI: TPM2 0x000000007FD80000 00004C (v04 ALASKA A M I    00000001 AMI  00000000)",
    "[    0.001852] ACPI: SSDT 0x000000007FD70000 0000B0 (v01 AMD    AmdTable 00000001 AMD  00000001)",
    "[    0.001854] ACPI: CRAT 0x000000007FD60000 000BD0 (v01 AMD    AmdTable 00000001 AMD  00000001)",
    "[    0.001855] ACPI: CDIT 0x000000007FD50000 000029 (v01 AMD    AmdTable 00000001 AMD  00000001)",
    "[    0.001857] ACPI: SSDT 0x000000007FD40000 000D53 (v01 AMD    AmdTable 00000001 INTL 20120913)",
    "[    0.001859] ACPI: SSDT 0x000000007FD30000 00007D (v01 AMD    AmdTable 00000001 INTL 20120913)",
    "[    0.001860] ACPI: WSMT 0x000000007FD20000 000028 (v01 ALASKA A M I    01072009 AMI  00010013)",
    "[    0.001862] ACPI: APIC 0x000000007FD10000 0000DE (v05 ALASKA A M I    01072009 AMI  00010013)",
    "[    0.001864] ACPI: SSDT 0x000000007FD00000 000874 (v01 AMD    AOD      00000001 INTL 20120913)",
    "[    0.001865] ACPI: Reserving FACP table memory at [mem 0x7fdf0000-0x7fdf0113]",
    "[    0.001866] ACPI: Reserving DSDT table memory at [mem 0x7fde0000-0x7fded1e8]",
    "[    0.001867] ACPI: Reserving FACS table memory at [mem 0x7ff1e000-0x7ff1e03f]",
    "[    0.001868] ACPI: Reserving SSDT table memory at [mem 0x7fe0a000-0x7fe0ba57]",
    "[    0.001868] ACPI: Reserving IVRS table memory at [mem 0x7fe09000-0x7fe090c7]",
    "[    0.001869] ACPI: Reserving SSDT table memory at [mem 0x7fe05000-0x7fe08a20]",
    "[    0.001870] ACPI: Reserving SSDT table memory at [mem 0x7fe04000-0x7fe04163]",
    "[    0.001870] ACPI: Reserving FIDT table memory at [mem 0x7fdd0000-0x7fdd009b]",
    "[    0.001871] ACPI: Reserving MCFG table memory at [mem 0x7fdc0000-0x7fdc003b]",
    "[    0.001871] ACPI: Reserving HPET table memory at [mem 0x7fdb0000-0x7fdb0037]",
    "[    0.001872] ACPI: Reserving FPDT table memory at [mem 0x7fda0000-0x7fda0043]",
    "[    0.001873] ACPI: Reserving BGRT table memory at [mem 0x7fd90000-0x7fd90037]",
    "[    0.001873] ACPI: Reserving UEFI table memory at [mem 0x7ff28000-0x7ff28041]",
    "[    0.001874] ACPI: Reserving TPM2 table memory at [mem 0x7fd80000-0x7fd8004b]",
    "[    0.001875] ACPI: Reserving SSDT table memory at [mem 0x7fd70000-0x7fd700af]",
    "[    0.001875] ACPI: Reserving CRAT table memory at [mem 0x7fd60000-0x7fd60bcf]",
    "[    0.001876] ACPI: Reserving CDIT table memory at [mem 0x7fd50000-0x7fd50028]",
    "[    0.001877] ACPI: Reserving SSDT table memory at [mem 0x7fd40000-0x7fd40d52]",
    "[    0.001877] ACPI: Reserving SSDT table memory at [mem 0x7fd30000-0x7fd3007c]",
    "[    0.001878] ACPI: Reserving WSMT table memory at [mem 0x7fd20000-0x7fd20027]",
    "[    0.001879] ACPI: Reserving APIC table memory at [mem 0x7fd10000-0x7fd100dd]",
    "[    0.001879] ACPI: Reserving SSDT table memory at [mem 0x7fd00000-0x7fd00873]",
    "[    0.002193] No NUMA configuration found",
    "[    0.002194] Faking a node at [mem 0x0000000000000000-0x000000003fffffff]",
    "[    0.002198] NODE_DATA(0) allocated [mem 0x3fffb000-0x3fffffff]",
    "[    0.002217] Zone ranges:",
    "[    0.002218]   DMA      [mem 0x0000000000001000-0x0000000000ffffff]",
    "[    0.002219]   DMA32    [mem 0x0000000001000000-0x000000003fffffff]",
    "[    0.002220]   Normal   empty",
    "[    0.002220]   Device   empty",
    "[    0.002221] Movable zone start for each node",
    "[    0.002222] Early memory node ranges",
    "[    0.002223]   node   0: [mem 0x0000000000001000-0x000000000009efff]",
    "[    0.002224]   node   0: [mem 0x0000000000100000-0x000000003fffffff]",
    "[    0.002225] Initmem setup node 0 [mem 0x0000000000001000-0x000000003fffffff]",
    "[    0.002227] On node 0, zone DMA: 1 pages in unavailable ranges",
    "[    0.002240] On node 0, zone DMA: 97 pages in unavailable ranges",
    "[    0.003610] ACPI: PM-Timer IO Port: 0x808",
    "[    0.003613] ACPI: LAPIC_NMI (acpi_id[0xff] high edge lint[0x1])",
    "[    0.003628] IOAPIC[0]: apic_id 0, version 32, address 0xfec00000, GSI 0-23",
    "[    0.003631] ACPI: INT_SRC_OVR (bus 0 bus_irq 0 global_irq 2 dfl dfl)",
    "[    0.003632] ACPI: INT_SRC_OVR (bus 0 bus_irq 9 global_irq 9 low level)",
    "[    0.003633] ACPI: Using ACPI (MADT) for SMP configuration information",
    "[    0.003634] ACPI: HPET id: 0x43538210 base: 0xfed00000",
    "[    0.003637] CPU topo: Max. logical packages:   1",
    "[    0.003638] CPU topo: Max. logical dies:       1",
    "[    0.003638] CPU topo: Max. dies per package:   1",
    "[    0.003643] CPU topo: Max. threads per core:   2",
    "[    0.003643] CPU topo: Num. cores per CPU:     8",
    "[    0.003644] CPU topo: Num. threads per CPU:  16",
    "[    0.003644] CPU topo: Allowing 16 present CPUs plus 0 hotplug CPUs",
    "[    0.003663] APIC: Switch to symmetric I/O mode setup",
    "[    0.004168] ..TIMER: vector=0x30 apic1=0 pin1=2 apic2=-1 pin2=-1",
    "[    0.009174] clocksource: tsc-early: mask: 0xffffffffffffffff max_cycles: 0x6d5a1b18, max_idle_ns: 440795202120 ns",
    "[    0.009179] Calibrating delay loop (skipped), value calculated using timer frequency.. 7585.88 BogoMIPS (lpj=3792940)",
    "[    0.009181] CPU0: Thermal monitoring enabled (TM1)",
    "[    0.009182] Last level iTLB entries: 4KB 512, 2MB 512, 4MB 256",
    "[    0.009183] Last level dTLB entries: 4KB 2048, 2MB 2048, 4MB 1024, 1GB 0",
    "[    0.009185] process: using mwait in idle threads",
    "[    0.009186] Spectre V1 : Mitigation: usercopy/swapgs barriers and __user pointer sanitization",
    "[    0.009188] Spectre V2 : Mitigation: Retpolines",
    "[    0.009188] Spectre V2 : Spectre v2 / SpectreRSB mitigation: Filling RSB on context switch",
    "[    0.009189] Spectre V2 : Spectre v2 / PBRSB-eIBRS: Retpoline",
    "[    0.009190] Speculative Store Bypass: Vulnerable",
    "[    0.009191] MDS: Vulnerable: Clear CPU buffers attempted, no microcode",
    "[    0.009192] MMIO Stale Data: Unknown: No mitigations",
    "[    0.009193] SRBDS: Vulnerable: No microcode",
    "[    0.009193] GDS: Vulnerable: No microcode",
    "[    0.009194] x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'",
    "[    0.009195] x86/fpu: Supporting XSAVE feature 0x002: 'SSE registers'",
    "[    0.009196] x86/fpu: Supporting XSAVE feature 0x004: 'AVX registers'",
    "[    0.009197] x86/fpu: xstate_offset[2]:  576, xstate_sizes[2]:  256",
    "[    0.009198] x86/fpu: Enabled xstate features 0x7, context size is 832 bytes, using 'compacted' format.",
    "[    0.022826] Freeing SMP alternatives memory: 32K",
    "[    0.022828] pid_max: default: 32768 minimum: 301",
    "[    0.022835] LSM: initializing lsm=lockdown,capability,landlock,yama,apparmor,tomoyo,bpf,integrity",
    "[    0.022843] landlock: Up and running.",
    "[    0.022844] Yama: becoming mindful.",
    "[    0.022847] AppArmor: AppArmor initialized",
    "[    0.022848] TOMOYO Linux initialized",
    "[    0.022850] LSM support for eBPF active",
    "[    0.022854] Mount-cache hash table entries: 1024 (order: 1, 8192 bytes, linear)",
    "[    0.022856] Mountpoint-cache hash table entries: 1024 (order: 1, 8192 bytes, linear)",
    "[    0.023097] smpboot: CPU0: Intel(R) Core(TM) i7-10700K CPU @ 3.80GHz (family: 0x6, model: 0xa5, stepping: 0x5)",
    "[    0.023121] RCU Tasks: Setting shift to 4 and lim to 1 rcu_task_cb_adjust=1 rcu_task_cpu_ids=16.",
    "[    0.023132] RCU Tasks Rude: Setting shift to 4 and lim to 1 rcu_task_cb_adjust=1 rcu_task_cpu_ids=16.",
    "[    0.023143] RCU Tasks Trace: Setting shift to 4 and lim to 1 rcu_task_cb_adjust=1 rcu_task_cpu_ids=16.",
    "[    0.023153] Performance Events: PEBS fmt3+, Skylake events, 32-deep LBR, full-width counters, Intel PMU driver.",
    "[    0.023160] ... version:                4",
    "[    0.023160] ... bit width:              48",
    "[    0.023161] ... generic registers:      4",
    "[    0.023162] ... value mask:             0000ffffffffffff",
    "[    0.023163] ... max period:             00007fffffffffff",
    "[    0.023163] ... fixed-purpose events:   3",
    "[    0.023164] ... event mask:             000000070000000f",
    "[    0.023175] signal: max sigframe size: 1776",
    "[    0.023176] rcu: Hierarchical SRCU implementation.",
    "[    0.023177] rcu: \tMax phase no-delay instances is 1000.",
    "[    0.023224] smp: Bringing up secondary CPUs ...",
    "[    0.023224] smp: Brought up 1 node, 1 CPU",
    "[    0.023225] smpboot: Total of 1 processors activated (7585.88 BogoMIPS)",
    "[    0.023307] node 0 deferred pages initialised in 0ms",
    "[    0.023337] devtmpfs: initialized",
    "[    0.023357] x86/mm: Memory block size: 128MB",
    "[    0.023360] ACPI: PM: Registering ACPI NVS region [mem 0x0a200000-0x0a20ffff] (65536 bytes)",
    "[    0.023361] ACPI: PM: Registering ACPI NVS region [mem 0x7ff1f000-0x7ff9efff] (524288 bytes)",
    "[    0.023363] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 1911260446275000 ns",
    "[    0.023365] futex hash table entries: 4096 (order: 6, 262144 bytes, linear)",
    "[    0.023372] pinctrl core: initialized pinctrl subsystem",
    "[    0.023395] NET: Registered PF_NETLINK/PF_ROUTE protocol family",
    "[    0.023402] DMA: preallocated 64 KiB GFP_KERNEL pool for atomic allocations",
    "[    0.023405] DMA: preallocated 64 KiB GFP_KERNEL|GFP_DMA pool for atomic allocations",
    "[    0.023408] DMA: preallocated 64 KiB GFP_KERNEL|GFP_DMA32 pool for atomic allocations",
    "[    0.023411] audit: initializing netlink subsys (disabled)",
    "[    0.023417] audit: type=2000 audit(1738215132.023:1): state=initialized audit_enabled=0 res=1",
    "[    0.023417] thermal_sys: Registered thermal governor 'fair_share'",
    "[    0.023418] thermal_sys: Registered thermal governor 'bang_bang'",
    "[    0.023419] thermal_sys: Registered thermal governor 'step_wise'",
    "[    0.023420] thermal_sys: Registered thermal governor 'user_space'",
    "[    0.023421] cpuidle: using governor menu",
    "[    0.023428] Simple Boot Flag at 0x44 set to 0x1",
    "[    0.023430] ACPI: bus type PCI registered",
    "[    0.023431] acpiphp: ACPI Hot Plug PCI Controller Driver version: 0.5",
    "[    0.023437] PCI: MMCONFIG for domain 0000 [bus 00-ff] at [mem 0xe0000000-0xefffffff] (base 0xe0000000)",
    "[    0.023439] PCI: MMCONFIG at [mem 0xe0000000-0xefffffff] reserved as ACPI motherboard resource",
    "[    0.023440] PCI: Using configuration type 1 for base access",
    "[    0.023443] core: PMU erratum BJ122, BV98, HSD29 worked around, HT is on",
    "[    0.023654] HugeTLB: registered 1.00 GiB page size, pre-allocated 0 pages",
    "[    0.023655] HugeTLB: 16380 KiB vmemmap can be freed for a 1.00 GiB page",
    "[    0.023656] HugeTLB: registered 2.00 MiB page size, pre-allocated 0 pages",
    "[    0.023657] HugeTLB: 28 KiB vmemmap can be freed for a 2.00 MiB page",
    "[    0.023658] cryptd: max_cpu_qlen set to 1000",
    "[    0.023662] ACPI: Added _OSI(Module Device)",
    "[    0.023663] ACPI: Added _OSI(Processor Device)",
    "[    0.023664] ACPI: Added _OSI(3.0 _SCP Extensions)",
    "[    0.023664] ACPI: Added _OSI(Processor Aggregator Device)",
    "[    0.027749] ACPI: 20 ACPI AML tables successfully acquired and loaded",
    "[    0.028364] ACPI: [Firmware Bug]: BIOS _OSI(Linux) query ignored",
    "[    0.028689] ACPI: Interpreter enabled",
    "[    0.028695] ACPI: PM: (supports S0 S3 S4 S5)",
    "[    0.028696] ACPI: Using IOAPIC for interrupt routing",
    "[    0.028714] PCI: Using host bridge windows from ACPI; if necessary, use \"pci=nocrs\" and report a bug",
    "[    0.028715] PCI: Using E820 reservations for host bridge windows",
    "[    0.028831] ACPI: Enabled 2 GPEs in block 00 to 1F",
    "[    0.029195] ACPI: PCI Root Bridge [PCI0] (domain 0000 [bus 00-ff])",
    "[    0.029199] acpi PNP0A08:00: _OSC: OS supports [ExtendedConfig ASPM ClockPM Segments MSI HPX-Type3]",
    "[    0.029310] acpi PNP0A08:00: _OSC: platform does not support [LTR]",
    "[    0.029419] acpi PNP0A08:00: _OSC: OS now controls [PCIeHotplug PME AER PCIeCapability]",
    "[    0.029425] PCI host bridge to bus 0000:00",
    "[    0.029427] pci_bus 0x00: root bus resource [io  0x0000-0x03af window]",
    "[    0.029428] pci_bus 0x00: root bus resource [io  0x03e0-0x0cf7 window]",
    "[    0.029429] pci_bus 0x00: root bus resource [io  0x0d00-0xffff window]",
    "[    0.029430] pci_bus 0x00: root bus resource [mem 0x000a0000-0x000dffff window]",
    "[    0.029431] pci_bus 0x00: root bus resource [mem 0x80000000-0xdfffffff window]",
    "[    0.029432] pci_bus 0x00: root bus resource [mem 0xf0000000-0xfebfffff window]",
    "[    0.029433] pci_bus 0x00: root bus resource [bus 00-ff]",
    "[    0.029441] pci 0000:00:00.0: [1022:1482] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.029499] pci 0000:00:01.0: [1022:1483] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.029555] pci 0000:00:01.2: [1022:1483] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.029610] pci 0000:00:01.3: [1022:1483] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.029666] pci 0000:00:02.0: [1022:1482] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.029720] pci 0000:00:03.0: [1022:1482] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.029774] pci 0000:00:03.1: [1022:1483] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.029830] pci 0000:00:04.0: [1022:1482] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.029884] pci 0000:00:05.0: [1022:1482] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.029938] pci 0000:00:07.0: [1022:1482] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.029992] pci 0000:00:07.1: [1022:1484] type 00 class 0x060000 PCIe Root Port",
    "[    0.029995] pci 0000:00:07.1: enabling Extended Tags",
    "[    0.030007] pci 0000:00:07.1: PME# supported from D0 D3hot D3cold",
    "[    0.030064] pci 0000:00:08.0: [1022:1482] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.030118] pci 0000:00:08.1: [1022:1484] type 00 class 0x060000 PCIe Root Port",
    "[    0.030121] pci 0000:00:08.1: enabling Extended Tags",
    "[    0.030133] pci 0000:00:08.1: PME# supported from D0 D3hot D3cold",
    "[    0.030190] pci 0000:00:08.2: [1022:1484] type 00 class 0x060000 PCIe Root Port",
    "[    0.030193] pci 0000:00:08.2: enabling Extended Tags",
    "[    0.030205] pci 0000:00:08.2: PME# supported from D0 D3hot D3cold",
    "[    0.030262] pci 0000:00:08.3: [1022:1484] type 00 class 0x060000 PCIe Root Port",
    "[    0.030265] pci 0000:00:08.3: enabling Extended Tags",
    "[    0.030277] pci 0000:00:08.3: PME# supported from D0 D3hot D3cold",
    "[    0.030334] pci 0000:00:14.0: [1022:790b] type 00 class 0x0c0500 conventional PCI endpoint",
    "[    0.030427] pci 0000:00:14.3: [1022:790e] type 00 class 0x060100 conventional PCI endpoint",
    "[    0.030520] pci 0000:00:18.0: [1022:1440] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.030548] pci 0000:00:18.1: [1022:1441] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.030576] pci 0000:00:18.2: [1022:1442] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.030604] pci 0000:00:18.3: [1022:1443] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.030632] pci 0000:00:18.4: [1022:1444] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.030660] pci 0000:00:18.5: [1022:1445] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.030688] pci 0000:00:18.6: [1022:1446] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.030716] pci 0000:00:18.7: [1022:1447] type 00 class 0x060000 conventional PCI endpoint",
    "[    0.030749] pci 0000:01:00.0: [1022:57ad] type 00 class 0x060000 PCIe Root Port",
    "[    0.030780] pci 0000:02:00.0: [1022:57a3] type 00 class 0x060000 PCIe Root Port",
    "[    0.030811] pci 0000:02:04.0: [1022:57a3] type 00 class 0x060000 PCIe Root Port",
    "[    0.030842] pci 0000:02:08.0: [1022:57a4] type 00 class 0x060000 PCIe Root Port",
    "[    0.030873] pci 0000:02:09.0: [1022:57a4] type 00 class 0x060000 PCIe Root Port",
    "[    0.030904] pci 0000:02:0a.0: [1022:57a4] type 00 class 0x060000 PCIe Root Port",
    "[    0.030935] pci 0000:03:00.0: [1022:1485] type 00 class 0x130000 PCIe Endpoint",
    "[    0.030950] pci 0000:03:00.0: enabling Extended Tags",
    "[    0.030968] pci 0000:03:00.0: 64 GT/s PCIe bus, Max bus width x16",
    "[    0.031002] pci 0000:04:00.0: [1022:7901] type 00 class 0x010601 PCIe Endpoint",
    "[    0.031034] pci 0000:04:00.0: enabling Extended Tags",
    "[    0.031052] pci 0000:04:00.0: 125 GT/s PCIe bus, Max bus width x2",
    "[    0.031086] pci 0000:05:00.0: [1022:148a] type 00 class 0x130000 PCIe Endpoint",
    "[    0.031101] pci 0000:05:00.0: enabling Extended Tags",
    "[    0.031120] pci 0000:05:00.0: 64 GT/s PCIe bus, Max bus width x16",
    "[    0.031154] pci 0000:06:00.0: [1022:149c] type 00 class 0x0c0330 PCIe Endpoint",
    "[    0.031169] pci 0000:06:00.0: enabling Extended Tags",
    "[    0.031188] pci 0000:06:00.0: BAR 0 [mem 0xfea00000-0xfea7ffff 64bit]",
    "[    0.031211] pci 0000:06:00.0: PME# supported from D0 D3hot",
    "[    0.031245] pci 0000:07:00.0: [1022:149c] type 00 class 0x0c0330 PCIe Endpoint",
    "[    0.031260] pci 0000:07:00.0: enabling Extended Tags",
    "[    0.031279] pci 0000:07:00.0: BAR 0 [mem 0xfe900000-0xfe97ffff 64bit]",
    "[    0.031302] pci 0000:07:00.0: PME# supported from D0 D3hot",
    "[    0.031336] pci 0000:08:00.0: [1022:7901] type 00 class 0x010601 PCIe Endpoint",
    "[    0.031368] pci 0000:08:00.0: enabling Extended Tags",
    "[    0.031386] pci 0000:08:00.0: 125 GT/s PCIe bus, Max bus width x4",
    "[    0.031420] pci 0000:09:00.0: [10ec:8125] type 00 class 0x020000 PCIe Endpoint",
    "[    0.031436] pci 0000:09:00.0: BAR 0 [io  0xf000-0xf0ff]",
    "[    0.031440] pci 0000:09:00.0: BAR 2 [mem 0xfe800000-0xfe80ffff 64bit]",
    "[    0.031443] pci 0000:09:00.0: BAR 3 [mem 0xfe810000-0xfe813fff 64bit]",
    "[    0.031449] pci 0000:09:00.0: supports D1 D2",
    "[    0.031450] pci 0000:09:00.0: PME# supported from D0 D1 D2 D3hot D3cold",
    "[    0.031484] pci 0000:0a:00.0: [8086:2723] type 00 class 0x028000 PCIe Endpoint",
    "[    0.031500] pci 0000:0a:00.0: BAR 0 [mem 0xfe700000-0xfe703fff 64bit]",
    "[    0.031523] pci 0000:0a:00.0: PME# supported from D0 D3hot D3cold",
    "[    0.031557] pci 0000:0b:00.0: [10de:1c03] type 00 class 0x030000 PCIe Legacy Endpoint",
    "[    0.031573] pci 0000:0b:00.0: BAR 0 [mem 0xfd000000-0xfdffffff]",
    "[    0.031577] pci 0000:0b:00.0: BAR 1 [mem 0xc0000000-0xcfffffff 64bit pref]",
    "[    0.031580] pci 0000:0b:00.0: BAR 3 [mem 0xd0000000-0xd1ffffff 64bit pref]",
    "[    0.031583] pci 0000:0b:00.0: BAR 5 [io  0xe000-0xe07f]",
    "[    0.031586] pci 0000:0b:00.0: ROM [mem 0xfe600000-0xfe67ffff pref]",
    "[    0.031588] pci 0000:0b:00.0: enabling Extended Tags",
    "[    0.031599] pci 0000:0b:00.0: PME# supported from D3hot D3cold",
    "[    0.031611] pci 0000:0b:00.0: 31.504 Gb/s available PCIe bandwidth, limited by 2.5 GT/s PCIe x16 link at 0000:00:03.1 (capable of 126.016 Gb/s with 8.0 GT/s PCIe x16 link)",
    "[    0.031643] pci 0000:0b:00.1: [10de:10f1] type 00 class 0x040300 PCIe Endpoint",
    "[    0.031659] pci 0000:0b:00.1: BAR 0 [mem 0xfe680000-0xfe683fff]",
    "[    0.031680] pci 0000:0b:00.1: enabling Extended Tags",
    "[    0.031714] pci 0000:0c:00.0: [1022:148a] type 00 class 0x130000 PCIe Endpoint",
    "[    0.031729] pci 0000:0c:00.0: enabling Extended Tags",
    "[    0.031748] pci 0000:0c:00.0: 64 GT/s PCIe bus, Max bus width x16",
    "[    0.031782] pci 0000:0d:00.0: [1022:1485] type 00 class 0x130000 PCIe Endpoint",
    "[    0.031797] pci 0000:0d:00.0: enabling Extended Tags",
    "[    0.031816] pci 0000:0d:00.0: 64 GT/s PCIe bus, Max bus width x16",
    "[    0.031850] pci 0000:0e:00.0: [1022:149c] type 00 class 0x0c0330 PCIe Endpoint",
    "[    0.031865] pci 0000:0e:00.0: enabling Extended Tags",
    "[    0.031884] pci 0000:0e:00.0: BAR 0 [mem 0xfe500000-0xfe57ffff 64bit]",
    "[    0.031907] pci 0000:0e:00.0: PME# supported from D0 D3hot",
    "[    0.031941] pci 0000:0f:00.0: [1022:149c] type 00 class 0x0c0330 PCIe Endpoint",
    "[    0.031956] pci 0000:0f:00.0: enabling Extended Tags",
    "[    0.031975] pci 0000:0f:00.0: BAR 0 [mem 0xfe400000-0xfe47ffff 64bit]",
    "[    0.031998] pci 0000:0f:00.0: PME# supported from D0 D3hot",
    "[    0.032032] pci 0000:10:00.0: [1022:7901] type 00 class 0x010601 PCIe Endpoint",
    "[    0.032064] pci 0000:10:00.0: enabling Extended Tags",
    "[    0.032082] pci 0000:10:00.0: 125 GT/s PCIe bus, Max bus width x4",
    "[    0.032116] ACPI: PCI: Interrupt link LNKA configured for IRQ 0",
    "[    0.032145] ACPI: PCI: Interrupt link LNKB configured for IRQ 0",
    "[    0.032173] ACPI: PCI: Interrupt link LNKC configured for IRQ 0",
    "[    0.032202] ACPI: PCI: Interrupt link LNKD configured for IRQ 0",
    "[    0.032230] ACPI: PCI: Interrupt link LNKE configured for IRQ 0",
    "[    0.032258] ACPI: PCI: Interrupt link LNKF configured for IRQ 0",
    "[    0.032286] ACPI: PCI: Interrupt link LNKG configured for IRQ 0",
    "[    0.032314] ACPI: PCI: Interrupt link LNKH configured for IRQ 0",
    "[    0.032505] iommu: Default domain type: Translated",
    "[    0.032506] iommu: DMA domain TLB invalidation policy: lazy mode",
    "[    0.032514] SCSI subsystem initialized",
    "[    0.032518] libata version 3.00 loaded.",
    "[    0.032520] ACPI: bus type USB registered",
    "[    0.032523] usbcore: registered new interface driver usbfs",
    "[    0.032525] usbcore: registered new interface driver hub",
    "[    0.032527] usbcore: registered new device driver usb",
    "[    0.032530] pps_core: LinuxPPS API ver. 1 registered",
    "[    0.032531] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>",
    "[    0.032532] PTP clock support registered",
    "[    0.032534] EDAC MC: Ver: 3.0.0",
    "[    0.032539] efivars: Registered efivars operations",
    "[    0.032551] NetLabel: Initializing",
    "[    0.032552] NetLabel:  domain hash size = 128",
    "[    0.032552] NetLabel:  protocols = UNLABELED CIPSOv4 CALIPSO",
    "[    0.032557] NetLabel:  unlabeled traffic allowed by default",
    "[    0.032559] mctp: management component transport protocol core",
    "[    0.032560] NET: Registered PF_MCTP protocol family",
    "[    0.032563] PCI: Using ACPI for IRQ routing",
    "[    0.032564] PCI: pci_cache_line_size set to 64 bytes",
    "[    0.032566] e820: reserve RAM buffer [mem 0x09f00000-0x0bffffff]",
    "[    0.032567] e820: reserve RAM buffer [mem 0x0a200000-0x0bffffff]",
    "[    0.032568] e820: reserve RAM buffer [mem 0x0b000000-0x0bffffff]",
    "[    0.032569] e820: reserve RAM buffer [mem 0x4d5a1000-0x4fffffff]",
    "[    0.032570] e820: reserve RAM buffer [mem 0x7fe30000-0x7fffffff]",
    "[    0.032571] e820: reserve RAM buffer [mem 0x7ff00000-0x7fffffff]",
    "[    0.032572] e820: reserve RAM buffer [mem 0x400000000-0x43fffffff]",
    "[    0.032576] pci 0000:0b:00.0: vgaarb: setting as boot VGA device",
    "[    0.032576] pci 0000:0b:00.0: vgaarb: bridge control possible",
    "[    0.032577] pci 0000:0b:00.0: vgaarb: VGA device added: decodes=io+mem,owns=io+mem,locks=none",
    "[    0.032579] vgaarb: loaded",
    "[    0.032580] clocksource: Switched to clocksource tsc-early",
    "[    0.032604] VFS: Disk quotas dquot_6.6.0",
    "[    0.032607] VFS: Dquot-cache hash table entries: 512 (order 0, 4096 bytes)",
    "[    0.032611] AppArmor: AppArmor Filesystem Enabled",
    "[    0.032618] pnp: PnP ACPI init",
    "[    0.032632] system 00:00: [mem 0xf0000000-0xf7ffffff] has been reserved",
    "[    0.032640] system 00:03: [io  0x040b] has been reserved",
    "[    0.032641] system 00:03: [io  0x04d6] has been reserved",
    "[    0.032642] system 00:03: [io  0x0c00-0x0c01] has been reserved",
    "[    0.032643] system 00:03: [io  0x0c14] has been reserved",
    "[    0.032644] system 00:03: [io  0x0c50-0x0c51] has been reserved",
    "[    0.032645] system 00:03: [io  0x0c52] has been reserved",
    "[    0.032646] system 00:03: [io  0x0c6c] has been reserved",
    "[    0.032647] system 00:03: [io  0x0c6f] has been reserved",
    "[    0.032648] system 00:03: [io  0x0cd8-0x0cdf] has been reserved",
    "[    0.032649] system 00:03: [io  0x0800-0x089f] has been reserved",
    "[    0.032650] system 00:03: [io  0x0b00-0x0b0f] has been reserved",
    "[    0.032651] system 00:03: [io  0x0b20-0x0b3f] has been reserved",
    "[    0.032652] system 00:03: [io  0x0900-0x090f] has been reserved",
    "[    0.032653] system 00:03: [io  0x0910-0x091f] has been reserved",
    "[    0.032654] system 00:03: [mem 0xfec00400-0xfec00fff window] has been reserved",
    "[    0.032655] system 00:03: [mem 0xfedc0000-0xfedc0fff window] has been reserved",
    "[    0.032656] system 00:03: [mem 0xfee00000-0xfee00fff window] has been reserved",
    "[    0.032657] system 00:03: [mem 0xfed80000-0xfed8ffff window] has been reserved",
    "[    0.032658] system 00:03: [mem 0xfec10000-0xfec10fff window] has been reserved",
    "[    0.032659] system 00:03: [mem 0xff000000-0xffffffff window] has been reserved",
    "[    0.032663] system 00:04: [io  0x0290-0x02af] has been reserved",
    "[    0.032668] system 00:05: [io  0x0a00-0x0a0f] has been reserved",
    "[    0.032669] system 00:05: [io  0x0a10-0x0a1f] has been reserved",
    "[    0.032670] system 00:05: [io  0x0a20-0x0a2f] has been reserved",
    "[    0.032671] system 00:05: [io  0x0a30-0x0a3f] has been reserved",
    "[    0.032672] system 00:05: [io  0x0a40-0x0a4f] has been reserved",
    "[    0.032676] pnp: PnP ACPI: found 6 devices",
    "[    0.038052] clocksource: acpi_pm: mask: 0xffffff max_cycles: 0xffffff, max_idle_ns: 2085701024 ns",
    "[    0.038058] NET: Registered PF_INET protocol family",
    "[    0.038075] IP idents hash table entries: 8192 (order: 4, 65536 bytes, linear)",
    "[    0.038086] tcp_listen_portaddr_hash hash table entries: 256 (order: 0, 4096 bytes, linear)",
    "[    0.038088] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)",
    "[    0.038090] TCP established hash table entries: 4096 (order: 3, 32768 bytes, linear)",
    "[    0.038093] TCP bind hash table entries: 4096 (order: 5, 131072 bytes, linear)",
    "[    0.038098] TCP: Hash tables configured (established 4096 bind 4096)",
    "[    0.038104] MPTCP token hash table entries: 512 (order: 1, 12288 bytes, linear)",
    "[    0.038107] UDP hash table entries: 256 (order: 1, 8192 bytes, linear)",
    "[    0.038109] UDP-Lite hash table entries: 256 (order: 1, 8192 bytes, linear)",
    "[    0.038112] NET: Registered PF_UNIX/PF_LOCAL protocol family",
    "[    0.038115] NET: Registered PF_XDP protocol family",
    "[    0.038117] pci_bus 0x00: resource 4 [io  0x0000-0x0cf7 window]",
    "[    0.038118] pci_bus 0x00: resource 5 [io  0x0d00-0xffff window]",
    "[    0.038119] pci_bus 0x00: resource 6 [mem 0x000a0000-0x000fffff window]",
    "[    0.038120] pci_bus 0x00: resource 7 [mem 0x80000000-0xdfffffff window]",
    "[    0.038121] pci_bus 0x00: resource 8 [mem 0xf0000000-0xfebfffff window]",
    "[    0.038123] pci 0000:00:01.2: PCI bridge to [bus 01-ff]",
    "[    0.038127] pci 0000:01:00.0: PCI bridge to [bus 02-ff]",
    "[    0.038131] pci 0000:02:00.0: PCI bridge to [bus 03]",
    "[    0.038150] pci 0000:02:04.0: PCI bridge to [bus 04]",
    "[    0.038169] pci 0000:02:08.0: PCI bridge to [bus 05]",
    "[    0.038188] pci 0000:02:09.0: PCI bridge to [bus 06]",
    "[    0.038207] pci 0000:02:0a.0: PCI bridge to [bus 07]",
    "[    0.038226] pci 0000:00:01.3: PCI bridge to [bus 08]",
    "[    0.038245] pci 0000:00:03.1: PCI bridge to [bus 09]",
    "[    0.038264] pci 0000:00:03.2: PCI bridge to [bus 0a]",
    "[    0.038283] pci 0000:00:07.1: PCI bridge to [bus 0b]",
    "[    0.038302] pci 0000:00:08.1: PCI bridge to [bus 0c]",
    "[    0.038321] pci 0000:00:08.2: PCI bridge to [bus 0d]",
    "[    0.038340] pci 0000:00:08.3: PCI bridge to [bus 0e]",
    "[    0.038359] pci_bus 0x00: resource 4 [io  0x0000-0x0cf7 window]",
    "[    0.038360] pci_bus 0x00: resource 5 [io  0x0d00-0xffff window]",
    "[    0.038361] pci_bus 0x00: resource 6 [mem 0x000a0000-0x000fffff window]",
    "[    0.038362] pci_bus 0x00: resource 7 [mem 0x80000000-0xdfffffff window]",
    "[    0.038363] pci_bus 0x00: resource 8 [mem 0xf0000000-0xfebfffff window]",
    "[    0.038365] pci 0000:0b:00.0: Video device with shadowed ROM at [mem 0xfe600000-0xfe67ffff]",
    "[    0.038367] PCI: CLS 64 bytes, default 64",
    "[    0.038372] PCI-DMA: Using software bounce buffering for IO (SWIOTLB)",
    "[    0.038373] software IO TLB: mapped [mem 0x000000007a000000-0x000000007e000000] (64MB)",
    "[    0.038375] Trying to unpack rootfs image as initramfs...",
    "[    0.038398] platform rtc_cmos: registered as rtc0",
    "[    0.038401] platform rtc_cmos: setting system clock to 2026-01-30T00:12:12 UTC (1754010732)",
    "[    0.038403] platform rtc_cmos: initialized",
    "[    0.038407] clocksource: tsc: mask: 0xffffffffffffffff max_cycles: 0x6d5a1b18, max_idle_ns: 440795202120 ns",
    "[    0.038410] clocksource: Switched to clocksource tsc",
    "[    0.038412] VFS: Mounted root (ext4 filesystem) readonly on device 259:0.",
    "[    0.038418] devtmpfs: mounted",
    "[    0.038420] Freeing init memory: 1234K",
    "[    0.038422] Run /sbin/init as init process",
    "[  OK  ] Started Journal Service.",
    "[  OK  ] Started Network Manager.",
    "[  OK  ] Started OpenSSH server daemon.",
    "[  OK  ] Finished Load/Save Random Seed.",
    "[  OK  ] Reached target Graphical Interface.",
  ];

  @override
  void initState() {
    super.initState();
    _startBootSequence();
    _startCursorBlink();
  }

  void _startBootSequence() {
    _bootTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (currentMessageIndex < bootMessages.length) {
        setState(() {
          currentMessageIndex++;
        });

        // 🔽 AUTO SCROLL ON EACH NEW LINE
        _scrollToBottom();
      } else {
        timer.cancel();

        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() => bootFinished = true);
          _scrollToBottom();

          Future.delayed(const Duration(seconds: 1), () {
            if (!mounted) return;
            setState(() => showPasswordPrompt = true);
            _scrollToBottom();

            Future.delayed(const Duration(seconds: 2), () {
              if (!mounted) return;
              setState(() => simulateLogin = true);
              _scrollToBottom();

              Future.delayed(const Duration(seconds: 1), () {
                if (!mounted) return;
                _goToNextScreen();
              });
            });
          });
        });
      }
    });
  }

  void _startCursorBlink() {
    bool visible = true;
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        cursor = visible ? '█' : ' ';
        visible = !visible;
      });
    });
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        controller: _scrollController, // 👈 REQUIRED 
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Boot messages
              ...List.generate(
                currentMessageIndex,
                (i) => Text(
                  bootMessages[i],
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12.sp,
                    color: bootMessages[i].contains('[  OK  ]')
                        ? Colors.green
                        : Colors.white,
                  ),
                ),
              ),
              if (bootFinished) ...[
                SizedBox(height: 16.h),
                Text(
                  'Windstrom5 Portfolio OS (GNU/Linux 6.8.0-windstrom x86_64)',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text(
                      'portfolio login: ',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'windstrom5',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                    if (!showPasswordPrompt)
                      Text(
                        cursor,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                if (showPasswordPrompt) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'Password: ',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 14.sp,
                      color: Colors.white,
                    ),
                  ),
                  if (simulateLogin) ...[
                    SizedBox(height: 8.h),
                    Text(
                      'Last login: Fri Jan 30 07:12:00 2026 from 127.0.0.1',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Welcome to Windstrom5 Portfolio OS!',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14.sp,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _goToNextScreen() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(), // 👈 CHANGE THIS
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }
}
