# Quectel 5G Quick Controller (GUI) | Kawalan Pantas Quectel 5G

A lightweight, native Windows PowerShell GUI application designed to control and monitor **Quectel RM500 Series (RM500U-EA / RM500Q)** 5G modules without manually typing AT commands in PuTTY or checking Device Manager for COM port numbers.

Available in both **English** and **Malay (Bahasa Melayu)**.

---

## 🌟 Key Features / Ciri-Ciri Utama
* **Smart Auto-Detect AT Port:** Automatically scans Windows WMI and performs an `ATI` serial handshake to lock onto the active Quectel AT Port at startup.
* **One-Click Signal & Cell Diagnostics:** Reads `AT+CSQ` and `AT+QENG="servingcell"` to display active 5G SA/NSA or 4G LTE bands, RSRP, RSRQ, and SINR.
* **Real-Time Thermal Monitoring:** Queries `AT+QTEMP` across all internal sensors (`soc-thermal`, `pa-thermal`, `pa5g-thermal`, `board-thermal`).
* **Instant Network Mode Locking:** Switch effortlessly between **AUTO (5G + 4G)**, **5G Only (NR5G)**, and **4G LTE Only**.
* **Dual-SIM Slot Switching:** Toggle between **SIM Slot 1** and **SIM Slot 2** (`AT+QUIMSLOT`) via software without opening the enclosure.
* **Custom AT Terminal:** Built-in command bar for sending manual AT commands directly to the modem.

---

## ⚠️ CRITICAL HARDWARE & POWER SUPPLY GUIDE (READ BEFORE USE!)

Every **5G USB Dongle** and **5G Router Enclosure Box** has a different internal board layout, M.2 Key-B slot orientation, antenna pigtail routing (IPEX1 / MHF4), and power delivery requirement. **Please verify how your 5G module is mounted and powered:**

### 1. Standard 5G USB Dongle / Bare Adapter
* **Mounting & Setup:** The 5G M.2 module is mounted onto an open or compact USB 3.0 adapter board without an active cooling fan or onboard Ethernet controller.
* **Power Requirement:** Can be plugged **directly into any standard laptop or PC USB port** without requiring an external power source.

### 2. 5G Router Enclosure Box (With Cooling Fan / Ethernet Port)
* **Mounting & Setup:** The 5G M.2 module is installed inside an aluminum enclosure with thermal pads contacting the casing/heatsink, an active cooling fan, and a USB-C / DC power splitter board.
* **Power Spike Discovery (13W Surge!):** Hardware power metering reveals that during network mode switching (`4G <-> 5G`) or RF rebooting, the 5G box draws a sudden peak surge of **12W to 13W**!
* **Why Internet Drops on Laptop USB:** Standard laptop/PC USB ports (limited to 4.5W–7.5W) cannot handle a 13W surge. The resulting voltage drop (*brownout*) causes the USB/NDIS data connection to disconnect even though the 5G radio stays connected to the cell tower.
* **Mandatory Solution:** You **MUST** connect an external power source (PD Power Bank or Wall Charger) to the enclosure's dedicated power port:
  * **Minimum Power:** 15W
  * **Recommended Standard:** 20W
  * **Voltage Range:** Minimum DC 5V – Maximum DC 12V

---

## 🛡️ Antivirus & VirusTotal False Positive Notice

We provide **3 file formats** in this repository so you can choose the method you trust most:

| File Format | English Version | Malay Version | Description |
| :--- | :--- | :--- | :--- |
| **Batch Launcher (`.bat`)** | `Launcher_5G_EN.bat` | `Pelancar_5G.bat` | **100% Antivirus Safe.** Runs the raw `.ps1` script cleanly without a console window. |
| **PowerShell Source (`.ps1`)** | `Quectel5G_EN.ps1` | `Quectel5G.ps1` | **100% Open-Source.** Inspect the raw code yourself in Notepad before running. |
| **Standalone App (`.exe`)** | `Quectel_5G_Controller.exe` | `Kawalan_Quectel_5G.exe` | Compiled from the `.ps1` script using the official Microsoft `ps2exe` module. |

