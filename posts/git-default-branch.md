# Consistent Handling of Git Repositories With Different Default Branches

## Why Do I Care About Default Branches?

Typically, I develop on a feature branch, and when the feature is ready, there is an obvious branch into which I want to merge the branch. This branch is often called `master', `main' or `develop'. During development, I will occasionally rebase my feature branch on top of this branch, to reduce future merge conflicts, and to avoid falling behind on changes merged by other developers. I will call this branch the default branch from here on.

To make common operations consistent across repositories, I want to use a `git default-branch' command that returns the name of the default branch, so that I can use commands like

```
# Rebase on latest version of the default branch
git fetch origin $(git default-branch) && git rebase origin/$(git default-branch)

# Switch to the default branch and bring it up to date
git switch $(git default-branch) && pull

# Absorb staged changes into the respective commits since branching off of the default branch
git absorb --base (git merge-base HEAD $(git default-branch))
```

## How to Determine the Default Branch

What I consider the default branch in the examples above is the HEAD of the remote repository (usually on GitHub). I use the remote name `origin` for the remote containing the latest version of the default branch. If your naming is different, adapt the commands accordingly.

The command `remote show origin` provides all relevant information about the remote, including the HEAD branch which can be filtered out with `git remote show origin | sed -n '/HEAD branch/s/.*: //p'`. The downside of this approach is that it queries the remote, so it will take quite a long time due to network latency, and will only work if you are online.

Fortunately there is a local representation of this information available via `git symbolic-ref refs/remotes/origin/HEAD`, but it may be out of date or unavailable (in which case you will see the error `fatal: ref refs/remotes/origin/HEAD is not a symbolic ref`). To update it, run `git remote set-head origin --auto`.

## Implementing the `default-branch' Command

Since I want to neither memorize nor type out these commands all the time, I package them up in two git aliases in my `.gitconfig`:

```
[alias]
	default-branch = "!git symbolic-ref refs/remotes/origin/HEAD --short | sed 's|origin/||'"
	update-default-branch = remote set-head origin --auto
```

Now you can update the information with `git update-default-branch` and then use the `git default-branch` as shown in examples at the top or however else you like.

If you prefer the slow, always up-to-date version with online requirement, use the following alias instead:

```
[alias]
	default-branch = "!git remote show origin | sed -n '/HEAD branch/s/.*: //p'"
```

## Q&A

> The remote names differ across my repositories, so I can't put the alias with an `origin` remote into my gitconfig?

If you want the same alias to work across all repos, you will have to set up consistent branch names.

Let's assume `origin` always points to your personal github repo, but for some repos your default branch lives in you repo while in other cases, your repo is a fork and your default branch lives in the `upstream` remote. In that case I suggest to add an `upstream` remote to all repos (even if it will be identical to `origin` when your repo contains the default branch). This allows you to use `upstream` in the alias and have your alias work across all repos again.

> Why don't you create a local branch called `default` that points to the default branch on the remote?

This would also be a valid solution, but I am easily confused when local branch names don't match remote branch names.
