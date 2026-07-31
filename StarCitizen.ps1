<#
.SYNOPSIS
    Recupere la fiche publique d'un Citizen sur robertsspaceindustries.com
    et l'ajoute a une blacklist locale (CSV) si elle n'y est pas deja.

.DESCRIPTION
    Powershell script fait par Ounet pour la communaute du LYS - 23 fev 2022.
    Compatible Windows PowerShell 5.1 et PowerShell 7+ (n'utilise plus le
    moteur Internet Explorer / ParsedHtml, deprecie et absent de pwsh).

.PARAMETER Name
    Nom (ou handle) du Citizen a rechercher. Si omis, il est demande de
    facon interactive. Le script propose ensuite de chainer les recherches.

.EXAMPLE
    .\StarCitizen.ps1 -Name "SomeHandle"
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Name
)

$ErrorActionPreference = 'Stop'

Clear-Host

$outfile = Join-Path $env:USERPROFILE 'Documents\Citizen_of_Star_Citizen.csv'
$fields  = 'Name', 'Handle Name', 'Role', 'Organisation', 'Spectrum Iden', 'Organisation Rank', 'Enlisted', 'Location', 'Fluency'

function Get-CitizenEntries
{
    param([Parameter(Mandatory)][string]$HtmlContent)

    $found = [regex]::Matches(
        $HtmlContent,
        '(?is)<p[^>]*class="[^"]*\bentry\b[^"]*"[^>]*>(.*?)</p>'
    )

    foreach ($item in $found)
    {
        $text = $item.Groups[1].Value -replace '<[^>]+>', ''
        $text = [System.Net.WebUtility]::HtmlDecode($text) -replace '\s+', ' '
        $text.Trim()
    }
}

function Test-CitizenAlreadyBlacklisted
{
    param([Parameter(Mandatory)][string]$CitizenName)

    if (-not (Test-Path -Path $outfile)) { return $null }

    Import-Csv -Path $outfile | Where-Object {
        $_.Name -eq $CitizenName -or $_.'Handle Name' -eq $CitizenName
    }
}

while ($true)
{
    if (-not $Name)
    {
        $Name = Read-Host -Prompt 'Entre le nom du Citizen que vous cherchez'
    }

    if ([string]::IsNullOrWhiteSpace($Name))
    {
        Write-Host 'Nom vide, arret.' -ForegroundColor Yellow
        break
    }

    $encodedName = [uri]::EscapeDataString($Name)
    $uri = "https://robertsspaceindustries.com/citizens/$encodedName"
    $response = $null

    try
    {
        $response = Invoke-WebRequest -Uri $uri -UseBasicParsing
    }
    catch
    {
        $statusCode = $null
        if ($_.Exception.Response) { $statusCode = [int]$_.Exception.Response.StatusCode }

        if ($statusCode -eq 404)
        {
            Write-Host "Citizen '$Name' introuvable (404)." -ForegroundColor Red
        }
        else
        {
            Write-Host "Erreur lors de la recuperation de la page : $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    if ($response)
    {
        $existing = Test-CitizenAlreadyBlacklisted -CitizenName $Name

        if ($existing)
        {
            Write-Host 'Existe deja dans la blacklist :' -ForegroundColor Red
            $existing | Format-Table -AutoSize
        }
        else
        {
            $entries = Get-CitizenEntries -HtmlContent $response.Content

            if (-not $entries -or $entries.Count -eq 0)
            {
                Write-Host "Aucune information trouvee pour '$Name' (profil prive ou inexistant)." -ForegroundColor Yellow
            }
            else
            {
                $record = [ordered]@{}
                for ($i = 0; $i -lt $fields.Count; $i++)
                {
                    $record[$fields[$i]] = if ($i -lt $entries.Count) { $entries[$i] } else { '' }
                }

                if (Test-Path -Path $outfile)
                {
                    [pscustomobject]$record | Export-Csv -Path $outfile -Append -NoTypeInformation -Encoding UTF8
                }
                else
                {
                    [pscustomobject]$record | Export-Csv -Path $outfile -NoTypeInformation -Encoding UTF8
                }

                Write-Host "Citizen '$Name' ajoute a la blacklist." -ForegroundColor Green
            }
        }
    }

    $Name = $null
    $again = Read-Host -Prompt 'Chercher un autre Citizen ? (O/N)'
    if ($again -notmatch '^[oOyY]') { break }
}
