# Formatos dos Arquivos

Formato exato para cada artefato gerado. Siga estes templates à risca.

## Layout canônico (sobrescreve o template do repositório)

Quando o workspace contiver **`docs/example/requirements.md`**, **`docs/example/design.md`** e **`docs/example/tasks.md`**:

- **Esses arquivos definem o layout**, não só este documento: replique **ordem de seções**, **níveis de heading** (`#`, `##`, `###`, `####`) e **padrões estruturais** (glossário, definição de pronto, requisitos numerados, subseções de contrato HTTP, etc.).
- Os templates abaixo são **fallback** quando `docs/example/*.md` **não** existir.
- **Não** acrescente nem remova seções estruturais de topo em relação ao exemplo para "simplificar" ou "melhorar", salvo pedido explícito do usuário.

## Papéis dos documentos (resumo)

| Arquivo | Papel |
| --- | --- |
| `requirements.md` | Comportamentos e critérios de aceitação (EARS, em pt-BR). Aponta para o design com links. |
| `design.md` | **Normativo**: um valor por decisão (rotas, corpos, status, políticas). Texto em pt-BR; identificadores técnicos podem ser em inglês. |
| `tasks.md` | Sequência de trabalho e verificação; cita números de requisito + `design.md#slug`, sem duplicar o contrato. |

## Links cruzados

- Use **headings Markdown** como alvos de link para que o preview (Cursor, VS Code, GitHub) gere fragmentos estáveis.
- Evite depender só de `<a id="...">` como âncora de uma subseção.

## Design normativo (sem ambiguidade)

Em `design.md`, para tudo que um verificador compare a um resultado esperado:

- Use inteiros HTTP **literais**, **nomes exatos** de campos JSON, políticas **fixas** (ex.: DLQ após N recebimentos).
- **Não** use: "escolha uma", "um ou outro", "antes da verificação", células placeholder "_ex.: 200_", ou dois métodos HTTP quando só um vale.
- Se faltar decisão, **pergunte** antes de escrever a subseção.

---

## requirements.md

```markdown
# Requisitos: <Nome da Feature>

## Visão Geral

<Um parágrafo descrevendo a feature e seu propósito de negócio.>

## Requisitos

### 1. <Título da História de Usuário>

**História:** Como <papel>, quero <capacidade>, para que <benefício>.

#### Critérios de Aceitação

1. QUANDO <condição>
   O SISTEMA DEVE <comportamento>

2. QUANDO <condição>
   O SISTEMA DEVE <comportamento>

3. SE <condição indesejada>
   ENTÃO O SISTEMA DEVE <comportamento>

---

### 2. <Título da História de Usuário>

**História:** Como <papel>, quero <capacidade>, para que <benefício>.

#### Critérios de Aceitação

1. QUANDO <condição>
   O SISTEMA DEVE <comportamento>

2. ENQUANTO <pré-condição>
   QUANDO <gatilho>
   O SISTEMA DEVE <comportamento>
```

**Regras:**
- Critérios são numerados por história (1.1, 1.2, 2.1, …) para rastreabilidade.
  Use o número da história como prefixo em referências cruzadas (ex.: "satisfaz 1.1").
- Toda história precisa de ao menos um critério de caminho feliz e um de erro/edge case.
- Com exemplo canônico no repo, seções extras dele (glossário, definição de pronto, introdução) são **esperadas** — replique a estrutura.
- Sem exemplo, mantenha o template mínimo: não adicione status, responsável ou data salvo pedido do usuário.

---

## design.md

```markdown
# Design: <Nome da Feature>

## Visão Geral

<Descrição de alto nível da abordagem técnica e por que foi escolhida.>

## Arquitetura

### Componentes

| Componente | Responsabilidade |
|---|---|
| <nome> | <O que faz> |
| <nome> | <O que faz> |

### Diagrama de Sequência

```mermaid
sequenceDiagram
    actor Usuário
    participant Frontend
    participant Backend
    participant Banco de Dados

    Usuário->>Frontend: ação
    Frontend->>Backend: requisição
    Backend->>Banco de Dados: consulta
    Banco de Dados-->>Backend: resultado
    Backend-->>Frontend: resposta
    Frontend-->>Usuário: feedback
```

## Modelos de Dados

<Descreva entidades, schemas ou tipos relevantes para esta feature.>

```typescript
interface ExemploEntidade {
  id: string
  // ...
}
```

## Tratamento de Erros

| Cenário | Comportamento | Requisito |
|---|---|---|
| <Caso de erro> | <Como é tratado> | <1.3> |

## Considerações Não-Funcionais

<Performance, segurança, escalabilidade ou compliance relevantes para esta
feature. Referencie números de requisito onde aplicável.>

## Estratégia de Testes

<Abordagem de testes unitários, de integração e e2e. Quais comportamentos
são cobertos em cada camada.>
```

**Regras:**
- Toda decisão de design deve referenciar ao menos um número de requisito.
- O diagrama de sequência deve cobrir o fluxo principal do caminho feliz (quando o exemplo canônico incluir um).
- Não invente comportamentos não cobertos pelo `requirements.md`.
- Tabelas e subseções que definem **HTTP**, **filas** ou **observabilidade** são **normativas**: preencha por completo; veja **Design normativo** acima.

---

## tasks.md

```markdown
# Tarefas: <Nome da Feature>

- [ ] 1. <Título de alto nível da tarefa>
  - <Sub-tarefa concreta>
  - <Sub-tarefa concreta>
  - **Requisitos:** 1.1, 1.2

- [ ] 2. <Título de alto nível da tarefa>
  - <Sub-tarefa concreta>
  - <Sub-tarefa concreta>
  - **Requisitos:** 2.1

- [ ] 3. <Tarefa de validação>
  - Escrever testes cobrindo os critérios de aceitação 1.1, 1.2
  - Verificar tratamento de erros para 1.3
  - **Requisitos:** 1.1, 1.2, 1.3
```

**Regras:**
- Tarefas são ordenadas por dependência — cada tarefa pode ser iniciada sem
  depender de uma não-resolvida acima dela.
- Toda tarefa referencia o(s) número(s) de requisito que satisfaz.
- Inclua ao menos uma tarefa de validação/testes por história.
- Sub-tarefas são concretas e acionáveis, não vagas ("implementar X", não "trabalhar em X").
- Bullets de **verificação** devem apontar para **`design.md#…`** e critérios do
  `requirements.md` em vez de copiar JSON ou tabelas de status inteiros.
- Não adicione campos de status, responsável ou data — o checkbox é suficiente
  (salvo se o exemplo canônico tiver bloco de definição de pronto no topo — replique).
