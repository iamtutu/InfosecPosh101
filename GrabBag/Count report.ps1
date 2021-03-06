function Get-AccessData { 
param ( 
    [string]$sql,
    [string]$database,
    [switch]$grid 
) 
	$conn = New-Object System.Data.OleDb.OleDbConnection("Provider=Microsoft.ACE.OLEDB.12.0; Data Source=$database")
    $conn.Open() 
      
    $cmd = New-Object System.Data.OleDb.OleDbCommand($sql, $conn) 
    $reader = $cmd.ExecuteReader() 

    
    $dt = New-Object System.Data.DataTable 
    $dt.Load($reader) 
    $conn.Close()    
    if ($grid) {$dt | Out-GridView -Title "$sql" } 
    else {$dt} 

}
$output = @()
$dir ="D:\"
$files = gci -path $dir -filter *.accdb
 
foreach($accessdb in $files){

write-host "processing $($accessdb.name)"

    $strPatchCritSQL ='SELECT DISTINCT PluginInfo.pluginHash AS pluginHash, PluginInfo.ID ' +`
             'FROM PluginInfo INNER JOIN (Hosts INNER JOIN ReportItem ON Hosts.ID = ReportItem.HostID) ON PluginInfo.ID = ReportItem.PID' +`
             ' WHERE (Not (PluginInfo.patch_publication_date) Is Null and (PluginInfo.risk_factor)="Critical");'

    $strHostCritSQL =   'SELECT DISTINCT Hosts.ID, Hosts.name FROM PluginInfo ' +`
                    'INNER JOIN (Hosts INNER JOIN ReportItem ON Hosts.ID = ReportItem.HostID) ON PluginInfo.ID = ReportItem.PID '+`
                    'WHERE (Not (PluginInfo.patch_publication_date) Is Null and (PluginInfo.risk_factor)="Critical");'

    $strPatchHighSQL ='SELECT DISTINCT PluginInfo.pluginHash AS pluginHash, PluginInfo.ID ' +`
             'FROM PluginInfo INNER JOIN (Hosts INNER JOIN ReportItem ON Hosts.ID = ReportItem.HostID) ON PluginInfo.ID = ReportItem.PID' +`
             ' WHERE (Not (PluginInfo.patch_publication_date) Is Null and (PluginInfo.risk_factor)="High");'
             
    $strHostHighSQL =   'SELECT DISTINCT Hosts.ID, Hosts.name FROM PluginInfo ' +`
                    'INNER JOIN (Hosts INNER JOIN ReportItem ON Hosts.ID = ReportItem.HostID) ON PluginInfo.ID = ReportItem.PID '+`
                    'WHERE (Not (PluginInfo.patch_publication_date) Is Null and (PluginInfo.risk_factor)="High");'
             
    $dtpatchCrit = Get-AccessData $strPatchCritSQL $accessdb.fullname         
    $dthostCrit = Get-AccessData $strHostCritSQL $accessdb.fullname  
    $dtPatchHigh = Get-AccessData $strPatchHighSQL $accessdb.fullname  
    $dtHostHigh = Get-AccessData $strHostHighSQL $accessdb.fullname

    $output += new-object psobject -property @{
                db = [system.io.path]::getfilename($accessdb)
                patches_crit = $dtpatchCrit | measure-object | %{$_.count}
                hosts_crit = $dthostCrit | measure-object | %{$_.count}
                patches_high = $dtPatchHigh | measure-object | %{$_.count}
                hosts_high = $dtHostHigh | measure-object | %{$_.count}
                }

}

Write-Output $output