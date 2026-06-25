#Connects to Exchange Online console 
Connect-ExchangeOnline

#Allows emails to be moved from one inbox to another on the new outlook. Setting is disabled by default. Applies setting to default 365 Mailbox policy
Set-OwaMailboxPolicy -Identity "OwaMailboxPolicy-Default" -ItemsToOtherAccountsEnabled $true

#View list of settings on the default policy to see if it has been enabled.
Get-OwaMailboxPolicy
