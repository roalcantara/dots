# SOPS/AGE CONFIGURATION GUIDE

This guide explains how to set up SOPS with AGE encryption for managing sensitive data in this dotfiles repository.

## OVERVIEW

- SOPS (Secrets OPerationS) is used to encrypt sensitive files (like `.env` files) before they are committed to git.
- AGE is the encryption backend used by SOPS.

## QUICK SETUP FOR NEW MACHINES

### 1. Install Required Tools

The `age` and `sops` tools are automatically installed by the install script when using `flox` or `mise` package managers.

### 2. Copy AGE Keys

Copy the AGE keys from this repository to your local configuration:

```bash
# Create the AGE configuration directory
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/sops/age"

# Copy the AGE keys from the repository
cp config/sops/age/keys.txt "${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"

# Set appropriate permissions
chmod 600 "${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"
```

### 3. Verify Setup

Test the setup by creating a test file:

```bash
# Create a test .env file
echo "TEST_SECRET=my-secret-value" > test.env

# Encrypt it with SOPS
sops --encrypt --in-place test.env

# Decrypt it back
sops --decrypt --in-place test.env

# Clean up
rm test.env
```

## HOW IT WORKS

### GIT FILTERS

The repository uses git clean/smudge filters to automatically:

- **Clean (on commit)**: Encrypt `.env` files using SOPS
- **Smudge (on checkout)**: Decrypt `.env` files automatically

#### Clean filter: avoiding “always modified”

SOPS (and AGE) use **non-deterministic encryption**: each encrypt run produces different ciphertext (e.g. new IV). Git treats a file as modified when `clean(working-tree)` differs from the blob in the index. If the clean filter always re-encrypts, that comparison never matches, so filtered files appear modified after every checkout.

