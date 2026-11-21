# Security

omarchy-ui is a set of QML components, JavaScript libraries and shell scripts for a plugin to copy and read. It is small on purpose, and it has no network access and no privileged code:

- **`ui/`** draws and handles keys. `UTheme.qml` reads two environment variables (`OMARCHY_REDUCED_MOTION`, `NOTCH_REDUCED_MOTION`) through `Quickshell.env` and Omarchy's colours through `qs.Commons`. Nothing in `ui/` opens a socket or a file, starts a process, or imports anything else from Quickshell. The `.js` files are pure functions.
- **`dev/sync-ui.sh`, `dev/check-ui.sh` and `dev/walk.sh`**, the scripts a plugin copies with `--tools`, run locally: the sync copies files and reads the kit checkout's `HEAD` and status with `git rev-parse` and `git status`, and the gate reads a commit with `git archive` when asked for `--ref`; the sync never clones, fetches or pulls, and never runs anything from the checkout. They contain no `git clone`, `fetch`, `pull`, `curl`, `wget`, `sudo`, `pkexec`, `systemctl` or `systemd-run` (`dev/test.sh` greps for them). They write only into the plugin directory you name and a temporary directory they remove.
- The tests and harnesses run offscreen and install and reload nothing.

Nothing here asks for root. If you are asked to run any part of it with `sudo`, that is not from this repository.

## Reporting

If you find a way for the kit, or the scripts a plugin copies, to do something outside the above (read or write a path it should not, run a command, reach the network, or escape the plugin directory), please report it **privately**: on GitHub, use *Security, Report a vulnerability* on [Kalinewb/omarchy-ui](https://github.com/Kalinewb/omarchy-ui/security) (private vulnerability reporting). If that option is not shown, open an issue that says only that you have a security report and how you would like to be reached, with no details, and it will be taken from there.

Please give the version (`head -n 2 ui/KIT`, or the release tag) and the steps to reproduce. Expect an acknowledgement as time allows: this is a one-person project, with no promised response time. Only the latest release is supported ([VERSIONING.md](VERSIONING.md#support-policy)).

A hard-to-read colour pair, a missing accessible name or a gate that misses a literal is a bug, not a vulnerability: use the bug template.
