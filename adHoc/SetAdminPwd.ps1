[CmdletBinding()]
param(
$computername = $env:COMPUTERNAME,
#$username = "Administrator",
$username = (gwmi Win32_UserAccount -Filter "LocalAccount = True AND SID LIKE 'S-1-5-21-%-500'" -ComputerName $computerName | Select -First 1 ).Name,
$password,
[switch] $Test
)

process{
$VerbosePreference = "Continue"
if (-not $password){$password = GeneratePassword}
if (-not $test){
	try{
		([adsi]("WinNT://$($computerName)/$($username)")).SetPassword($password)
		SaveToSCCMDB $computername $password
		Write-Verbose "Password $password set for $username on $computername"
		}
	catch{
		Write-Verbose "Error while setting password $password for $username on $computername"
		}
	}
else{
	Write-Verbose "TEST: Password $password set for $username on $computername"
	write-host "The generated password is $password"
	}
}


begin{
#save verbosepreference to revert upon end of script
$script:verbosepref = $VerbosePreference
function GeneratePassword {
param(
[byte]$LowerCase = 4, 
[byte]$UpperCase = 2, 
[byte]$Numbers = 2, 
[byte]$Specials = 0, 
[switch]$AvoidAmbiguous = $true
)

if ($AvoidAmbiguous){
	$arrLCase = "abcdefghijkmnpqrstuvwxyz".ToCharArray()
	$arrUCase = "ABCDEFGHJKLMNPQRSTUVWXYZ".ToCharArray()
	$arrNum = "23456789".ToCharArray()
	$arrSpec = "!#$%&()*+,-./:;<=>?@[\]^_{}~".ToCharArray()
	}
else{
	$arrLCase = "abcdefghijklmnopqrstuvwxyz".ToCharArray()
	$arrUCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()
	$arrNum = "1234567890".ToCharArray()
	$arrSpec = "!#$%&()*+,-./:;<=>?@[\]^_{}~|".ToCharArray()
	}
$aCharacters = @()
	
#Selects Lower Case Characters
if ($LowerCase -gt 0){$aCharacters += $arrLCase | get-random -count $LowerCase}
#Selects Upper Case Characters
if ($UpperCase -gt 0){$aCharacters += $arrUCase | get-random -count $UpperCase}
#Selects Numerical Characters
if ($Numbers -gt 0){$aCharacters += $arrNum | get-random -count $Numbers}
#Selects Special Characters
if ($Specials -gt 0){$aCharacters += $arrSpec | get-random -count $Specials}
#Randomize characters and return as string
$result = [string]::join("", $($aCharacters | get-random -count $aCharacters.length))
Write-Verbose "generated password = $result"
return $result
}# end function

function SaveToSCCMDB ($computername,$password){
try{
	$conn = New-Object System.Data.SqlClient.SqlConnection("Server=sccmsql.domain.com; Database=LocalPwd; User Id=lpwd;Password=hiddenpwd;")
	$conn.Open()
	$cmd = $conn.CreateCommand()
	$cmd.CommandText = "EXEC [dbo].[SetLocalAdminPassword] @ComputerName = N'$computername', @Password = N'$password'"
	$cmd.ExecuteNonQuery()
	$conn.Close()
	}
catch{}
}
}#end begin

end{
$VerbosePreference = $script:verbosepref
}