# =====================================================================
#  Wake-on-LAN na komputerze-pracowni (uruchomić na pracowni jako administrator).
#  Laptop (serwer KaWii) budzi pracownię "magicznym pakietem" przez kabel sieciowy.
#  Ten skrypt ustawia stronę Windows; BIOS trzeba ustawić ręcznie (instrukcja na końcu).
#    1. karta Ethernet: budzenie magicznym pakietem (także po wyłączeniu), bez oszczędzania energii łącza
#    2. zezwolenie karcie na wybudzanie komputera (powercfg)
#    3. wyłączenie szybkiego uruchamiania Windows (z nim karta po "Zamknij" nie nasłuchuje)
#  Raport: C:\KuzniaAI\wol.txt
# =====================================================================
$ErrorActionPreference = "Continue"
$id = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $id.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Uruchom PowerShell jako administrator i wykonaj polecenie ponownie." -ForegroundColor Red; return
}
$log = New-Object Collections.Generic.List[string]
function Say ($m, $c = "Gray") { Write-Host $m -ForegroundColor $c; $log.Add($m) }

# Karta przewodowa, która jest podłączona (nie Wi-Fi, nie wirtualna)
$nic = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" -and $_.MediaType -eq "802.3" } | Select-Object -First 1
if (-not $nic) { Say "[!] Nie widzę podłączonej karty Ethernet. Wake-on-LAN działa tylko przez kabel." Red; return }
Say "[i] Karta: $($nic.Name) / $($nic.InterfaceDescription), MAC $($nic.MacAddress)" Cyan

# 1. Zarządzanie energią karty
try { Set-NetAdapterPowerManagement -Name $nic.Name -WakeOnMagicPacket Enabled -ErrorAction Stop; Say "[+] Budzenie magicznym pakietem: włączone" Green }
catch { Say "[!] Nie udało się włączyć WakeOnMagicPacket: $($_.Exception.Message)" Yellow }

# Ustawienia zaawansowane karty (nazwy różnią się między producentami: Realtek, Intel...)
foreach ($p in Get-NetAdapterAdvancedProperty -Name $nic.Name) {
    $name = $p.DisplayName
    $want = $null
    if ($name -match "(?i)wake.*magic|magic.*packet|shutdown.*wake|wake.*shutdown|wake on lan|wol") { $want = "on" }
    elseif ($name -match "(?i)energy.efficient|green.ethernet|power.saving|eee|gigabit lite|auto disable gigabit") { $want = "off" }
    if (-not $want) { continue }
    $values = $p.ValidDisplayValues
    $pick = if ($want -eq "on") { $values | Where-Object { $_ -match "(?i)^(enabled|włączone|on|wł)" } | Select-Object -First 1 }
            else { $values | Where-Object { $_ -match "(?i)^(disabled|wyłączone|off|wył)" } | Select-Object -First 1 }
    if ($pick -and $p.DisplayValue -ne $pick) {
        try { Set-NetAdapterAdvancedProperty -Name $nic.Name -DisplayName $name -DisplayValue $pick -ErrorAction Stop; Say "[+] $name -> $pick" Green }
        catch { Say "[!] ${name}: $($_.Exception.Message)" Yellow }
    } elseif ($pick) { Say "[=] ${name}: $pick (już było)" }
}

# 2. Zezwolenie na wybudzanie
$dev = (Get-PnpDevice -Class Net | Where-Object { $_.FriendlyName -eq $nic.InterfaceDescription } | Select-Object -First 1).FriendlyName
if ($dev) { powercfg /deviceenablewake "$dev" | Out-Null; Say "[+] Karta może wybudzać komputer (powercfg)" Green }
Say ("[i] Urządzenia, które mogą wybudzać: " + ((powercfg /devicequery wake_armed) -join ", "))

# 3. Szybkie uruchamianie Windows wyłączone
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name HiberbootEnabled -Value 0 -Type DWord
Say "[+] Szybkie uruchamianie Windows: wyłączone" Green

Say ""
Say "MAC tej karty: $($nic.MacAddress)  (laptop budzi adres zapisany w C:\KaWia\dane\pracownia.json; jeśli się różni, podaj go Claude na laptopie)" Cyan
Say ""
Say "TERAZ BIOS (jednorazowo, przy starcie komputera klawisz Del albo F2):" Yellow
Say "  - włącz: Wake on LAN / Power On By PCI-E / Resume by PCI-E Device / PME Event Wake Up (nazwa zależy od płyty)"
Say "  - wyłącz: ErP Ready / ErP / EuP / Deep Sleep (te tryby odcinają zasilanie karty sieciowej po wyłączeniu)"
Say "  - zapisz i wyjdź (F10)"
Say "Sprawdzenie: uśpij albo wyłącz pracownię, a na laptopie zamów model w KaWii: serwer sam ją obudzi."
New-Item -ItemType Directory -Force C:\KuzniaAI | Out-Null
[IO.File]::WriteAllLines("C:\KuzniaAI\wol.txt", $log)
