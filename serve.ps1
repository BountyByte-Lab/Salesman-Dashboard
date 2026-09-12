$port = 8743
$root = [System.IO.Path]::GetFullPath($PSScriptRoot)
$listener = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Loopback, $port)
try {
  $listener.Start(200)
} catch {
  Write-Host "FAILED to start the local server on port $port."
  Write-Host $_.Exception.Message
  Write-Host ""
  Write-Host "This window will stay open so you can read the error above."
  Read-Host "Press Enter to close"
  exit 1
}
Write-Host "Serving $root at http://127.0.0.1:$port/  (close this window to stop)"

$mime = @{
  ".html" = "text/html"; ".js" = "application/javascript"; ".json" = "application/json";
  ".css" = "text/css"; ".png" = "image/png"; ".ico" = "image/x-icon"; ".svg" = "image/svg+xml"
}

while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)
    $requestLine = $reader.ReadLine()
    while (($line = $reader.ReadLine()) -and $line -ne "") { }

    $reqPath = "salesman_dashboard.html"
    if ($requestLine -match '^GET\s+/(\S*)\s+HTTP') {
      if ($matches[1] -ne "") { $reqPath = [System.Uri]::UnescapeDataString($matches[1]) }
    }

    $filePath = [System.IO.Path]::GetFullPath((Join-Path $root $reqPath))
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.NewLine = "`r`n"

    $isInsideRoot = $filePath.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)
    if ($isInsideRoot -and (Test-Path $filePath -PathType Leaf)) {
      $ext = [System.IO.Path]::GetExtension($filePath)
      $ct = $mime[$ext]; if (-not $ct) { $ct = "application/octet-stream" }
      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $writer.WriteLine("HTTP/1.1 200 OK")
      $writer.WriteLine("Content-Type: $ct")
      $writer.WriteLine("Content-Length: $($bytes.Length)")
      $writer.WriteLine("Connection: close")
      $writer.WriteLine("")
      $writer.Flush()
      $stream.Write($bytes, 0, $bytes.Length)
    } else {
      $body = [System.Text.Encoding]::UTF8.GetBytes("Not found")
      $writer.WriteLine("HTTP/1.1 404 Not Found")
      $writer.WriteLine("Content-Type: text/plain")
      $writer.WriteLine("Content-Length: $($body.Length)")
      $writer.WriteLine("Connection: close")
      $writer.WriteLine("")
      $writer.Flush()
      $stream.Write($body, 0, $body.Length)
    }
    $stream.Flush()
  } catch {
  } finally {
    $client.Close()
  }
}
