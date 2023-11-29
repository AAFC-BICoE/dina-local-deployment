# Setup

From project root:

```
cp pre-commit-hook/pre-commit .git/hooks/pre-commit
chmod +x pre-commit
```

# Test

Run `git commit` and make sure you see the output `Checking files with pre-commit hook ....` in the console.
