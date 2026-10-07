# Security policy

## Reporting a vulnerability

Please don't open a public issue for a security problem. Report it privately: open the repository's Security tab and click "Report a vulnerability". Include your macOS version, the output of `removemacai --version` and the steps to reproduce it.

## Supported versions

Fixes go into new releases only, so check that you're on the latest one before reporting.

## Installing

The one-line installer downloads the latest release, checks it against the SHA-256 checksum published with that release and stops if they don't match. It runs the binary from a temporary directory and deletes it afterwards. You can read [install.sh](install.sh) before running it, or install with Homebrew instead:

```sh
brew install omlahore/tap/removemacai
```

### Verifying a download

The checksum is published next to the file, so it catches a damaged download but not a replaced one. Each release is also attested by its build workflow. With the [GitHub CLI](https://cli.github.com) installed and signed in, `install.sh` verifies the attestation itself (set `REMOVEMACAI_VERIFY=1` to refuse to run without `gh`). To check a file by hand:

```sh
gh attestation verify removemacai-darwin-arm64.tar.gz --repo omlahore/RemoveMacAI
```

For a fork, set `REMOVEMACAI_REPO` and `REMOVEMACAI_URL` to the fork's repository and release URL. The piped `main` copy of the script changes over time, so pin it to a tag or commit if that matters to you. The binary is ad-hoc signed and not notarized.

### Building from source

`swift build -c release --arch arm64`, then `.build/arm64-apple-macosx/release/removemacai selftest`. The package has no external dependencies, and the build scripts make no network requests.

### Before applying changes

Nothing changes until you confirm. Run `removemacai off --dry-run` or `removemacai apply <names> --dry-run` first, and inspect the profile it writes with `plutil -p`. `removemacai clean` moves files to the Trash, but unavailable simulators and Time Machine local snapshots are deleted for good, so review its list before confirming.
