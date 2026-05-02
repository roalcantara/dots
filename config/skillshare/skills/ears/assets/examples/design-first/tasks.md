# Tarefas: Middleware de Rate Limiting

- [ ] 1. Implementar algoritmo central do TokenBucket
  - Criar `TokenBucket.consumir(estado, config)` com cálculo de reabastecimento
  - Aplicar teto de burst (`min(tokens + reabastecido, capacidade)`)
  - Retornar `{ permitido, restantes, resetEm }`
  - **Requisitos:** 1.1, 1.2

- [ ] 2. Implementar RedisStore com operações atômicas
  - Usar script Lua para GET + SET atômico e evitar condições de corrida
  - Definir TTL das chaves de bucket igual a `config.windowMs`
  - Expor métodos `buscar(chave)` e `salvar(chave, estado, ttl)`
  - **Requisitos:** 1.2, 1.3

- [ ] 3. Implementar factory de middleware `rateLimiter()`
  - Aceitar `LimitConfig` por rota; usar padrão global se ausente
  - Resolver chave do cliente: ID do usuário autenticado ou IP
  - Chamar `RedisStore.buscar()` → `TokenBucket.consumir()` → `RedisStore.salvar()`
  - Se permitido: chamar `next()`
  - Se negado: responder 429 com header `Retry-After`
  - Se Redis falhar: registrar aviso e chamar `next()` (fail-open)
  - **Requisitos:** 1.1, 1.2, 1.3, 2.1, 2.2, 3.1, 3.2

- [ ] 4. Escrever testes
  - Unitários: `TokenBucket.consumir()` — reabastecimento, teto, casos de exaustão
  - Unitários: `resolverChave()` — caminho autenticado vs. não autenticado
  - Integração: middleware em app Express de teste com `ioredis-mock`
  - Integração: falha do Redis → comportamento fail-open
  - Carga: verificar overhead menor que 100ms a 1.000 req/s com `autocannon`
  - **Requisitos:** 1.1, 1.2, 1.3, 2.1, 2.2, 3.1, 3.2
