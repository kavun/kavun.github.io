---
comments: true
date: "2015-11-08"
layout: "post"
slug: "comparing-git-branches"
title: "Comparing Git Branches"
summary: "Git commands to compare branches before merges or deployments."
tags: ["Git"]
---

The majority of the time I manage Git repositories in [SourceTree](https://www.sourcetreeapp.com/) because wrangling lots of Git projects on the command line can get hairy. The visibility of statuses across mutiple local repositories that a GUI like SourceTree provides is not available on the command line. However, some things are often simpler and quicker on the command line than in GUI Git clients. One of those things is comparing branches.

    git log <since>..<until>

This will show any commits that happened in the `<until>` branch that are not in `<since>`. Often I will use this command to compare a feature branch with a master branch before merging, just to make sure I'm not missing anything. Note that `<until>` is optional and if omitted will default to the current checked out branch.

    git log master..


This also works with tags.

    git log 2.4.0..

This is useful as a pre deployment task to check what's about to be deployed, create changelogs for a new tag, etc. `git shortlog` can also be useful for changelogs.

### Useful flags for `git log`

#### `--oneline`

Condense log messages to a single line to be more readable.

#### `--stat`

Show files that have changed. This can be extremely useful when combined with `<since>..` and `grep`. The following will output filenames of all `.png` files in the current checked out branch that are not in `master`.

    git log --oneline --stat master.. | grep .png

Usually this is accurate enough, but grep could also accept a regular expression of `-e ".*\.png\b"`

### Resources

- [git log](https://git-scm.com/docs/git-log) documentation
- [Prettier `git log` with `--graph` and `--decorate`](http://fredkschott.com/post/2014/02/git-log-is-so-2005/)
