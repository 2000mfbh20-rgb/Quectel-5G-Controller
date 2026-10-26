Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Standard Power Supply Advisory Text
$PowerAdvisoryText = @"
========================================================
   POWER SUPPLY GUIDE & HARDWARE WARNING (IMPORTANT!)
========================================================
1. STANDARD 5G USB DONGLE / ADAPTER USERS:
   - Can be plugged directly into any laptop or PC USB 
     port without an external power source.

2. 5G ROUTER BOX / ENCLOSURE USERS (WITH COOLING FAN):
   - WARNING: During network mode switching (4G <-> 5G), 
     the 5G box draws a sudden power spike up to 13W!
   - Standard laptop USB ports cannot handle this surge, 
     causing the internet connection to drop.
   - MUST use an external power source (Power Bank / 
     PD Charger) rated above 12W:
     * Minimum Power : 15W
     * Standard Power: 20W (Recommended for stability)
     * Voltage Range : Min DC 5V - Max DC 12V
========================================================

"@

# Function to send AT Commands to Quectel Modem
function Send-ATCommand {
    param([string]$PortName, [string]$Command, [int]$WaitMs = 600)
    if ([string]::IsNullOrWhiteSpace($PortName)) {
        return "Error: No COM Port selected or detected!`r`n"
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
        return "Error on $PortName : $($_.Exception.Message)`r`nMake sure PuTTY or other serial tools are closed!`r`n----------------------------------------`r`n"
    }
}

