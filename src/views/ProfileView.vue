<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref } from 'vue'
import { getProfileApi, updateProfileApi, uploadAvatarApi } from '@/api/user.js'
import MarketIcon from '@/components/MarketIcon.vue'
import ProfileGoodsGrid from '@/components/ProfileGoodsGrid.vue'
import { goods } from '@/data/market.js'
import { useUserStore } from '@/stores/user.js'
import { DEMO_FAVORITES_KEY, readPreference } from '@/utils/preferences.js'

const tradeLinks = [
  { id: 'published', label: '我发布的' },
  { id: 'sell', label: '我卖出的' },
  { id: 'buy', label: '我买到的' },
]
const settingsLinks = [
  { id: 'profile', label: '个人资料' },
  { id: 'security', label: '账号与安全' },
]
const sectionNames = {
  home: '我的拾光',
  favorites: '我的收藏',
  ...Object.fromEntries([...tradeLinks, ...settingsLinks].map(({ id, label }) => [id, label])),
}
const sampleGoods = goods.filter(({ id }) => id === 4 || id === 7)
  .map((item) => ({ ...item, status: item.id === 7 ? 'SOLD' : 'ON_SALE' }))
const sampleReviews = [{ id: 'example', author: '示例买家', rating: '好评', comment: '台灯和描述一样，包装仔细，收到就能用。' }]
const homeTabs = [
  { id: 'goods', label: '宝贝', count: sampleGoods.length },
  { id: 'reviews', label: '信用及评价', count: sampleReviews.length },
]

const user = useUserStore()
const profile = ref(null)
const section = ref('home')
const homeTab = ref('goods')
const menuOpen = ref(false)
const tradesOpen = ref(true)
const settingsOpen = ref(true)
const content = ref(null)
const favorites = ref([])
const nickname = ref('')
const file = ref(null)
const preview = ref('')
const removeAvatar = ref(false)
const loading = ref(true)
const saving = ref(false)
const loadError = ref('')
const formError = ref('')
const message = ref('')
const failedAvatar = ref('')

const displayName = computed(() => profile.value?.nickname || profile.value?.username || '我的拾光')
const avatarUrl = computed(() => profile.value?.avatarUrl || '')
const editedAvatar = computed(() => preview.value || (!removeAvatar.value && avatarUrl.value) || '')

async function showSection(id) {
  const focusContent = id !== section.value || menuOpen.value
  menuOpen.value = false
  if (!focusContent) return
  section.value = id
  message.value = ''
  if (id === 'profile') settingsOpen.value = true
  if (id === 'favorites') {
    const ids = readPreference(DEMO_FAVORITES_KEY, [])
    favorites.value = Array.isArray(ids)
      ? goods.filter(({ id: goodsId }) => ids.includes(String(goodsId)))
      : []
  }
  await nextTick()
  content.value?.querySelector('h1')?.focus()
}

function moveTab(event) {
  const tabs = Array.from(event.currentTarget.querySelectorAll('[role="tab"]'))
  const index = tabs.indexOf(event.target)
  const directions = {
    ArrowLeft: (index + tabs.length - 1) % tabs.length,
    ArrowRight: (index + 1) % tabs.length,
    Home: 0,
    End: tabs.length - 1,
  }
  if (index === -1 || !Object.hasOwn(directions, event.key)) return
  event.preventDefault()
  const next = directions[event.key]
  homeTab.value = homeTabs[next].id
  tabs[next].focus()
}

function clearPreview() {
  if (preview.value) URL.revokeObjectURL(preview.value)
  preview.value = ''
}
onUnmounted(clearPreview)

async function load() {
  loading.value = true
  loadError.value = ''
  const token = user.token
  try {
    const info = await getProfileApi()
    if (user.token !== token) return
    profile.value = info
    nickname.value = info.nickname || ''
    user.setUserInfo(info)
  } catch (e) { loadError.value = e.message }
  finally { loading.value = false }
}
onMounted(load)

