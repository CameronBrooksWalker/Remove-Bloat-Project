

$testy = "C:\Program Files\Autodesk\DWG TrueView 2021 - English\Setup\en-us\Setup\Setup.exe /P {28B89EEF-4128-0409-0100-CF3F3A09B77D} /M AOEM /language en-US"

$testy = $testy.Substring(0, $testy.IndexOf('}')+1)
$testy = $testy.Substring($testy.IndexOf('{'))

echo $testy