---
comments: true
date: "2021-01-05"
layout: "post"
slug: "creating-a-command-based-cli-in-powershell"
title: "Creating a Command-Based CLI in Powershell"
summary: "How to create a cross platform CLI using simple powershell scripts."
tags: ["DevOps", "Powershell"]
---

Lately, I've become obsessed with automating local development environment tasks, especially when it comes to onboarding, bootstrapping, and managing my local machine's environments for various projects. When something like a web application starts to add environment dependencies like docker-compose, quickly that project's onboarding steps can get quite lengthy. Managing issues around onboarding steps can become a pain, and troubleshooting them, especially when those tasks are expected to be run across operating systems, can be very difficult and time consuming. Powershell Core, being cross-platform and JIT runnable, offers a friendly scripting experience for creating command-based command line interfaces for whatever application you need.

## Goal

Let's build a script with these commands:

```ps1
.\cli.ps1 up
.\cli.ps1 down
.\cli.ps1 build
.\cli.ps1 test
.\cli.ps1 migrate <name>
.\cli.ps1 ip
```

All the examples can also be found here: https://github.com/kavun/ps-cli

## Validate the commands

To enable these ad-hoc command names (without the default '`-`' prefixes the Powershell params normally require), we can use a combination of `ValidateSet` and `Parameter(Position=0)` attributes on the script's first `param`.

```ps1
param(
  [Parameter(Position=0, Mandatory=$True)]
  [ValidateSet("up", "down", "build", "test", "migrate", "ip")]
  [string]$Command
)

Write-Host $Command
```

This ensures that when you pass an incorrect command or if you exclude the command, you get a detailed error message.

![ValidateSet's error message](/assets/ps-cli/1-validate.png)

## Handle the commands

Now we need to handle the commands and run functions for each one. For this, we'll use a `switch`.

```ps1
param(
  [Parameter(Position=0, Mandatory=$True)]
  [ValidateSet("up", "down", "build", "test", "ip")]
  [string]$Command
)

function Command-Up    { iex "docker compose up" }
function Command-Down  { iex "docker compose down" }
function Command-Build { iex "dotnet build" }
function Command-Test  { iex "dotnet test" }
function Command-Ip {
    $ip = iwr "https://api.ip.sb/ip" `
        | Select-Object -Expand Content
    
    Write-Host "Your IP address is: " -N
    Write-Host $ip -F Green
}

switch ($Command) {
    "up"    { Command-Up }
    "down"  { Command-Down }
    "build" { Command-Build }
    "test"  { Command-Test }
    "ip"    { Command-Ip }
}
```

Now, when a command is passed, the associated function is run.

![Handling commands with switch](/assets/ps-cli/2-handle.png)

## Support `Get-Help`

This is great so far, but it's not immediately known what commands are available without opening up the `.ps1` file and reading it. We could add a command `help` and then spit out some help content with `Write-Host "help string"`, but there's a better way. Powershell scripts can hook into the `Get-Help` command to provide structured help documentation for the whole script. Let's do both!

```ps1
<#
.SYNOPSIS
This script is an example of how any .ps1 script can provide content to `Get-Help`.

.DESCRIPTION
USAGE
    .\3-help.ps1 <command>

COMMANDS
    up          run `docker-compose up`
    down        run `docker-compose down`
    build       run `dotnet build`
    test        run `dotnet test`
    ip          get your local ip
    help, -?    show this help message
#>
param(
  [Parameter(Position=0)]
  [ValidateSet("up", "down", "build", "test", "ip", "help")]
  # The command to run
  [string]$Command
)

function Command-Help { Get-Help $PSCommandPath }

if (!$Command) {
    Command-Help
    exit
}

function Command-Up    { iex "docker compose up" }
function Command-Down  { iex "docker compose down" }
function Command-Build { iex "dotnet build" }
function Command-Test  { iex "dotnet test" }
function Command-Ip {
    $ip = iwr "https://api.ip.sb/ip" `
        | Select-Object -Expand Content
    
    Write-Host "Your IP address is: " -N
    Write-Host $ip -F Green
}

switch ($Command) {
    "up"    { Command-Up }
    "down"  { Command-Down }
    "build" { Command-Build }
    "test"  { Command-Test }
    "ip"    { Command-Ip }
    "help"  { Command-Help }
}
```

Let's look at what we changed:
1. Added `<# #>` help content at the top of the file. And added `.SYNOPSIS` and `.DESCRIPTION` sections.
1. Removed `Mandatory=$True` from the `$Command` param, so that we can show the help content when you call the script with no params.
1. Added the `help` command, which ends up calling `Get-Help $PSCommandPath`

This will show help for all 4 of these commands. The goal here is to make this foolproof.
```
.\3-help.ps1

.\3-help.ps1 help

.\3-help.ps1 -?

Get-Help .\3-help.ps1
```

![Showing help content when no params are passed](/assets/ps-cli/3-help.png)

## Handle nested commands

What we have is great for simple one-liners, but eventually we'll want to pass params to the commands and also support nested commands.

```ps1
<#
.SYNOPSIS
An example of how to next commands.

.DESCRIPTION
USAGE
    .\4-nest.ps1 <command>

COMMANDS
    speak       speak some text
    logs        view logs
#>
param(
    [Parameter(Position=0)]
    [ValidateSet("speak", "logs")]
    [string]$Command,

    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    $Rest
)

if (!$Command) {
    Get-Help $PSCommandPath
    exit
}

function Command-Speak {
    param (
        [Parameter(Position=0, Mandatory=$True)]
        [string]$Text
    )

    if (!$IsWindows) {
        Write-Error "Sorry, the 'speak' command is only supported on Windows"
        exit
    }

    Write-Host "Speaking the text: '$Text'"
    $sp = New-Object -ComObject SAPI.SpVoice
    $sp.Speak($Text) | Out-Null
}

function Command-Logs {
<#
.SYNOPSIS
Show logs for an application.

.DESCRIPTION
USAGE
    .\4-nest.ps1 logs <command>

COMMANDS
    app-one     show logs for app-one
    app-two     show logs for app-two
#>
    param(
        [Parameter(Position=0)]
        [ValidateSet("", "app-one", "app-two")]
        [string]$App
    )

    if (!$App) {
        Get-Help Command-Logs
        exit
    }

    Write-Host "Showing logs for " -N
    Write-Host $App -F Green
}

switch ($Command) {
    "speak" { Command-Speak $Rest }
    "logs"  { Command-Logs $Rest }
}
```
Let's look at what we did:

- We used `ValueFromRemainingArguments` to capture any trailing params in the `$Rest` param and passed those along to the inner functions.
- We used `ValidateSet` on an inner function's param, just like we did on the script's params.
- Added help docs to one of the inner functions!

These are just examples, but you can see the range of possibilities the open up when we start nesting commands and forwarding params. Here's what this example looks like in use.

![Example of nested commands](/assets/ps-cli/4-nest.png)

