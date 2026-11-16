<script setup>
import { ref, watch, onMounted, onUnmounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useUserStore } from "@/stores/user.js";
import { useHomeStore } from "@/stores/home.js";
import MarketIcon from "./MarketIcon.vue";
import {
  readPreference,
  writePreference,
  rememberSearch,
} from "@/utils/preferences.js";
import { ElMessage } from "element-plus";
const router = useRouter();
const route = useRoute();
const user = useUserStore();
const home = useHomeStore();
const keyword = ref("");
const searchInput = ref();
const suggestionsOpen = ref(false);
const savedHistory = readPreference("market_search_history", []);
const history = ref(
  (Array.isArray(savedHistory) ? savedHistory : [])
    .filter((item) => typeof item === "string")
    .slice(0, 6),
);
const removedHistory = ref(null);
function clearHistory() {
  searchInput.value?.focus();
  removedHistory.value = [...history.value];
  history.value = [];
  writePreference("market_search_history", []);
}
function undoHistory() {
  searchInput.value?.focus();
  history.value = removedHistory.value;
  removedHistory.value = null;
  writePreference("market_search_history", history.value);
}
function shortcut(event) {
  const editing = event.target.closest?.(
    "input,textarea,select,[contenteditable=true]",
  );
  if (
    (event.key === "/" && !editing && !event.ctrlKey && !event.metaKey) ||
    ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k")
  ) {
    event.preventDefault();
    searchInput.value?.focus();
    suggestionsOpen.value = true;
  }
}
onMounted(() => { window.addEventListener("keydown", shortcut); home.load(); });
onUnmounted(() => window.removeEventListener("keydown", shortcut));
watch(
  () => route.query.q,
  (value) => {
    keyword.value = typeof value === "string" ? value : "";
  },
  { immediate: true },
);
function search(value = keyword.value) {
  const text = value.trim().slice(0, 100);
  keyword.value = text;
  history.value = rememberSearch(history.value, text);
  removedHistory.value = null;
  writePreference("market_search_history", history.value);
  suggestionsOpen.value = false;
  searchInput.value?.blur();
  router.push({
    path: "/",
    query: { ...(route.path === "/" ? route.query : {}), q: text || undefined },
  });
}
function logout() {
  user.logout();
  ElMessage.success("已退出登录，你仍可以浏览商品");
  router.replace("/");
}
</script>
<template>
  <header class="market-header">
    <div class="header-main">
      <RouterLink class="brand" to="/" aria-label="拾光闲置首页">
        <svg class="brand-mark" width="30" height="34" viewBox="0 0 40 40" fill="none" aria-hidden="true">
          <path d="M10 14 6 23l14 10 14-10-4-9-10 7-10-7Z" stroke="currentColor" stroke-width="2.4" stroke-linejoin="round" />
          <path d="m11 7 9 6 9-6M20 21v12" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" />
        </svg>
        <span><strong>拾光闲置<span>.</span></strong><small>让好物，继续被喜欢</small></span>
      </RouterLink>
      <div class="header-search" @focusout="(event) => { if (!event.currentTarget.contains(event.relatedTarget)) suggestionsOpen = false; }" @keydown.esc="suggestionsOpen = false">
        <form class="search-field" role="search" @submit.prevent="search()">
          <MarketIcon name="search" :size="19" />
          <input v-model="keyword" ref="searchInput" maxlength="100" autocomplete="off" @focus="suggestionsOpen = true" :aria-expanded="suggestionsOpen" aria-controls="search-suggestions" aria-label="搜索闲置商品" placeholder="搜一搜，找到你的下一件喜欢" type="search" />
          <kbd aria-hidden="true">Ctrl K</kbd>
          <button type="submit">搜索</button>
        </form>
        <div v-if="home.data?.hotSearches?.length" class="hot-searches" aria-label="热门搜索">
          <span>大家在搜</span>
          <button v-for="tag in home.data.hotSearches.slice(0, 4)" :key="tag" @click="search(tag)">{{ tag }}</button>
        </div>
        <div v-if="suggestionsOpen" id="search-suggestions" class="search-suggestions">
          <div class="suggestion-heading"><strong>最近搜索</strong><button v-if="history.length" @click="clearHistory">清空</button><button aria-label="关闭搜索建议" @click="suggestionsOpen = false"><MarketIcon name="close" :size="18" /></button></div>
          <div class="history-tags"><button v-for="item in history" :key="item" @click="search(item)">{{ item }}</button></div>
          <p v-if="!history.length">还没有搜索记录，试试“相机”或“耳机”。</p>
          <div v-if="removedHistory" class="history-undo" role="status">搜索记录已清空 <button @click="undoHistory">撤销</button></div>
          <small>Enter 搜索 · Esc 关闭</small>
        </div>
      </div>
      <nav class="user-nav" aria-label="用户导航">
        <div class="account-entry" v-if="!user.isLoggedIn"><RouterLink to="/login">登录</RouterLink><span aria-hidden="true">/</span><RouterLink to="/register">注册</RouterLink></div>
        <div class="account-entry signed-in" v-else><RouterLink to="/user/profile" aria-label="个人中心">{{ user.userInfo?.nickname || user.userInfo?.username || '个人中心' }}</RouterLink><button @click="logout">退出</button></div>
        <RouterLink class="orders-entry" to="/user/orders" aria-label="订单"><MarketIcon name="order" :size="19" /><span>订单</span></RouterLink>
        <RouterLink v-if="route.path !== '/'" class="header-publish" to="/publish" aria-label="发布闲置"><MarketIcon name="plus" :size="18" /><span>发布闲置</span></RouterLink>
      </nav>
    </div>
  </header>
