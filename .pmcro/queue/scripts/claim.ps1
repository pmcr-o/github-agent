[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$WorkerId,[string]$Kind='',[string]$MessageId='')
Import-Module (Join-Path $PSScriptRoot 'queue.psm1') -Force -DisableNameChecking
Assert-SafeId $WorkerId 'WorkerId';$c=Get-QueueConfig;$q=Get-QueueRoot;& (Join-Path $PSScriptRoot 'recover.ps1')|Out-Null;$now=UtcNow
$files=@(Get-ChildItem -LiteralPath (Join-Path $q 'inbox') -Filter '*.json' -File|Sort-Object LastWriteTimeUtc,Name)
foreach($f in $files){
  if($MessageId -and $f.BaseName -ne $MessageId){continue}
  try{$m=Read-QueueJson $f.FullName;Validate-Message $m $c|Out-Null;if($Kind -and [string]$m.kind -ne $Kind){continue};$s=Read-State $m.messageId;if($s -and $s.availableAt -and [DateTimeOffset]::Parse([string]$s.availableAt) -gt $now){continue};$dest=Join-Path $q "processing/$($m.messageId).json";Move-Item -LiteralPath $f.FullName -Destination $dest -ErrorAction Stop}catch{continue}
  if(-not $s){$s=[pscustomobject]@{messageId=$m.messageId;attempt=0;availableAt=$m.availableAt;lastError=''}};$s.attempt=[int]$s.attempt+1;$s.status='PROCESSING';$s.claimedBy=$WorkerId;$s.leaseUntil=Iso $now.AddSeconds([int]$c.leaseSeconds);$s.updatedAt=Iso $now;Write-State $m.messageId $s
  [ordered]@{status='CLAIMED';path=$dest;message=$m;delivery=$s}|ConvertTo-Json -Depth 30;return
}
Write-Output 'NO_MESSAGE';return