# Function to Auto-Detect Quectel AT Port
function Find-QuectelATPort {
    $allPorts = [System.IO.Ports.SerialPort]::GetPortNames()
    if ($allPorts.Count -eq 0) { return $null }

    # Layer 1: Search for "AT Port" in Device Manager (WMI)
    try {
        $wmiPorts = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction SilentlyContinue | 
                    Where-Object { $_.Name -match '\(COM\d+\)' }
        
        foreach ($item in $wmiPorts) {
            if ($item.Name -match 'AT Port' -and $item.Name -match '\((COM\d+)\)') {
                return $matches[1]
            }
        }
    } catch {}

    # Layer 2: Probe each COM Port with "ATI" handshake
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

# Main GUI Window Design
$form = New-Object System.Windows.Forms.Form
$form.Text = "Quectel 5G Quick Controller (Auto-Detect Port)"
$form.Size = New-Object System.Drawing.Size(535, 680)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Connection Status Label
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Status: Scanning for Quectel AT port..."
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblStatus.Location = New-Object System.Drawing.Point(15, 10)
$lblStatus.Size = New-Object System.Drawing.Size(490, 20)
$form.Controls.Add($lblStatus)

# COM Port Selection
$lblPort = New-Object System.Windows.Forms.Label
$lblPort.Text = "AT Port:"
$lblPort.Location = New-Object System.Drawing.Point(15, 38)
$lblPort.Size = New-Object System.Drawing.Size(55, 20)
$form.Controls.Add($lblPort)

$cmbPort = New-Object System.Windows.Forms.ComboBox
$cmbPort.Location = New-Object System.Drawing.Point(75, 35)
$cmbPort.Size = New-Object System.Drawing.Size(105, 25)
$form.Controls.Add($cmbPort)

# Update & Auto-Select Port Function
$UpdatePortList = {
    $cmbPort.Items.Clear()
    [System.IO.Ports.SerialPort]::GetPortNames() | ForEach-Object { $cmbPort.Items.Add($_) } | Out-Null
    
    $detected = Find-QuectelATPort
    if ($detected) {
        $cmbPort.SelectedItem = $detected
        $lblStatus.Text = "Status: Automatically detected on $detected"
        $lblStatus.ForeColor = [System.Drawing.Color]::DarkGreen
    } else {
        if ($cmbPort.Items.Count -gt 0) { $cmbPort.SelectedIndex = 0 }
        $lblStatus.Text = "Status: AT Port not verified (Please check USB connection)"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
}

$btnAutoDetect = New-Object System.Windows.Forms.Button
$btnAutoDetect.Text = "Auto-Detect AT Port"
$btnAutoDetect.BackColor = [System.Drawing.Color]::LightCyan
$btnAutoDetect.Location = New-Object System.Drawing.Point(190, 34)
$btnAutoDetect.Size = New-Object System.Drawing.Size(145, 26)
$btnAutoDetect.Add_Click($UpdatePortList)
$form.Controls.Add($btnAutoDetect)

$btnClearGuide = New-Object System.Windows.Forms.Button
$btnClearGuide.Text = "Power Guide / Clear Log"
$btnClearGuide.BackColor = [System.Drawing.Color]::LemonChiffon
$btnClearGuide.Location = New-Object System.Drawing.Point(345, 34)
$btnClearGuide.Size = New-Object System.Drawing.Size(160, 26)
$btnClearGuide.Add_Click({
    $txtOutput.Text = $PowerAdvisoryText
})
$form.Controls.Add($btnClearGuide)

# --- PERMANENT POWER SUPPLY WARNING BANNER (CLEAN ASCII) ---
$lblWarningBox = New-Object System.Windows.Forms.Label
$lblWarningBox.BorderStyle = "FixedSingle"
$lblWarningBox.BackColor = [System.Drawing.Color]::FromArgb(255, 250, 205)
$lblWarningBox.ForeColor = [System.Drawing.Color]::DarkRed
$lblWarningBox.Font = New-Object System.Drawing.Font("Segoe UI", 7.8, [System.Drawing.FontStyle]::Bold)
$lblWarningBox.Location = New-Object System.Drawing.Point(15, 68)
$lblWarningBox.Size = New-Object System.Drawing.Size(490, 76)
$lblWarningBox.Padding = New-Object System.Windows.Forms.Padding(5)
$lblWarningBox.Text = "POWER SUPPLY WARNING & GUIDE:`r`n" +
                      "- Standard 5G USB: Can be powered directly from any laptop/PC USB port.`r`n" +
                      "- 5G Router Box: Power spikes up to 13W (>12W) during 4G/5G switching! Must use`r`n" +
                      "  external charger/power bank min 15W (Standard 20W) | Voltage: DC 5V - DC 12V."
$form.Controls.Add($lblWarningBox)

# Output Log TextBox
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

# --- FUNCTION BUTTONS ---

# 1. Check Signal & Cell Info
$btnSignal = New-Object System.Windows.Forms.Button
$btnSignal.Text = "Check Signal Strength"
$btnSignal.Location = New-Object System.Drawing.Point(15, 154)
$btnSignal.Size = New-Object System.Drawing.Size(155, 35)
$btnSignal.Add_Click({
    $res1 = Send-ATCommand -PortName $cmbPort.Text -Command "AT+CSQ"
    $res2 = Send-ATCommand -PortName $cmbPort.Text -Command 'AT+QENG="servingcell"'
    $txtOutput.AppendText($res1 + $res2)
})
$form.Controls.Add($btnSignal)

# 2. Check Chip Temperature
$btnTemp = New-Object System.Windows.Forms.Button
$btnTemp.Text = "Check Chip Temp"
$btnTemp.Location = New-Object System.Drawing.Point(182, 154)
$btnTemp.Size = New-Object System.Drawing.Size(155, 35)
$btnTemp.Add_Click({
    $txtOutput.AppendText((Send-ATCommand -PortName $cmbPort.Text -Command "AT+QTEMP"))
})
$form.Controls.Add($btnTemp)

# 3. Check Chip Info & IMEI
$btnIMEI = New-Object System.Windows.Forms.Button
$btnIMEI.Text = "Chip Info & IMEI"
$btnIMEI.Location = New-Object System.Drawing.Point(350, 154)
$btnIMEI.Size = New-Object System.Drawing.Size(155, 35)
$btnIMEI.Add_Click({
    $res1 = Send-ATCommand -PortName $cmbPort.Text -Command "ATI"
    $res2 = Send-ATCommand -PortName $cmbPort.Text -Command "AT+GSN"
    $txtOutput.AppendText($res1 + $res2)
})
$form.Controls.Add($btnIMEI)

# 4. Auto Mode (5G + 4G)
$btnAuto = New-Object System.Windows.Forms.Button
$btnAuto.Text = "Mode: AUTO (5G + 4G)"
$btnAuto.Location = New-Object System.Drawing.Point(15, 202)
$btnAuto.Size = New-Object System.Drawing.Size(155, 35)
$btnAuto.Add_Click({
    $txtOutput.AppendText("[INFO] Switching to AUTO Mode... (Ensure 5G Box has 15W/20W DC5V-12V external power)`r`n")
    $res = Send-ATCommand -PortName $cmbPort.Text -Command 'AT+QNWPREFCFG="mode_pref",AUTO' -WaitMs 1500
    $txtOutput.AppendText($res)
})
$form.Controls.Add($btnAuto)

# 5. Lock 5G Only
$btn5G = New-Object System.Windows.Forms.Button
$btn5G.Text = "Lock: 5G SA/NSA Only"
$btn5G.Location = New-Object System.Drawing.Point(182, 202)
$btn5G.Size = New-Object System.Drawing.Size(155, 35)
$btn5G.Add_Click({
    $txtOutput.AppendText("[INFO] Locking 5G Only... (~13W Surge: Ensure 15W/20W external power is active)`r`n")
    $res = Send-ATCommand -PortName $cmbPort.Text -Command 'AT+QNWPREFCFG="mode_pref",NR5G' -WaitMs 1500
    $txtOutput.AppendText($res)
})
$form.Controls.Add($btn5G)

# 6. Lock 4G LTE Only
$btn4G = New-Object System.Windows.Forms.Button
$btn4G.Text = "Lock: 4G LTE Only"
$btn4G.Location = New-Object System.Drawing.Point(350, 202)
$btn4G.Size = New-Object System.Drawing.Size(155, 35)
$btn4G.Add_Click({
    $txtOutput.AppendText("[INFO] Locking 4G LTE... (~13W Surge: Ensure 15W/20W external power is active)`r`n")
    $res = Send-ATCommand -PortName $cmbPort.Text -Command 'AT+QNWPREFCFG="mode_pref",LTE' -WaitMs 1500
    $txtOutput.AppendText($res)
})
$form.Controls.Add($btn4G)

# 7. Switch to SIM 1
$btnSim1 = New-Object System.Windows.Forms.Button
$btnSim1.Text = "Use SIM Slot 1"
$btnSim1.Location = New-Object System.Drawing.Point(15, 250)
$btnSim1.Size = New-Object System.Drawing.Size(155, 35)
$btnSim1.Add_Click({
    $txtOutput.AppendText((Send-ATCommand -PortName $cmbPort.Text -Command "AT+QUIMSLOT=1"))
})
$form.Controls.Add($btnSim1)

# 8. Switch to SIM 2
$btnSim2 = New-Object System.Windows.Forms.Button
$btnSim2.Text = "Use SIM Slot 2"
$btnSim2.Location = New-Object System.Drawing.Point(182, 250)
$btnSim2.Size = New-Object System.Drawing.Size(155, 35)
$btnSim2.Add_Click({
    $txtOutput.AppendText((Send-ATCommand -PortName $cmbPort.Text -Command "AT+QUIMSLOT=2"))
})
$form.Controls.Add($btnSim2)

# 9. Reboot 5G Modem
$btnReboot = New-Object System.Windows.Forms.Button
$btnReboot.Text = "Reboot 5G Chip"
$btnReboot.BackColor = [System.Drawing.Color]::MistyRose
$btnReboot.Location = New-Object System.Drawing.Point(350, 250)
$btnReboot.Size = New-Object System.Drawing.Size(155, 35)
$btnReboot.Add_Click({
    $txtOutput.AppendText("[WARNING] Rebooting draws ~13W peak power. Ensure 15W-20W (DC 5V-12V) power is connected!`r`n")
    $txtOutput.AppendText((Send-ATCommand -PortName $cmbPort.Text -Command "AT+CFUN=1,1"))
})
$form.Controls.Add($btnReboot)

# 10. Manual AT Command Input
$txtCustom = New-Object System.Windows.Forms.TextBox
$txtCustom.Text = "AT+"
$txtCustom.Location = New-Object System.Drawing.Point(15, 304)
$txtCustom.Size = New-Object System.Drawing.Size(322, 25)
$form.Controls.Add($txtCustom)

$btnSendCustom = New-Object System.Windows.Forms.Button
$btnSendCustom.Text = "Send Manual Command"
$btnSendCustom.Location = New-Object System.Drawing.Point(350, 301)
$btnSendCustom.Size = New-Object System.Drawing.Size(155, 28)
$btnSendCustom.Add_Click({
    $txtOutput.AppendText((Send-ATCommand -PortName $cmbPort.Text -Command $txtCustom.Text))
})
$form.Controls.Add($btnSendCustom)

# Run Auto-Detect on startup
$form.Add_Shown({ &$UpdatePortList })

[void]$form.ShowDialog()