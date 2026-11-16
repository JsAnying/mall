<script setup>
import { computed, ref, watch, nextTick, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import { feedTabs, filterGoods, goods } from "@/data/market.js";
import { useHomeStore } from "@/stores/home.js";
import { getCategoriesApi } from "@/api/category.js";
import MarketIcon from "@/components/MarketIcon.vue";
import GoodsCard from "@/components/GoodsCard.vue";
import ProductVisual from "@/components/ProductVisual.vue";
import FloatingDock from "@/components/FloatingDock.vue";
import CategoryNav from "@/components/CategoryNav.vue";
const route = useRoute();
const router = useRouter();
const home = useHomeStore();
const feedRef = ref();
const categories = ref([]);
const categoriesLoading = ref(true);
const categoriesError = ref("");
async function loadCategories() {
  categoriesLoading.value = true;
  categoriesError.value = "";
  try {
    const result = await getCategoriesApi();
    if (!Array.isArray(result)) throw new Error("分类数据格式不正确");
    categories.value = result;
  } catch (error) {
    categories.value = [];
    categoriesError.value = error.message || "分类加载失败，请重试";
  } finally {
    categoriesLoading.value = false;
  }
}
onMounted(loadCategories);
const activeTab = computed(() => typeof route.query.category === "string" ? route.query.category : "all");
const keyword = computed(() => typeof route.query.q === "string" ? route.query.q : "");
const activeType = computed(() => typeof route.query.type === "string" ? route.query.type : "");
const filtered = computed(() => filterGoods({ query: keyword.value, category: activeTab.value, type: activeType.value }));
const defaultBanner = {
  title: "让喜欢的好物，续写新的故事。",
  subtitle: "不必全新，也能怦然心动。",
  buttonText: "发现心动好物",
  imageUrl: "/images/editorial-hero.png",
};
const banner = computed(() => ({ ...defaultBanner, ...home.data?.banner }));
const channels = [
  { id: "digital", title: "数码捡漏", subtitle: "热门装备省心入", icon: "phone", productIds: [6, 1] },
  { id: "fashion", title: "穿搭鞋包", subtitle: "质感美衣低价淘", icon: "bag", productIds: [3, 7] },
  { id: "toys", title: "潮玩手办", subtitle: "热门藏品随手入", icon: "star", productIds: [5, 14] },
  { id: "home", title: "居家好物", subtitle: "品质生活放心购", icon: "home", productIds: [4, 13] },
].map(channel => ({
  ...channel,
  products: goods.filter(item => channel.productIds.includes(item.id)),
}));
function browseCategory({ category, type, group }) {
  router.push({ path: "/browse", query: { category: category === "all" ? undefined : category, type, group } });
}
function scrollToFeed() {
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  feedRef.value?.scrollIntoView({ behavior: reduced ? "instant" : "smooth", block: "start" });
}
function removeFilter(key) {
  const query = { ...route.query };
  delete query[key];
  router.push({ path: "/", query });
}
function clearFilters() { router.push({ path: "/" }); }
async function selectCategory(category, type) {
  await router.push({ path: "/", query: { ...route.query, category: category === "all" ? undefined : category, type } });
  await nextTick();
  scrollToFeed();
}
async function showFeed(category = "all", type) {
  await router.push({ path: "/", query: { category: category === "all" ? undefined : category, type } });
  await nextTick();
  scrollToFeed();
}
watch(() => route.query.q, async (value) => { if (value) { await nextTick(); scrollToFeed(); } });
</script>
<template>
  <div class="market-home">
    <h1 class="sr-only">拾光闲置集市</h1>
    <section class="hero-bento" aria-label="分类与精选好物">
      <CategoryNav
        :categories="categories" :loading="categoriesLoading" :error="categoriesError"
        :active-category="activeTab" :active-type="activeType"
        @retry="loadCategories" @select="browseCategory"
      />
      <section class="hero-poster" aria-labelledby="poster-title">
        <img class="poster-image" :src="banner.imageUrl || defaultBanner.imageUrl" alt="" fetchpriority="high" />
        <div class="poster-copy">
          <h2 id="poster-title">{{ banner.title }}</h2>
          <p>{{ banner.subtitle }}</p>
        </div>
        <button class="poster-action" @click="showFeed(banner.targetCategoryId || 'all')">
          {{ banner.buttonText }}<MarketIcon name="arrow" :size="16" />
        </button>
      </section>
      <div class="channel-grid" aria-label="特色频道">
        <RouterLink
          v-for="channel in channels" :key="channel.id"
          :class="['channel-card', 'channel-' + channel.id]"
          :to="{ path: '/browse', query: { category: channel.id } }"
        >
          <div class="channel-copy">
            <h2>{{ channel.title }}<MarketIcon name="chevron" :size="13" /></h2>
            <p>{{ channel.subtitle }}</p>
            <MarketIcon class="channel-icon" :name="channel.icon" :size="22" />
          </div>
          <div class="channel-products">
            <div v-for="item in channel.products" :key="item.id" class="channel-product">
              <div class="channel-image">
                <ProductVisual :kind="item.kind" :image-url="item.imageUrl" :color="item.color" :accent="item.accent" />
              </div>
              <strong>¥{{ item.price.toLocaleString('zh-CN') }}</strong>
            </div>
          </div>
        </RouterLink>
      </div>
    </section>

    <section ref="feedRef" class="feed-section" aria-label="商品列表">
      <div class="feed-toolbar">
        <div class="feed-tabs" role="group" aria-label="筛选商品分类">
          <button
            v-for="tab in feedTabs" :key="tab.id" :class="{ selected: activeTab === tab.id }"
            :aria-pressed="activeTab === tab.id" @click="selectCategory(tab.id)"
          >
            <MarketIcon v-if="tab.id === 'all'" name="spark" :size="15" />
            {{ tab.id === 'all' ? '全部好物' : tab.name }}
          </button>
        </div>
        <span class="feed-counter" role="status" aria-live="polite">
          <span v-if="keyword">“{{ keyword }}” · </span>共 {{ filtered.length }} 件好物
        </span>
      </div>
      <div v-if="filtered.length" class="goods-feed">
        <GoodsCard v-for="item in filtered" :key="item.id" :goods="item" compact />
      </div>
      <div v-else class="feed-empty">
        <MarketIcon name="search" :size="36" />
        <h2>暂时没找到合适的好物</h2>
        <p>试试其他商品名，或减少筛选条件。</p>
        <button class="primary-link" @click="clearFilters">清除条件，查看全部</button>
        <button v-if="keyword" class="text-link" @click="removeFilter('q')">仅移除关键词</button>
      </div>
      <p v-if="filtered.length" class="feed-end">已经看完这 {{ filtered.length }} 件好物。</p>
    </section>

    <section class="closing-note" aria-labelledby="closing-title">
      <div><h2 id="closing-title">你的闲置，是别人的心动。</h2><p>给好物一个新的去处，也给生活留一点空间。</p></div>
      <RouterLink class="text-link" to="/publish">发布我的闲置<MarketIcon name="arrow" :size="18" /></RouterLink>
    </section>
    <FloatingDock />
  </div>
</template>

<style scoped>
.market-home { min-width: 0; }
.sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }
.hero-bento { display: grid; grid-template-columns: 230px 270px minmax(0, 1fr); grid-auto-rows: 340px; gap: 16px; padding: 16px; background: #fff; border-radius: 16px; }
.hero-poster { position: relative; isolation: isolate; min-width: 0; overflow: hidden; border-radius: 12px; background: #ded7c7; display: flex; flex-direction: column; justify-content: space-between; align-items: flex-start; padding: 20px; }
.poster-image, .hero-poster::before { position: absolute; inset: 0; width: 100%; height: 100%; }
.poster-image { z-index: -2; object-fit: cover; object-position: 45% 50%; }
.hero-poster::before { z-index: -1; content: ""; background: linear-gradient(180deg, #f3eee1 0%, #f3eee1f5 16%, #f3eee1b8 32%, #f3eee100 62%, #20261f55 100%); }
.poster-copy h2 { margin: 0 0 8px; font-size: 29px; line-height: 1.22; letter-spacing: -.025em; color: #203427; }
.poster-copy p { margin: 0; font-size: 13px; color: #37463a; }
.poster-action { display: inline-flex; align-items: center; gap: 8px; min-height: 40px; padding: 0 14px; border-radius: 999px; background: var(--primary); color: #fff; font-weight: 600; }
.poster-action:hover { background: var(--accent); }
.channel-grid { display: grid; grid-template: repeat(2, minmax(0, 1fr)) / repeat(2, minmax(0, 1fr)); gap: 12px; min-width: 0; }
.channel-card { display: grid; grid-template-columns: minmax(0, 35fr) minmax(0, 65fr); align-items: center; gap: 8px; min-width: 0; padding: 14px; border-radius: 12px; color: #24382c; transition: filter 150ms; }
.channel-card:hover { color: #24382c; filter: saturate(1.2); }
.channel-digital { background: linear-gradient(120deg, #dfeee9, #ecf6f7); }
.channel-fashion { background: linear-gradient(120deg, #f7ebca, #fff5df); }
.channel-toys { background: linear-gradient(120deg, #e1f0db, #edf7e9); }
.channel-home { background: linear-gradient(120deg, #efe4f0, #f8eef2); }
.channel-copy { align-self: stretch; display: flex; flex-direction: column; align-items: flex-start; justify-content: center; }
.channel-copy h2 { display: flex; align-items: center; gap: 2px; margin: 0; font-size: clamp(15px, 1.4vw, 19px); line-height: 1.3; white-space: nowrap; }
.channel-copy p { margin: 6px 0 0; color: #405348; font-size: 13px; line-height: 1.45; }
.channel-icon { margin-top: 14px; color: #597b69; }
.channel-products { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 7px; }
.channel-product { min-width: 0; text-align: center; font-variant-numeric: tabular-nums; }
.channel-image { aspect-ratio: 1; overflow: hidden; border-radius: 8px; background: #fff; }
.channel-image :deep(.product-frame) { background: #fff; }
.channel-product strong { display: block; margin-top: 5px; color: #a3391c; font-size: 15px; line-height: 1.3; }
.feed-section { margin-top: 20px; scroll-margin-top: 16px; }
.feed-toolbar { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 16px; padding: 10px 12px; background: #fff; border-radius: 16px; }
.feed-tabs { display: flex; align-items: center; gap: 8px; min-width: 0; padding: 4px; overflow-x: auto; scrollbar-width: thin; }
.feed-tabs button { display: inline-flex; align-items: center; gap: 5px; flex-shrink: 0; min-height: 38px; padding: 8px 18px; border-radius: 999px; background: #F4F5F7; color: var(--text); font-size: 14px; white-space: nowrap; }
.feed-tabs button:hover { background: var(--active); }
.feed-tabs button.selected { background: var(--primary); color: #fff; font-weight: 650; }
.feed-counter { max-width: 28%; padding-right: 6px; color: var(--text-secondary); font-size: 13px; text-align: right; overflow-wrap: anywhere; font-variant-numeric: tabular-nums; }
.goods-feed { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 16px; }
.feed-end { margin: 28px 0 0; text-align: center; color: var(--text-secondary); font-size: 13px; }
.feed-empty { padding: 48px 16px; text-align: center; color: var(--text-secondary); }
.feed-empty h2 { margin: 16px 0 8px; font-size: 18px; color: var(--text); }
.feed-empty p { margin: 0 0 24px; }
.feed-empty .text-link { display: flex; width: fit-content; margin: 8px auto 0; }
.closing-note { display: flex; align-items: center; justify-content: space-between; gap: 20px; padding: 24px; margin-top: 32px; border-radius: 12px; background: #fff; }
.closing-note h2 { margin: 0 0 6px; font-size: 18px; }
.closing-note p { margin: 0; color: var(--text-secondary); font-size: 13px; }
.closing-note > a { flex-shrink: 0; }
@media (max-width: 1160px) {
  .hero-bento { grid-template-columns: 200px 218px minmax(0, 1fr); gap: 12px; }
  .channel-card { grid-template-columns: minmax(0, 1fr); gap: 5px; padding: 10px; }
  .channel-copy { flex-direction: row; align-items: baseline; justify-content: flex-start; flex-wrap: wrap; gap: 4px 7px; }
  .channel-copy p { margin: 0; }
  .channel-icon { display: none; }
  .channel-products { max-width: 164px; width: 100%; justify-self: center; }
}
@media (max-width: 960px) {
  .hero-bento { grid-template-columns: 200px minmax(0, 1fr); grid-auto-rows: auto; }
  .hero-poster { min-height: 340px; }
  .channel-grid { grid-column: 1 / -1; }
  .channel-card { grid-template-columns: minmax(0, 35fr) minmax(0, 65fr); padding: 12px; gap: 8px; }
  .channel-copy { flex-direction: column; justify-content: center; align-items: flex-start; }
  .channel-products { max-width: 180px; }
  .goods-feed { grid-template-columns: repeat(3, minmax(0, 1fr)); }
}
@media (max-width: 800px) {
  .hero-bento { grid-template-columns: minmax(0, 1fr); padding: 12px; }
  .hero-poster { min-height: 210px; }
  .poster-image { object-position: 50% 60%; }
  .poster-copy h2, .poster-copy p { max-width: 220px; }
  .hero-poster::before { background: linear-gradient(90deg, #f3eee1 0%, #f3eee1f5 25%, #f3eee1b8 50%, #f3eee100 90%); }
}
@media (max-width: 600px) {
  .channel-grid { gap: 8px; }
  .channel-card { grid-template-columns: minmax(0, 1fr); gap: 8px; padding: 9px; }
  .channel-products { max-width: 150px; }
  .feed-toolbar { align-items: flex-start; flex-direction: column; gap: 4px; padding: 8px; }
  .feed-tabs { width: 100%; }
  .feed-tabs button { min-height: 44px; padding-inline: 14px; }
  .feed-counter { align-self: flex-end; max-width: 100%; }
  .goods-feed { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px 12px; }
  .closing-note { align-items: flex-start; flex-direction: column; padding: 20px; gap: 12px; }
}
</style>
