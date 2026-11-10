Add-Type -AssemblyName PresentationFramework

function Test-Luhn {
    param(
        [Parameter(Mandatory)]
        [string]$CardNumber
    )

    $digits = $CardNumber.ToCharArray() |
        ForEach-Object { :Parse($_) }

    :Reverse($digits)

    $sum = 0

    for ($i = 0; $i -lt $digits.Count; $i++) {
        $digit = $digits[$i]

        if ($i % 2 -eq 1) {
            $digit *= 2

            if ($digit -gt 9) {
                $digit -= 9
            }
        }

        $sum += $digit
    }

    return ($sum % 10 -eq 0)
}

function Get-CardType {
    param(
        [Parameter(Mandatory)]
        [string]$CardNumber
    )

    switch -Regex ($CardNumber) {

        '^4\d{12}(\d{3})?(\d{3})?$' {
            return "Visa"
        }

        '^3[47]\d{13}$' {
            return "American Express"
        }

        '^(5[1-5]\d{14}|2(2[2-9][1-9]|2[3-9]\d{2}|[3-6]\d{3}|7[01]\d{2}|720)\d{12})$' {
            return "Mastercard"
        }

        default {
            return "Unknown"
        }
    }
}

function Show-InvalidCard {
    param(
        [string]$Message = "The card number entered is invalid."
    )

    [System.Windows.MessageBox]::Show(
        $Message,
        "INVALID CARD",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Warning
    )
}

Clear-Host

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "       PowerShell Card Terminal"
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Supported: Visa | Mastercard | Amex" -ForegroundColor Gray
Write-Host ""

$cardNumber = Read-Host "Enter card number"

# Remove spaces and dashes
$cardNumber = $cardNumber -replace '[\s-]', ''

# Make sure we only have digits
if ($cardNumber -notmatch '^\d+$') {
    Show-InvalidCard "The card number must contain only numbers."
    return
}

$cardType = Get-CardType -CardNumber $cardNumber

if ($cardType -eq "Unknown") {
    Show-InvalidCard "The card number does not match Visa, Mastercard, or American Express."
    return
}

if (-not (Test-Luhn -CardNumber $cardNumber)) {
    Show-InvalidCard "The $cardType card number failed validation."
    return
}

Write-Host ""
Write-Host "CARD VALID" -ForegroundColor Green
Write-Host "Card Type : $cardType" -ForegroundColor Green
Write-Host "Status    : VALID" -ForegroundColor Green
Write-Host ""