</template>
<style scoped>
.market-header { background: var(--surface); }
.header-main { width: min(var(--content-width), calc(100% - var(--gutter) * 2)); margin-inline: auto; display: grid; grid-template-columns: 184px minmax(0, 1fr) auto; gap: 32px; align-items: start; padding-block: 18px 8px; }
.brand, .user-nav { min-height: 48px; }
.brand { display: inline-flex; align-items: center; gap: 10px; width: fit-content; }
.brand-mark { color: var(--accent); }
.brand strong { font-size: 23px; font-weight: 700; letter-spacing: -0.02em; line-height: 1.2; }
.brand strong span { color: var(--accent); }
.brand small { display: block; margin-top: 4px; font-size: 11px; color: var(--text-secondary); }
.header-search { position: relative; min-width: 0; }
.search-field { display: flex; align-items: center; gap: 12px; min-height: 48px; border: 1px solid var(--control-border); border-radius: 999px; padding: 4px 4px 4px 18px; background: var(--surface); color: var(--text-secondary); transition: border-color 160ms; }
.search-field:focus-within { border-color: var(--accent); outline: 1px solid var(--accent); }
.search-field input { width: 100%; min-width: 0; border: 0; outline: none; background: none; color: var(--text); height: 36px; font-size: 14px; }
.search-field input::placeholder { color: var(--text-secondary); }
.search-field kbd { flex-shrink: 0; font: inherit; font-size: 11px; color: var(--text-secondary); border: 1px solid var(--line); border-radius: 4px; padding: 1px 5px; }
.search-field > button { flex-shrink: 0; min-height: 38px; padding: 0 24px; font-size: 14px; border-radius: 999px; background: var(--primary); color: white; font-weight: 600; }
.search-field > button:hover { background: var(--accent); }
.user-nav { display: flex; align-items: center; gap: 20px; white-space: nowrap; }
.account-entry { display: flex; align-items: center; gap: 7px; font-size: 13px; }
.account-entry a, .account-entry button { display: inline-flex; align-items: center; min-height: 44px; padding: 0; }
.account-entry > span { color: var(--text-secondary); }
.signed-in > a { max-width: 84px; overflow: hidden; text-overflow: ellipsis; }
.signed-in button { font-size: 12px; color: var(--text-secondary); }
.orders-entry { display: flex; align-items: center; gap: 6px; font-size: 13px; min-height: 44px; }
.header-publish { display: flex; gap: 7px; align-items: center; min-height: 44px; padding: 0 16px; border-radius: var(--control-radius); background: var(--primary); color: white; font-size: 13px; font-weight: 550; }
.header-publish:hover { background: var(--accent); color: white; }
.hot-searches { display: flex; align-items: center; gap: 16px; padding-inline: 18px; overflow-x: auto; scrollbar-width: thin; white-space: nowrap; font-size: 13px; color: var(--text-secondary); }
.hot-searches button { flex-shrink: 0; padding: 0; min-height: 32px; }
.hot-searches button:hover { color: var(--accent); text-decoration: underline; text-underline-offset: 4px; }
.search-suggestions { position: absolute; top: 52px; left: 0; right: 0; z-index: 50; background: var(--surface); border-radius: 12px; box-shadow: 0 12px 36px #182c1f24; padding: 16px; }
.suggestion-heading { display: flex; align-items: center; gap: 16px; }
.suggestion-heading strong { margin-right: auto; font-size: 14px; }
.suggestion-heading button { display: inline-flex; align-items: center; justify-content: center; min-width: 44px; min-height: 44px; color: var(--text-secondary); font-size: 13px; }
.history-tags { display: flex; flex-wrap: wrap; gap: 8px; }
.history-tags button { min-height: 44px; max-width: 100%; overflow-wrap: anywhere; text-align: left; padding: 8px 12px; border-radius: 6px; background: var(--raised); }
.search-suggestions p, .search-suggestions small { font-size: 12px; color: var(--text-secondary); }
.history-undo button { min-height: 44px; text-decoration: underline; }
@media (max-width: 1100px) { .header-main { grid-template-columns: 172px minmax(0, 1fr) auto; gap: 20px; } .user-nav { gap: 14px; } .hot-searches { gap: 12px; } .search-field kbd { display: none; } }
@media (max-width: 800px) { .header-main { grid-template-columns: 1fr auto; gap: 8px 12px; padding-block: 10px 4px; } .header-search { grid-column: 1 / -1; grid-row: 2; } .orders-entry { justify-content: center; min-width: 32px; } .orders-entry span { display: none; } }
@media (max-width: 480px) { .brand { gap: 6px; } .brand strong { font-size: 19px; } .brand small { font-size: 10px; } .brand-mark { width: 24px; } .user-nav { gap: 6px; } .signed-in > a { max-width: 52px; } .header-publish { justify-content: center; padding-inline: 8px; } .header-publish span { display: none; } .account-entry { gap: 4px; } .hot-searches { padding-inline: 8px; font-size: 12px; } }
</style>
