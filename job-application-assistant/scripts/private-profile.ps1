param(
  [ValidateSet('Summary','SealForBrowser')][string]$Mode='Summary',
  [string]$VaultPath=(Join-Path $env:LOCALAPPDATA 'Codex\job-application-assistant\private\profile.dpapi'),
  [string[]]$Fields,
  [string]$PublicKeyFile,
  [string]$DestinationOrigin,
  [string]$OutputFile
)
$ErrorActionPreference='Stop'
if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) { throw 'Windows DPAPI is required.' }
$entropy=[System.Text.Encoding]::UTF8.GetBytes('job-application-assistant/profile/v1')
$plainBytes=$null
$messageBytes=$null
$aesKey=$null
try {
  $plainBytes=[System.Security.Cryptography.ProtectedData]::Unprotect([System.IO.File]::ReadAllBytes($VaultPath),$entropy,[System.Security.Cryptography.DataProtectionScope]::CurrentUser)
  $profile=[System.Text.Encoding]::UTF8.GetString($plainBytes) | ConvertFrom-Json
  if ($Mode -eq 'Summary') {
    $available=@($profile.canonical_fields.PSObject.Properties | Where-Object { $null -ne $_.Value -and $_.Value -ne '' } | ForEach-Object { $_.Name })
    $missing=@($profile.canonical_fields.PSObject.Properties | Where-Object { $null -eq $_.Value -or $_.Value -eq '' } | ForEach-Object { $_.Name })
    [pscustomobject]@{encryption='Windows DPAPI CurrentUser';source_url=$profile.source_url;available_fields=$available;missing_fields=$missing;review_notes=$profile.review_notes} | ConvertTo-Json -Depth 8
    return
  }
  if (-not $Fields -or -not $PublicKeyFile -or -not $DestinationOrigin -or -not $OutputFile) { throw 'SealForBrowser requires Fields, PublicKeyFile, DestinationOrigin and OutputFile.' }
  $destination=[Uri]$DestinationOrigin
  if ($destination.Scheme -ne 'https' -or $destination.AbsolutePath -ne '/' -or $destination.Query -or $destination.Fragment -or $destination.UserInfo) { throw 'DestinationOrigin must be an HTTPS origin without a path or credentials.' }
  $selected=[ordered]@{}
  foreach ($field in $Fields) {
    $property=$profile.canonical_fields.PSObject.Properties[$field]
    if ($null -eq $property -or $null -eq $property.Value -or $property.Value -eq '') { throw "Field unavailable: $field" }
    $selected[$field]=$property.Value
  }
  $payload=[ordered]@{destination_origin=$destination.GetLeftPart([UriPartial]::Authority);fields=$selected}
  $messageBytes=[System.Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Depth 12 -Compress))
  $aesKey=[System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)
  $iv=[System.Security.Cryptography.RandomNumberGenerator]::GetBytes(12)
  $cipher=[byte[]]::new($messageBytes.Length)
  $tag=[byte[]]::new(16)
  $aes=[System.Security.Cryptography.AesGcm]::new($aesKey,16)
  try { $aes.Encrypt($iv,$messageBytes,$cipher,$tag) } finally { $aes.Dispose() }
  $publicKey=[Convert]::FromBase64String(([System.IO.File]::ReadAllText($PublicKeyFile)).Trim())
  $rsa=[System.Security.Cryptography.RSA]::Create()
  try {
    $consumed=0
    $rsa.ImportSubjectPublicKeyInfo($publicKey,[ref]$consumed)
    $wrapped=$rsa.Encrypt($aesKey,[System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)
  } finally { $rsa.Dispose() }
  $combined=[byte[]]::new($cipher.Length+$tag.Length)
  [System.Array]::Copy($cipher,0,$combined,0,$cipher.Length)
  [System.Array]::Copy($tag,0,$combined,$cipher.Length,$tag.Length)
  $envelope=[ordered]@{algorithm='RSA-OAEP-SHA256+AES-256-GCM';wrappedKey=[Convert]::ToBase64String($wrapped);iv=[Convert]::ToBase64String($iv);ciphertext=[Convert]::ToBase64String($combined)}
  $outputPath=[System.IO.Path]::GetFullPath($OutputFile)
  [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($outputPath)) | Out-Null
  [System.IO.File]::WriteAllText($outputPath,($envelope | ConvertTo-Json -Compress),[System.Text.UTF8Encoding]::new($false))
  [pscustomobject]@{saved_encrypted_envelope=$outputPath;destination_origin=$payload.destination_origin;fields=@($selected.Keys);plaintext_written=$false} | ConvertTo-Json -Depth 5
} finally {
  foreach ($buffer in @($plainBytes,$messageBytes,$aesKey)) {
    if ($null -ne $buffer) { [System.Array]::Clear($buffer,0,$buffer.Length) }
  }
}
