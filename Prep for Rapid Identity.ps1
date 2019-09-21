<#

.SYNOPSIS
This Powershell script copies accountExpires attribute to idAutoPersonEndDate, and then sets accountExpires attribute to "never".

.NOTES
This is being done for Rapid Identity Connect project.

#AUTHOR
Josh Gold

#>

# Log the script results to a text file
Start-Transcript -Path "K:\Output\AccountExpirationScript.txt" -Append

Import-Module ActiveDirectory
$OU = "OU=SomeDepartment,OU=City,DC=ad,DC=fabrikam"
$Users = Get-ADUser -Filter * -SearchBase $OU -Properties Description
$CurrentDate = Get-Date
$DatePlusOneYear = $CurrentDate.AddDays(365)

foreach ( $User in $Users) {
    #Get accountExpires Date  
    $ExpirationDate = (Get-ADObject -Identity $User.DistinguishedName -Properties accountExpires).accountExpires

    # If expiration is set to never (Microsoft calls this December 31, 1600), then set expiration date to 1 year from today
        if ($ExpirationDate -eq 9223372036854775807) {
            $ConvertedExpirationDate = $DatePlusOneYear
    }
    # Otherwise convert the existing account expiration date to a usable format
        else { 
            $ConvertedExpirationDate = [datetime]::FromFileTime($ExpirationDate)
    }
   
    Write-Host "Account expires for $User.DistinguishedName on $ConvertedExpirationDate"

    #Copy date to attribute idAutoPersonEndDate
    Set-ADObject -Identity $User.DistinguishedName -Replace @{ idAutoPersonEndDate = $ConvertedExpirationDate } 
        
    #Set accountExpires attribute to "never"   
    Clear-ADAccountExpiration -Identity $User.DistinguishedName 
}

#Stop logging to "K:\Output\AccountExpirationScript.txt"
Stop-Transcript