To fix this, `script/clean.sops.sh` uses a **hash-compare** approach (see [getsops/sops#1137](https://github.com/getsops/sops/issues/1137) and [FiloSottile/age#507](https://github.com/FiloSottile/age/discussions/507)):

1. Decrypt the blob in the index for the given path.
2. Hash the decrypted content and the working-tree content (stdin).
3. If the hashes match → content unchanged → **output the existing encrypted blob** (no re-encrypt).
4. If they differ → content changed → encrypt the working-tree content and output that.

When unchanged, Git sees the same bytes as in the index, so the file is not reported as modified.

### CONFIGURATION FILES

- `.sops.yaml`: SOPS configuration defining encryption rules
- `script/clean.sops.sh`: Git clean filter script
- `script/smudge.sops.sh`: Git smudge filter script
- `.gitattributes`: Tells git to use the SOPS filters for `.env` files

### AGE KEY MANAGEMENT

- **Private Key**: Stored in `config/sops/age/keys.txt` (should be copied to `~/.config/sops/age/keys.txt`)
- **Public Key**: `age17q0hc40w3zukdw47zagn5f0rj72ggcu5ygxxpekpua6x3trp6q0syn9lt4`
- **Usage**: SOPS uses the public key for encryption, private key for decryption

## SECURITY CONSIDERATIONS

1. **Private Key Security**: The private key should be kept secure and never committed to version control
2. **Backup**: Keep a secure backup of your AGE keys
3. **Key Rotation**: Consider rotating keys periodically for enhanced security

## TROUBLESHOOTING

### COMMON ISSUES

1. **"AGE key file not found"**: Ensure you've copied the keys to the correct location
2. **"sops command not found"**: Install sops via your package manager
3. **Permission denied**: Check that the AGE key file has correct permissions (600)
4. **Filtered files always appear modified after checkout**: SOPS uses non-deterministic encryption, so a naïve clean filter (always re-encrypt) makes Git see changes every time. This repo uses the [hash-compare fix](https://github.com/getsops/sops/issues/1137) in `script/clean.sops.sh`; ensure you use that script (see [Clean filter: avoiding “always modified”](#clean-filter-avoiding-always-modified)).

### MANUAL COMMANDS

If git filters aren't working, you can manually encrypt/decrypt:

```sh
sops --encrypt --in-place filename.env # Encrypt a file
sops --decrypt --in-place filename.env # Decrypt a file
sops filename.env # View encrypted file without decrypting

# UNSET ALL SOPS-RELATED CONFIG
git config --unset filter.sops.clean    # UNSETS clean filter (secures secrets on commit)
git config --unset filter.sops.smudge   # UNSETS smudge filter (restores secrets on checkout)

# ADD SOPS-RELATED CONFIG
git config filter.sops.clean script/clean.sops.sh %f   # SETS clean filter (secures secrets on commit)
git config filter.sops.smudge script/smudge.sops.sh %f  # SETS smudge filter (restores secrets on checkout)
git config filter.sops.required true

# CHECK ALL FILTER CONFIGS
git config --get filter.sops.clean      # secures secrets on commit
git config --get filter.sops.smudge     # restores secrets on checkout
git config --get diff.sops.textconv     # shows decrypted content in diffs (NOT IMPLEMENTED IN THIS REPO!!!)
git config --get-regexp "\.sops\."      # check if sops filters are configured
cat .git/config                         # cat the git config file

head -5 config/.env                     # Must show actual API keys; NOT ENC[...].CONTENT!
git show :config/.env | head -5         # Must show decrypted content; ENC[...] CONTENT!
```

### DECRYPT THE FILE THAT'S CURRENTLY ENCRYPTED IN YOUR WORKING DIRECTORY

In the case where the file is already encrypted in your working directory,
you can decrypt it using the following command:

```sh
# 💡 DECRYPT THE FILE THAT'S CURRENTLY ENCRYPTED IN YOUR WORKING DIRECTORY
cat config/.env                         # check that the file is encrypted - IT SHOWS ENC[...].CONTENT!
cat .git/config                         # check the git config file - SHOULD HAVE THE FILTERS SET!
sops decrypt --in-place --input-type dotenv --output-type dotenv config/.env # decrypt the file
git status                              # check git status - SHOULD BE CLEAN!
echo "# Test comment" >> config/.env    # make a small change
cat config/.env                         # check that the file is decrypted - IT SHOWS THE CONTENT! YAY!
git status                              # check git status - SHOULD SHOW MODIFIED!
git diff config/.env                    # shows decrypted diff (ONLY IF WE ADD THE DIFF FILTER - which we didn't do in this repo!)
```

### SCRIPT WHICH ENCRYPT/DECRYPT THE FILE (EXAMPLE)

This script is meant to be used as a global smudge-clean filter for removing sensitive data from your commits.

[SOURCE](https://developers.redhat.com/articles/2022/02/02/protect-secrets-git-cleansmudge-filter)

```sh
__git_smudge_clean_filter() {
  #####################################################################################################
  # This script is meant to be used as a global smudge-clean filter for removing sensitive data       #
  # from your commits.                                                                                #
  #                                                                                                   #
  # 1. Place this script in an acceisble path, i.e. ~/scripts/git-smudge-clean-filter.sh.             #
  #                                                                                                   #
  # 2. Populate the 'mapArr' using what you need hidden as the key, and the replacment as the value.  #
  #    DO NOT use same values for multiple keys (this will work only in one direction).               #
  #                                                                                                   #
  # 3. Set up the filter with git (2 options):                                                        #
  # 3.1. You can either add the following section in your global ~/.gitconfig file:                   #
  #      [filter "reductScript"]                                                                      #
  #          smudge = ~/scripts/git-smudge-clean-filter.sh smudge                                     #
  #          clean = ~/scripts/git-smudge-clean-filter.sh clean                                       #
  # 3.2. Or run the following command from you cli:                                                   #
  #      git config --global filter.reductScript.smudge "~/scripts/git-smudge-clean-filter.sh smudge" #
  #      git config --global filter.reductScript.clean "~/scripts/git-smudge-clean-filter.sh clean"   #
  #                                                                                                   #
  # 4. For every file type, in every repository you are working on, and need sensitive data removed,  #
  #    add the 'filter=reductScript' property in the attributes file and you're good to go.           #
  #    For example for filtering yaml files: `*.yaml text eol=lf filter=reductScript`.                #
  #                                                                                                   #
  #    Tip: for shared repositories, you can store your attributes in in '$GIT_DIR/info/attributes'   #
  #         instead of the standard '.gitattributes' file.                                            #
  #         Follow this https://git-scm.com/docs/gitattributes for more attibtues inforamtion.        #
  # REFERENCES:                                                                                       #
  #    - https://developers.redhat.com/articles/2022/02/02/protect-secrets-git-cleansmudge-filter     #
  #    - https://gist.github.com/TomerFi/0911f573ea0474b9ab74bcfcef0f2a49                             #
  #####################################################################################################

  declare -A mapArr

  # Populate the 'mapArr' using what you need hidden as the key, and the replacment as the value
  # DO NOT use same values for multiple keys (this will work only in one direction)
  mapArr["my-work-private-server.mywork.com"]="<reducted-work-server>"
  mapArr["my-personal-private-server.myowndomain.org"]="<reducted-personal-server>"
  mapArr["A*&#QAADDA(77##F"]="super-secret-token"
  mapArr["oops@mypersonal.email"]="support@correct.email"

  # mac users: use gsed instead of sed
  [ $UNAME == "Darwin" ] && sedcmd="gsed" || sedcmd="sed"

  if [[ "$1" == "clean" ]]; then
    for key in ${!mapArr[@]}; do
      sedcmd+=" -e \"s/${key}/${mapArr[${key}]}/g\""
    done
  elif [[ "$1" == "smudge" ]]; then
    for key in ${!mapArr[@]}; do
      sedcmd+=" -e \"s/${mapArr[${key}]}/${key}/g\""
    done
  else
    echo "use smudge/clean as the first argument"
    exit 1
  fi

  eval $sedcmd
}
```

## REFERENCES

- [SOPS Documentation](https://github.com/getsops/sops)
- [SOPS #1137 — Use with git-filter (clean/smudge), “always modified”](https://github.com/getsops/sops/issues/1137)
- [AGE #507 — Using age as a git clean/smudge filter? (hash-compare fix)](https://github.com/FiloSottile/age/discussions/507)
- [AGE Documentation](https://github.com/FiloSottile/age)
- [SOPS with AGE and Git](https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html)
- [Protect Secrets in Git with the clean/smudge filter](https://developers.redhat.com/articles/2022/02/02/protect-secrets-git-cleansmudge-filter)
- [Using SOPS with Age and Git like a Pro](https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html)
