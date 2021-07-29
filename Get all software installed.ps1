

$computer = get-content C:\Users\cwalker\Documents\allusercomputers.txt


foreach ($computer in $computer)
{

Try {
    
Invoke-Command -cn $computer -ErrorAction Stop {Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | select DisplayName, Publisher, VersionMajor, VersionMinor, uninstallstring, estimatedsize } | Export-Csv -path c:\users\cwalker\desktop\allsoftwaremaybe.csv -notypeinformation -Append

echo $computer" yes likey"

} Catch { echo $computer" is VERY ANGY"}
}