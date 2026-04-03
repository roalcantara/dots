# pr

Create a pull request for the current changes.

1. Look at the staged and unstaged changes with `git diff`
2. Write a clear commit message based on what changed fallowing the project commit message conventions
3. Commit and push to the current branch
4. Use `gh pr create` to open a pull request with title/description
5. Return the PR URL when done
6. Monitor the GitHub Actions CI Pipeline and wait for it to complete
7. If the CI Pipeline fails, fix the issues and repeat the process ammend the commit message and push to the current branch
8. Iterate until the CI Pipeline succeeds or the user cancels the process
9. If the CI Pipeline succeeds, return the PR URL when done