function selectAvatar(event) {
  const selected = event.target.files?.[0]
  event.target.value = ''
  if (!selected) return
  if (!['image/png', 'image/jpeg'].includes(selected.type) || selected.size > 512 * 1024) {
    formError.value = '请选择 512KB 以内的 PNG 或 JPEG 图片。'
    return
  }
  clearPreview()
  file.value = selected
  preview.value = URL.createObjectURL(selected)
  removeAvatar.value = false
  formError.value = ''
}
function clearAvatar() {
  clearPreview()
  file.value = null
  removeAvatar.value = true
  formError.value = ''
}
async function save() {
  if (saving.value) return
  const name = nickname.value.trim()
  if (!name || name.length > 32) {
    formError.value = '昵称须为 1～32 位非空字符。'
    return
  }
  saving.value = true
  formError.value = ''
  const token = user.token
  try {
    const changes = { nickname: name }
    if (file.value) changes.avatarFileId = (await uploadAvatarApi(file.value)).avatarFileId
    else if (removeAvatar.value) changes.avatarFileId = null
    if (user.token !== token) return
    const info = await updateProfileApi(changes)
    if (user.token !== token) return
    profile.value = info
    nickname.value = info.nickname || ''
    user.setUserInfo(info)
    file.value = null
    clearPreview()
    removeAvatar.value = false
    failedAvatar.value = ''
    await showSection('home')
    message.value = '资料已保存。'
  } catch (e) { formError.value = e.message }
  finally { saving.value = false }
}
</script>

