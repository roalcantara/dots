# Tarefas: Autenticação de Usuários

- [ ] 1. Configurar schema do banco de dados e repositórios
  - Criar tabela `users` com `id`, `email`, `password_hash`, `created_at`, `updated_at`
  - Criar tabela `reset_tokens` com `id`, `user_id`, `token`, `expires_at`, `used_at`
  - Implementar `UserRepository.buscarPorEmail()` e `UserRepository.criar()`
  - Implementar `ResetTokenRepository.criar()`, `buscarPorToken()` e `marcarComoUsado()`
  - **Requisitos:** 1.1, 3.1, 3.4

- [ ] 2. Implementar endpoint de cadastro
  - `POST /auth/cadastro` — validar formato de e-mail e tamanho de senha
  - Gerar hash da senha com bcrypt (fator de custo 12)
  - Retornar 409 se o e-mail já existir
  - Retornar 201 e JWT em caso de sucesso
  - **Requisitos:** 1.1, 1.2, 1.3, 1.4

- [ ] 3. Implementar endpoint de login com proteção contra força bruta
  - `POST /auth/login` — validar credenciais contra o hash armazenado
  - Incrementar contador Redis de tentativas falhas em caso de falha
  - Bloquear conta por 15 minutos após 5 falhas consecutivas
  - Retornar mensagem genérica 401 (sem revelar o campo incorreto)
  - Zerar contador após login bem-sucedido
  - **Requisitos:** 2.1, 2.2, 2.3

- [ ] 4. Implementar fluxo de redefinição de senha
  - `POST /auth/redefinir-senha` — gerar token de redefinição, enviar e-mail via MailService
  - Retornar resposta idêntica para e-mails cadastrados e não cadastrados
  - `POST /auth/confirmar-redefinicao` — validar token, verificar expiração e `used_at`
  - Atualizar hash da senha, marcar token como usado, redirecionar para login
  - **Requisitos:** 3.1, 3.2, 3.3, 3.4

- [ ] 5. Implementar endpoint de logout
  - `POST /auth/logout` — invalidar token de sessão (adicionar à denylist ou limpar cookie)
  - Retornar 401 para requisições subsequentes usando o token antigo
  - **Requisitos:** 4.1, 4.2

- [ ] 6. Escrever testes
  - Unitários: `AuthService` — validação de credenciais, contador de bloqueio, expiração de token
  - Integração: fluxo cadastro → login → logout contra banco de teste
  - Integração: fluxo completo de redefinição de senha com MailService mock
  - E2E: caminho feliz de login via interface
  - E2E: bloqueio por força bruta (5 tentativas falhas)
  - **Requisitos:** 1.1–1.4, 2.1–2.3, 3.1–3.4, 4.1–4.2
