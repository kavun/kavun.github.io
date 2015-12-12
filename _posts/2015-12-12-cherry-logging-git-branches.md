---
comments: true
date: "2015-12-12"
layout: "post"
slug: "cherry-logging-git-branches"
title: "Cherry Logging Git Branches"
summary: "Use --cherry with git log when comparing Git branches to ignore shared merge commits."
tags: ["Git"]
---

In a [previous post](/2015/11/08/comparing-git-branches/) I showed how to compare branches with `git log master..topic`. This method is great, but it only shows commits in `topic` not yet in `master` based on a sha1 comparison. If we have another branch called `shared` that has been merged into `master` and `topic`, `git log master..topic` would show the commits that were merged from `shared` even though they have been merged into `topic` and `master`. If we use `git cherry -v topic master` or `git log --cherry master..topic`, the actual diffs from each commit will be compared instead of only the sha1. This will make sure the commits from `shared` will not show up. Here is an example.

![git cherry](/assets/gitcherry.png)

Notice how the commit `Merge branch 'shared' into topic` doesn't really need to show up as part of `topic` when comparing to `master` because `master` also has that merge. `--cherry` compares the diff of the merge so that it's not included in the command `git log --oneline --cherry master..topic`. This would also ignore shared cherry picked commits.