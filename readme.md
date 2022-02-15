This write-up documents the Powershell script I’ve composed to remotely uninstall all software from a remote computer, filtered by whatever criteria you deem fit. This script is by far the longest I’ve written into notes, so be forewarned. I also highly recommended looking over the “Remote Software Check” note/script in this directory. Many of the same principals will apply, and it’s important to have an idea of what all software you’ll be uninstalling using this script.


All of the “echo” statements are purely for aesthetics and providing verbal cues to the technician running the script about the status of the process. They can be ignored or removed if you’d like, which will ever so slightly improve performance.

It’s also worth mentioning that this process COULD be done using the WMI “product” applet, however even Microsoft themselves recommends against this, as that method is unnecessarily slow, and will often actually attempt to run a “repair” on all of the programs you query, regardless of whether you run a method on them. For this reason, we are begrudgingly using the Registry and UninstallString method, which leverages MSIEXEC. This method is not without flaws, namely that it cannot uninstall programs the utilize an .exe for installation as opposed to an .msi. However, this was the most efficient, by-the-books, non-intrusive method of remote installation I was able to create. I may attempt to add the WMI method as a failover in the event of .exe installers, but that is outside the scope of the current project.




First, we have our declared variables. In this case, $badname allows you to specify a name to filter by software publisher. Setting anything in the $badname variable will limit the returned results to exclusively software where the “Publisher” field contains the string from $badname. This is particularly useful for publishers with inconsistent names, like “Dell, Dell Inc., Dell Software, Dell EMC, etc.”. Any software by the developer entered in this variable will attempt to be removed.

$computers is just a list pointed at a .txt with a list of all domain computers, return delimited, like so

    C100a 
    C101a 
    C102b 

$butignore is a string that allows you to ignore a particular program name. This would be applicable if you wanted documentation on every piece of software by Dell, but that DOES NOT mention the word “WLAN” in the title. If you decide NOT to utilize $butignore, you MUST put a random string inside of it. It works by ignoring entries that contain the contents of string, so if you leave it empty, it will match EVERY program and ignore all of them. I find that leaving “ignorestring” in there when not in use is perfect.

Finally, $outfile is the path for a .csv generated at the end of the script showing what software was detected, but was unable to be uninstalled.

    $badname = "Dell"
    $computers = get-content C:\Users\cwalker\Desktop\ICorpComputers.txt
    $butignore = "WLAN"
    $outfile = “C:\Users\cwalker\Desktop\onesthatdidntdo.csv”



