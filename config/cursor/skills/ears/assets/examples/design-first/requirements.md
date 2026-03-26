# Requisitos: Middleware de Rate Limiting

## Visão Geral

Fornecer rate limiting configurável por endpoint para a API Express usando
algoritmo de token bucket com Redis, aplicando limites por usuário ou IP.

## Requisitos

### 1. Limitação de Requisições

**História:** Como operador da API, quero que as requisições sejam limitadas
por endpoint, para que nenhum cliente consiga esgotar os recursos do servidor.

#### Critérios de Aceitação

1. QUANDO um cliente exceder o limite configurado de requisições para um endpoint
   O SISTEMA DEVE responder com HTTP 429 e um header `Retry-After` indicando
   quando o cliente poderá tentar novamente.

2. QUANDO um cliente estiver dentro do limite configurado de requisições
   O SISTEMA DEVE deixar a requisição passar para o próximo middleware sem
   adicionar mais de 100ms de latência.

3. SE o Redis estiver inacessível
   ENTÃO O SISTEMA DEVE permitir a requisição, registrar um aviso de alerta
   e não bloquear o fluxo (comportamento fail-open).

---

### 2. Configuração

**História:** Como desenvolvedor, quero configurar limites diferentes por
endpoint, para que eu possa aplicar restrições mais rígidas em rotas sensíveis.

#### Critérios de Aceitação

1. QUANDO uma rota não tiver limite explícito configurado
   O SISTEMA DEVE aplicar o limite padrão global.

2. QUANDO uma rota tiver um limite explícito configurado
   O SISTEMA DEVE aplicar esse limite no lugar do padrão global.

---

### 3. Identificação do Cliente

**História:** Como operador da API, quero que os limites sejam aplicados por
usuário em requisições autenticadas e por IP nas não autenticadas, para que
os limites sejam distribuídos de forma justa.

#### Critérios de Aceitação

1. QUANDO uma requisição contiver um token de autenticação válido
   O SISTEMA DEVE aplicar o rate limit contra o ID do usuário autenticado.

2. QUANDO uma requisição não contiver token de autenticação
   O SISTEMA DEVE aplicar o rate limit contra o endereço IP do cliente.
