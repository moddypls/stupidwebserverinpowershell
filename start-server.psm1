function start-server
{
    [CmdletBinding()]
    param (
        [string]$drive_path = $PWD.Path,
        [string]$protocol = "http",
        [string]$host_name = "localhost",
        [int]$port = 7777
    )

    $prefix = "$protocol" + "://" + $host_name + ":$port/"
    Write-Host "Server starting ..."

    $PWD.Path

    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($prefix)
    $listener.Start()

    Write-Host "Listening to $prefix ..."

    #Start-Process $prefix

    $drive = New-PSDrive -Name "hosted-drive" -PSProvider FileSystem -Root (Resolve-Path -Path $drive_path)

    while($true)
    {
        try {
            $context = $listener.GetContext()
            $context.Request.Url
            $URL = $context.Request.Url.LocalPath.TrimStart('/')
            $file_path = Join-Path -Path "hosted-drive" -ChildPath $URL
            if(Test-Path $file_path) 
            {
                $content = Get-Content -Encoding Byte -Path $file_path
                $context.Response.OutputStream.Write($content, 0, $content.Length)
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