<template>
  <div class="profile-center">
    <div class="profile-sidebar">
      <button class="mobile-menu" type="button" :aria-expanded="menuOpen" aria-controls="profile-navigation" @click="menuOpen = !menuOpen">
        <MarketIcon name="user" :size="18" />
        {{ sectionNames[section] }}
        <MarketIcon class="menu-chevron" name="chevron" :size="15" />
      </button>
      <nav id="profile-navigation" class="profile-nav" :class="{ 'is-open': menuOpen }" aria-label="个人中心">
        <button class="menu-item" type="button" :aria-current="section === 'home' ? 'page' : undefined" :disabled="saving" @click="showSection('home')">
          <MarketIcon name="user" :size="18" /> 我的拾光
        </button>
        <button class="menu-item" type="button" :aria-expanded="tradesOpen" aria-controls="profile-trades" @click="tradesOpen = !tradesOpen">
          <MarketIcon name="bag" :size="18" /> 我的交易
          <MarketIcon class="menu-chevron" name="chevron" :size="15" />
        </button>
        <div v-show="tradesOpen" id="profile-trades" class="menu-group">
          <button v-for="item in tradeLinks" :key="item.id" class="menu-item menu-child" type="button" :aria-current="section === item.id ? 'page' : undefined" :disabled="saving" @click="showSection(item.id)">
            {{ item.label }}
          </button>
        </div>
        <button class="menu-item" type="button" :aria-current="section === 'favorites' ? 'page' : undefined" :disabled="saving" @click="showSection('favorites')">
          <MarketIcon name="star" :size="18" /> 我的收藏
        </button>
        <button class="menu-item" type="button" :aria-expanded="settingsOpen" aria-controls="profile-settings" @click="settingsOpen = !settingsOpen">
          <MarketIcon name="settings" :size="18" /> 账户设置
          <MarketIcon class="menu-chevron" name="chevron" :size="15" />
        </button>
        <div v-show="settingsOpen" id="profile-settings" class="menu-group">
          <button v-for="item in settingsLinks" :key="item.id" class="menu-item menu-child" type="button" :aria-current="section === item.id ? 'page' : undefined" :disabled="saving" @click="showSection(item.id)">
            {{ item.label }}
          </button>
        </div>
      </nav>
    </div>

    <section ref="content" class="profile-content" aria-labelledby="profile-title">
      <template v-if="section === 'home' && profile">
        <header class="profile-banner">
          <svg class="banner-pattern" viewBox="0 0 326 174" fill="none" aria-hidden="true">
            <path d="M78 174c35-42 76-83 145-103 33-10 70-14 103-12M122 174c31-33 67-62 111-77 31-11 64-16 93-16M166 174c33-31 76-56 160-65" stroke="currentColor" />
            <path d="m232 11 39 19 17 35-47 35-37-47 14-32zM256 32l-14 10 10 14 14-10z" stroke="currentColor" stroke-width="1.5" />
            <path d="M291 18v16m-8-8h16M197 71v12m-6-6h12" stroke="currentColor" stroke-linecap="round" />
          </svg>
          <div class="profile-identity">
            <img v-if="avatarUrl && failedAvatar !== avatarUrl" class="avatar banner-avatar" :src="avatarUrl" alt="" @error="failedAvatar = avatarUrl" />
            <span v-else class="avatar banner-avatar avatar-fallback" aria-hidden="true">{{ Array.from(displayName)[0] }}</span>
            <div class="profile-identity-copy">
              <div class="profile-name">
                <h1 id="profile-title" tabindex="-1">{{ displayName }}</h1>
                <span class="credit-badge"><MarketIcon name="shield" :size="13" /> 信用待开放</span>
              </div>
              <p class="profile-meta"><span>拾光号 {{ profile.username }}</span><span>关注数据待开放</span></p>
            </div>
          </div>
          <button class="profile-pill" type="button" @click="showSection('profile')">编辑资料</button>
        </header>

        <p v-if="message" class="profile-saved" role="status">{{ message }}</p>
        <div class="home-tabs" role="tablist" aria-label="个人主页内容" @keydown="moveTab">
          <button v-for="tab in homeTabs" :id="`profile-tab-${tab.id}`" :key="tab.id" type="button" role="tab" :aria-selected="homeTab === tab.id" :aria-controls="`profile-panel-${tab.id}`" :tabindex="homeTab === tab.id ? 0 : -1" @click="homeTab = tab.id">
            {{ tab.label }}<sup :aria-label="`${tab.count} 条示例`">{{ tab.count }}</sup>
          </button>
        </div>
        <div v-show="homeTab === 'goods'" id="profile-panel-goods" class="home-panel" role="tabpanel" aria-labelledby="profile-tab-goods" tabindex="0">
          <p class="sample-note"><strong>商品展示示例</strong><span>个人宝贝列表待开放</span></p>
          <ProfileGoodsGrid :items="sampleGoods" />
        </div>
        <div v-show="homeTab === 'reviews'" id="profile-panel-reviews" class="home-panel" role="tabpanel" aria-labelledby="profile-tab-reviews" tabindex="0">
          <p class="sample-note"><strong>评价展示示例</strong><span>真实信用与评价待开放</span></p>
          <ul class="review-list">
            <li v-for="review in sampleReviews" :key="review.id">
              <div class="review-heading"><strong>{{ review.author }}</strong><span>{{ review.rating }}</span></div>
              <p>{{ review.comment }}</p>
            </li>
          </ul>
        </div>
      </template>

      <div v-else class="section-body">
        <button v-if="section === 'profile'" class="back-link" type="button" :disabled="saving" @click="showSection('home')">
          <MarketIcon name="arrow" :size="16" /> 返回个人主页
        </button>
        <h1 id="profile-title" tabindex="-1">{{ sectionNames[section] }}</h1>

        <template v-if="['home', 'profile', 'security'].includes(section) && !profile">
          <p v-if="loading" role="status">正在加载资料…</p>
          <div v-else class="error-panel" role="alert">
            <p>{{ loadError || '资料加载失败，请重试。' }}</p>
            <button type="button" @click="load">重新加载</button>
          </div>
        </template>

        <form v-else-if="section === 'profile'" @submit.prevent="save">
          <p class="section-intro">头像和昵称会显示在你的拾光主页。</p>
          <div class="profile-row">
            <div><h2>头像</h2><p id="avatar-hint">PNG 或 JPEG，最大 512KB。</p></div>
            <div class="avatar-actions">
              <img v-if="editedAvatar && failedAvatar !== editedAvatar" class="avatar form-avatar" :src="editedAvatar" alt="头像预览" @error="failedAvatar = editedAvatar" />
              <span v-else class="avatar form-avatar avatar-fallback" aria-hidden="true">{{ Array.from(nickname.trim() || profile.username)[0] }}</span>
              <div class="avatar-buttons">
                <label class="file-label">选择图片<input type="file" accept="image/png,image/jpeg" aria-describedby="avatar-hint" :disabled="saving" @change="selectAvatar" /></label>
                <button v-if="editedAvatar" class="remove-avatar" type="button" :disabled="saving" @click="clearAvatar">移除头像</button>
              </div>
            </div>
          </div>
          <div class="profile-row"><div><h2>账号</h2><p>用于登录，暂不可修改。</p></div><p class="account-name">{{ profile.username }}</p></div>
          <div class="profile-row">
            <div><label for="nickname">昵称</label><p id="nickname-hint">其他用户看到的名字，1～32 个字符。</p></div>
            <input id="nickname" v-model="nickname" maxlength="32" required :disabled="saving" aria-describedby="nickname-hint" />
          </div>
          <p v-if="formError" class="error-panel" role="alert">{{ formError }}</p>
          <div class="form-actions"><button class="profile-pill" type="submit" :disabled="saving">{{ saving ? '保存中…' : '保存资料' }}</button></div>
        </form>

        <template v-else-if="section === 'favorites'">
          <p class="section-intro">这里显示当前浏览器收藏的示例商品。</p>
          <ProfileGoodsGrid v-if="favorites.length" :items="favorites" link-to-goods />
          <div v-else class="section-state">
            <h2>本机还没有收藏</h2>
            <p>在商品详情页点击收藏，就能从这里找回。</p>
            <RouterLink class="text-link" to="/">去逛集市</RouterLink>
          </div>
        </template>

        <div v-else-if="section === 'published'" class="section-state">
          <h2>发布记录待开放</h2>
          <p>可以先在发布页准备本机草稿。</p>
          <RouterLink class="text-link" to="/publish">前往发布页</RouterLink>
        </div>

        <div v-else-if="section === 'security'" class="section-state">
          <h2>登录账号</h2>
          <p class="account-name">{{ profile.username }}</p>
          <p>密码与其他安全设置待开放。</p>
        </div>

        <div v-else class="section-state">
          <h2>订单服务待开放</h2>
          <p>服务开放后，这里会显示{{ section === 'sell' ? '卖出' : '买入' }}记录。</p>
          <RouterLink class="text-link" :to="{ name: 'orders', query: { role: section } }">前往订单页</RouterLink>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
