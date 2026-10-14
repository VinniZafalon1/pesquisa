<script setup lang="ts">
import { onMounted, ref } from 'vue'
import type { User } from '@supabase/supabase-js'
import {
  IonApp, IonButton, IonContent, IonInput, IonItem, IonLabel, IonLoading,
  IonPage, IonText
} from '@ionic/vue'
import { supabase } from './lib/supabase'

type Profile = { full_name: string; birth_date: string; nickname: string; avatar_url: string | null }

const user = ref<User | null>(null)
const profile = ref<Profile>({ full_name: '', birth_date: '', nickname: '', avatar_url: null })
const avatarPath = ref<string | null>(null)
const email = ref('')
const password = ref('')
const mode = ref<'login' | 'signup' | 'recovery'>('login')
const recoverySession = ref(false)
const welcomeVisible = ref(false)
const newPassword = ref('')
const loading = ref(false)
const message = ref('')
const errorMessage = ref('')

function tellError(message: string) {
  errorMessage.value = message
  window.setTimeout(() => { errorMessage.value = '' }, 5000)
}

async function loadProfile() {
  if (!supabase || !user.value) return
  const { data, error } = await supabase.from('profiles')
    .select('full_name, birth_date, nickname, avatar_url')
    .eq('id', user.value.id).maybeSingle()
  if (error) return tellError(error.message)
  if (data) {
    profile.value = { ...profile.value, ...data }
    avatarPath.value = data.avatar_url
  }
  if (data?.avatar_url) {
    const { data: image } = await supabase.storage.from('avatars').createSignedUrl(data.avatar_url, 3600)
    profile.value.avatar_url = image?.signedUrl ?? null
  }
}

async function submitAuth() {
  if (!supabase) return tellError('Configure o Supabase no arquivo .env para continuar.')
  loading.value = true
  message.value = ''
  const result = mode.value === 'signup'
    ? await supabase.auth.signUp({ email: email.value, password: password.value, options: { emailRedirectTo: window.location.origin } })
    : await supabase.auth.signInWithPassword({ email: email.value, password: password.value })
  loading.value = false
  if (result.error) return tellError(result.error.message)
  if (mode.value === 'signup' && !result.data.session) {
    message.value = 'Conta criada! Confira seu e-mail para confirmar o cadastro.'
  }
}

async function recoverPassword() {
  if (!supabase) return tellError('Configure o Supabase no arquivo .env para continuar.')
  if (!email.value) return tellError('Digite seu e-mail primeiro.')
  loading.value = true
  const { error } = await supabase.auth.resetPasswordForEmail(email.value, { redirectTo: window.location.origin })
  loading.value = false
  if (error) return tellError(error.message)
  message.value = 'Se esse e-mail estiver cadastrado, você receberá um link para redefinir a senha.'
}

async function updatePassword() {
  if (!supabase) return tellError('Configure o Supabase no arquivo .env para continuar.')
  loading.value = true
  const { error } = await supabase.auth.updateUser({ password: newPassword.value })
  loading.value = false
  if (error) return tellError(error.message)
  recoverySession.value = false
  newPassword.value = ''
  message.value = 'Senha alterada. Você já pode entrar com a nova senha.'
  await logout()
  mode.value = 'login'
}

async function saveProfile() {
  if (!supabase || !user.value) return
  loading.value = true
  const { error } = await supabase.from('profiles').upsert({
    id: user.value.id,
    full_name: profile.value.full_name,
    birth_date: profile.value.birth_date || null,
    nickname: profile.value.nickname,
    avatar_url: avatarPath.value
  })
  loading.value = false
  if (error) return tellError(error.message)
  message.value = 'Perfil salvo.'
}

async function uploadPhoto(event: Event) {
  if (!supabase || !user.value) return
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return
  if (!file.type.startsWith('image/')) return tellError('Escolha uma imagem.')
  loading.value = true
  const path = `${user.value.id}/avatar-${Date.now()}.${file.name.split('.').pop() || 'jpg'}`
  const { error } = await supabase.storage.from('avatars').upload(path, file, { upsert: true, contentType: file.type })
  loading.value = false
  if (error) return tellError(error.message)
  avatarPath.value = path
  await saveProfile()
  const { data } = await supabase.storage.from('avatars').createSignedUrl(path, 3600)
  if (data) profile.value.avatar_url = data.signedUrl
}

async function logout() {
  if (supabase) await supabase.auth.signOut()
}

