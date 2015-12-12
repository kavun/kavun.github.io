---
comments: true
date: "2015-12-12"
layout: "post"
slug: "low-quality-image-placeholders-with-powershell-and-imagemagik"
title: "Low Quality Image Placeholders with PowerShell and ImageMagik"
summary: "Loading LQIPs before lazy loading full size images can speed up page loads while keeping a decent user experience. PowerShell can help automate the creation of LQIPs in bulk."
tags: ["PowerShell"]
---

Lazy loading images can be great for page performance, but what if we want low quality image placeholders to load before the full lazy loaded image? ImageMagik's `convert` can be used to create LQIPs, and PowerShell can be used to call `convert` and generate base 64 strings of the LQIPs for inlining into web pages. Here are some PowerShell functions that will:

- Find all `.png`s files or files with an `$extension` in a given `$path`.
- If LQIP doesn't already exist, pass the image to `convert $($file) -resize 1% -gaussian-blur 0.05 -quality 1 $($file).lqip.jpg` (these parameters will need to be tweaked based on the end goal, for example you may not want to resize to 1%)
- Pass LQIP to `[convert]::ToBase64String((Get-Content $path -Encoding Byte))` to generate base 64 string. Output base 64 string, along with the width and the height of the original image to a file ending in `.b64`.

Make sure that [ImageMagik](http://www.imagemagick.org/script/binary-releases.php) is installed and that `convert` is available on the `PATH`.

{% highlight powershell %}
Function Generate-LQIP {
    Param (
        [string]$path=".",
        [string]$extension=".png"
    )

    Add-Type -AssemblyName System.Drawing
    Set-Location $path

    Get-ChildItem $path -Filter "*$($extension)" | % {
        $nameStub = $_.Name -replace '\$($extension)$', ''
        $newFileName = "$($nameStub).lqip.jpg"
        $oldLength = (Get-Item $_).Length
        $png = New-Object System.Drawing.Bitmap $_.FullName

        If ((Test-Path $newFileName) -eq $true) {
            $newLength = (Get-Item $newFileName).Length
            Write-Host "Already exists: $($newFileName) $($oldLength)b > $($newLength)b"
        } Else {
            Invoke-Expression "convert $($_.Name) -resize 1% -gaussian-blur 0.05 -quality 1 $($newFileName)"
            Generate-B64 $newFileName >> "$($newFileName).b64"
            $png.Width >> "$($newFileName).b64"
            $png.Height >> "$($newFileName).b64"
            $newLength = (Get-Item $newFileName).Length
            Write-Host "Created $($newFileName) $($oldLength)b > $($newLength)b"
        }
    }
}

Function Generate-B64 {
    Param (
        [String]$path
    )

    [convert]::ToBase64String((Get-Content $path -Encoding Byte))
}
{% endhighlight %}

To be honest, I'm not actually using LQIPs on this blog or anywhere else for that matter. Usually just lazy loading images is quick enough that LQIPs are uneccessary and actually degrade performance since it's extra bytes that the page has to load before rendering. Nevertheless, PowerShell and ImageMagik prove to work nicely together making it easy to do automated bulk image processing.
