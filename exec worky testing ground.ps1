
$badname = "Autodesk"
$computers = get-content C:\Users\cwalker\Desktop\upstairsguys.txt
$butignore = "WLAN"


foreach ($computer in $computers) {
    

    echo $computer
    echo "--------"
    echo "UNINSTALLING:"

$bloats = @()

$bloats += Invoke-Command -cn $computer {Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*" -and $_.DisplayName -notlike "*$using:butignore*"} | select DisplayName, Publisher, uninstallstring}

$bloats += Invoke-Command -cn $computer {Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*" -and $_.DisplayName -notlike "*$using:butignore*"} | select DisplayName, Publisher, uninstallstring}

$bloats += Invoke-Command -cn $computer {Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall* | where {$_.Publisher -like "*$using:badname*" -and $_.DisplayName -notlike "*$using:butignore*"} | select DisplayName, Publisher, uninstallstring}

Foreach($bloat in $bloats) {

if ($bloat.uninstallstring -ne $null -and $bloat.uninstallstring.Contains("{") -and $bloat.uninstallstring -notlike "*C:\*")
{
    echo $bloat.DisplayName
    echo $bloat.uninstallstring

    $bleh = $bloat.uninstallstring
    $bleh = $bleh.Substring(0, $bleh.IndexOf('}')+1)
    $bleh = $bleh.Substring($bleh.IndexOf('{'))

    echo $bleh

    $params = @("/x",$bleh,"/qn")

    Invoke-Command -cn $computer {Start-Process -FilePath msiexec.exe -ArgumentList $using:params -Wait}
    echo "it be running the ID string way with $bleh as the thingy"

}
elseif($bloat.uninstallstring -eq $null)
{
    echo $bloat.DisplayName "appears to NOT have an uninstall string at all. This means it may not function."
}
elseif($bloat.uninstallstring -like "*C:\*") 
{

    $blexe = $bloat.uninstallstring
    $blexe = $blexe.Substring(0, $blexe.IndexOf('.')+4)
    $blexe = $blexe.Substring($blexe.IndexOf('C'))

    echo "it be trying to run the exe way with this garbage ass string"
    echo $blexe

    $paramsexe = @("/x",$blexe,"/qn")

    Invoke-Command -cn $computer {Start-Process -FilePath msiexec.exe -ArgumentList $using:paramsexe -Wait}


}


}

$bloatier = Invoke-Command -cn $computer {Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*"  -and $_.DisplayName -notlike "*$using:butignore*"}  | select DisplayName}

echo " "
echo "----------"
echo " "

if($bloatier -ne $null)
{
echo "the following are still in the registry: "
echo " "

foreach($bloat in $bloatier)
{
echo $bloat.DisplayName
}

}
else
{
echo "UNINSTALLATION SUCESSFULL BITCHES"    
}


echo "*******************************"

}