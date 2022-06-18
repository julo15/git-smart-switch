# git-smart-switch

A replacement for `git checkout` and `git switch` to make switching between branches easier by:

- Allow you to checkout a branch via partial matching
- Automatically managing per-branch stashes

## Installation

```
# With NPM
npm i -g git-smart-switch

# Or with Yarn
yarn global add git-smart-switch

# Then use the following to make a git alias
git config --global alias.ss '!git-ss'
```

## Usage
```
# Checkout a specific branch. No need to type the entire branch name.
git ss <branch>

# Create and checkout a new branch.
git ss -n <branch>

# List available branches
git ss
```

## Why?

### Problem 1: It sucks typing out entire branch names

With `git checkout` and `git switch`, you need to type out the entire branch name in order to checkout a different branch.

```
$ git branch
* develop
  feat/BUG-123-analytics-issue
  feat/BUG-567-app-start-pref
  
$ git checkout feat/BUG-123-analytics-issue
Switched to branch 'feat/BUG-123-analytics-issue'
```

### Better solution: Branch search via `git ss`

`git ss` allows you to type the shortest portion of a branch name that disambiguates it from the rest.

```
$ git branch
* develop
  feat/BUG-123-analytics-issue
  feat/BUG-567-app-start-pref
  
## You could be basic and type out the entire branch name
$ git ss feat/BUG-123-analytics-issue
Switched to branch 'feat/BUG-123-analytics-issue'

## But why not type less?
$ git ss BUG-123
Found branch matching 'BUG-123': feat/BUG-123-analytics-issue.
Switched to branch 'feat/BUG-123-analytics-issue'

## Or even less?
$ git ss 123
Found branch matching '123': feat/BUG-123-analytics-issue.
Switched to branch 'feat/BUG-123-analytics-issue'

## If multiple branches are found, it'll show the branches that match
$ git ss BUG
Found multiple branches matching 'BUG':
  feat/BUG-123-analytics-issue
  feat/BUG-567-app-start-pref

```
Never type an entire branch name ever again!

### Problem 2: Managing stashes sucks

Imagine you currently have `my-feature-branch` checked out, with several uncommitted changes in there.

Now you want to briefly switch to the `develop` branch to investigate an issue that has come up.

How will you go about **switching branches** without **disturbing your uncommitted changes**?

#### Solution 1: Stash and unstash manually
```
## 1) Stash your changes
$ git stash -u

## 2) Switch branch
$ git checkout develop

## 3) Do your stuff on develop
...

## 4) When you're done, switch back and pop your stash
$ git checkout my-feature-branch
$ git stash pop

```

#### Solution 2: Commit your changes temporarily
```
## 1) Make a temporary commit
$ git add .
$ git commit -m 'WIP: Some work on my-feature-branch' --no-verify

## 2) Switch branch
$ git checkout develop

## 3) Do your stuff on develop
...

## 4) When you're done, switch back and undo your commit
$ git checkout my-feature-branch
$ git reset --soft HEAD^
```

### Better solution: Per-branch stashes via `git ss`

`git-smart-switch` makes this workflow easy by managing **per-branch stash entries**.

- Any time you switch away from a branch using `git ss`, it will stash the changes for that branch.
- When you switch back to the branch later, `git ss` will automatically apply the stash associated with that branch.

```
## 1) Use 'git ss' to switch branches and stash any changes.
##    'git ss' is smart enough to tie the stash entry to my-feature-branch.
$ git ss develop    # or 'git ss dev' to fuzzy match

Attempting to stash changes for my-feature-branch
Saved working directory and index state On my-feature-branch: smart-switch|my-feature-branch

Switching from my-feature-branch --> develop
Switched to branch 'develop'

## 2) Do your stuff on develop
...

## 3) When you're done, use 'git ss' to switch back
##    'git ss' will notice that there is a smart-switch entry for my-feature-branch and apply it.
$ git ss my-feature-branch    # or 'git ss my-feat' to fuzzy match

Switching from develop --> my-feature-branch
Switched to branch 'my-feature-branch'

Looking for stash to apply to my-feature-branch
Stash found. Applying
 src/first.ts     | 1 +
 src/second.ts.   | 1 +
 2 files changed, 2 insertions(+)

```
