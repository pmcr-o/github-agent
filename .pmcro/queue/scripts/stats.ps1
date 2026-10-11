param()
Import-Module (Join-Path $PSScriptRoot 'queue.psm1') -Force -DisableNameChecking
$q=Get-QueueRoot;$o=[ordered]@{agent=(Get-QueueConfig).agent};foreach($d in @('inbox','processing','delayed','completed','dead-letter','receipts')){$o[$d]=@(Get-ChildItem -LiteralPath (Join-Path $q $d) -Filter '*.json' -File -ErrorAction SilentlyContinue).Count};$o|ConvertTo-Json
