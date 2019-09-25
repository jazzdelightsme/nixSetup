# jazzdelightsme's nixSetup

These are just some crufty scripts to automate configuration of Ubuntu machines with basic tools that I like.

- git
- gvim
- pwsh
- git-cola
- bcompare
- git-credential-manager
- personal profile scripts
- etc.

To bootstrap, paste this into a terminal

```bash
sudo bash -c "wget -O - https://raw.githubusercontent.com/jazzdelightsme/nixSetup/master/setupMachine.sh | bash -s"
```

If you need to use a different branch, replace the branch name in the URL **and** pass the `-branch <branchname>` option, like so:

```bash
sudo bash -c "wget -O - https://raw.githubusercontent.com/jazzdelightsme/nixSetup/otherBranch/setupMachine.sh | bash -s - -branch otherBranch"
```

Another option you can pass is `-nogui`, to omit gui-related stuff. But you may not need it; it will try to auto-detect a "no GUI" situation.
