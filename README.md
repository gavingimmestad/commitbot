# commitbot

A small commit bot. It runs a command and, if that command changed any files,
commits and pushes them. If nothing changed, it does nothing.

Use it to refresh data files, regenerate docs, update lockfiles, and so on.

## Use it as a GitHub Action

```yaml
name: refresh data
on:
  schedule:
    - cron: "0 6 * * *"
  workflow_dispatch:
permissions:
  contents: write
jobs:
  refresh:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: gavingimmestad/commitbot@main
        with:
          command: python scripts/refresh.py
          message: "data: daily refresh"
```

| Input | Required | Default |
|-------|----------|---------|
| `command` | yes | |
| `message` | no | `chore: automated update` |

Commits are authored by `github-actions[bot]`.

## Use it locally

```sh
bash /path/to/commitbot.sh "python scripts/refresh.py" "data: daily refresh"
```

Run it inside any git repository. Local commits use your own git identity,
so `user.name` and `user.email` must be set.

## Good to know

- It refuses to run with uncommitted changes or unpushed commits, so it never publishes unrelated work.
  If an earlier step in your workflow creates files, add them to `.gitignore`.
- It needs a checked-out branch. Pull request checkouts are detached, so it refuses to run there.
- If the branch moved while the command ran, it rebases and retries the push once. On a conflict it fails
  and keeps the commit locally.
- Pushes made with `GITHUB_TOKEN` do not trigger other workflows.
- GitHub disables scheduled workflows in public repositories after 60 days without activity.
- Please follow GitHub's [Acceptable Use Policies](https://docs.github.com/en/site-policy/acceptable-use-policies/github-acceptable-use-policies).
  Automated inauthentic activity is not allowed, which is why there is no "commit anyway" mode.

## Test

```sh
bash test.sh
```

## License

MIT
