---
name: ears
description: >
  Generates structured feature specs (requirements.md, design.md, tasks.md)
  using EARS notation, replicating Kiro's spec workflow inside Cursor.
  Use when the user asks to create a spec, PRD, feature spec, SDD,
  requirements document, design doc, or implementation plan for a new
  feature or system. Supports Requirements-First and Design-First workflows.
  All generated artifacts must be written in Brazilian Portuguese (pt-BR).
compatibility: Designed for Cursor Agent and similar agentic coding tools.
metadata:
  author: roalcantara
  version: "1.0"
---

# Gerador de Feature Spec (estilo Kiro)

Gere uma spec completa com três arquivos para a feature descrita, replicando
o workflow de specs do Kiro. Leia [references/EARS.md](references/EARS.md)
antes de escrever qualquer requisito. Leia
[references/FORMATS.md](references/FORMATS.md) antes de criar qualquer arquivo.

**Todos os artefatos gerados devem estar em português brasileiro (pt-BR).**
Isso inclui textos, comentários, exemplos, mensagens de erro e diagramas.
Nomes de variáveis, tipos e código permanecem em inglês.

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

2. Gere `docs/specs/<feature-slug>/requirements.md` seguindo o formato em
   [references/FORMATS.md](references/FORMATS.md#requirementsmd).

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

1. Gere `docs/specs/<feature-slug>/design.md` seguindo o formato em
   [references/FORMATS.md](references/FORMATS.md#designmd).

2. Toda decisão arquitetural deve referenciar ao menos um número de requisito
   do `requirements.md`.

3. Inclua um diagrama de sequência Mermaid para o fluxo principal.

4. **PARE. Mostre o arquivo e pergunte:**
   > "Aqui está o `design.md`. A arquitetura está correta?
   > Alguma mudança antes de eu gerar as tarefas?"

   Aguarde aprovação explícita antes de prosseguir.

### Fase 3 — Tarefas

1. Gere `docs/specs/<feature-slug>/tasks.md` seguindo o formato em
   [references/FORMATS.md](references/FORMATS.md#tasksmd).

2. Regras para tarefas:
   - Cada tarefa deve referenciar o(s) número(s) de requisito que satisfaz
   - Ordene por dependência (nenhuma tarefa deve depender de uma não-resolvida acima dela)
   - Inclua tarefas de setup, implementação e validação

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

2. Gere `docs/specs/<feature-slug>/design.md` seguindo o formato em
   [references/FORMATS.md](references/FORMATS.md#designmd).

3. Inclua explicitamente todas as restrições e requisitos não-funcionais.

4. **PARE. Mostre o arquivo e pergunte:**
   > "Aqui está o `design.md`. A arquitetura corresponde ao que você tinha
   > em mente? Itere aqui antes de eu derivar os requisitos."

   Aguarde aprovação explícita antes de prosseguir.

### Fase 2 — Requisitos

1. Derive os requisitos a partir do design confirmado.

2. Gere `docs/specs/<feature-slug>/requirements.md` seguindo o formato em
   [references/FORMATS.md](references/FORMATS.md#requirementsmd).

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
