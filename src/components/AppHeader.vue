<script setup>
import { ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useUserStore } from "@/stores/user.js";
import { hotSearches } from "@/data/market.js";
import MarketIcon from "./MarketIcon.vue";
const router = useRouter();
const route = useRoute();
const user = useUserStore();
const keyword = ref("");
watch(
  () => route.query.q,
  (value) => {
    keyword.value = typeof value === "string" ? value : "";
  },
  { immediate: true },
);
function search(value = keyword.value) {
  router.push({ path: "/", query: value.trim() ? { q: value.trim() } : {} });
}
function logout() {
  user.logout();
  router.replace("/");
}
</script>
<template>
  <header class="market-header">
    <div class="header-top">
      <div class="header-top-inner">
        <span>少一点闲置，多一点喜欢。</span
        ><span>PRE-LOVED THINGS. NEW POSSIBILITIES.</span>
      </div>
    </div>
    <div class="header-main">
      <RouterLink class="brand" to="/" aria-label="拾光闲置首页"
        ><span class="brand-mark"
          ><svg
            width="29"
            height="29"
            viewBox="0 0 40 40"
            fill="none"
            aria-hidden="true"
          >
            <path
              d="M10 14 6 23l14 10 14-10-4-9-10 7-10-7Z"
              stroke="currentColor"
              stroke-width="2.4"
              stroke-linejoin="round"
            />
            <path
              d="m11 7 9 6 9-6M20 21v12"
              stroke="currentColor"
              stroke-width="2.4"
              stroke-linecap="round"
            /></svg></span
        ><span
          ><strong>拾光闲置<span>.</span></strong
          ><small>SHIGUANG MARKET</small></span
        ></RouterLink
      >
      <div class="header-search">
        <form class="search-capsule" role="search" @submit.prevent="search()">
          <MarketIcon name="search" :size="18" /><input
            v-model="keyword"
            aria-label="搜索闲置商品"
            placeholder="寻找下一件，属于你的好物"
            type="search"
          /><button type="submit">
            搜索 <MarketIcon name="arrow" :size="15" />
          </button>
        </form>
        <div class="hot-searches">
          <span>灵感热搜</span
          ><button v-for="tag in hotSearches" :key="tag" @click="search(tag)">
            {{ tag }}
          </button>
        </div>
      </div>
      <nav class="user-nav" aria-label="用户导航">
        <div class="account-entry">
          <span class="avatar-placeholder"
            ><MarketIcon name="user" :size="19"
          /></span>
          <div v-if="!user.isLoggedIn">
            <RouterLink to="/login">登录</RouterLink
            ><span class="divider">/</span
            ><RouterLink to="/register">注册</RouterLink
            ><small>你的好物，从这里开始</small>
          </div>
          <div v-else>
            <span>{{
              user.userInfo?.nickname || user.userInfo?.username || "拾光用户"
            }}</span
            ><button class="logout-link" @click="logout">退出登录</button>
          </div>
        </div>
        <RouterLink class="orders-entry" to="/user/orders"
          ><MarketIcon name="order" :size="20" /><span
            >我的订单</span
          ></RouterLink
        >
      </nav>
    </div>
    <div class="header-navigation">
      <nav aria-label="集市导航">
        <RouterLink
          to="/"
          :class="{ current: route.path === '/' && !route.query.category }"
          >发现好物</RouterLink
        ><RouterLink
          to="/?category=digital"
          :class="{ current: route.query.category === 'digital' }"
          >数码灵感</RouterLink
        ><RouterLink
          to="/?category=fashion"
          :class="{ current: route.query.category === 'fashion' }"
          >衣橱新生</RouterLink
        ><RouterLink
          to="/?category=home"
          :class="{ current: route.query.category === 'home' }"
          >生活美学</RouterLink
        ><RouterLink
          to="/?category=toys"
          :class="{ current: route.query.category === 'toys' }"
          >热爱收藏</RouterLink
        >
      </nav>
      <RouterLink class="header-publish" to="/publish"
        ><MarketIcon name="plus" :size="15" />发布闲置</RouterLink
      >
    </div>
  </header>
