# B2 CLI Command Reference

## Account Management

```bash
b2 account authorize [applicationKeyId] [applicationKey]
b2 account get
b2 account clear
```

## Bucket Operations

```bash
b2 bucket list
b2 bucket create <name> allPrivate|allPublic
b2 bucket get <name>
b2 bucket update <name> allPrivate|allPublic
b2 bucket delete <name>
b2 bucket get-download-auth <name>
```

## File Operations

```bash
b2 file upload <bucket> <local-file> <remote-name>
b2 file upload --content-type "text/plain" <bucket> <file> <remote>
b2 file download b2://<bucket>/<path> <local-file>
b2 file cat b2://<bucket>/<path>
b2 file info b2://<bucket>/<path>
b2 file url b2://<bucket>/<path>
b2 file hide b2://<bucket>/<path>
b2 file unhide b2://<bucket>/<path>
b2 file server-side-copy b2://<src-bucket>/<path> b2://<dst-bucket>/<path>
```

## Listing Files

```bash
b2 ls b2://<bucket>
b2 ls -l b2://<bucket>                          # with details
b2 ls -r b2://<bucket>                          # recursive
b2 ls --json b2://<bucket>                      # JSON output
b2 ls --versions b2://<bucket>                  # all versions
b2 ls -r --with-wildcard "b2://<bucket>/*.txt"  # wildcard filter
b2 ls -r --exclude "*.log" b2://<bucket>        # exclude pattern
```

## Sync Operations

```bash
b2 sync /local/folder b2://<bucket>/folder      # local → B2
b2 sync b2://<bucket>/folder /local/folder      # B2 → local
b2 sync b2://<src>/folder b2://<dst>/folder     # B2 → B2
b2 sync --dry-run /local b2://<bucket>          # preview changes
b2 sync --delete /local b2://<bucket>           # remove dest-only files
b2 sync --keep-days 30 /local b2://<bucket>     # retain old versions
b2 sync --exclude-regex '.*\.log$' /local b2://<bucket>
b2 sync --skip-newer /local b2://<bucket>
b2 sync --replace-newer /local b2://<bucket>
b2 sync --threads 10 /local b2://<bucket>
```

### Sync Comparison Modes

| Flag | Behavior |
|------|----------|
| `--compare-versions modTime` | Default — compare modification time |
| `--compare-versions size` | Compare file size only |
| `--compare-versions none` | Compare names only |
| `--compare-threshold 1000` | Fuzzy match within N ms/bytes |

## Delete Operations

```bash
b2 rm b2://<bucket>/<file>
b2 rm -r b2://<bucket>/folder/
b2 rm --dry-run -r b2://<bucket>/folder/
```

## Application Key Management

```bash
b2 key list
b2 key create <name> listFiles,readFiles,writeFiles
b2 key create <name> listFiles,readFiles --bucket <bucket>
b2 key delete <keyId>
```

### Available Capabilities

`listKeys`, `writeKeys`, `deleteKeys`, `listBuckets`, `writeBuckets`, `deleteBuckets`, `listFiles`, `readFiles`, `writeFiles`, `deleteFiles`, `readBucketEncryption`, `writeBucketEncryption`, `readBucketReplications`, `writeBucketReplications`

## Environment Variables

```bash
B2_APPLICATION_KEY_ID="your-key-id"
B2_APPLICATION_KEY="your-application-key"
B2_ACCOUNT_INFO="/path/to/account-info"          # custom credential location
B2_DESTINATION_SSE_C_KEY_B64="base64-key"         # server-side encryption
B2_SOURCE_SSE_C_KEY_B64="base64-key"
B2_ESCAPE_CONTROL_CHARACTERS=1
B2_USER_AGENT_APPEND="my-app/1.0"
```
