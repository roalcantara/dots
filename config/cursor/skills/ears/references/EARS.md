# Referência Rápida — EARS

EARS (Easy Approach to Requirements Syntax) restringe requisitos em linguagem
natural a padrões determinísticos e testáveis.

---

## Padrão Principal do Kiro

O Kiro usa uma forma simplificada de duas cláusulas para a maioria dos
requisitos de produto:

```
QUANDO <condição ou evento de disparo>
O SISTEMA DEVE <comportamento esperado>
```

Use este como padrão para todos os critérios de aceitação.

---

## Padrões Completos do EARS

Use estes quando a forma simplificada perder nuance importante.

### Ubíquo — sempre ativo, sem condição

```
O SISTEMA DEVE <resposta>
```

Exemplo:
```
O SISTEMA DEVE responder a todas as requisições da API em menos de 500ms
sob carga normal.
```

### Orientado a Estado — ativo enquanto uma condição se mantém

```
ENQUANTO <pré-condição>
O SISTEMA DEVE <resposta>
```

Exemplo:
```
ENQUANTO a sessão do usuário estiver expirada
O SISTEMA DEVE redirecionar todas as requisições para /login.
```

### Orientado a Evento — disparado por um evento (padrão do Kiro)

```
QUANDO <gatilho>
O SISTEMA DEVE <resposta>
```

Exemplo:
```
QUANDO o usuário enviar o formulário de checkout
O SISTEMA DEVE validar todos os campos obrigatórios antes de processar
o pagamento.
```

### Comportamento Indesejado — tratamento de erros e edge cases

```
SE <gatilho indesejado>
ENTÃO O SISTEMA DEVE <resposta>
```

Exemplo:
```
SE o gateway de pagamento retornar um erro de timeout
ENTÃO O SISTEMA DEVE exibir "Não foi possível processar o pagamento.
Tente novamente."
```

### Complexo — pré-condição + gatilho combinados

```
ENQUANTO <pré-condição>
QUANDO <gatilho>
O SISTEMA DEVE <resposta>
```

Exemplo:
```
ENQUANTO o carrinho contiver ao menos um item
QUANDO o usuário clicar em "Finalizar Compra"
O SISTEMA DEVE exibir a tela de resumo do pedido.
```

---

## Regras

1. A ordem das cláusulas é sempre: ENQUANTO → QUANDO/SE → DEVE. Nunca reordene.
2. Cada requisito tem exatamente um nome de sistema e uma ou mais respostas.
3. Divida comportamentos compostos: evite "e" para encadear respostas não relacionadas.
4. Evite "não" como verbo principal — use o padrão de Comportamento Indesejado.
5. Evite termos vagos: "adequado", "amigável", "conforme necessário", "rapidamente".
6. Cada critério deve ser testável de forma independente.

---

## Escolhendo o Padrão Correto

| Situação | Padrão |
|---|---|
| Comportamento padrão de produto | Orientado a Evento (`QUANDO … DEVE`) |
| Restrição sempre ativa | Ubíquo (`DEVE`) |
| Modo ou estado de sessão | Orientado a Estado (`ENQUANTO … DEVE`) |
| Caso de erro ou falha | Comportamento Indesejado (`SE … ENTÃO DEVE`) |
| Estado + evento combinados | Complexo (`ENQUANTO … QUANDO … DEVE`) |