Then we iterate through the list of computers, passing the currently in-use name to the $computer variable.

    foreach ($computer in $computers) {
        
    
        echo $computer
        echo "--------"
        echo " "

Here we declare the list of objects, $bloats. This variable will contain all of the software grabbed by the rest of this process prior to uninstallation.

    $bloats = @()
    
    echo "checking x64 registry"


These individual lines have a lot going on, so I’ll step through it piece-by-piece. 

$bloats += simply appends the new data to the $bloats variable.

    $bloats +=

Invoke-Command, used in conjunction with the -cn flag and the $computer variable allows us to send the remaining bits of code to the remote computer.

 

    Invoke-Command -cn $computer 

Get-ItemProperty searches this one of three locations in which Windows stores program data in the Registry. This particular entry is solely for 64bit programs. We’ll search the other two locations further down.

    {Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 

This line filters our search to software where the “Publisher” field contains the string we put in $badname, the “Displayname” field does NOT match the string we placed in $butignore, and explicitly ignores any software that has the word “driver” in it. These filters can be changed to suit your use-case, and a comprehensive list of fields with which you can filter can be found at the bottom of this document.

    where {$_.Publisher -like "*$using:badname*" -and $_.DisplayName -notlike "*$using:butignore*" -and $_.displayname -notlike "*driver*"} 

This line further filters and only grabs the fields relevant to our process, namely “displayname, publisher, and uninstallstring”.

    | select DisplayName, Publisher, uninstallstring}
        
    echo "checking x32 registry"

This line does the same as the above line, except while checking the registry location for 32bit software.

    $bloats += Invoke-Command -cn $computer {Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {$_.Publisher -like "*$using:badname*" -and $_.DisplayName -notlike "*$using:butignore*" -and $_.displayname -notlike "*driver*"} | select DisplayName, Publisher, uninstallstring}

This final bit does almost the same as the previous two, though it of course checks the third and final location that Windows stores program data. The issue however, is that this directory only contains software installed for individual users, and it EXISTS if that computer has a piece of software installed in that manner. Many do not and checking for a non-existent registry entry makes Powershell unhappy, so there’s an additional if-statement checking for the existence of the directory before running the final line.

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


Now that we’ve gathered all the information about the software, and which ones we need to remove, we commence the uninstallation process.


Here we verify that there IS software listed in the $bloats variable that needs to be removed, and iterate through the list.

    If($bloats.Length -ne '0')
    {
    
        echo "UNINSTALLING:"
        echo " "
    
    Foreach($bloat in $bloats) {

The actual act of running the uninstallation is unfortunately convoluted. The uninstallation string placed in the registry is formatted in a way that’s intended to run in CMD. Obviously, we’re using powershell for the flexibility and featureset, so we have to change the string.

Your average uninstall string looks like “MsiExec.exe /I{5155A9DC-98B2-4D01-BDD2-673F84170225}”, but we have to check and make sure its not formatted the .exe way, which looks like “C:\Windows\Installer\{AF92DD77-6C33-4677-B11F-1A212543F618}\_setup.exe /U:”. We check to confirm that the string contains a “{“ so we know we can use the string, and ignore it and output an error if it’s completely blank, or contains “C:\”.

Then we chop out everything on either side of the curly “{}” brackets, so we’re left with just the productid, which is the long string of numbers and letters.

    if ($bloat.uninstallstring -ne $null -and $bloat.uninstallstring.Contains("{") -and $bloat.uninstallstring -notlike "*C:\*")
    {
        echo $bloat.DisplayName
    
        $bleh = $bloat.uninstallstring
    
        $bleh = $bleh.Substring(0, $bleh.IndexOf('}')+1)
        $bleh = $bleh.Substring($bleh.IndexOf('{'))
    
        echo $bleh

Then we create a variable for the parameters for MSIEXEC. /x tells it to uninstall, /qn tells it to do so silently, and $bleh tells it what product to uninstall via the productid.

    $params = @("/x",$bleh,"/qn")

Here we do another Invoke-Command to run MSIEXEC remotely, we call MSIEXEC, pass it the parameters from our above variable, and (VERY CRUCIALLY) add the -Wait flag. Without the -Wait, our remote session will terminate before the uninstall has finished, which effectively cancels it immediately. Unfortunately, the -Wait flag can only be assigned to the “Start-Process” command, which runs withing our Invoke-Command, and then calls MSIEXEC. It really is “Turtles All The Way Down”.

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


And with that, all files that can be uninstalled, are gone! Now we go back and check the registry again to verify that they actually disappeared. This is basically the exact same process as when we grabbed the entries to remove in the beginning, only with $bloatier as our list variable instead of $bloats.

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

Here we check $bloatier for content, and write any files left to a .csv in your location of choice (set in the $outfile variable) so you can reference them later. If $bloatier is empty, then mission success! Congrats!

    if($bloatier -ne $null)
    {
    echo "the following are still in the registry: "
    echo " "
    
    $bloatier | Export-Csv $outfile -notypeinformation -Append
    
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






The list of available filters for the registry software list is, with example entries, as follows:


| Filter                | Example                                                                                                                                           |
|-----------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| AuthorizedCDFPrefix : |                                                                                                                                                   |
| Comments              | :                                                                                                                                                 |
| Contact               | :                                                                                                                                                 |
| DisplayVersion        | : 2.81.0.0                                                                                                                                        |
| HelpLink              | :                                                                                                                                                 |
| HelpTelephone         | :                                                                                                                                                 |
| InstallDate           | : 20210623                                                                                                                                        |
| InstallLocation       | :                                                                                                                                                 |
| InstallSource         | : C:\Windows\TEMP\                                                                                                                                |
| ModifyPath            | : MsiExec.exe /X{E5A95BC5-81DF-4F0C-B910-B59DD012F037}                                                                                            |
| NoModify              | : 1                                                                                                                                               |
| NoRepair              | : 1                                                                                                                                               |
| Publisher             | : Microsoft Corporation                                                                                                                           |
| Readme                | :                                                                                                                                                 |
| Size                  | :                                                                                                                                                 |
| EstimatedSize         | : 1104                                                                                                                                            |
| UninstallString       | : MsiExec.exe /X{E5A95BC5-81DF-4F0C-B910-B59DD012F037}                                                                                            |
| URLInfoAbout          | :                                                                                                                                                 |
| URLUpdateInfo         | :                                                                                                                                                 |
| VersionMajor          | : 2                                                                                                                                               |
| VersionMinor          | : 81                                                                                                                                              |
| WindowsInstaller      | : 1                                                                                                                                               |
| Version               | : 38862848                                                                                                                                        |
| Language              | : 0                                                                                                                                               |
| DisplayName           | : Microsoft Update Health Tools                                                                                                                   |
| PSPath                | Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\{E5A95BC5-81DF-4F0C-B910-B59DD012F037} |
| PSParentPath          | : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall                                      |
| PSChildName           | : {E5A95BC5-81DF-4F0C-B910-B59DD012F037}                                                                                                          |
| PSDrive               | : HKLM                                                                                                                                            |
| PSProvider            | : Microsoft.PowerShell.Core\Registry                                                                                                              |
