# ZSH: Configuration Files

Zsh has several system-wide and user-local configuration [files][5].

## Structure

The project is organized as follows:

```tree
zsh ($ZDOTDIR)
│
│── .zlogin
│── .zlogout
│── .zprofile
│── .zshenv
└── .zshrc
```

### [Startup Files][5]

The configuration files are read in the following order

- **.zshenv**

    This file is sourced by all instances of Zsh, and thus, it should be kept as small as possible and should only define environment variables.

- **.zprofile**

    This file is similar to zlogin, but it is sourced before zshrc. It was added for [KornShell][2] fans. See the description of zlogin below for what it may contain.

- **.zshrc**

    This file is sourced by interactive shells. It should define aliases,
    functions, shell options, key bindings and plugins.

- **.zlogin**

    This file is sourced by login shells after zshrc, and thus, it should contain commands that need to execute at login. It is usually used for messages such as [fortune][3], [msgs][4], or for the creation of files.

    This is not the file to define aliases, functions, shell options, and key bindings. It should not change the shell environment.

- **.zlogout**

    This file is sourced by login shells during logout. It should be used for displaying messages and the deletion of files.

*The authors of these files should be contacted via the [issue tracker][0].*

## References

- [Z shell][1]
- [The KornShell Command And Programming Language][2]
- [Fortune (Unix)][3]
- [manpagez: man pages & more][4]
- [ZSH: Startup/Shutdown Files][5]
- [ZSH: Functions][6]
- [ZSH: Parameters][7]
- [ZSH: Options][8]
- [ZSH: Aliasing][9]
- [ZSH: Binding keys and handling keymaps][10]
- [ZSH: Completion System][11]
- [ZSH: Autoloading Functions][12]
- [Writing Zsh Completion][13]

[0]: https://github.com/roalcantara/dots/issues
[1]: http://zsh.sourceforge.io
[2]: http://kornshell.com
[3]: http://en.wikipedia.org/wiki/Fortune_(Unix)
[4]: http://manpagez.com/man/1/msgs
[5]: http://zsh.sourceforge.io/Doc/Release/Files.html
[6]: http://zsh.sourceforge.io/Doc/Release/Functions.html
[7]: http://zsh.sourceforge.io/Doc/Release/Parameters.html
[8]: http://zsh.sourceforge.io/Doc/Release/Options.html
[9]: http://zsh.sourceforge.io/Intro/intro_8.html
[10]: http://zsh.sourceforge.io/Guide/zshguide04.html#l93
[11]: http://zsh.sourceforge.io/Doc/Release/Completion-System.html
[12]: http://zsh.sourceforge.io/Doc/Release/Functions.html#Autoloading-Functions
[13]: https://wikimatze.de/writing-zsh-completion-for-padrino
