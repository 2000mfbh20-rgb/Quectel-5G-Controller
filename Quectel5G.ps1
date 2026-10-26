Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Teks Panduan & Amaran Kuasa Standard
$PowerAdvisoryText = @"
========================================================
   PANDUAN & AMARAN BEKALAN KUASA (PENTING!)
========================================================
1. PENGGUNA USB 5G (DONGLE / ADAPTER BIASA):
   - Boleh cucuk dan guna terus pada mana-mana port USB 
     laptop atau PC tanpa sumber kuasa tambahan.

2. PENGGUNA KOTAK 5G (ROUTER ENCLOSURE + KIPAS):
   - AMARAN: Semasa pertukaran rangkaian (4G <-> 5G), 
     kotak 5G menarik lonjakan kuasa sehingga 13W!
   - Port USB laptop biasa tidak mampu menampung kuasa
     ini dan akan menyebabkan internet terputus.
   - WAJIB guna sumber kuasa tambahan (Power Bank / 
     Pengecas) melebihi 12W:
     * Kuasa Minimum : 15W
     * Kuasa Standard: 20W (Disyorkan untuk kestabilan)
     * Julat Voltan  : Minimum DC 5V - Maksimum DC 12V
========================================================

"@

# Fungsi menghantar AT Command ke Modem Quectel
function Send-ATCommand {
    param([string]$PortName, [string]$Command, [int]$WaitMs = 600)
    if ([string]::IsNullOrWhiteSpace($PortName)) {
        return "Ralat: Tiada COM Port dipilih atau dikesan!`r`n"
    }
    
    $port = New-Object System.IO.Ports.SerialPort $PortName, 115200, None, 8, one
    $port.ReadTimeout = 1500
    $port.WriteTimeout = 1500
    $port.DtrEnable = $true
    $port.RtsEnable = $true
    
    try {
        $port.Open()
        $port.DiscardInBuffer()
        $port.Write("$Command`r`n")
        Start-Sleep -Milliseconds $WaitMs
        $response = $port.ReadExisting()
        $port.Close()
        return ">>> $Command ($PortName)`r`n$($response.Trim())`r`n----------------------------------------`r`n"
    } catch {
        if ($port.IsOpen) { $port.Close() }
        return "Ralat pada $PortName : $($_.Exception.Message)`r`nPastikan PuTTY sudah ditutup!`r`n----------------------------------------`r`n"
    }
}

# Fungsi Automatik Kesan AT Port Quectel
function Find-QuectelATPort {
    $allPorts = [System.IO.Ports.SerialPort]::GetPortNames()
    if ($allPorts.Count -eq 0) { return $null }

    # Lapisan 1: Cari nama "AT Port" terus dari rekod Device Manager (WMI)
    try {
        $wmiPorts = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction SilentlyContinue | 
                    Where-Object { $_.Name -match '\(COM\d+\)' }
        
        foreach ($item in $wmiPorts) {
            if ($item.Name -match 'AT Port' -and $item.Name -match '\((COM\d+)\)') {
                return $matches[1]
            }
        }
    } catch {}

    # Lapisan 2: Uji setiap COM Port dengan arahan "ATI" untuk cari respon Quectel
    foreach ($p in $allPorts) {
        $testPort = New-Object System.IO.Ports.SerialPort $p, 115200, None, 8, one
        $testPort.ReadTimeout = 300
        $testPort.WriteTimeout = 300
        $testPort.DtrEnable = $true
        $testPort.RtsEnable = $true
        try {
            $testPort.Open()
            $testPort.DiscardInBuffer()
            $testPort.Write("ATI`r`n")
            Start-Sleep -Milliseconds 250
            $reply = $testPort.ReadExisting()
            $testPort.Close()
            if ($reply -match "Quectel|RM500|OK") {
                return $p
            }
        } catch {
            if ($testPort.IsOpen) { $testPort.Close() }
        }
    }
    return $null
}

