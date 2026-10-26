<script setup>
import { computed, ref, watch, nextTick } from "vue";
import { useRoute, useRouter } from "vue-router";
import { categories, channels, feedTabs, filterGoods } from "@/data/market.js";
import MarketIcon from "@/components/MarketIcon.vue";
import ProductVisual from "@/components/ProductVisual.vue";
import GoodsCard from "@/components/GoodsCard.vue";
import FloatingDock from "@/components/FloatingDock.vue";
import CategoryNav from "@/components/CategoryNav.vue";
import { getTypeName } from "@/data/categoryTypes.js";
const route = useRoute();
const router = useRouter();
const feedRef = ref();
const previousFilters = ref(null);
const activeTab = computed(() => typeof route.query.category === "string" ? route.query.category : "all");
const keyword = computed(() => typeof route.query.q === "string" ? route.query.q : "");
const activeType = computed(() => typeof route.query.type === "string" ? route.query.type : "");
const typeName = computed(() => getTypeName(activeTab.value, activeType.value));
const sort = computed(() => ["priceAsc", "priceDesc"].includes(route.query.sort) ? route.query.sort : "recommended");
const filtered = computed(() => {
  const result = filterGoods({ query: keyword.value, category: activeTab.value, type: activeType.value });
  return sort.value === "recommended" ? result : [...result].sort((a, b) => sort.value === "priceAsc" ? a.price - b.price : b.price - a.price);
});
const isFiltered = computed(() => Boolean(keyword.value) || activeTab.value !== "all" || Boolean(activeType.value));
const currentCategory = computed(() => categories.find((item) => item.id === activeTab.value)?.name || feedTabs.find((item) => item.id === activeTab.value)?.name || "全部好物");
function scrollToFeed() {
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  feedRef.value?.scrollIntoView({ behavior: reduced ? "instant" : "smooth", block: "start" });
}
function updateSort(value) {
  router.replace({ path: "/", query: { ...route.query, sort: value === "recommended" ? undefined : value } });
}
function removeFilter(key) {
  previousFilters.value = { ...route.query };
  const query = { ...route.query };
  delete query[key];
  if (key === "category") delete query.type;
  router.push({ path: "/", query });
}
function clearFilters() {
  previousFilters.value = { ...route.query };
  router.push({ path: "/", query: { sort: route.query.sort } });
}
function undoFilters() {
  const query = previousFilters.value;
  previousFilters.value = null;
  router.push({ path: "/", query });
}
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
    <CategoryNav :active-category="activeTab" :active-type="activeType" @select="({ category, type }) => selectCategory(category, type)" />
    <div class="catalog-main">
      <div class="catalog-heading">
        <div><h1>闲置集市</h1><p>不必全新，也能刚刚好。</p></div>
        <span class="demo-note">展示集市 · 交易暂未开放</span>
      </div>
      <section v-if="!isFiltered" class="discovery-note" aria-label="发现闲置灵感">
        <div class="discovery-copy"><h2>让喜欢，不止一次。</h2><p>心动装备，轻松拥有。</p><button @click="showFeed('digital')">从手机数码逛起<MarketIcon name="arrow" :size="18" /></button></div>
        <img src="/images/editorial-hero.png" alt="自然光中的复古相机、皮质手提包与奶油色台灯" fetchpriority="high" width="1536" height="1024" />
      </section>
      <section ref="feedRef" class="feed-section" aria-labelledby="feed-title">
        <div class="feed-heading"><h2 id="feed-title">{{ keyword ? `“${keyword}”的搜索结果` : isFiltered ? currentCategory : "发现好物" }}</h2><span class="feed-counter" role="status" aria-live="polite" aria-atomic="true">{{ filtered.length }} 件好物</span></div>
        <div class="feed-toolbar">
          <div class="feed-tabs" role="group" aria-label="筛选商品分类"><button v-for="tab in feedTabs" :key="tab.id" :class="{ selected: activeTab === tab.id }" :aria-pressed="activeTab === tab.id" @click="selectCategory(tab.id)">{{ tab.id === 'all' ? '全部' : tab.name }}</button></div>
          <label class="sort-control"><span>排序</span><select :value="sort" aria-label="商品排序" @change="updateSort($event.target.value)"><option value="recommended">默认推荐</option><option value="priceAsc">价格从低到高</option><option value="priceDesc">价格从高到低</option></select></label>
        </div>
        <div v-if="isFiltered" class="filter-summary">
          <div class="active-filters">
            <button v-if="keyword" @click="removeFilter('q')" :aria-label="'移除关键词 ' + keyword">{{ keyword }}<MarketIcon name="close" :size="14" /></button>
            <button v-if="activeTab !== 'all'" @click="removeFilter('category')" :aria-label="'移除分类 ' + currentCategory">{{ currentCategory }}<MarketIcon name="close" :size="14" /></button>
            <button v-if="activeType" @click="removeFilter('type')" :aria-label="'移除类型 ' + typeName">{{ typeName }}<MarketIcon name="close" :size="14" /></button>
          </div><button class="clear-filters" @click="clearFilters">清除筛选</button>
        </div>
        <div v-if="previousFilters" class="undo-bar" role="status">筛选条件已更新<button @click="undoFilters">撤销上次移除</button><button aria-label="关闭撤销提示" @click="previousFilters = null"><MarketIcon name="close" :size="16" /></button></div>
        <!-- 1440 宽：1280 - 184 侧栏 - 24 间距 - 48 内边距 = 1024；4 × 238 + 3 × 24 = 1024。源顺序就是视觉和键盘顺序。 -->
        <div v-if="filtered.length" class="goods-feed"><GoodsCard v-for="item in filtered" :key="item.id" :goods="item" /></div>
        <div v-else class="feed-empty"><MarketIcon name="search" :size="36" /><h3>暂时没找到合适的好物</h3><p>试试其他商品名，或减少筛选条件。</p><button class="primary-link" @click="clearFilters">清除条件，查看全部</button><button v-if="keyword" class="text-link" @click="removeFilter('q')">仅移除关键词</button></div>
        <p v-if="filtered.length" class="feed-end">已经看完这 {{ filtered.length }} 件好物，喜欢的总会相遇。</p>
      </section>
      <section class="collections" aria-labelledby="collections-title">
        <div class="feed-heading"><h2 id="collections-title">从你的热爱出发</h2><button class="text-link" @click="showFeed()">逛逛全部<MarketIcon name="arrow" :size="17" /></button></div>
        <div class="collection-grid"><button v-for="channel in channels" :key="channel.id" class="collection-card" @click="showFeed(channel.id)"><div class="collection-image"><ProductVisual :kind="channel.kind" :color="channel.color" :accent="channel.accent" /></div><div class="collection-copy"><h3>{{ channel.title }}</h3><p>{{ channel.subtitle }}</p></div><MarketIcon name="arrow" :size="18" /></button></div>
      </section>
      <section class="closing-note" aria-labelledby="closing-title"><div><h2 id="closing-title">你的闲置，是别人的心动。</h2><p>给好物一个新的去处，也给生活留一点空间。</p></div><RouterLink class="text-link" to="/publish">发布我的闲置<MarketIcon name="arrow" :size="18" /></RouterLink></section>
    </div>
    <FloatingDock />
  </div>