</template>
<style scoped>
.market-header {
  background: #fffefa;
  border-bottom: 1px solid var(--line);
}
.header-top {
  background: #eeeee8;
  color: #85877d;
  font-size: 9px;
}
.header-top-inner {
  max-width: 1200px;
  margin: auto;
  min-height: 30px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.header-top-inner > span:last-child {
  font-size: 8px;
  letter-spacing: 1.7px;
}
.header-main {
  max-width: 1200px;
  margin: auto;
  display: grid;
  grid-template-columns: 225px minmax(0, 1fr) 255px;
  gap: 34px;
  align-items: center;
  min-height: 108px;
}
.brand {
  display: flex;
  align-items: center;
  gap: 11px;
}
.brand-mark {
  display: grid;
  place-items: center;
  width: 42px;
  height: 45px;
  border-radius: 12px;
  color: var(--accent);
  border: 1px solid #de9b8538;
  background: #f7ebe4;
}
.brand strong {
  font-size: 24px;
  font-weight: 650;
  letter-spacing: -1px;
  color: #323b2f;
}
.brand strong span {
  color: var(--accent);
}
.brand small {
  display: block;
  font-size: 8px;
  color: #a1a395;
  letter-spacing: 2.3px;
  margin-top: 5px;
}
.search-capsule {
  display: flex;
  align-items: center;
  gap: 11px;
  background: #f3f3ed;
  border: 1px solid #eaeae1;
  border-radius: 9px;
  height: 43px;
  padding: 4px 5px 4px 14px;
  color: #9fa391;
}
.search-capsule:focus-within {
  border-color: #baaf92;
}
.search-capsule input {
  outline: 0;
  border: 0;
  background: none;
  min-width: 0;
  width: 100%;
  font-size: 11px;
  color: #59624d;
}
.search-capsule input::placeholder {
  color: #a4a79a;
}
.search-capsule button {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  gap: 9px;
  height: 32px;
  padding: 0 13px;
  border-radius: 6px;
  background: var(--accent);
  color: #fff;
  font-size: 10px;
}
.hot-searches {
  display: flex;
  gap: 15px;
  white-space: nowrap;
  overflow: auto;
  scrollbar-width: none;
  margin: 9px 0 0 4px;
  font-size: 9px;
  color: #a6a89b;
}
.hot-searches button {
  padding: 0;
  color: #94998a;
  font-size: 9px;
}
.hot-searches button:hover {
  color: var(--accent);
}
.user-nav {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 26px;
  padding-bottom: 14px;
  font-size: 11px;
  color: #626b59;
}
.account-entry {
  display: flex;
  align-items: center;
  gap: 9px;
}
.avatar-placeholder {
  display: grid;
  place-items: center;
  border: 1px solid #e6e8dd;
  border-radius: 50%;
  background: #f6f6f1;
  width: 34px;
  height: 34px;
  color: #919983;
}
.divider {
  color: #b8bcaf;
  margin: 0 5px;
}
.account-entry small {
  display: block;
  font-size: 9px;
  color: #a7ab9e;
  margin-top: 5px;
}
.orders-entry {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
  font-size: 9px;
}
.logout-link {
  font-size: 9px;
  color: #a0a593;
  padding: 0;
  display: block;
  margin-top: 4px;
}
.header-navigation {
  max-width: 1200px;
  margin: auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 45px;
}
.header-navigation > nav {
  display: flex;
  height: 100%;
  gap: 38px;
}
.header-navigation > nav > a {
  display: flex;
  align-items: center;
  position: relative;
  color: #8c9182;
  font-size: 11px;
}
.header-navigation > nav > a.current {
  color: var(--accent);
  font-weight: 550;
}
.header-navigation > nav > a.current::after {
  content: "";
  position: absolute;
  bottom: -1px;
  left: 0;
  right: 0;
  height: 2px;
  background: var(--accent);
}
.header-publish {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: #8b927f;
}
@media (max-width: 1360px) {
  .header-top-inner,
  .header-main,
  .header-navigation {
    margin-left: 40px;
    margin-right: 85px;
  }
  .header-main {
    grid-template-columns: 200px minmax(0, 1fr) 220px;
    gap: 24px;
  }
}
@media (max-width: 1000px) {
  .header-main {
    grid-template-columns: 175px minmax(0, 1fr) 180px;
    gap: 20px;
  }
  .user-nav {
    gap: 18px;
  }
  .account-entry small {
    display: none;
  }
  .header-top-inner > span:last-child {
    font-size: 7px;
  }
  .brand strong {
    font-size: 22px;
  }
  .brand-mark {
    width: 38px;
  }
  .hot-searches {
    gap: 12px;
  }
  .header-navigation > nav {
    gap: 28px;
  }
}
@media (max-width: 800px) {
  .header-main {
    grid-template-columns: 1fr auto;
    gap: 20px;
    padding: 23px 0 18px;
  }
  .header-search {
    grid-row: 2;
    grid-column: 1/-1;
  }
  .user-nav {
    padding: 0;
  }
  .header-top-inner,
  .header-main,
  .header-navigation {
    margin-left: 25px;
    margin-right: 25px;
  }
  .header-top-inner > span:last-child {
    display: none;
  }
  .header-navigation > nav {
    gap: 26px;
  }
  .header-publish {
    font-size: 10px;
  }
}
@media (max-width: 520px) {
  .header-top-inner,
  .header-main,
  .header-navigation {
    margin-left: 20px;
    margin-right: 20px;
  }
  .header-main {
    gap: 18px;
  }
  .brand strong {
    font-size: 22px;
  }
  .brand-mark {
    width: 35px;
    height: 40px;
  }
  .brand small {
    font-size: 7px;
  }
  .avatar-placeholder {
    display: none;
  }
  .user-nav {
    gap: 17px;
  }
  .header-navigation {
    height: 43px;
    gap: 20px;
  }
  .header-navigation > nav {
    gap: 24px;
    overflow: auto;
    scrollbar-width: none;
    white-space: nowrap;
  }
  .header-navigation > nav > a {
    font-size: 10px;
    flex-shrink: 0;
  }
  .header-publish {
    display: none;
  }
  .search-capsule {
    height: 43px;
  }
  .hot-searches {
    gap: 14px;
  }
  .orders-entry {
    font-size: 9px;
  }
}
</style>
