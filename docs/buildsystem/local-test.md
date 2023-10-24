---
parent: Build system
nav_order: 4
---

# Run builds locally

When creating or enhancing [GitHub Actions] builds it is a problem to test the
build. After each change you need to commit and check the build result. This
leads to a lot of unnecessary commits.

Therefor it is needed to run the build locally on the developer PC. The tool
which enabled this is [act]. It uses [Docker] to create a build runner and
executes the [GitHub Actions] build with it.

[act] can by installed by [Chocolatey] by this single command: `choco install act-cli`.

We use the `Medium Docker Image` for our MOOSE builds to work properly.
Unfortunately the docker images used by [act] are not as up to date as the
images used by [GitHub Actions]. So we needed to add a build step with
`sudo apt-get -qq update`.

The build jobs needs `TOKENS` to run properly. So you have to create a PAT
([Personal Access Token]). A classic Token with read rights is enough to run
the build, as long as don't want to push the results.

{: .important }
> The push step is only executed if the variable `FORCE_PUSH` with value `true` is set.
> - This is only needed if the push step itself must be change and tested!
> - Add parameter `--var FORCE_PUSH=true` to your [act] commando.
> - You and your PAT needs write access to the target repos, too.

Save your PAT in the file `.secrets` in the main folder
of the MOOSE repository. This file is added to `.gitignore`, so it is not
recognized by git for commits. Add the following line to `.secrets`:

```
BOT_TOKEN=<your PAT>
```

To run the builds use these commands:
- `act push -W .github/workflows/build-includes.yml`
- `act push -W .github/workflows/build-docs.yml`

[GitHub Actions]: https://docs.github.com/en/actions
[act]: https://github.com/nektos/act
[Docker]: https://www.docker.com/
[Chocolatey]: https://community.chocolatey.org/
[Personal Access Token]: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
