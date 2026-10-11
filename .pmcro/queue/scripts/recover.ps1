param()
Import-Module (Join-Path $PSScriptRoot 'queue.psm1') -Force -DisableNameChecking
$c=Get-QueueConfig;$q=Get-QueueRoot;$now=UtcNow
foreach($dir in @('inbox','processing','delayed')){
  foreach($f in @(Get-ChildItem -LiteralPath (Join-Path $q $dir) -Filter '*.json' -File -ErrorAction SilentlyContinue)){
    try{$m=Read-QueueJson $f.FullName;Validate-Message $m $c|Out-Null}catch{continue}
    if($m.expiresAt -and [DateTimeOffset]::Parse([string]$m.expiresAt) -le $now){$dest=Join-Path $q "dead-letter/$($m.messageId).json";Move-Item -LiteralPath $f.FullName -Destination $dest -Force;$s=Read-State $m.messageId;if(-not $s){$s=[pscustomobject]@{messageId=$m.messageId;attempt=0}};$s.status='DEAD_LETTER';$s.lastError='expired';$s.updatedAt=Iso $now;Write-State $m.messageId $s;continue}
    $s=Read-State $m.messageId
    if($dir -eq 'processing' -and $s -and $s.leaseUntil -and [DateTimeOffset]::Parse([string]$s.leaseUntil) -le $now){
      if([int]$s.attempt -ge [int]$c.maxAttempts){$dest=Join-Path $q "dead-letter/$($m.messageId).json";$s.status='DEAD_LETTER';$s.lastError='lease expired at max attempts'}else{$dest=Join-Path $q "delayed/$($m.messageId).json";$delay=[int]$c.retryBaseSeconds*[Math]::Pow(2,[Math]::Max(0,[int]$s.attempt-1));$s.status='DELAYED';$s.availableAt=Iso $now.AddSeconds($delay);$s.lastError='lease expired'}
      $s.claimedBy='';$s.leaseUntil='';$s.updatedAt=Iso $now;Move-Item -LiteralPath $f.FullName -Destination $dest -Force;Write-State $m.messageId $s
    }
    elseif($dir -eq 'delayed' -and $s -and $s.availableAt -and [DateTimeOffset]::Parse([string]$s.availableAt) -le $now){$dest=Join-Path $q "inbox/$($m.messageId).json";$s.status='ENQUEUED';$s.updatedAt=Iso $now;Move-Item -LiteralPath $f.FullName -Destination $dest -Force;Write-State $m.messageId $s}
  }
}
Write-Output 'RECOVERED'