</template>
<style scoped>
.market-home { display: grid; grid-template-columns: 184px minmax(0, 1fr); gap: var(--gap); align-items: start; }
.catalog-main { min-width: 0; padding: 24px; border: 1px solid var(--line); border-radius: var(--radius); background: var(--surface); }
.catalog-heading { display: flex; justify-content: space-between; gap: 20px; align-items: center; margin-bottom: 24px; }
.catalog-heading h1 { font-size: 28px; font-weight: 650; margin: 0 0 6px; }
.catalog-heading p { margin: 0; color: var(--text-secondary); font-size: 14px; }
.demo-note { color: var(--text-secondary); font-size: 12px; }
.discovery-note { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1.15fr); height: 156px; margin-bottom: 24px; border-radius: 12px; overflow: hidden; background: #edf1ed; }
.discovery-copy { position: relative; z-index: 1; padding: 20px 28px; }
.discovery-copy h2 { margin: 0 0 8px; font-size: 26px; line-height: 1.35; font-weight: 600; letter-spacing: -0.02em; }
.discovery-copy p { margin: 0; color: var(--text-secondary); font-size: 13px; }
.discovery-copy button { display: flex; align-items: center; gap: 16px; min-height: 44px; margin-top: 4px; padding: 0; font-size: 13px; font-weight: 550; }
.discovery-copy button:hover { color: var(--accent); }
.discovery-note > img { width: 100%; height: 156px; object-fit: cover; object-position: 80% 67%; }
.feed-section { scroll-margin-top: 24px; }
.feed-heading { display: flex; align-items: center; justify-content: space-between; gap: 16px; margin-bottom: 16px; }
.feed-heading h2 { min-width: 0; font-size: 20px; font-weight: 600; margin: 0; overflow-wrap: anywhere; }
.feed-counter { color: var(--text-secondary); font-size: 12px; flex-shrink: 0; font-variant-numeric: tabular-nums; }
.feed-toolbar { display: flex; align-items: center; gap: 16px; margin-bottom: 24px; border-bottom: 1px solid var(--line); }
.feed-tabs { display: flex; flex: 1; min-width: 0; gap: 20px; overflow-x: auto; scrollbar-width: thin; }
.feed-tabs button { position: relative; flex-shrink: 0; min-height: 48px; padding: 0 0 8px; font-size: 13px; color: var(--text-secondary); }
.feed-tabs button.selected { color: var(--text); font-weight: 600; }
.feed-tabs button.selected::after { content: ''; position: absolute; left: 0; right: 0; bottom: 0; height: 2px; background: var(--accent); }
.sort-control { display: flex; align-items: center; gap: 8px; flex-shrink: 0; padding-bottom: 8px; font-size: 12px; color: var(--text-secondary); }
.sort-control select { min-height: 36px; max-width: 142px; padding: 4px 26px 4px 10px; background: var(--surface); border: 1px solid var(--control-border); border-radius: 6px; color: var(--text); font: inherit; }
.filter-summary { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 8px 16px; margin: -8px 0 20px; }
.active-filters { display: flex; flex-wrap: wrap; min-width: 0; gap: 8px; }
.active-filters button { display: inline-flex; align-items: center; gap: 8px; max-width: 100%; min-height: 36px; padding: 6px 10px; border-radius: 6px; background: var(--active); font-size: 12px; overflow-wrap: anywhere; text-align: left; }
.clear-filters { min-height: 36px; padding: 0; font-size: 12px; color: var(--text-secondary); text-decoration: underline; text-underline-offset: 4px; }
.goods-feed { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 32px 24px; }
.feed-end { margin: 32px 0 0; text-align: center; color: var(--text-secondary); font-size: 12px; }
.feed-empty { padding: 48px 16px; text-align: center; color: var(--text-secondary); }
.feed-empty h3 { margin: 16px 0 8px; font-size: 18px; color: var(--text); }
.feed-empty p { font-size: 14px; margin: 0 0 24px; }
.feed-empty .text-link { display: flex; width: fit-content; margin: 8px auto 0; }
.collections { margin-top: 48px; padding-top: 32px; border-top: 1px solid var(--line); }
.collection-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px 24px; }
.collection-card { display: flex; align-items: center; gap: 16px; text-align: left; min-width: 0; padding: 8px 0; }
.collection-image { width: 80px; height: 80px; flex-shrink: 0; overflow: hidden; border-radius: var(--control-radius); }
.collection-copy { min-width: 0; }
.collection-copy h3 { font-size: 15px; font-weight: 550; margin: 0 0 6px; }
.collection-copy p { font-size: 12px; color: var(--text-secondary); margin: 0; }
.collection-card > svg { margin-left: auto; }
.collection-card:hover h3 { color: var(--accent); }
.closing-note { display: flex; align-items: center; justify-content: space-between; gap: 20px; padding: 24px; margin-top: 32px; border-radius: 12px; background: var(--raised); }
.closing-note h2 { margin: 0 0 6px; font-size: 18px; }
.closing-note p { margin: 0; color: var(--text-secondary); font-size: 13px; }
.closing-note > a { flex-shrink: 0; }
@media (max-width: 1200px) { .goods-feed { grid-template-columns: repeat(3, minmax(0, 1fr)); } .sort-control > span { display: none; } }
@media (max-width: 1100px) { .market-home { grid-template-columns: 172px minmax(0, 1fr); } .catalog-main { padding: 20px; } .catalog-heading { align-items: flex-start; } .demo-note { max-width: 96px; text-align: right; } .discovery-copy { padding-inline: 20px; } .collection-image { width: 64px; height: 64px; } }
@media (max-width: 800px) {
  .market-home { grid-template-columns: 1fr; gap: 8px; }
  .catalog-main { padding: 20px; }
  .catalog-heading { margin-bottom: 24px; align-items: center; }
  .demo-note { max-width: none; }
  .discovery-note { display: none; }
  .goods-feed { grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 24px 16px; }
  .feed-tabs button { min-height: 44px; }
  .sort-control select { min-height: 44px; }
  .filter-summary button { min-height: 44px; }
}
@media (max-width: 600px) {
  .catalog-main { padding: 16px; }
  .catalog-heading { margin-bottom: 20px; gap: 12px; }
  .catalog-heading h1 { font-size: 24px; }
  .catalog-heading p { font-size: 12px; }
  .demo-note { font-size: 11px; max-width: 84px; line-height: 1.8; }
  .feed-heading { margin-bottom: 8px; }
  .feed-heading h2 { font-size: 17px; }
  .feed-toolbar { gap: 12px; margin-bottom: 16px; }
  .feed-tabs { gap: 20px; }
  .feed-tabs button { font-size: 12px; }
  .sort-control { padding-bottom: 4px; }
  .sort-control select { font-size: 11px; max-width: 116px; padding-inline: 6px 18px; }
  .goods-feed { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 24px 12px; }
  .feed-end { font-size: 11px; margin-top: 24px; }
  .collections { margin-top: 32px; padding-top: 24px; }
  .collection-grid { grid-template-columns: 1fr; gap: 8px; }
  .collection-image { width: 64px; height: 64px; }
  .collection-card { gap: 14px; }
  .closing-note { align-items: flex-start; flex-direction: column; padding: 20px; gap: 12px; }
  .closing-note h2 { font-size: 17px; }
}
</style>