# Reka Bentuk Tetingkap Utama (GUI)
$form = New-Object System.Windows.Forms.Form
$form.Text = "Kawalan Pantas Quectel 5G (Auto-Detect Port)"
$form.Size = New-Object System.Drawing.Size(535, 680)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Label Status Sambungan
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Status: Mengimbas port Quectel..."
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblStatus.Location = New-Object System.Drawing.Point(15, 10)
$lblStatus.Size = New-Object System.Drawing.Size(490, 20)
$form.Controls.Add($lblStatus)

# Pilihan COM Port
$lblPort = New-Object System.Windows.Forms.Label
$lblPort.Text = "AT Port:"
$lblPort.Location = New-Object System.Drawing.Point(15, 38)
$lblPort.Size = New-Object System.Drawing.Size(55, 20)
$form.Controls.Add($lblPort)

$cmbPort = New-Object System.Windows.Forms.ComboBox
$cmbPort.Location = New-Object System.Drawing.Point(75, 35)
$cmbPort.Size = New-Object System.Drawing.Size(105, 25)
$form.Controls.Add($cmbPort)

# Fungsi Kemas Kini & Auto-Pilih Port
$UpdatePortList = {
    $cmbPort.Items.Clear()
    [System.IO.Ports.SerialPort]::GetPortNames() | ForEach-Object { $cmbPort.Items.Add($_) } | Out-Null
    
    $detected = Find-QuectelATPort
    if ($detected) {
        $cmbPort.SelectedItem = $detected
        $lblStatus.Text = "Status: Berjaya dikesan secara automatik pada $detected"
        $lblStatus.ForeColor = [System.Drawing.Color]::DarkGreen
    } else {
        if ($cmbPort.Items.Count -gt 0) { $cmbPort.SelectedIndex = 0 }
        $lblStatus.Text = "Status: AT Port tidak dapat disahkan (Sila semak sambungan USB)"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
}

$btnAutoDetect = New-Object System.Windows.Forms.Button
$btnAutoDetect.Text = "Auto-Kesan AT Port"
$btnAutoDetect.BackColor = [System.Drawing.Color]::LightCyan
$btnAutoDetect.Location = New-Object System.Drawing.Point(190, 34)
$btnAutoDetect.Size = New-Object System.Drawing.Size(145, 26)
$btnAutoDetect.Add_Click($UpdatePortList)
$form.Controls.Add($btnAutoDetect)

$btnClearGuide = New-Object System.Windows.Forms.Button
$btnClearGuide.Text = "Nota Kuasa / Bersih Log"
$btnClearGuide.BackColor = [System.Drawing.Color]::LemonChiffon
$btnClearGuide.Location = New-Object System.Drawing.Point(345, 34)
$btnClearGuide.Size = New-Object System.Drawing.Size(160, 26)
$btnClearGuide.Add_Click({
    $txtOutput.Text = $PowerAdvisoryText
})
$form.Controls.Add($btnClearGuide)

# --- PANEL AMARAN BEKALAN KUASA (KEMAS & TIADA SIMBOL PELIK) ---
$lblWarningBox = New-Object System.Windows.Forms.Label
$lblWarningBox.BorderStyle = "FixedSingle"
$lblWarningBox.BackColor = [System.Drawing.Color]::FromArgb(255, 250, 205)
$lblWarningBox.ForeColor = [System.Drawing.Color]::DarkRed
$lblWarningBox.Font = New-Object System.Drawing.Font("Segoe UI", 7.8, [System.Drawing.FontStyle]::Bold)
$lblWarningBox.Location = New-Object System.Drawing.Point(15, 68)
$lblWarningBox.Size = New-Object System.Drawing.Size(490, 76)
$lblWarningBox.Padding = New-Object System.Windows.Forms.Padding(5)
$lblWarningBox.Text = "AMARAN & PANDUAN KUASA:`r`n" +
                      "- USB 5G Biasa: Boleh guna kuasa terus daripada mana-mana port USB laptop/PC.`r`n" +
                      "- Kotak 5G: Lonjakan kuasa mencecah 13W (>12W) semasa tukar 4G/5G! Wajib guna`r`n" +
                      "  pengecas/power bank min 15W (Standard 20W) | Voltan: Min DC 5V - Maks DC 12V."
$form.Controls.Add($lblWarningBox)

# Kotak Paparan Output (Log)
$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Multiline = $true
$txtOutput.ScrollBars = "Vertical"
$txtOutput.ReadOnly = $true
$txtOutput.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtOutput.BackColor = [System.Drawing.Color]::Black
$txtOutput.ForeColor = [System.Drawing.Color]::LightGreen
$txtOutput.Location = New-Object System.Drawing.Point(15, 350)
$txtOutput.Size = New-Object System.Drawing.Size(490, 275)
$txtOutput.Text = $PowerAdvisoryText
$form.Controls.Add($txtOutput)

# --- KUMPULAN BUTANG FUNGSI ---

# 1. Semak Signal & Info Sel
$btnSignal = New-Object System.Windows.Forms.Button
$btnSignal.Text = "Semak Kekuatan Signal"
$btnSignal.Location = New-Object System.Drawing.Point(15, 154)
$btnSignal.Size = New-Object System.Drawing.Size(155, 35)
$btnSignal.Add_Click({
    $res1 = Send-ATCommand -PortName $cmbPort.Text -Command "AT+CSQ"
    $res2 = Send-ATCommand -PortName $cmbPort.Text -Command 'AT+QENG="servingcell"'
    $txtOutput.AppendText($res1 + $res2)
})
$form.Controls.Add($btnSignal)

# 2. Semak Suhu Cip
$btnTemp = New-Object System.Windows.Forms.Button
$btnTemp.Text = "Semak Suhu Cip (Temp)"
$btnTemp.Location = New-Object System.Drawing.Point(182, 154)
$btnTemp.Size = New-Object System.Drawing.Size(155, 35)
$btnTemp.Add_Click({
    $txtOutput.AppendText((Send-ATCommand -PortName $cmbPort.Text -Command "AT+QTEMP"))
})
$form.Controls.Add($btnTemp)

# 3. Semak Info Cip & IMEI
$btnIMEI = New-Object System.Windows.Forms.Button
$btnIMEI.Text = "Info Cip & IMEI"
$btnIMEI.Location = New-Object System.Drawing.Point(350, 154)
$btnIMEI.Size = New-Object System.Drawing.Size(155, 35)
$btnIMEI.Add_Click({
    $res1 = Send-ATCommand -PortName $cmbPort.Text -Command "ATI"
    $res2 = Send-ATCommand -PortName $cmbPort.Text -Command "AT+GSN"
    $txtOutput.AppendText($res1 + $res2)
})
$form.Controls.Add($btnIMEI)

# 4. Mod Auto (5G + 4G)
$btnAuto = New-Object System.Windows.Forms.Button
$btnAuto.Text = "Mod: AUTO (5G + 4G)"
$btnAuto.Location = New-Object System.Drawing.Point(15, 202)
$btnAuto.Size = New-Object System.Drawing.Size(155, 35)
$btnAuto.Add_Click({
    $txtOutput.AppendText("[INFO] Menukar ke Mod AUTO... (Pastikan Kotak 5G disambung ke kuasa 15W/20W DC5V-12V)`r`n")
    $res = Send-ATCommand -PortName $cmbPort.Text -Command 'AT+QNWPREFCFG="mode_pref",AUTO' -WaitMs 1500
    $txtOutput.AppendText($res)
})
$form.Controls.Add($btnAuto)

# 5. Kunci 5G Sahaja
$btn5G = New-Object System.Windows.Forms.Button
$btn5G.Text = "Kunci: 5G Sahaja"
$btn5G.Location = New-Object System.Drawing.Point(182, 202)
$btn5G.Size = New-Object System.Drawing.Size(155, 35)
$btn5G.Add_Click({
    $txtOutput.AppendText("[INFO] Mengunci 5G... (Lonjakan ~13W: Pastikan kuasa luar 15W/20W aktif pada Kotak 5G)`r`n")
    $res = Send-ATCommand -PortName $cmbPort.Text -Command 'AT+QNWPREFCFG="mode_pref",NR5G' -WaitMs 1500
    $txtOutput.AppendText($res)
})
$form.Controls.Add($btn5G)

# 6. Kunci 4G LTE Sahaja
$btn4G = New-Object System.Windows.Forms.Button
$btn4G.Text = "Kunci: 4G LTE Sahaja"
$btn4G.Location = New-Object System.Drawing.Point(350, 202)
$btn4G.Size = New-Object System.Drawing.Size(155, 35)
$btn4G.Add_Click({
    $txtOutput.AppendText("[INFO] Mengunci 4G LTE... (Lonjakan ~13W: Pastikan kuasa luar 15W/20W aktif pada Kotak 5G)`r`n")
    $res = Send-ATCommand -PortName $cmbPort.Text -Command 'AT+QNWPREFCFG="mode_pref",LTE' -WaitMs 1500
    $txtOutput.AppendText($res)
})
$form.Controls.Add($btn4G)

# 7. Tukar ke SIM 1
$btnSim1 = New-Object System.Windows.Forms.Button
$btnSim1.Text = "Guna Slot SIM 1"
$btnSim1.Location = New-Object System.Drawing.Point(15, 250)
$btnSim1.Size = New-Object System.Drawing.Size(155, 35)
$btnSim1.Add_Click({
    $txtOutput.AppendText((Send-ATCommand -PortName $cmbPort.Text -Command "AT+QUIMSLOT=1"))
})
$form.Controls.Add($btnSim1)

# 8. Tukar ke SIM 2
$btnSim2 = New-Object System.Windows.Forms.Button
$btnSim2.Text = "Guna Slot SIM 2"
$btnSim2.Location = New-Object System.Drawing.Point(182, 250)
$btnSim2.Size = New-Object System.Drawing.Size(155, 35)
$btnSim2.Add_Click({
    $txtOutput.AppendText((Send-ATCommand -PortName $cmbPort.Text -Command "AT+QUIMSLOT=2"))
})
$form.Controls.Add($btnSim2)

# 9. Restart Cip Modem
$btnReboot = New-Object System.Windows.Forms.Button
$btnReboot.Text = "Restart Cip 5G"
$btnReboot.BackColor = [System.Drawing.Color]::MistyRose
$btnReboot.Location = New-Object System.Drawing.Point(350, 250)
$btnReboot.Size = New-Object System.Drawing.Size(155, 35)
$btnReboot.Add_Click({
    $txtOutput.AppendText("[AMARAN] Restart Cip 5G menarik kuasa puncak ~13W. Pastikan kuasa 15W-20W (DC 5V-12V) disambungkan!`r`n")
    $txtOutput.AppendText((Send-ATCommand -PortName $cmbPort.Text -Command "AT+CFUN=1,1"))
})
$form.Controls.Add($btnReboot)

# 10. Baris Arahan Manual (Custom AT)
$txtCustom = New-Object System.Windows.Forms.TextBox
$txtCustom.Text = "AT+"
$txtCustom.Location = New-Object System.Drawing.Point(15, 304)
$txtCustom.Size = New-Object System.Drawing.Size(322, 25)
$form.Controls.Add($txtCustom)

$btnSendCustom = New-Object System.Windows.Forms.Button
$btnSendCustom.Text = "Hantar Arahan Manual"
$btnSendCustom.Location = New-Object System.Drawing.Point(350, 301)
$btnSendCustom.Size = New-Object System.Drawing.Size(155, 28)
$btnSendCustom.Add_Click({
    $txtOutput.AppendText((Send-ATCommand -PortName $cmbPort.Text -Command $txtCustom.Text))
})
$form.Controls.Add($btnSendCustom)

# Jalankan Auto-Detect sebaik sahaja tetingkap dibuka
$form.Add_Shown({ &$UpdatePortList })

[void]$form.ShowDialog()