### Why do some Antivirus / VirusTotal engines flag the `.exe`?
If you scan the `.exe` files on VirusTotal, major trusted security vendors (**Bitdefender, Malwarebytes, Kaspersky, Acronis, AhnLab**) confirm the file is **Clean / Undetected**. However, a few heuristic AI engines (such as *MaxSecure* or *SentinelOne Static ML*) may label the `.exe` as `susgen` (Suspect Generic) or `Suspicious PE`.
* **Reason:** `ps2exe` wraps a PowerShell script inside an executable container that communicates directly with hardware `COM` ports. Heuristic AI engines automatically flag unknown self-compiled wrappers as a precaution (**False Positive**).
* **What to do:** If your antivirus blocks the `.exe`, simply add it to your antivirus **Exclusions / Whitelist**, OR delete the `.exe` and use **`Launcher_5G_EN.bat` + `Quectel5G_EN.ps1`** instead!

---

## 🚀 How to Use / Cara Penggunaan

### Method 1: Using the `.bat` Launcher (Recommended & Zero Antivirus Alerts)
1. Download **`Launcher_5G_EN.bat`** and **`Quectel5G_EN.ps1`** (or **`Pelancar_5G.bat`** and **`Quectel5G.ps1`** for Malay) into the **same folder**.
2. Double-click the **`.bat`** file. The GUI controller will open immediately.

### Method 2: Using the Standalone `.exe`
1. Download **`Quectel_5G_Controller.exe`** (English) or **`Kawalan_Quectel_5G.exe`** (Malay).
2. Double-click to launch directly (no `.ps1` or `.bat` file needed).

---

# 🇲🇾 Panduan Ringkas Bahasa Melayu

### 1. Perbezaan Pemasangan USB 5G Biasa vs Kotak 5G (Penting!)
Setiap penyesuai (**USB Dongle 5G**) dan **Kotak 5G (Enclosure Box)** mempunyai reka bentuk papan litar (PCB), kedudukan slot M.2, susunan wayar antena (`IPEX1` / `MHF4`), serta keperluan kuasa yang berbeza:
* **Pengguna USB 5G Biasa:** Cip 5G dipasang terus pada papan penyesuai USB ringkas tanpa kipas. Ia boleh dicucuk terus ke port USB laptop atau PC tanpa memerlukan bekalan kuasa luar.
* **Pengguna Kotak 5G (Berkipas):** Cip 5G dipasang di dalam kotak aluminium lengkap dengan *thermal pad* dan kipas penyejuk. Ketika menukar rangkaian (`4G <-> 5G`), kotak ini menarik lonjakan kuasa mengejut sehingga **13W (melebihi 12W)**! Port USB laptop biasa tidak mampu menampung beban ini dan akan menyebabkan internet terputus.
  * **Penyelesaian Wajib:** Sila cucuk kuasa tambahan (*Power Bank* / Pengecas PD) berkuasa **Minimum 15W (Standard 20W)** dengan julat voltan **Min DC 5V – Maks DC 12V** pada port kuasa kotak 5G anda.

### 2. Nota Keselamatan Antivirus (Positif Palsu / False Positive)
* Fail `.exe` dibina menggunakan modul `ps2exe` daripada kod asal `.ps1`. Sesetengah enjin AI di VirusTotal mungkin memberi amaran generik (`susgen`) kerana ia merupakan fail bungkusan skrip baharu yang mengakses *COM Port*.
* Jika anda ragu-ragu atau antivirus anda menyekat fail `.exe`, anda hanya perlu memuat turun fail **`Pelancar_5G.bat`** bersama **`Quectel5G.ps1`** ke dalam satu folder yang sama, dan klik dua kali pada fail **`.bat`** tersebut. Anda juga boleh membuka fail `.ps1` menggunakan Notepad untuk melihat sendiri keseluruhan kod sumber yang bersih dan selamat.
