
$badname = ""
$computers = get-content C:\Users\cwalker\Desktop\allcomputers.txt
$outfile = "c:\users\cwalker\desktop\listofinstalledsoftware.csv"
$butignore = "shitfuck" #PUT SOMETHING HERE IF YOU DONT USE IT OR IT WONT GRAB ANYTHING



foreach ($computer in $computers) {

    echo $computer
  
Invoke-Command -cn $computer {Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*" -and $_.DisplayName -notlike "*$using:butignore*"} | select PSComputerName, DisplayName, Publisher, uninstallstring} | Export-Csv $outfile -notypeinformation -Append

Invoke-Command -cn $computer {Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*" -and $_.DisplayName -notlike "*$using:butignore*"} | select PSComputerName, DisplayName, Publisher, uninstallstring} | Export-Csv $outfile -notypeinformation -Append

if (Invoke-Command -cn $computer {Test-Path -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*}) 
{
    echo "has local files"
Invoke-Command -cn $computer {Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*" -and $_.DisplayName -notlike "*$using:butignore*"} | select PSComputerName, DisplayName, Publisher, uninstallstring} | Export-Csv $outfile -notypeinformation -Append
}
else {
    echo "local user programs directory not found"
}

echo "-----"
echo " "

}