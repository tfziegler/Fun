# =====================================================================
# PowerShell Credit Card Validator
# =====================================================================
# Purpose:
#   Demonstrates basic credit-card-number validation in PowerShell.
#
# Supported card types:
#   - Visa
#   - Mastercard
#   - American Express
#
# Validation performed:
#   1. Removes spaces and dashes from the entered number.
#   2. Confirms that only numeric characters remain.
#   3. Determines the card type based on known numbering patterns.
#   4. Runs the Luhn checksum algorithm.
#   5. Displays a warning popup if validation fails.
#
# IMPORTANT:
#   This does NOT contact Visa, Mastercard, American Express, a bank,
#   or a payment processor. Passing validation only means that the
#   card number has a structurally valid format.
#
#   For testing, use synthetic/test card numbers rather than real
#   credit-card information.
# =====================================================================


# Load the Windows Presentation Framework assembly.
# This gives us access to the Windows MessageBox class that will
# be used for warning popups.
Add-Type -AssemblyName PresentationFramework


# =====================================================================
# FUNCTION: Test-Luhn
# =====================================================================
# Runs the Luhn algorithm against a card number.
#
# The Luhn algorithm is a checksum commonly used to detect accidental
# errors in credit-card numbers.
#
# NOTE:
#   Passing Luhn validation does NOT mean the card exists or can
#   actually be charged.
# =====================================================================
function Test-Luhn {

    param(
        [Parameter(Mandatory)]
        [string]$CardNumber
    )

    # Convert every character in the card number into an integer.
    #
    # Example:
    #   "1234"
    #
    # becomes:
    #   1, 2, 3, 4
    $digits = $CardNumber.ToCharArray() |
        ForEach-Object { :Parse($_) }


    # Reverse the array so we can process the digits starting
    # from the right side of the card number.
    :Reverse($digits)


    # This will contain the running checksum total.
    $sum = 0


    # Work through each digit in the card number.
    for ($i = 0; $i -lt $digits.Count; $i++) {

        $digit = $digits[$i]


        # Starting with the second digit from the right,
        # double every other digit.
        if ($i % 2 -eq 1) {

            $digit *= 2


            # If doubling produced a two-digit value,
            # subtract 9.
            #
            # Example:
            #   8 * 2 = 16
            #   16 - 9 = 7
            if ($digit -gt 9) {
                $digit -= 9
            }
        }


        # Add the processed digit to our checksum.
        $sum += $digit
    }


    # A number passes the Luhn test when the checksum
    # is evenly divisible by 10.
    return ($sum % 10 -eq 0)
}


# =====================================================================
# FUNCTION: Get-CardType
# =====================================================================
# Attempts to determine whether the number looks like a:
#
#   Visa
#   American Express
#   Mastercard
#
# Regular expressions are used to look at the numbering pattern
# and expected length of the card number.
# =====================================================================
function Get-CardType {

    param(
        [Parameter(Mandatory)]
        [string]$CardNumber
    )


    switch -Regex ($CardNumber) {

        # -------------------------------------------------------------
        # VISA
        # -------------------------------------------------------------
        # Visa card numbers begin with 4.
        #
        # This demonstration recognizes common Visa lengths.
        '^4\d{12}(\d{3})?(\d{3})?$' {
            return "Visa"
        }


        # -------------------------------------------------------------
        # AMERICAN EXPRESS
        # -------------------------------------------------------------
        # American Express cards:
        #
        #   Begin with 34 or 37
        #   Contain 15 digits
        '^3[47]\d{13}$' {
            return "American Express"
        }


        # -------------------------------------------------------------
        # MASTERCARD
        # -------------------------------------------------------------
        # Mastercard traditionally uses prefixes 51 through 55
        # and also supports the newer 2221 through 2720 range.
        '^(5[1-5]\d{14}|2(2[2-9][1-9]|2[3-9]\d{2}|[3-6]\d{3}|7[01]\d{2}|720)\d{12})$' {
            return "Mastercard"
        }


        # -------------------------------------------------------------
        # UNKNOWN
        # -------------------------------------------------------------
        # If none of our supported patterns match, mark the card
        # type as unknown.
        default {
            return "Unknown"
        }
    }
}


# =====================================================================
# FUNCTION: Show-InvalidCard
# =====================================================================
# Displays a Windows warning popup when the card fails validation.
#
# Windows controls the appearance of MessageBox warning dialogs.
# The warning icon provides the familiar yellow warning indicator.
# =====================================================================
function Show-InvalidCard {

    param(
        [string]$Message = "The card number entered is invalid."
    )


    # Display the warning dialog.
    [System.Windows.MessageBox]::Show(
        $Message,
        "INVALID CARD",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Warning
    )
}


# =====================================================================
# MAIN PROGRAM
# =====================================================================

# Clear the PowerShell window before displaying our simulated terminal.
Clear-Host


# Display the terminal header.
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "       PowerShell Card Terminal"          -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Supported: Visa | Mastercard | Amex" -ForegroundColor Gray
Write-Host ""


# =====================================================================
# GET CARD NUMBER
# =====================================================================

# Ask the user to enter a card number.
#
# NOTE:
# Read-Host is being used because this is just a demonstration.
# We do NOT save the card number to a file or transaction log.
$cardNumber = Read-Host "Enter card number"


# =====================================================================
# NORMALIZE INPUT
# =====================================================================

# Remove spaces and hyphens.
#
# This lets users enter the card number in formats such as:
#
#   4111 1111 1111 1111
#
# or
#
#   4111-1111-1111-1111
#
# Internally, both become:
#
#   4111111111111111
$cardNumber = $cardNumber -replace '[\s-]', ''


# =====================================================================
# VERIFY NUMERIC INPUT
# =====================================================================

# After removing spaces and dashes, make sure the value contains
# digits only.
if ($cardNumber -notmatch '^\d+$') {

    # Show our yellow warning popup.
    Show-InvalidCard "The card number must contain only numbers."

    # Stop the script because the input cannot be processed.
    return
}


# =====================================================================
# DETERMINE CARD TYPE
# =====================================================================

# Attempt to identify the card as Visa, Mastercard, or Amex.
$cardType = Get-CardType -CardNumber $cardNumber


# If the number does not match one of our supported card patterns,
# display the warning dialog and stop processing.
if ($cardType -eq "Unknown") {

    Show-InvalidCard "The card number does not match Visa, Mastercard, or American Express."

    return
}


# =====================================================================
# RUN LUHN VALIDATION
# =====================================================================

# Run the card number through the Luhn checksum.
if (-not (Test-Luhn -CardNumber $cardNumber)) {

    # The card format looked correct, but its checksum failed.
    Show-InvalidCard "The $cardType card number failed validation."

    return
}


# =====================================================================
# CARD PASSED VALIDATION
# =====================================================================

# If execution reaches this point:
#
#   - Input contained only numbers.
#   - The card matched a supported numbering pattern.
#   - The card passed the Luhn checksum.
#
# Again, this does NOT mean that the card is a real or active account.

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "              CARD VALID"                -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Card Type : " -NoNewline -ForegroundColor Gray
Write-Host $cardType -ForegroundColor Green

Write-Host "Status    : " -NoNewline -ForegroundColor Gray
Write-Host "VALID" -ForegroundColor Green

Write-Host ""