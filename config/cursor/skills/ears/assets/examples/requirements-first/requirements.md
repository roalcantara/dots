# Requisitos: Autenticação de Usuários

## Visão Geral

Permitir que usuários se cadastrem, façam login, redefinam senhas esquecidas
e se desconectem com segurança. O sistema deve prevenir ataques de força bruta
e validar o formato do e-mail antes da criação da conta.

## Requisitos

### 1. Cadastro de Usuário

**História:** Como novo usuário, quero criar uma conta com meu e-mail e senha,
para que eu possa acessar a plataforma.

#### Critérios de Aceitação

1. QUANDO o usuário enviar um e-mail e senha válidos
   O SISTEMA DEVE criar uma nova conta e redirecionar para o painel principal.

2. QUANDO o usuário enviar um e-mail já cadastrado
   O SISTEMA DEVE exibir "E-mail já cadastrado" e não criar uma conta duplicada.

3. QUANDO o usuário enviar um e-mail com formato inválido
   O SISTEMA DEVE exibir um erro de validação inline antes do envio do formulário.

4. QUANDO o usuário enviar uma senha com menos de 8 caracteres
   O SISTEMA DEVE exibir "A senha deve ter pelo menos 8 caracteres."

---

### 2. Login

**História:** Como usuário cadastrado, quero fazer login com minhas credenciais,
para que eu possa acessar minha conta.

#### Critérios de Aceitação

1. QUANDO o usuário enviar credenciais válidas
   O SISTEMA DEVE criar uma sessão autenticada e redirecionar para o painel principal.

2. SE o usuário enviar credenciais inválidas 5 vezes consecutivas
   ENTÃO O SISTEMA DEVE bloquear a conta por 15 minutos e exibir
   "Muitas tentativas falhas. Tente novamente em 15 minutos."

3. QUANDO o usuário enviar credenciais inválidas (abaixo do limite de bloqueio)
   O SISTEMA DEVE exibir "E-mail ou senha inválidos" sem revelar qual campo
   está incorreto.

---

### 3. Redefinição de Senha

**História:** Como usuário que esqueceu minha senha, quero redefini-la por
e-mail, para que eu possa recuperar o acesso à minha conta.

#### Critérios de Aceitação

1. QUANDO o usuário solicitar redefinição de senha para um e-mail cadastrado
   O SISTEMA DEVE enviar um link de redefinição válido por 1 hora para esse endereço.

2. QUANDO o usuário solicitar redefinição de senha para um e-mail não cadastrado
   O SISTEMA DEVE exibir a mesma mensagem de confirmação de um e-mail cadastrado
   (para evitar enumeração de contas).

3. QUANDO o usuário clicar em um link de redefinição expirado ou já utilizado
   O SISTEMA DEVE exibir "Este link expirou. Solicite um novo."

4. QUANDO o usuário enviar uma nova senha via link de redefinição válido
   O SISTEMA DEVE atualizar a senha, invalidar o token de redefinição e
   redirecionar para a página de login.

---

### 4. Logout

**História:** Como usuário autenticado, quero me desconectar, para que minha
sessão seja encerrada neste dispositivo.

#### Critérios de Aceitação

1. QUANDO o usuário clicar em "Sair"
   O SISTEMA DEVE invalidar o token de sessão e redirecionar para a página
   de login.

2. ENQUANTO uma sessão estiver invalidada
   O SISTEMA DEVE rejeitar qualquer requisição subsequente usando o token
   antigo com resposta 401.
