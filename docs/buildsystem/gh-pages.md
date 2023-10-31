---
parent: Build system
nav_order: 3
---

# Build GitHub Pages

This documentation is created by [GitHub Pages]. The source files are
stored in the repository [MOOSE] in the subfolder `docs`.
We use [Just the Docs], which is a modern, highly customizable, and responsive
[Jekyll] theme for documentation.

{: .note }
> The class documentation is created by its own [build] and is not the scope for this page!

The build steps to create this documentation are defined in [.github/workflows/gh-pages.yml].

It is divided into two jobs:
- build:
    - Only changes to in the subfolder `docs` or `gh-pages.yml` will trigger a build.
    - Checkout of the git repository [MOOSE].
    - Setup [Ruby] version 3.1, which is needed by [Jekyll].
    - Run action [configure-pages].
    - Build with [Jekyll].
    - Run action [upload-pages-artifact].
- deploy:
    - Run action [deploy-pages].

# Preview of this documentation

When enhancing this documentation it is very useful to see a 1on1 preview of the pages.
This can be displayed as follows:

- You need a working installation of [Docker].
- Go to the `docs` subfolder.
- Run `docker compose up`.
- Open a browser with the following URL: `http://127.0.0.1:4000/`.
- After a change of the [Markdown] files, wait some seconds and press F5 in the browser.

[GitHub Pages]: https://pages.github.com/
[MOOSE]: https://github.com/FlightControl-Master/MOOSE
[Just the Docs]: https://github.com/just-the-docs/just-the-docs
[Jekyll]: https://jekyllrb.com/
[Ruby]: https://www.ruby-lang.org/en/
[build]: build-docs.md
[.github/workflows/gh-pages.yml]: https://github.com/FlightControl-Master/MOOSE/blob/master/.github/workflows/gh-pages.yml
[configure-pages]: https://github.com/actions/configure-pages/
[upload-pages-artifact]: https://github.com/actions/upload-pages-artifact
[deploy-pages]: https://github.com/actions/deploy-pages/
[Docker]: https://www.docker.com/
[Markdown]: https://www.markdownguide.org/
