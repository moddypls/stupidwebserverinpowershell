function start-server
{
  [CmdletBinding()]
  param (
    [Alias("root", "r", "directory", "d")]
    [string]$root_directory = $PWD.Path,

    [Alias("s")]
    [string]$scheme = "http",

    [Alias("hn", "host", "h", "ip", "address", "a")]
    [string]$host_name = "localhost",

    [Alias("p")]
    [int]$port = 7777
  )

  $prefix = "$scheme" + "://" + $host_name + ":$port/"
  Write-Host "Server starting..."

  $listener = New-Object System.Net.HttpListener
  $listener.Prefixes.Add($prefix)
  $listener.Start()

  $resolved_directory = Resolve-Path -Path $root_directory

  Write-Host "Listening to $prefix with $resolved_directory..."

  #Start-Process $prefix

  $drive = New-PSDrive -Name hosted-drive -PSProvider FileSystem -Root $resolved_directory

  while($true)
  {
    try {
      $context = $listener.GetContext()
      $context.Request
      $URL = $context.Request.Url.LocalPath.TrimStart('/')
      Write-Host "URL: $URL"
      $file_path = Join-Path -Path hosted-drive -ChildPath $URL
      if(Test-Path $resolved_directory) 
      {
        if ($URL -ne "favicon.ico")
        {
          $content = Get-Content -Encoding Byte -Path "hosted-drive:$URL"
          $context.Response.OutputStream.Write($content, 0, $content.Length)
        }
      } else {
        $context.Response.StatusCode = 404
        $error_msg = "File not found"
        $error_bytes = [System.Text.Encoding]::UTF8.GetBytes($error_msg)
        $context.Response.OutputStream.Write($error_bytes, 0, $error_bytes.Length)
      }
      
      $context.Response.Close()
    }
    catch
    {
      Write-Error $Error
      break
    }
  }
}

Export-ModuleMember -Function start-server
