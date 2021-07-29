
$badname = "Autodesk"
$computer = 'c202b'

$bloats = Invoke-Command -cn $computer {Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*"} | select DisplayName, Publisher, uninstallstring}

Foreach($bloat in $bloats) {

if ($bloat.uninstallstring -ne $null -and $bloat.uninstallstring.Contains("{"))
{
    echo $bloat.DisplayName

    $bleh = $bloat.uninstallstring

    $bleh = $bleh.Substring(0, $bleh.IndexOf('}')+1)
    $bleh = $bleh.Substring($bleh.IndexOf('{'))

    echo $bleh
    echo " "

    $params = @("/x",$bleh,"/qn","/l*v","c:\diedell.log")

    Invoke-Command -cn $computer {Start-Process -FilePath msiexec.exe -ArgumentList $using:params -Wait}

}
elseif($bloat.uninstallstring -eq $null)
{
    echo $bloat.DisplayName "appears to NOT have an uninstall string at all. This means it likely does not function."
}
elseif($bloat.uninstallstring.Contains(".exe")) 
{
    echo $bloat.DisplayName "does not have the right kind of uninstall string. Fuck." 
}


}

$bloatier = Invoke-Command -cn $computer {Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*"} | select DisplayName}

echo " "
echo "--------------"
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