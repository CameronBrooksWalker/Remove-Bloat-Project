
$badname = "Dell"
$computers = get-content C:\Users\cwalker\Desktop\upstairsguys.txt
$butignore = "WLAN"


foreach ($computer in $computers) {
    

    echo $computer
    echo "--------"
    echo " "

$bloats = @()

echo "checking x64 registry"

$bloats += Invoke-Command -cn $computer {Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*" -and $_.DisplayName -notlike "*$using:butignore*" -and $_.displayname -notlike "*driver*"} | select DisplayName, Publisher, uninstallstring}
    
echo "checking x32 registry"

$bloats += Invoke-Command -cn $computer {Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*" -and $_.DisplayName -notlike "*$using:butignore*" -and $_.displayname -notlike "*driver*"} | select DisplayName, Publisher, uninstallstring}


if (Invoke-Command -cn $computer {Test-Path -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*}) 
{
echo "checking local user registry"

$bloats += Invoke-Command -cn $computer {Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*" -and $_.DisplayName -notlike "*$using:butignore*" -and $_.displayname -notlike "*driver*"} | select DisplayName, Publisher, uninstallstring}

}
else
{
    echo "This computer has no local user software installed"    
}

echo "-------"



If($bloats.Length -ne '0')
{
Foreach($bloat in $bloats) {

    echo "UNINSTALLING:"
    echo " "

if ($bloat.uninstallstring -ne $null -and $bloat.uninstallstring.Contains("{") -and $bloat.uninstallstring -notlike "*C:\*")
{
    echo $bloat.DisplayName

    $bleh = $bloat.uninstallstring

    $bleh = $bleh.Substring(0, $bleh.IndexOf('}')+1)
    $bleh = $bleh.Substring($bleh.IndexOf('{'))

    echo $bleh

    $params = @("/x",$bleh,"/qn")

    Invoke-Command -cn $computer {Start-Process -FilePath msiexec.exe -ArgumentList $using:params -Wait}

}
elseif($bloat.uninstallstring -eq $null)
{
    echo $bloat.DisplayName "appears to NOT have an uninstall string at all. This means it likely does not function."
}
elseif($bloat.uninstallstring -like "*C:\*") 
{
    echo $bloat.displayname  "utilizes an exe as its uninstaller, and thus cannot reliably be silently uninstalled. :("

}



}



$bloatier = @()

echo "------"

echo "Verifying uninstall."

$bloatier += Invoke-Command -cn $computer {Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*"  -and $_.DisplayName -notlike "*$using:butignore*" -and $_.displayname -notlike "*driver*"}  | select DisplayName}

echo "Verifying uninstall.."

$bloatier += Invoke-Command -cn $computer {Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*"  -and $_.DisplayName -notlike "*$using:butignore*" -and $_.displayname -notlike "*driver*"}  | select DisplayName}

echo "Verifying uninstall..."
if (Invoke-Command -cn $computer {Test-Path -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*})
{ 
$bloatier += Invoke-Command -cn $computer {Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*"  -and $_.DisplayName -notlike "*$using:butignore*" -and $_.displayname -notlike "*driver*"}  | select DisplayName}
}

echo " "
echo "----------"
echo " "

if($bloatier -ne $null)
{
echo "the following are still in the registry: "
echo " "

$bloatier | Export-Csv -Append C:\Users\cwalker\onesthatdidntdo.csv

foreach($bloat in $bloatier)
{
echo $bloat.DisplayName
}

}
else
{
echo "UNINSTALLATION PRESUMABLY SUCESSFUL"    
}


}else 
{
    echo "Device appears to have no bloat!"
}

echo " "
echo "*******************************"
}
