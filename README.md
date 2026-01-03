# Oprava: Když nereaguje panel Start (Windows 11)

Tento repozitář obsahuje PowerShell skript `startOprava1.ps1`, který provede postupné kroky opravy nabídky Start — od nejméně invazivních akcí po hloubkovou re-registraci AppX komponent. Skript je navržen pro spuštění s právy Administrátora a je idempotentní (kontroluje existenci souborů a procesů před jejich použitím).

Poznámka: Používejte tento skript na vlastní riziko. Doporučuji vytvořit bod obnovení systému nebo zálohu před provedením hlubších zásahů.

Obsah
- startOprava1.ps1 — PowerShell skript provádějící opravy
- Tento README — postup a vysvětlení kroků

Jak použít
1. Otevřete PowerShell jako Administrátor:
   - Stiskněte Start → napište `powershell` → pravým tlačítkem klikněte na "Windows PowerShell" nebo "Windows Terminal" → Spustit jako správce.
2. Zkopírujte skript na cestu C:\ (pokud jste skript stáhli nebo ho máte v jiném adresáři), v konzoli s právy administrátora spusťte:
   - Kopírování (pokud máte skript ve stejném adresáři, stačí přizpůsobit cestu):
     ```
     Copy-Item -Path .\startOprava1.ps1 -Destination C:\ -Force
     ```
3. Spusťte skript:
   ```
   cd C:\
   .\startOprava1.ps1
   ```
4. Pokud skript vyžaduje znovuspouštění procesu Start, systém jej obvykle automaticky znovu spustí po ukončení. Pokud ne, (můžete se odhlásit a přihlásit nebo restartovat explorer).

Kontrola stavu indexování Windows Search
- Pokud podezříváte, že problém souvisí s indexováním, zkontrolujte stav služby WSearch:
```powershell
Get-Service -Name "WSearch" | Select-Object -Property Status, StartType
```
- Pro restart služby (vyžaduje admin práva):
```powershell
Restart-Service -Name "WSearch" -Force
```

Co skript dělá (shrnutí kroků a logiky)
1. Kontrola práv: Skript se sám pokusí přepnout do jádra s právy administrátora (pokud není spuštěn jako admin, zkusí se znovu spustit s UAC).
2. Terminace procesů (nejméně invazivní): Pořadí zabití procesů startuje u izolovaných procesů Start (např. StartMenuExperienceHost, ShellExperienceHost, SearchUI apod.). Prosté ukončení procesu nutí Windows proces automaticky znovu spustit při dalším použití Startu a to často vyřeší závěsy nebo zamrznutí.
3. Restart/ověření služby Windows Search (WSearch): Pokud je problém s vyhledáváním nebo indexováním, restart služby často pomůže. Skript kontroluje stav a pokusí se službu restartovat bezpečným způsobem.
4. Re-registrace AppX aplikací (hlubší oprava): Skript vyhledá AppX manifesty v `C:\Windows\SystemApps\` a pokusí se je znovu zaregistrovat pomocí `Add-AppxPackage -Register -DisableDevelopmentMode`. Tento příkaz nevyžaduje internet — pracuje s lokální kopií manifestů v `C:\Windows\SystemApps`. Parametr `-DisableDevelopmentMode` v kombinaci s `-Register` říká systému: „Vezmi tuto systémovou aplikaci a znovu ji zaregistruj do databáze aktuálního uživatele.“
5. Idempotence a bezpečnost: Před spuštěním operací skript kontroluje existenci souborů (`Test-Path`) a přítomnost procesů/služeb, aby se minimalizovaly chyby či zbytečné akce. Případné chyby se logují do `C:\startOprava1_log.txt`.

Kdy skript nestačí
- Pokud problém přetrvává i po re-registraci AppX komponent, může být poškozen index vyhledávání hlubší úrovně nebo poškození profilu uživatele. Doporučuji:
  - Zkontrolovat stav WSearch (viz výše)
  - Vytvořit nový lokální uživatelský účet a ověřit, zda Start funguje v novém profilu
  - Pokud je potřeba, obnovit systém ze zálohy nebo použít „Obnovení systému“

Bezpečnostní upozornění
- Skript provádí operace se systémovými komponentami; spouštějte jej pouze s důvěrou ke zdroji a pod administrátorskými právy.
- Ujistěte se, že nepřerušujete kritické systémové procesy, pokud systém provádí důležité aktualizace.

Pokud chcete, mohu:
- upravit skript (např. přidat volbu pro pouze testovací režim / dry-run),
- nebo přidat krok automatického vytvoření bodu obnovení před re-registrací AppX.
