---
comments: true
date: "2014-03-05"
layout: "post"
slug: "managing-multiple-local-changesets-with-svn"
title: "Managing Multiple Local Changesets with SVN"
summary: "Local branching is very easy with Git, but with Subversion some magic is needed to manage local changesets."
tags: ["Git", "SVN"]
---

Local branching is very easy with Git, but with Subversion (SVN) some magic is needed to manage complex local working directories. When working on more than one feature or bug within one SVN branch, the changes can quickly become hard to manage and keep separate. If the change ends up being in the same file as another feature's change, a real problem occurs when trying to commit the code separately. There are options to make sure changes don't encroach on each other, but none of them are as simple and lightweight as local branching with Git. Since SVN does not have the concept of a pull request, code reviews might be done pre-commit, forcing the developer to keep local changes in a working directory until the review is complete and changes can be committed. In this situation, the following solutions for managing  multiple local changesets might come in handy.

## Solutions for managing multiple changes in Subversion
1. [Create a separate SVN branch](#createsvnbranch)
2. [Copy/paste working directory](#copypaste)
3. [Use `svn changelist`](#changelist)
4. [Manage multiple `.patch` files](#patch)
5. [Git & SVN in the same working directory](#gitsvn)

### Create a separate SVN branch <a name="createsvnbranch"></a>
The first and best option would be to create another SVN branch in the centralized repository to work in. Then, when the work is complete `svn merge --reintegrate` into the main branch. This is the most manageable way to deal with multiple changes, but requires your team to allow any developer to create and manage their own branches separate from the trunk. This can be done by allowing developers to create and manage branches in a folder named after them, like `/svn/branches/kevin`, or in a branches folder related to what they are working on like `/svn/branches/bugs` or `/svn/branches/features`.

#### Copy an existing branch

If creating a new branch is a feasible option then one can be created with `svn copy`.

    svn copy http://svn/trunk http://svn/branches/kevin/feature1 -m "create branch for feature1"

A branch can also be created from your working directory via

    svn copy . http://svn/branches/kevin/feature1 -m "create branch for feature1"

With TortoiseSVN, you can create a branch from a working directory via `TortoiseSVN` → `Branch/Tag...`, or you can copy another branch in your SVN repository from the `Repository Browser` by holding `Ctrl` while dragging a branch folder to a new location.

Those who already manage branches in SVN would obviously be aware of this, but developers that don't have the responsibility of managing branching and merging would need to know this moving forward.

#### Merge & Reintegrate

When work is complete in the feature branch, merge any revisions that are not present in the feature branch from the trunk, then reintegrate back into the trunk.

    > svn switch http://svn/branches/kevin/feature1
    > svn merge http://svn/trunk
    > svn commit -m "merge trunk into kevin/feature1"

    > svn switch http://svn/trunk
    > svn merge --reintegrate http://svn/branches/kevin/feature1
    > svn commit -m "merge feature1 back into trunk"

This  process can also be done easily with TortoiseSVN via `Tortoise SVN` → `Merge` → `Reintegrate a branch`. For more information on reintegrating branches, [refer to the SVN Book](http://svnbook.red-bean.com/en/1.7/svn.branchmerge.basicmerging.html#svn.branchemerge.basicmerging.reintegrate).

If code reviews are done pre-commit, this solution would be a way to improve the code review process to act more like a Git pull request, by moving code reviews after the commit into the feature branch, but before the branch is reintegrated.

### Copy/paste working directory <a name="copypaste"></a>
Copy/pasting a clean working directory to a new directory before working on a feature can be manageable, but is often too bulky of a process for large code bases.

#### Pros
- Don't have to worry about creating "unnecessary" branches that you would probably delete or never look at again
- Having a clean working directory always at hand allows for quick merging, branching, reverting, etc. (you should always have a clean working copies of branches anyways)

#### Cons
- Paste action could take a long time
- Renaming folders to keep track of what you're working on becomes a must and can be a pain when you have to kill all processes with handles in the directory to be renamed
- Doesn't give you the kind of sandbox that creating a separate branch would

### Use `svn changelist` <a name="changelist"></a>
In a single working directory, files with local modifications can be grouped under different names by using SVN changelists. SVN changelists are ideal for simple features that will not end up having changes in the same file as another feature's changes. To create a SVN changelist from a group of files use `svn changelist`.

    > svn changelist my-first-changelist module1.js module2.js
    A [my-first-changelist] module1.js
    A [my-first-changelist] module2.js

    > svn status
    --- Changelist 'my-first-changelist':
    M       module1.js
    M       module2.js

This can also be done with TortoiseSVN via `TortoiseSVN` → `Check for modifications`, selecting the files you want to add to a changelist, and selecting `Move to changelist` → `<new changelist>`. At that point the files will be grouped under the new changelist's name.

### Manage multiple `.patch` files <a name="patch"></a>
This is not really a good option, but it is an option nonetheless.

When finished working on a feature in a working directory (or before switching focus to work on something else), create a `.patch` file containing all the current modifications and then revert the working directory. Then when you want to work on the feature contained in the `.patch` file, just create another `.patch` file with any modifications in the current directory, revert the working directory, and apply the `.patch` file so you can continue working on any changes.

### Git & SVN in the same working directory <a name="gitsvn"></a>
Running `git init` in any folder will create a local Git repository in that directory. This allows for easy management of local branches, and if you are new to Git or are looking to switch from SVN to Git at some point, this is a good way to get your feet wet. Some might view this as more work than it's worth, but if you are up for it, the following is my workflow when managing a Git repository inside a SVN working directory.

#### Get Git
For Windows users I highly recommend downloading the full version the portable console emulator [cmder](http://bliker.github.io/cmder/) which contains [msysgit](http://msysgit.github.io/). Alternatively, you can download Git from [git-scm.com/downloads](http://git-scm.com/downloads).

If you are new to Git, [here is a great guide to get you started](http://rogerdudler.github.io/git-guide/).

#### Create a new Git repository
Start with a clean SVN working directory, then initialize and empty Git repo in the working directory.

    > git init

Now you will see a `.git` folder alongside  your `.svn` folder. Two source controls in one directory!

#### Create a branch
Create a branch for a feature you will work on and then checkout that branch.

    > git branch feature1
    > git checkout feature1

The create and checkout can also be done with one command.

    > git checkout -b feature1

You can commit you local changes in a Git branch as often as you want to keep track of your change history.

    > git add .
    > git commit -m "committing some changes"

Then after working in that branch for a while, you might start working on another feature and end up with multiple branches. Though, at some point you will want to update from SVN.

#### Update SVN
Before updating from SVN, commit any changes to the current Git branch, then (1) checkout the `master` branch, (2) update from SVN, and (3) commit the updates to the `master` Git branch.

    > git checkout master
    > svn up
    > git commit -m "svn update"

#### Push SVN update to Git branches

At this point the updates from SVN are only in the `master` branch, and not in the `feature1` branch, so we will need to `rebase` our `feature1` branch to have a new base of `master`'s most recent commit. If you are unfamiliar with `git rebase`, [there is a great visualization here](https://www.atlassian.com/git/tutorial/rewriting-git-history#!rebase).

    > git checkout feature1
    > git rebase master

You will then want to rebase all other Git branches to `master` as well, or else whenever you checkout a different Git branch SVN will show changes where it expected the files from the SVN update to have been changed.

If you are used to handling merge conflicts with TortoiseSVN, then you might want to use [TortioseGit](https://code.google.com/p/tortoisegit/) when rebasing as it can alleviate the stress of not knowing how to handle rebase conflicts via the Git bash.

#### Committing changes to SVN
After rebasing our feature branch we can safely merge our Git branch into `master` and then commit to the central SVN repository.

    > git checkout master
    > git merge feature1
    > svn commit -m "feature1 to svn"

The `feature1` Git branch can now be deleted since it is completed.

#### Other considerations
- Take the time to configure a `.gitignore` file so that any build artifacts will be ignored by Git. [Common `.gitignore` files can be found here](https://github.com/github/gitignore).
- Consider adding any Git related items to the SVN repository's ignore list, so that you do not accidentally commit them to SVN.

#### Drawbacks to using Git in an SVN directory
- Extra work
- Required knowledge of Git
- All Git branches must be rebased after an SVN update, so that pre-commit code reviews that require a later update would not show changes from the SVN update

#### More information on using Git & SVN together
- [A great tutorial on how to use Git in an SVN working directory](http://lostechies.com/derickbailey/2010/02/03/branch-per-feature-how-i-manage-subversion-with-git-branches/)
- [SubGit](http://subgit.com/) is a tool to help gently migrate from SVN to Git by creating a bidirectional Subversion to Git replication
- [git-svn](http://git-scm.com/book/en/Git-and-Other-Systems-Git-and-Subversion#git-svn) is a way to interface directly with a SVN repository via git ([manual](http://schacon.github.io/git/git-svn.html))

## tl;dr
Git's cheap local branching is the easiest way to deal with multiple changes locally, but when SVN is the version control of choice, other methods like SVN branching, copy/pasting working directories, using `svn changelist`, using `.patch` files, and/or integrating a Git repository in a SVN working directory should be part of the workflow to correctly handle a complex working directory. Pre-commit code reviews can spoil a workflow when working in SVN without the option of creating a branch for each code reviewable changeset. Giving developers the option to create their own SVN branches is definitely worth it, even if only to remove the pain of having to deal with multiple changesets via the other options mentioned.