:global(body:has(.profile-center)) { background: #f5f6f8; }
:global(.page:has(> .profile-center)) { width: 100%; }
.profile-center {
  display: grid;
  grid-template-columns: 220px minmax(0, 1fr);
  align-items: start;
  gap: 20px;
  max-width: 1200px;
  margin: 20px auto;
  padding-inline: 24px;
}
.profile-sidebar, .profile-content { border-radius: 16px; background: var(--surface); }
.profile-sidebar { padding: 16px 12px; }
.profile-nav, .menu-group { display: grid; gap: 2px; }
.menu-item, .mobile-menu {
  display: flex;
  width: 100%;
  min-height: 44px;
  align-items: center;
  gap: 10px;
  padding: 6px 10px;
  border-radius: 10px;
  text-align: left;
}
.menu-item:hover, .menu-item[aria-current='page'] { background: #f4f5f7; }
.menu-item[aria-current='page'] { color: #1f2329; font-weight: 600; }
.menu-child { padding-left: 36px; color: #555; }
.menu-chevron { margin-left: auto; transform: rotate(90deg); }
[aria-expanded='true'] > .menu-chevron { transform: rotate(-90deg); }
.mobile-menu { display: none; }
.profile-content { --profile-inset: 36px; min-height: 620px; overflow: hidden; }
.profile-content h1:focus { outline: none; }
.profile-banner {
  position: relative;
  isolation: isolate;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  padding: 32px var(--profile-inset);
  border-bottom: 1px solid #f2f3f5;
  background: linear-gradient(105deg, #fff 45%, #f3f8f5 75%, #fef9ec); /* taste-skill-ignore: brief specifies a light name-card gradient */
}
.banner-pattern {
  position: absolute;
  right: 0;
  bottom: 0;
  z-index: -1;
  width: min(42%, 326px);
  height: 100%;
  color: #819680;
  opacity: .28;
  pointer-events: none;
}
.profile-identity, .profile-name, .profile-meta { display: flex; align-items: center; }
.profile-identity { gap: 20px; min-width: 0; }
.profile-identity-copy { min-width: 0; }
.avatar { flex: none; border-radius: 50%; object-fit: cover; }
.banner-avatar { width: 84px; height: 84px; border: 3px solid #fff; box-shadow: 0 2px 8px #22352a16; } /* taste-skill-ignore: brief specifies a subtle avatar shadow */
.form-avatar { width: 72px; height: 72px; }
.avatar-fallback { display: grid; place-items: center; background: var(--active); color: var(--accent); font-size: 28px; font-weight: 600; }
.profile-name { flex-wrap: wrap; gap: 4px 10px; }
.profile-name h1 { margin: 0; color: #1f2329; font-size: 22px; font-weight: 700; overflow-wrap: anywhere; }
.credit-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  border-radius: 6px;
  background: #edf3e8;
  color: #385242;
  font-size: 12px;
  font-weight: 600;
}
.profile-meta { flex-wrap: wrap; gap: 3px 12px; margin: 8px 0 0; color: #62686a; font-size: 13px; }
.profile-meta span { min-width: 0; overflow-wrap: anywhere; }
.profile-meta span + span { padding-left: 12px; border-left: 1px solid #c9cecb; }
.profile-pill {
  flex: none;
  min-height: 44px;
  padding: 10px 22px;
  border-radius: 999px;
  background: #222;
  color: #fff;
  font-weight: 600;
  white-space: nowrap;
}
.profile-pill:hover { background: #33483c; }
.profile-pill:disabled { opacity: .62; }
.home-tabs { display: flex; gap: 32px; padding: 16px var(--profile-inset) 0; border-bottom: 1px solid #f2f3f5; }
.home-tabs button { position: relative; min-height: 48px; padding: 0 0 4px; color: var(--text-secondary); font-size: 16px; }
.home-tabs button:hover { color: var(--text); }
.home-tabs button[aria-selected='true'] { color: #1f2329; font-size: 18px; font-weight: 700; }
.home-tabs button[aria-selected='true']::after {
  position: absolute;
  inset: auto auto 0 50%;
  width: 24px;
  height: 4px;
  transform: translateX(-50%);
  border-radius: 2px;
  background: #1b3b2b;
  content: '';
}
.home-tabs sup { margin-left: 4px; color: var(--text-secondary); font-size: 12px; font-weight: 600; }
.home-panel { padding: 20px var(--profile-inset) var(--profile-inset); }
.home-panel:focus-visible { outline: 2px solid var(--accent); outline-offset: -4px; }
.sample-note { display: flex; flex-wrap: wrap; gap: 4px 12px; align-items: baseline; margin: 0 0 16px; color: var(--text-secondary); font-size: 13px; }
.sample-note strong { color: var(--text); font-weight: 600; }
.review-list { margin: 0; padding: 0; list-style: none; }
.review-list li { padding: 16px 0; border-top: 1px solid var(--line); }
.review-list p { margin: 8px 0 0; }
.review-heading { display: flex; align-items: baseline; gap: 12px; }
.review-heading span { color: var(--accent); font-size: 13px; }
.profile-saved { margin: 12px var(--profile-inset) 0; color: var(--accent); }
.section-body { padding: 28px var(--profile-inset) var(--profile-inset); }
.section-body h1 { margin-bottom: 8px; font-size: 24px; }
.section-body .back-link { margin: -6px 0 10px; padding: 0; }
.section-body .back-link svg { transform: rotate(180deg); }
.section-intro, .section-state p { margin: 0 0 20px; color: var(--text-secondary); }
.section-state { margin-top: 20px; padding: 22px 0 0; border-top: 1px solid var(--line); }
.section-state h2 { margin: 0 0 8px; font-size: 17px; }
.section-state p { margin-bottom: 6px; }
.profile-row {
  display: grid;
  grid-template-columns: minmax(160px, 220px) minmax(0, 1fr);
  align-items: start;
  gap: 20px;
  padding: 22px 0;
  border-top: 1px solid var(--line);
}
.profile-row h2, .profile-row label[for] { margin: 0; font-size: 16px; font-weight: 600; }
.profile-row p { margin: 4px 0 0; color: var(--text-secondary); font-size: 13px; }
.profile-content .account-name { color: var(--text); font-size: 14px; }
.avatar-actions, .avatar-buttons { display: flex; align-items: center; flex-wrap: wrap; gap: 4px 16px; }
.file-label, .remove-avatar { display: inline-flex; align-items: center; min-height: 44px; padding: 0; }
.file-label { color: var(--accent); text-decoration: underline; text-underline-offset: 3px; cursor: pointer; }
.file-label input { position: absolute; width: 1px; height: 1px; opacity: 0; }
.file-label:focus-within { outline: 2px solid var(--accent); outline-offset: 4px; }
.file-label:has(input:disabled) { opacity: .62; cursor: not-allowed; }
.remove-avatar { color: var(--text-secondary); }
.remove-avatar:hover { text-decoration: underline; text-underline-offset: 3px; }
#nickname { width: 100%; max-width: 360px; min-height: 44px; border: 1px solid var(--control-border); border-radius: var(--control-radius); padding: 8px 12px; }
.form-actions { border-top: 1px solid var(--line); padding-top: 20px; }

@media (max-width: 960px) {
  .profile-center { grid-template-columns: 184px minmax(0, 1fr); }
  .profile-content { --profile-inset: 24px; }
}
@media (max-width: 700px) {
  .profile-center { grid-template-columns: minmax(0, 1fr); gap: 12px; margin-block: 16px; padding-inline: 16px; }
  .profile-sidebar { padding: 4px 8px; }
  .mobile-menu { display: flex; font-weight: 600; }
  .profile-nav { display: none; padding: 4px 0 8px; border-top: 1px solid var(--line); }
  .profile-nav.is-open { display: grid; }
  .profile-content { --profile-inset: 20px; min-height: 420px; }
}
@media (max-width: 500px) {
  .profile-content { --profile-inset: 16px; }
  .profile-banner { align-items: flex-start; flex-direction: column; gap: 14px; padding-block: 22px; }
  .profile-identity { gap: 12px; }
  .banner-avatar { width: 64px; height: 64px; }
  .banner-pattern { width: 56%; }
  .home-tabs { gap: 24px; padding-top: 8px; }
  .profile-row { grid-template-columns: 1fr; gap: 12px; padding-block: 16px; }
}
@media (max-width: 360px) {
  .profile-meta { align-items: flex-start; flex-direction: column; }
  .profile-meta span + span { padding-left: 0; border-left: 0; }
}
</style>
