

$testy = "C:\Program Files\Autodesk\AdODIS\V1\Installer.exe -i uninstall --trigger_point system -m
C:\ProgramData\Autodesk\ODIS\metadata\{3E4FF57B-0533-3C99-A29F-C9E2838E11E5}\bundleManifest.xml -x
C:\ProgramData\Autodesk\ODIS\metadata\{3E4FF57B-0533-3C99-A29F-C9E2838E11E5}\SetupRes\manifest.xsd"

$testy = $testy.Substring(0, $testy.IndexOf('.')+4)
$testy = $testy.Substring($testy.IndexOf('C'))

echo $testy


