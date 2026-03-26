---
name: ears
description: >
  Same scope as skill "sdd": exactly three files under docs/specs/<feature-slug>/
  (requirements.md, design.md, tasks.md) with EARS, normative design contract,
  and ordered verification tasks. MUST match docs/example/{requirements,design,
  tasks}.md layout when present. Design must use concrete values only (no "pick
  one", "either", or pre-verification placeholders). Cross-links via Markdown
  headings for stable fragments. **All generated prose in Brazilian Portuguese
  (pt-BR).** Code identifiers stay English. Use when the user wants specs in
  pt-BR or asks for EARS / SDD / PRD / requisitos in Portuguese.
compatibility: Designed for Cursor Agent and similar agentic coding tools.
metadata:
  author: roalcantara
  version: "1.1"
---

# Gerador de Feature Spec (estilo Kiro)

Gere uma spec completa com três arquivos para a feature descrita, replicando
o workflow de specs do Kiro. Leia [references/EARS.md](references/EARS.md)
antes de escrever qualquer requisito. Leia
[references/FORMATS.md](references/FORMATS.md) antes de criar qualquer arquivo.

**Todos os artefatos gerados devem estar em português brasileiro (pt-BR).**
Isso inclui textos, comentários, exemplos, mensagens de erro e rótulos em diagramas.
Nomes de variáveis, tipos, campos JSON e código permanecem em inglês quando for
convenção da stack.

## Inegociáveis (layout, papéis, links)

1. **Fonte da verdade do layout**
   - Se o workspace tiver **`docs/example/requirements.md`**, **`docs/example/design.md`** e **`docs/example/tasks.md`**, trate-os como **esqueleto canônico**: **mesma ordem de seções**, **mesmos níveis de heading** (`#`, `##`, `###`, `####`) e **mesmos padrões** (tabelas vs listas) desses arquivos. Preencha o conteúdo para `<feature-slug>` em **pt-BR**; **não** troque o outline pelo template curto do FORMATS sozinho.
   - Se esses arquivos **não existirem**, use apenas os templates em [references/FORMATS.md](references/FORMATS.md).

2. **Separação de papéis**
   - **`requirements.md`**: *o quê* deve valer e *como saber* (critérios EARS em pt-BR). **Referencie** o design com links (`design.md#slug-do-heading`). **Não** duplique tabelas normativas longas (códigos HTTP, matriz de rotas, schemas JSON) se já estiverem no `design.md`.
   - **`design.md`**: *como* em detalhe **fechado** e **verificável** — rotas, métodos, corpos, status HTTP, formato de erro, filas, retries, DLQ, etc. **Fonte única da verdade** para esses fatos (texto em pt-BR; nomes técnicos podem ser em inglês).
   - **`tasks.md`**: *ordem de trabalho* e passos de verificação que **apontam** para ids de requisito **e** headings do design; **não** recoloque o contrato inteiro no meio da tarefa.

3. **Âncoras e links cruzados**
   - Defina alvos de link com **headings Markdown** reais (`#### 8.1 Tabela de rotas`, etc.). **Não** dependa só de `<a id="...">` para preview no Cursor/VS Code.
   - Links de `requirements` ou `tasks` para o design devem usar o **fragmento** gerado a partir do texto do heading (slug estilo GitHub).

4. **Proibido em trechos normativos do design** (tudo que um verificador compara a um valor esperado)
   - Frases como: "escolha uma", "o design decide depois", "antes da verificação preencha", "X ou Y" para o mesmo caso, `_ex.: 200_` **no lugar** de um valor fixo em tabela canônica, "PUT ou PATCH" quando só um método vale.
   - Se faltar decisão, **pergunte ao usuário** antes de escrever a subseção — **não** deixe opções abertas no documento entregue.

---

## Passo 0 — Seleção do Workflow

Pergunte ao usuário:

> "Qual workflow você quer usar?
> - **Requirements-First** — você sabe o comportamento desejado; a arquitetura
>   vai se adaptar para atendê-lo.
> - **Design-First (Alto Nível)** — você tem uma arquitetura em mente;
>   os requisitos serão derivados dela.
> - **Design-First (Baixo Nível)** — você tem pseudocódigo, interfaces ou
>   algoritmos em mente; os requisitos serão derivados deles."

Aguarde a seleção explícita antes de continuar.

Derive o `<feature-slug>` a partir do nome da feature (minúsculas, apenas hífens).
Todos os arquivos vão para `docs/specs/<feature-slug>/`.

---

## Workflow A — Requirements-First

**Fluxo:** Requisitos → Design → Tarefas

### Fase 1 — Requisitos

1. Faça perguntas de clarificação se a descrição da feature for ambígua:
   - Quem são os usuários / papéis envolvidos?
   - Quais são os cenários de sucesso principais?
   - Quais são os casos de erro e edge cases relevantes?
   - Há restrições não-funcionais (performance, segurança, compliance)?

2. Gere `docs/specs/<feature-slug>/requirements.md` seguindo
   [references/FORMATS.md](references/FORMATS.md#requirementsmd) **e**, quando
   existir, a **ordem de seções e headings** de `docs/example/requirements.md`
   (conteúdo em **pt-BR**).

3. Regras para requisitos:
   - Escreva cada critério de aceitação em formato EARS (veja [references/EARS.md](references/EARS.md))
   - Use `QUANDO … O SISTEMA DEVE …` como padrão principal
   - Numere cada critério dentro da sua história (1.1, 1.2, 2.1, …)
   - Cubra caminho feliz, edge cases e tratamento de erros

4. **PARE. Mostre o arquivo e pergunte:**
   > "Aqui está o `requirements.md`. Isso captura tudo corretamente?
   > Me diga o que ajustar antes de eu seguir para o design."

   Aguarde aprovação explícita ("ok", "aprovado", "pode continuar", etc.)
   antes de prosseguir.

### Fase 2 — Design

1. Gere `docs/specs/<feature-slug>/design.md` seguindo
   [references/FORMATS.md](references/FORMATS.md#designmd) **e**, quando existir,
   a **ordem de seções e headings** de `docs/example/design.md` (pt-BR).

2. Toda decisão arquitetural deve referenciar ao menos um número de requisito
   do `requirements.md`.

3. **Contrato normativo**: toda API, payload, código de status ou política que um
   testador possa asserir DEVE aparecer **uma vez**, de forma **concreta**, neste
   arquivo (veja **Inegociáveis**). Sem linhas placeholder ou escolhas adiadas.

4. Inclua um diagrama de sequência Mermaid para o fluxo principal (salvo se o
   exemplo canônico omitir para esse tipo de feature — nesse caso, siga o exemplo).

5. **PARE. Mostre o arquivo e pergunte:**
   > "Aqui está o `design.md`. A arquitetura está correta?
   > Alguma mudança antes de eu gerar as tarefas?"

   Aguarde aprovação explícita antes de prosseguir.

### Fase 3 — Tarefas

1. Gere `docs/specs/<feature-slug>/tasks.md` seguindo
   [references/FORMATS.md](references/FORMATS.md#tasksmd) **e**, quando existir,
   a **ordem de seções e headings** de `docs/example/tasks.md` (pt-BR).

2. Regras para tarefas:
   - Cada tarefa deve referenciar o(s) número(s) de requisito que satisfaz
   - Ordene por dependência (nenhuma tarefa deve depender de uma não-resolvida acima dela)
   - Inclua tarefas de setup, implementação e validação
   - Bullets de verificação devem citar **`design.md#slug-do-heading`** (e o
     `requirements.md` quando fizer sentido) em vez de recolar JSON ou tabelas de status inteiros

3. **PARE. Mostre o arquivo e pergunte:**
   > "Aqui está o `tasks.md`. Podemos começar a implementação,
   > ou você quer ajustar algo?"

---

## Workflow B — Design-First

**Fluxo:** Design → Requisitos → Tarefas

### Fase 1 — Design

1. Faça perguntas de clarificação se necessário:
   - Quais são as restrições técnicas ou stack obrigatório?
   - Há requisitos não-funcionais (latência, throughput, compliance)?
   - Existem diagramas ou documentos de arquitetura para incorporar?
   - Alto Nível (componentes, interações) ou Baixo Nível (pseudocódigo,
     interfaces)?

2. Gere `docs/specs/<feature-slug>/design.md` seguindo
   [references/FORMATS.md](references/FORMATS.md#designmd) e, quando existir,
   o layout de **`docs/example/design.md`**. Aplique os **Inegociáveis**: valores
   técnicos **já fechados** (sem tabelas "TBD").

3. Inclua explicitamente todas as restrições e requisitos não-funcionais.

4. **PARE. Mostre o arquivo e pergunte:**
   > "Aqui está o `design.md`. A arquitetura corresponde ao que você tinha
   > em mente? Itere aqui antes de eu derivar os requisitos."

   Aguarde aprovação explícita antes de prosseguir.

### Fase 2 — Requisitos

1. Derive os requisitos a partir do design confirmado.

2. Gere `docs/specs/<feature-slug>/requirements.md` seguindo
   [references/FORMATS.md](references/FORMATS.md#requirementsmd) e, quando
   existir, o layout de **`docs/example/requirements.md`**.

3. Os requisitos devem ser viáveis dado o design confirmado — não adicione
   comportamentos que o design não suporta.

4. Escreva cada critério de aceitação em formato EARS (veja [references/EARS.md](references/EARS.md)).

5. **PARE. Mostre o arquivo e pergunte:**
   > "Aqui está o `requirements.md` derivado do seu design. Isso reflete
   > todos os comportamentos esperados? Alguma lacuna antes de eu gerar as tarefas?"

   Aguarde aprovação explícita antes de prosseguir.

### Fase 3 — Tarefas

Idêntico ao Workflow A, Fase 3.

---

## Regras Gerais

- Nunca pule uma fase nem prossiga sem aprovação explícita do usuário.
- Nunca gere os três arquivos de uma vez.
- Se o usuário pedir alterações após a aprovação, atualize o arquivo,
  mostre o diff e reconfirme antes de continuar.
- Prefira descrições de tarefas curtas e sem ambiguidade.
- Todos os diagramas Mermaid devem ser válidos e renderizáveis.
- **Layout**: não "melhore" nem reorganize a estrutura do exemplo canônico sem
  pedido explícito do usuário; consistência entre features pesa mais que um outline
  preferido pelo agente.
- **Design alinhado**: se o requisito disser "conforme design §…" ou linkar uma
  subseção, essa subseção DEVE existir e conter **um** valor claro por decisão.
