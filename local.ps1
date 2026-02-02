param(
  [Parameter(Position=0, Mandatory=$True)]
  [ValidateSet("run")]
  [string]$Command
)

function Invoke-Run {
    & bundle exec jekyll serve
}

switch ($Command) {
    "run"  { Invoke-Run }
}