onMounted(() => {
  if (!supabase) return
  supabase.auth.getSession().then(({ data }) => { user.value = data.session?.user ?? null; void loadProfile() })
  supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'PASSWORD_RECOVERY') recoverySession.value = true
    if (event === 'SIGNED_IN') welcomeVisible.value = true
    user.value = session?.user ?? null
    if (user.value) window.setTimeout(() => { void loadProfile() }, 0)
    else {
      welcomeVisible.value = false
      avatarPath.value = null
      profile.value = { full_name: '', birth_date: '', nickname: '', avatar_url: null }
    }
  })
})
</script>

<template>
  <IonApp>
    <IonPage>
      <IonContent :fullscreen="true">
        <main class="container">
          <section v-if="recoverySession" class="card">
            <h1>Nova senha</h1>
            <p class="muted">Escolha uma senha nova para sua conta.</p>
            <form @submit.prevent="updatePassword()">
              <IonItem><IonLabel position="stacked">Nova senha</IonLabel><IonInput v-model="newPassword" type="password" required :minlength="6" autocomplete="new-password" /></IonItem>
              <IonButton expand="block" type="submit" class="main-button">Salvar nova senha</IonButton>
            </form>
            <IonText v-if="errorMessage" color="danger"><p>{{ errorMessage }}</p></IonText>
          </section>

          <section v-else-if="!user" class="card">
            <h1>{{ mode === 'signup' ? 'Criar conta' : mode === 'recovery' ? 'Recuperar senha' : 'Entrar' }}</h1>
            <p class="muted">Que bom ter você por aqui.</p>
            <form @submit.prevent="mode === 'recovery' ? recoverPassword() : submitAuth()">
              <IonItem><IonLabel position="stacked">E-mail</IonLabel><IonInput v-model="email" type="email" required autocomplete="email" /></IonItem>
              <IonItem v-if="mode !== 'recovery'"><IonLabel position="stacked">Senha</IonLabel><IonInput v-model="password" type="password" required :minlength="6" autocomplete="current-password" /></IonItem>
              <IonButton expand="block" type="submit" class="main-button">{{ mode === 'signup' ? 'Criar conta' : mode === 'recovery' ? 'Enviar link' : 'Entrar' }}</IonButton>
            </form>
            <div class="links">
              <button v-if="mode !== 'login'" @click="mode = 'login'">Voltar para entrar</button>
              <template v-else><button @click="mode = 'recovery'">Esqueci minha senha</button><button @click="mode = 'signup'">Criar uma conta</button></template>
            </div>
            <IonText v-if="message" color="success"><p>{{ message }}</p></IonText>
            <IonText v-if="errorMessage" color="danger"><p>{{ errorMessage }}</p></IonText>
          </section>

          <section v-else-if="welcomeVisible" class="card welcome-card">
            <h1>Seja bem-vindo!</h1>
            <p class="muted">Que bom ter você aqui, {{ profile.nickname || profile.full_name || user.email }}.</p>
            <IonButton expand="block" class="main-button" @click="welcomeVisible = false">Ir para meu perfil</IonButton>
          </section>

          <section v-else class="card">
            <h1>Oi, {{ profile.nickname || profile.full_name || user.email }}!</h1>
            <p class="muted">Que bom ter você de volta. Aqui você pode cuidar do seu perfil.</p>
            <div class="avatar-area">
              <img v-if="profile.avatar_url" :src="profile.avatar_url" alt="Foto do perfil" class="avatar" />
              <div v-else class="avatar placeholder">Sua foto</div>
              <label class="photo-button">Escolher foto<input type="file" accept="image/*" @change="uploadPhoto" /></label>
            </div>
            <form @submit.prevent="saveProfile()">
              <IonItem><IonLabel position="stacked">Nome</IonLabel><IonInput v-model="profile.full_name" autocomplete="name" /></IonItem>
              <IonItem><IonLabel position="stacked">Data de nascimento</IonLabel><IonInput v-model="profile.birth_date" type="date" /></IonItem>
              <IonItem><IonLabel position="stacked">Apelido</IonLabel><IonInput v-model="profile.nickname" /></IonItem>
              <IonButton expand="block" type="submit" class="main-button">Salvar perfil</IonButton>
            </form>
            <IonText v-if="message" color="success"><p>{{ message }}</p></IonText>
            <IonText v-if="errorMessage" color="danger"><p>{{ errorMessage }}</p></IonText>
            <button class="logout" @click="logout">Sair da conta</button>
          </section>
        </main>
        <IonLoading :is-open="loading" message="Só um instante..." />
      </IonContent>
    </IonPage>
  </IonApp>
</template>
