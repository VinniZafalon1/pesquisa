# Meu Perfil

Aplicativo simples feito com Ionic, Vue 3, TypeScript, Capacitor e Supabase.

## Preparar o Supabase

1. Crie um projeto no [Supabase](https://supabase.com/dashboard).
2. Em **Project Settings > API**, copie a Project URL e a chave pública (publishable/anon).
3. Copie `.env.example` para `.env` e preencha `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY`.
4. No **SQL Editor**, execute todo o conteúdo de `supabase/schema.sql`. Isso cria a tabela de perfis, o bucket privado de fotos e as regras para cada usuário acessar apenas os próprios dados.
5. Em **Authentication > URL Configuration**, adicione `http://localhost:5173` aos Redirect URLs.
6. Se a confirmação de e-mail estiver ativada, confirme o cadastro pelo link recebido.

## Rodar o aplicativo

```sh
npm install
npm run dev
```

Para gerar a versão web: `npm run build`. Para preparar Android: `npx cap add android` e depois `npx cap sync android`.

## Checklist de requisitos

- [x] Ionic Framework com Vue.js e TypeScript.
- [x] Capacitor configurado para gerar aplicativo móvel.
- [x] Supabase Auth: criar conta, entrar e solicitar recuperação de senha.
- [x] Supabase Database: salvar nome, data de nascimento e apelido.
- [x] Supabase Storage: enviar e exibir foto do perfil com acesso privado.
- [x] Tela de boas-vindas após o login.
- [x] CSS básico e layout responsivo.
- [x] Compilação web verificada com `npm run build`.
- [ ] Configurar as chaves do seu projeto Supabase em `.env`.
- [ ] Executar `supabase/schema.sql` no SQL Editor do seu projeto.
- [ ] Confirmar o cadastro pelo e-mail, se a confirmação estiver ativada.
