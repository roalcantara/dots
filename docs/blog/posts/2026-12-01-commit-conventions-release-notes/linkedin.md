## Post

Meus commits seguiam o formato. Os títulos dos meus PRs, não.. e com squash merge, o título é o único commit que o
semantic-release lê. 67 features e fixes nunca chegaram ao meu changelog. :(

Veja como resolvi:
{devto.url}

\#git \#DevOps \#GitHub

## In-between post

Minha regra de commit aceitava "send the payload" com letra minúscula. No `/bin/sh` do macOS, com `en_US.UTF-8`,
`[A-Z]` é um range de ordenação: pega quase todas as minúsculas, menos o "a". O teste passava porque começava com "add".

`[[:upper:]]` resolveu:
{devto.url}

\#bash \#macOS

## English source

Translate only from this; never edit the PT copy on its own.

Post:

```text
My commits followed the format. My PR titles didn't.. and with squash merges, the title is the only commit
semantic-release reads. 67 features and fixes never made my changelog. :(

Here is how I fixed it:
{devto.url}
```

In-between:

```text
My commit rule let "send the payload" through, lowercase. On macOS's /bin/sh under en_US.UTF-8, [A-Z] is a
collation range: it matches almost every lowercase letter except "a". My test passed because it began with "add".

[[:upper:]] fixed it:
{devto.url}
```
