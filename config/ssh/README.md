# [ssh][1]

Using the SSH protocol, you can connect and authenticate to remote servers and services.

## Private keys

Is equivalent of your password

- It's used to verify the public key used belongs to the same cloud server
- It's important to never share your private key with anyone

## Public keys

Is public and can be uploaded to cloud service

- It's used to verify the public key used belongs to the same cloud server
- It's important to never share your public key with anyone

## SSH Setup GitHub

> You can access and write data in repositories on GitHub using SSH (Secure Shell Protocol).
> When you connect via SSH, you authenticate using a private key file on your local machine.

### 1. Setup ssh-agent

Program that manages your SSH keys and passphrases.

```bash
# 1. Kill existing agents
killall ssh-agent

# 2. Start single agent
eval "$(ssh-agent -s)"
# => Agent pid 62683
```

### 2. Generate SSH Private and Public Keys

1. To generate a new SSH key pair, you can use the following command:

    ```bash
    ssh-keygen -t ed25519 -C "rogerio.alcantara@gmail.com" -f ~/.ssh/id_ed25519_github

    # Set correct permissions
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/id_ed25519_github
    chmod 644 ~/.ssh/id_ed25519_github.pub
    ```

2. Test the SSH Private Key locally

    ```bash
    # prints its fingerprint
    ssh-keygen -y -f ~/.ssh/id_ed25519_github
    # => ssh-ed25519 222A421A59C942EF9A1F276130B674A8 rogerio.alcantara@gmail.com
    ```

3. Modify `~/.ssh/config` to automatically load keys into the ssh-agent and store passphrases in keychain

    ```bash
    # ~/.ssh/config
    Host github.com
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519_github
    ```

4. Add SSH Private Key to the ssh-agent

    ```bash
    # [macOS] add SSH Private Key to the ssh-agent
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519_github

    # [Linux] add SSH Private Key to the ssh-agent
    ssh-add ~/.ssh/id_ed25519_github
    ```

5. Note that the `IdentityFile` directive in `~/.ssh/config` isn't a problem even if the physical key file is removed

    ```bash
    # ~/.ssh/config
    Host github.com
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519_github # The SSH Agent handles authentication even if the physical file is not found via Apple's Keychain
    ```

6. Confirm SSH Authentication Key is added to the ssh-agent

    ```bash
    ssh-add -l
    # => 256 SHA256:222A421A59C942EF9A1F276130B674A8 rogerio.alcantara@gmail.com (ED25519)
    ```

7. Copy SSH Public Key to add to GitHub Account

    ```bash
    # Copy the Public Key to the Clipboard
    pbcopy < ~/.ssh/id_ed25519_github.pub
    ```

8. Add SSH Public Key to GitHub as Authentication Key

    ```bash
    # Open GitHub account settings
    open https://github.com/settings/keys

    # Click "New SSH key"
    # [FIELD] Title: "Macbook M3 (id_ed25519_github.pub)"
    # [FIELD] Key type: "Authentication Key"
    # [FIELD] Key: cmd + v to paste the SSH Public Key from the clipboard
    # Click "Add SSH key"
    ```

9. Check if SSH Public Key is added to GitHub

    ```bash
    ssh -T -i ~/.ssh/id_ed25519_github git@github.com
    # => Hello roalcantara! You've successfully authenticated, but GitHub does not provide shell access.
    ```

10. (optional) Enables GPGTools to store and retrieve GPG key passphrases using the macOS Keychain

    ```bash
    # allows automatic passphrase retrieval rather than requiring manual entry each time.
    defaults write org.gpgtools.common UseKeychain YES
    ```

11. (optional) Encrypt SSH Files using [transcrypt][5]

    > [transcrypt][5] is a tool that encrypts files in a Git repository using a symmetric cipher and a public key.
    > Files added to `/.gitattributes` are automatically encrypted on commit and decrypted on checkout.

    ```sh
    # Install
    brew install transcrypt

    # Initialize
    transcrypt -c aes-256-cbc -p 'password'

    # Add files to protect
    echo "~/.config/ssh/id_ed25519_github filter=crypt diff=crypt merge=crypt" >> ~/.gitattributes
    echo "~/.config/ssh/id_ed25519_github.pub filter=crypt diff=crypt merge=crypt" >> ~/.gitattributes

    # Commit and push
    d add -f ~/.config/ssh/id_ed25519_github
    d add -f ~/.config/ssh/id_ed25519_github.pub
    d add ~/.gitattributes
    d commit -m 'Add encrypted SSH Private Key'
    d push

    # List all of the currently encrypted files in a repository
    d ls-crypt

    # Show ecrypted content of the file on HEAD
    d show HEAD:.config/ssh/id_ed25519_github --no-textconv
    ```

## REFERENCES

- [GitHub: About SSH][1]
- [GitHub: About SSH > Checking for existing SSH keys][2]
- [GitHub: About SSH > Generating a new SSH key and adding it to the ssh-agent][3]
- [Bad configuration option: UseKeychain on Mac OS Sierra 10.12.6][4]

[1]: https://docs.github.com/en/github/authenticating-to-github/about-ssh "GitHub: About SSH"
[2]: https://docs.github.com/en/github/authenticating-to-github/checking-for-existing-ssh-keys "GitHub: About SSH > Checking for existing SSH keys"
[3]: https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent "GitHub: About SSH > Generating a new SSH key and adding it to the ssh-agent"
[4]: https://stackoverflow.com/a/50204502/1603694 "Bad configuration option: UseKeychain on Mac OS Sierra 10.12.6"
[5]: https://github.com/elasticdog/transcrypt "Transcrypt: Encrypt files with GPG and Git"
