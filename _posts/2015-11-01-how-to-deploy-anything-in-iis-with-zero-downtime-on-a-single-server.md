---
comments: true
date: "2015-11-07"
layout: "post"
slug: "how-to-deploy-anything-in-iis-with-zero-downtime-on-a-single-server"
title: "How to Deploy Anything in IIS with Zero Downtime on a Single Server"
summary: "Utilize the blue green deployment pattern in IIS with Application Request Routing to acheive zero downtime deployments of any IIS hosted application on a single server."
tags: ["DevOps", "IIS", "PowerShell"]
---

No one likes downtime. It is stressful for managers, operations, and developers. Downtime is frustrating and confusing for users of a site, whether or not the "down for maintenance" page is live. Most of the popular deployment strategies for ASP.NET apps hosted in IIS do not even try to deploy without downtime. Any change to `Web.config` or `.dll` files on a live site can cause significant downtime (I've seen 5-10 minutes for large apps). There is a better way. *It is possible to achieve zero downtime with the ["blue green deployment" strategy](http://martinfowler.com/bliki/BlueGreenDeployment.html) in IIS using Application Request Routing, and URL Rewrite.* Let's get started.

The general idea of "blue green deployment" is that there is an entry point (load balancer) that routes requests to a site that is up. An application is deployed to a site that is down, that application is warmed up, then the entry point is notified to route new requests to the newly warmed up site instead of the old one. The entry point needs to be able to make the switch with no hiccups, no lost connections, low CPU/memory overhead, and definitely without any perceived downtime by end users. Application Request Routing can act as that load balancing entry point for us.

### Prerequisites

- IIS 7 or higher
- [Application Request Routing](http://www.iis.net/downloads/microsoft/application-request-routing)

## Tutorial

Start with a basic static site called `alwaysup`. Keep in mind that this site could be any IIS hosted application ([ASP.NET](http://www.asp.net/), [HttpPlatformHandler](http://www.hanselman.com/blog/AnnouncingRunningRubyOnRailsOnIIS8OrAnythingElseReallyWithTheNewHttpPlatformHandler.aspx), [iisnode](https://github.com/tjanczuk/iisnode), [PHP](http://php.iis.net/), etc). A static site will be enough for this example. There will need to be two instances of `alwaysup` in IIS, so duplicate the folder that `alwaysup` lives in to create `/alwaysup-green` and `/alwaysup-blue`. The application files are simple. Just some `index.html` files to indicate which application is being hit.

<img alt="Blue green deployment in IIS - application files" src="/assets/zero-downtime-files.png" />

Create corresponding IIS sites for each application and name them `alwaysup-green` and `alwaysup-blue`. These sites need to be bound to a unique port that is not port `80`, like `8001` and `8002`.

<img alt="Blue green deployment in IIS - IIS Sites" src="/assets/zero-downtime-sites.png" />

Also create some host entries for each site so that when the Server Farm is created later each unique host name will act as a server address in the Server Farm. Use `alwaysup-blue` and `alwaysup-green` for the host names, and also add a host name for the server farm that will act as the entry point for the application `alwaysup`.

    127.0.0.1 alwaysup
    127.0.0.1 alwaysup-blue
    127.0.0.1 alwaysup-green

This is the complete configuration for the `alwaysup-blue` and `alwaysup-green` sites.

{% highlight xml %}
<site name="alwaysup-blue" id="3" serverAutoStart="true">
    <application path="/" applicationPool="DefaultAppPool">
        <virtualDirectory path="/" physicalPath="C:\Projects\alwaysup\alwaysup-blue" />
    </application>
    <bindings>
        <binding protocol="http" bindingInformation="*:8001:" />
    </bindings>
</site>
<site name="alwaysup-green" id="4" serverAutoStart="true">
    <application path="/" applicationPool="DefaultAppPool">
        <virtualDirectory path="/" physicalPath="C:\Projects\alwaysup\alwaysup-green" />
    </application>
    <bindings>
        <binding protocol="http" bindingInformation="*:8002:" />
    </bindings>
</site>
{% endhighlight %}

Next create a Server Farm in IIS to route traffic between the two sites. Add a Server Farm named `alwaysup`.

<img alt="Blue green deployment in IIS - Server Farm" src="/assets/zero-downtime-farm.png" />

Next add a server for each host name binding of the `alwaysup-green:8001` and `alwaysup-blue:8002` sites.

<img alt="Blue green deployment in IIS - Server Farm Server" src="/assets/zero-downtime-farm-server.png" />

After creating the servers, IIS will ask prompt to create a URL rewrite rule to route all incoming requests to this server farm automatically. Select "No" because a rule will be created later manually with the URL Rewrite module.

Next add some health checks to the server farm. This is how Application Request Routing will know which site is "up" to route requests to. A simple way to do this is to add an `up.html` file in the root of `alwaysup-blue` and `alwaysup-green` with the text "up" in one, and "down" in the other.

<img alt="Blue green deployment in IIS - health check files" src="/assets/zero-downtime-health-files.png" />

Then add a health check to the `alwaysup` Server Farm that makes sure the response received from `/up.html` contains the text "up". Set the polling interval to be quick so that when changes are made to the health check files very little wait time is required for the health checks to fail or pass. Notice also that the `alwaysup` HOSTS entry is used here.

<img alt="Blue green deployment in IIS - health check" src="/assets/zero-downtime-health.png" />

The "Monitoring and Management" page of the Server Farm shows that one of the Server Farm servers is marked as unhealthy - which is to be expected.

<img alt="Blue green deployment in IIS - health monitor" src="/assets/zero-downtime-health-monitor.png" />

This is the complete configuration for the `alwaysup` Server Farm.

{% highlight xml %}
<webFarm name="alwaysup" enabled="true">
    <server address="alwaysup-blue" enabled="true">
        <applicationRequestRouting httpPort="8001" />
    </server>
    <server address="alwaysup-green" enabled="true">
        <applicationRequestRouting httpPort="8002" />
    </server>
    <applicationRequestRouting>
        <healthCheck url="http://alwaysup/up.html" interval="00:00:01" responseMatch="up" />
    </applicationRequestRouting>
</webFarm>
{% endhighlight %}

Now route the actual traffic to our Server Farm `alwaysup`. To do this use the URL Rewrite module in IIS. Requests will be made on host name `alwaysup`, so add a URL Rewrite rule to match on `{HTTP_HOST}` `alwaysup` on port 80. Route this traffic to the `alwaysup` Server Farm. One thing to note is that IIS needs at least one site listening on port `80` for our URL Rewrite to work.

{% highlight xml %}
<rule name="alwaysup" stopProcessing="true">
    <match url=".*" />
    <conditions>
        <add input="{HTTP_HOST}" pattern="^alwaysup$" />
        <add input="{SERVER_PORT}" pattern="^80$" />
    </conditions>
    <action type="Rewrite" url="http://alwaysup/{R:0}" />
</rule>
{% endhighlight %}

Test everything done so far by making a request to `http://alwaysup/`.

<img alt="Blue green deployment in IIS - blue site up" src="/assets/zero-downtime-blue-up.png" />

Make one of the sites fail the health test and the other pass and see the site content change.

<img alt="Blue green deployment in IIS - green site up" src="/assets/zero-downtime-green-up.png" />

At this point any deployment strategy could be used to deploy to a site in IIS, except now it is necessary to check which site is down and deploy to that one instead of the one that is up. Deployment can happen via [WebDeploy/`msdeploy`](http://www.iis.net/downloads/microsoft/web-deploy), FTP, Dropbox [(yes - some people deploy with Dropbox)](https://azure.microsoft.com/en-us/documentation/articles/web-sites-deploy/#dropbox), an [Octopus Deploy Tentacle](http://docs.octopusdeploy.com/display/OD/Installing+Tentacles), etc. *After new code has been deployed to the site that is down, the down site needs to be warmed up before its health check can be changed to a passing state.* To do this, make a request to the site manually. In this example, a request would be made to `http://alwaysup-blue:8001` to initiate a warm up in IIS. Then edit the health check file to make it pass the health check by changing `down` to `up`. Then once the server's health status is "Healthy", the initial site that was up can safely be brought down. *All of this is done without introducing any downtime.*

<img alt="yes" src="//www.reactiongifs.com/r/dstfp.gif" />

No more 4:30am deployments!

## Automating with PowerShell

Doing all of this manually can be tedious, and *should be automated so that steps aren't accidentally skipped or done incorrectly*. Here are some PowerShell snippets to achieve what was done manually in this example.

### Check which site is unhealthy and ready for deployment

The quickest way would be to check the contents of the `up.html` file with `Get-Content`, essentially mimicking the health check in the IIS Server Farm.

{% highlight powershell %}
$bluePath = "C:\Projects\alwaysup\alwaysup-blue"
$greenPath = "C:\Projects\alwaysup\alwaysup-green"

$upPath = @($bluePath, $greenPath) | Where {
    (Get-Content "$($_)\up.html") -contains "up"
}

$downPath = if ($upPath -eq $bluePath) {
    $greenPath
} else {
    $bluePath
}

Write-Host "$($upPath) is up"
Write-Host "$($downPath) is down"
{% endhighlight %}

<img alt="Blue green deployment in IIS - PowerShell health check" src="/assets/zero-downtime-webfarm-health-files-ps1.png" />

We can also check the status of the Server Farm itself in IIS through [`Microsoft.Web.Administration.ServerManager`](https://msdn.microsoft.com/en-us/library/microsoft.web.administration.servermanager(v=vs.90).aspx).

First define a function to return a Server Farm by name.

{% highlight powershell %}
function Get-ServerFarm {
    param ([string]$webFarmName)

    $assembly = [System.Reflection.Assembly]::LoadFrom("$env:systemroot\system32\inetsrv\Microsoft.Web.Administration.dll")
    $mgr = new-object Microsoft.Web.Administration.ServerManager "$env:systemroot\system32\inetsrv\config\applicationhost.config"
    $conf = $mgr.GetApplicationHostConfiguration()
    $section = $conf.GetSection("webFarms")
    $webFarms = $section.GetCollection()
    $webFarm = $webFarms | Where {
        $_.GetAttributeValue("name") -eq $serverFarmName
    }

    $webFarm
}
{% endhighlight %}

Then get the `isHealthy` status from the ARR counters.

{% highlight powershell %}
$serverFarmName = "alwaysup"
$webFarm = Get-ServerFarm $serverFarmName
$servers = $webFarm.GetCollection()

$servers | % {
    $arr = $_.GetChildElement("applicationRequestRouting")
    $counters = $arr.GetChildElement("counters")
    $isHealthy = $counters.GetAttributeValue("isHealthy")
    if ($isHealthy) {
        $healthyNode = $_
    } else {
        $unhealthyNode = $_
    }
}

$healthyAddress = $healthyNode.GetAttributeValue("address")
$unhealthyAddress = $unhealthyNode.GetAttributeValue("address")

Write-Host "$($healthyAddress) is up"
Write-Host "$($unhealthyAddress) is down"
{% endhighlight %}

<img alt="Blue green deployment in IIS - PowerShell health check" src="/assets/zero-downtime-webfarm-health-ps1.png" />

### Deploy!

At this point use whetever deployment method necessary to deploy to the site that is down.

### Warming up after deployment

I'm still trying to figure out how best to warm up a site without setting a timeout, but the idea so far has been to `Invoke-WebRequest` to the down site until a response comes back within a short enough time period.

{% highlight powershell %}
$blueSite = "http://alwaysup-blue:8001"
$greenSite = "http://alwaysup-green:8002"
$minTime = 400

@($blueSite, $greenSite) | % {
    Write-Host "Warming up $($_)"
    Do {
        $time = Measure-Command {
            $res = Invoke-WebRequest $_
        }
        $ms = $time.TotalMilliSeconds
        If ($ms -ge $minTime) {
            Write-Host "$($res.StatusCode) from $($_) in $($ms)ms" -foreground "yellow"
        }
    } While ($ms -ge $minTime)
    Write-Host "$($res.StatusCode) from $($_) in $($ms)ms" -foreground "cyan"
}
{% endhighlight %}

<img alt="Blue green deployment in IIS - PowerShell warm up" src="/assets/zero-downtime-warmup-ps1.png" />

Then change the content of the `up.html` file to pass the health check, wait a couple of seconds and then bring the up site down. Bringing the up site down can be done with or without draining the server in the Server Farm first.

{% highlight powershell %}
$siteBlue = "http://alwaysup-blue:8001"
$siteGreen = "http://alwaysup-green:8002"
$pathBlue = "C:\Projects\alwaysup\alwaysup-blue"
$pathGreen = "C:\Projects\alwaysup\alwaysup-green"
$pathBlueContent = (Get-Content $pathBlue\up.html)
$serverFarmName = "alwaysup"
$webFarm = Get-ServerFarm $serverFarmName
$webFarmArr = $webFarm.GetChildElement("applicationRequestRouting")
$webFarmHeathCheck = $webFarmArr.GetChildElement("healthCheck")
$healthCheckTimeoutS = $webFarmHeathCheck.GetAttributeValue("interval").TotalSeconds

$siteToWarm = $siteBlue
$pathToBringDown = $pathGreen
$pathToBringUp = $pathBlue

if ($pathBlueContent -contains 'up')
{
    $siteToWarm = $siteGreen
    $pathToBringUp = $pathGreen
    $pathToBringDown = $pathBlue
}

Write-Host "Warming up $($siteToWarm)"
Do {
    $time = Measure-Command {
        $res = Invoke-WebRequest $siteToWarm
    }
    $ms = $time.TotalMilliSeconds
    If ($ms -ge 400) {
        Write-Host "$($res.StatusCode) from   $($siteToWarm) in $($ms)ms" -foreground "yellow"
    }
} While ($ms -ge 400)
Write-Host "$($res.StatusCode) from $($siteToWarm) in $($ms)ms" -foreground "cyan"

if ($res.StatusCode -eq 200) {
    Write-Host "Bringing $($pathToBringUp) up" -foreground "cyan"
    (Get-Content $pathToBringUp\up.html).replace('down', 'up') | Set-Content $pathToBringUp\up.html

    Write-Host "Waiting for health check to pass in $($healthCheckTimeoutS) seconds..."
    Start-Sleep -s $healthCheckTimeoutS

    Write-Host "Bringing $($pathToBringDown) down"
    (Get-Content $pathToBringDown\up.html).replace('up', 'down') | Set-Content $pathToBringDown\up.html
} else {
    Write-Host "Cannot warm up $($siteToWarm)" -foreground "red"
}
{% endhighlight %}

<img alt="Blue green deployment in IIS - PowerShell blue green switch" src="/assets/zero-downtime-bluegreenswitch-ps1.png" />

To disallow new connections on the server that is up before bringing it down, we can call the `SetState` method with the following values.

{% highlight powershell %}
$serverFarmName = "alwaysup"
$serverAddress = "alwaysup-green"

$webFarm = Get-ServerFarm $serverFarmName
$servers = $webFarm.GetCollection()

$server = $servers | Where {
    $_.GetAttributeValue("address") -eq $serverAddress
}

$arr = $server.GetChildElement("applicationRequestRouting")
$method = $arr.Methods["SetState"]
$methodInstance = $method.CreateInstance()

# 0 = Available
# 1 = Drain
# 2 = Unavailable
# 3 = Unavailable Gracefully
$methodInstance.Input.Attributes[0].Value = 1
$methodInstance.Execute()
{% endhighlight %}

After setting the state to `Drain` it would be possible to loop until the server has `0` connections, then make health check fail and make the server "Available" and "Unhealthy" - ready for the next deployment.

## Enabling SSL

If SSL needs to be terminated in IIS it will now have to be done at the Server Farm. To do this a new URL Rewrite rule has to be created to match port `443`. Make sure that the certificate to be used is bound to at least 1 site in IIS, or use IIS's centralized certificates.

{% highlight xml %}
<rule name="alwaysup HTTPS" stopProcessing="true">
    <match url=".*" />
    <conditions>
        <add input="{SERVER_PORT}" pattern="^443$" />
        <add input="{HTTP_HOST}" pattern="^alwaysup$" />
    </conditions>
    <action type="Rewrite" url="http://alwaysup/{R:0}" />
</rule>
{% endhighlight %}

When ARR terminates SSL it will add a server variable of `HTTP_X_ARR_SSL`. Checking this server variable is useful for preventing redirect loops in applications that need to do HTTPS redirection.

## Other things to consider

- If a deployed application uses ASP.NET `InProc` session, all session data will be lost when requests are routed to a different site. Use `StateServer`, `SQLServer`, or a custom session state provider in order to retain session state across deployments.
- Don't autogenerate or use a different [`machineKey`](https://msdn.microsoft.com/en-us/library/vstudio/w8h3skw9(v=vs.100).aspx) in blue and green ASP.NET sites so that Session, ViewState, and Forms Authentication will be decrypted the same for each.
- Make sure the proxy timeout is greater than or equal to your application's timeout setting. This is often defined in an ASP.NET application's `Web.config` as `<httpRuntime executionTimeout="120"/>`
- Caching on the Server Farm is enabled by default. Consider disabling it if you have a different caching strategy.
- If you choose not to use a health check and instead servers are only set to "Unavailable" between deployments, note that when IIS restarts, all sites (both blue and green) will be "Available" and "Healthy". As a precaution to this, it is recommended to enable one of the Server Affinity options to make requests "sticky".

## Other resources

- [Martin Fowler's 2010 definition of "Blue green deployment"](http://martinfowler.com/bliki/BlueGreenDeployment.html)
- [Server Fault answer from Matt Bathje outlining a "blue green deployment" process](http://serverfault.com/a/126379/205754)
- [`Microsoft.Web.Administration.ServerManager` PowerShell samples for setting state of servers in a Server Farm](http://automagik.piximo.me/2013/03/make-server-unavailable-gracefully.html)
- ["Blue green deployment" PowerShell scripts from yosoyadri](https://github.com/yosoyadri/IIS-ARR-Zero-Downtime/) (includes useful functions for creating IPs, creating Sites, creating Server Farms, and archiving previous deployments in `.zip` files)
- [Documentation on "blue green deployments" from Octopus Deploy](http://docs.octopusdeploy.com/display/OD/Blue-green+deployments)