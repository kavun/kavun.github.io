---
comments: true
date: "2021-01-05"
layout: "post"
slug: "how-to-run-dotnet-test-alongside-docker-compose-in-gitlab-ci-cd"
title: "How to Run Dotnet Test Alongside Docker Compose in GitLab CI/CD"
summary: "Run <code>dotnet test</code> as a GitLab CI job, but have it connect to running containers started by <code>docker-compose</code> inside the docker container that GitLab CI/CD uses for its test runner."
tags: ["DevOps", "Docker", "Dotnet"]
---

To run `dotnet test` in GitLab and have it connect to and use containerized services like databases, caches, or in this case Selenium Hub, you can use the following pattern:

1. Rely on GitLab CI's built-in `docker:dind` ("docker in docker") service to run docker commands as job scripts.
2. Install `docker-compose` manually (if you know of a way to somehow use an image instead for this, let me know!)
3. Run `docker-compose` using a test-specific `docker-compose.yml`.
4. Run `dotnet test` using `docker run [...] mcr.microsoft.com/dotnet/sdk:5.0 dotnet test [...]`.

## Example xUnit Test Class

This is using xUnit, pulling the Selenium Hub URL from `appsettings.json`, and grabbing the title of `google.com`.

**SomeBrowserTests.cs**

{% highlight csharp %}
public class SomeBrowserTests
{
    [Fact]
    public void GetTitleTest()
    {
        var env = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
        var configuration = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json")
            .AddJsonFile($"appsettings.{env}.json", optional: true)
            .Build();
        var webDriverHubUrl = configuration.GetSection("Selenium")["HubUrl"];
        var options = new ChromeOptions();
        var hubUri = new Uri(webDriverHubUrl);
        using var driver = new RemoteWebDriver(hubUri, options);

        driver.Url = "https://www.google.com";
        var title = driver.Title;

        Assert.Contains("Google", title);

        driver.Quit();
    }
}
{% endhighlight %}

## Example `appsettings.json`

This is the `appsettings.json` that GitLab CI will use. For local development it's possible to use a separate `appsettings.json` pointed to `localhost`, since a local `docker-compose` setup for development would expose the necessary ports on `localhost`. <em>However, GitLab CI creates a new container for each job script, so anything running there will have to connect from the a test container to the Selenium Hub container using the container name that docker provides via it's magic DNS stuff.</em> (this took me a long time to figure out, and adding a job script of `docker network ls` helped.)

**appsettings.CI.json**

{% highlight json %}
{
  "Selenium": {
    "HubUrl": "http://some-selenium-hub:4444/wd/hub"
  }
}
{% endhighlight %}

## Example `docker-compose.yml`

Nothing fancy here (this is close to what the Selenium docs show), other than to note what network name (bridged by default) is used (`some-tests`) because it will be used later when running `dotnet test`.

**docker-compose.some-tests.yml**

{% highlight yml %}
version: "3.3"

networks:
  some-tests:

services:

  some-selenium-chrome:
    image: selenium/node-chrome:4.0
    restart: always
    volumes:
      - /dev/shm:/dev/shm
    environment:
      - SE_EVENT_BUS_HOST=some-selenium-hub
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443
    entrypoint: bash -c 'SE_OPTS="--host $$HOSTNAME" /opt/bin/entry_point.sh'
    networks:
      - some-tests
    depends_on:
      - some-selenium-hub

  some-selenium-hub:
    image: selenium/hub:4.0
    restart: always
    ports:
      - "4442:4442"
      - "4443:4443"
      - "4444:4444"
    networks:
      - some-tests
{% endhighlight %}

## Example `.gitlab-ci.yml`

Here's where the rubber meets the road.
- Alpine now allows `apk add docker-compose` (so there's no need to mess with python/pip installation of `docker-compose` 🙌).
- After `docker-compose` is installed, start the Selenium Hub.
- Then run the dotnet tests:
  - Notice it runs the `dotnet/sdk` image in the same `some-tests` network (so that it can connect to `http://some-selenium-hub:4444/wd/hub`)
  - Notice it sets the `ASPNETCORE_ENVIRONMENT=CI` (so that the test will read from the `appsettings.CI.json` configuration)
  - Notice it mounts `-v $PWD:/app` so that the output from `--logger "junit"` will be readable by the GitLab CI task runner to capture test results. This requires the `JUnitTestLogger` nuget package to be installed in the test project(s).
  - Notice it calls `docker-compose down`, and I'm not entirely sure that's necessary -- I just like to be a good citizen.

**.gitlab-ci.yml**

{% highlight yml %}
image: docker:latest
services:
  - name: docker:dind
    entrypoint: ["dockerd-entrypoint.sh"]
    command: ["--max-concurrent-downloads", "6"]

stages:
  - test

variables:
  DOCKER_DRIVER: overlay2

some-tests:
  stage: test
  before_script:
    - apk add docker-compose
  script:
    - docker-compose -f docker-compose.some-tests.yml up -d --build --remove-orphans
    - docker run --network some-tests -v $PWD:/app -w /app -e "ASPNETCORE_ENVIRONMENT=CI" mcr.microsoft.com/dotnet/sdk:5.0-alpine dotnet test SomeSolution.sln --logger "junit"
    - docker-compose -f docker-compose.some-tests.yml down
  artifacts:
    reports:
      junit: ./**/TestResults/TestResults.xml
{% endhighlight %}