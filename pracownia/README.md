# Pracownia AI (komputer z kartą graficzną dla modeli 3D w KaWii)

`wlacz_wol.ps1` ustawia Wake-on-LAN po stronie Windows (karta Ethernet, zezwolenie na wybudzanie,
wyłączenie szybkiego uruchamiania), żeby komputer w domu (serwer KaWii) mógł sam obudzić pracownię.

Uruchomienie na pracowni (PowerShell jako administrator):

```powershell
irm https://raw.githubusercontent.com/wfirasiewicz-beep/KaWia-pobierz/main/pracownia/wlacz_wol.ps1 | iex
```

Na końcu skrypt wypisze, co ustawić w BIOS-ie (Wake on LAN włączone, ErP wyłączone). Raport: `C:\KuzniaAI\wol.txt`.
