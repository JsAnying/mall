<script setup>
import { computed, ref, watch, nextTick, onMounted, onUnmounted } from "vue";
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
const activeTab = computed(() =>
  typeof route.query.category === "string" ? route.query.category : "all",
);
const keyword = computed(() =>
  typeof route.query.q === "string" ? route.query.q : "",
);
const activeType = computed(() =>
  typeof route.query.type === "string" ? route.query.type : "",
);
const typeName = computed(() => getTypeName(activeTab.value, activeType.value));
const filtered = computed(() =>
  filterGoods({
    query: keyword.value,
    category: activeTab.value,
    type: activeType.value,
  }),
);
const columnCount = ref(4);
function updateColumns() {
  const width = window.innerWidth;
  columnCount.value = width > 1000 ? 4 : width > 700 ? 3 : 2;
}
onMounted(() => {
  updateColumns();
  window.addEventListener("resize", updateColumns);
});
onUnmounted(() => window.removeEventListener("resize", updateColumns));
// Grid 管理列宽，每列独立堆叠，避免不同图片高度带来的行间空白。
const feedColumns = computed(() => {
  const columns = Array.from({ length: columnCount.value }, () => []);
  filtered.value.forEach((item, index) =>
    columns[index % columnCount.value].push(item),
  );
  return columns;
});
const isFiltered = computed(
  () =>
    Boolean(keyword.value) ||
    activeTab.value !== "all" ||
    Boolean(activeType.value),
);
const currentCategory = computed(
  () =>
    categories.find((item) => item.id === activeTab.value)?.name ||
    feedTabs.find((item) => item.id === activeTab.value)?.name ||
    "全部商品",
);
function selectCategory(id) {
  router.push({
    path: "/",
    query: {
      ...route.query,
      category: id === "all" ? undefined : id,
      type: undefined,
    },
  });
}
async function showFeed(id = "all", type) {
  await router.push({
    path: "/",
    query: { category: id === "all" ? undefined : id, type },
  });
  await nextTick();
  feedRef.value?.scrollIntoView({ behavior: "smooth", block: "start" });
}
watch(
  () => route.query.q,
  async (value) => {
    if (value) {
      await nextTick();
      feedRef.value?.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  },
);
</script>
<template>
  <div class="market-home">
    <div class="section-eyebrow">
      <span><i></i> THE SECOND LIFE OF GOOD THINGS</span
      ><span>每一件好物，都值得再次被喜欢。</span>
    </div>
    <section class="discovery" aria-label="发现好物">
      <CategoryNav
        :active-category="activeTab"
        :active-type="activeType"
        @select="({ category, type }) => showFeed(category, type)"
      />
      <article class="editorial-hero">
        <img
          class="hero-photograph"
          src="/images/editorial-hero.png"
          alt="自然光中的复古相机、皮质手提包与奶油色台灯"
          fetchpriority="high"
        />
        <div class="hero-wash"></div>
        <div class="hero-content">
          <span class="hero-kicker"><span></span> 拾光 · 好物新生计划</span>
          <h1>让喜欢的好物，<br />续写<span>新的故事。</span></h1>
          <p>
            不必全新，也能怦然心动。<br />在这里，遇见有故事的物件，与刚刚好的生活。
          </p>
          <button class="hero-button" @click="showFeed()">
            发现心动好物 <MarketIcon name="arrow" :size="18" />
          </button>
          <div class="hero-caption">
            <span>PRE-LOVED, RE-LOVED.</span><span>精选闲置 / 循环生活</span>
          </div>
        </div>
        <RouterLink class="hero-product-label" to="/goods/1"
          ><span class="label-dot"></span
          ><span>本期灵感<small>留住生活里的每一帧</small></span
          ><MarketIcon name="arrow" :size="16"
        /></RouterLink>
      </article>
    </section>
    <div class="trust-strip">
      <span><MarketIcon name="shield" :size="17" />个人闲置，真实分享</span
      ><span><MarketIcon name="heart" :size="17" />让喜欢，不止一次</span
      ><span><MarketIcon name="spark" :size="17" />理性消费，轻盈生活</span
      ><span class="trust-note">GOOD FINDS. BETTER LIVING.</span>
    </div>
    <section class="collections" aria-label="精选频道">
      <div class="section-heading">
        <div>
          <span class="overline">THE CURATED EDIT</span>
          <h2>从你的热爱出发<span>四种生活灵感，慢慢挑。</span></h2>
        </div>
        <button class="text-link" @click="showFeed()">
          逛逛全部 <MarketIcon name="arrow" :size="17" />
        </button>
      </div>
      <div class="collection-grid">
        <button
          v-for="(channel, index) in channels"
          :key="channel.id"
          class="collection-card"
          @click="showFeed(channel.id)"
        >
          <div class="collection-image">
            <ProductVisual
              :kind="channel.kind"
              :color="channel.color"
              :accent="channel.accent"
            /><span class="collection-number">0{{ index + 1 }} / EDIT</span
            ><span class="collection-arrow"
              ><MarketIcon name="arrow" :size="18"
            /></span>
          </div>
          <div class="collection-copy">
            <h3>{{ channel.title }}</h3>
            <p>{{ channel.subtitle }}</p>
          </div>
        </button>
      </div>
    </section>
    <section ref="feedRef" class="feed-section" aria-label="推荐商品">
      <div class="section-heading">
        <div>
          <span class="overline">DISCOVER YOUR NEXT FAVOURITE</span>
          <h2>刚刚好，是你想要的<span>好物不必昂贵，喜欢自有价值。</span></h2>
        </div>
        <span class="feed-counter"
          ><span></span>{{ filtered.length }} 件好物，等待相遇</span
        >
      </div>
      <div class="feed-toolbar">
        <div class="feed-tabs" role="group" aria-label="筛选商品分类">
          <button
            v-for="tab in feedTabs"
            :key="tab.id"
            :class="{ selected: activeTab === tab.id }"
            :aria-pressed="activeTab === tab.id"
            @click="selectCategory(tab.id)"
          >
            {{ tab.name }}<span v-if="activeTab === tab.id"></span>
          </button>
        </div>
        <span class="feed-sort"
          >为你精选 <MarketIcon name="spark" :size="15"
        /></span>
      </div>
      <div v-if="isFiltered" class="filter-summary">
        <span
          >{{
            keyword
              ? "“" + keyword + "” 的搜索结果"
              : [currentCategory, typeName].filter(Boolean).join(" / ")
          }}
          · {{ filtered.length }} 件</span
        ><button @click="router.push('/')">清除筛选 ×</button>
      </div>
      <div
        v-if="filtered.length"
        class="goods-feed"
        :style="{ '--feed-columns': columnCount }"
      >
        <div
          v-for="(column, index) in feedColumns"
          :key="index"
          class="goods-column"
        >
          <GoodsCard v-for="item in column" :key="item.id" :goods="item" />
        </div>
      </div>
      <el-empty v-else description="暂时没找到这件好物，换个关键词试试吧"
        ><el-button @click="router.push('/')">看看全部好物</el-button></el-empty
      >
      <div class="feed-end"><span></span>慢慢逛，好物总会相遇<span></span></div>
    </section>
    <section class="closing-note">
      <span class="closing-symbol">↗</span>
      <div>
        <span class="overline">MAKE ROOM FOR WHAT'S NEXT</span>
        <h2>你的闲置，是别人的心动。</h2>
        <p>让好物继续被使用，让生活留一点空间。</p>
      </div>
      <RouterLink class="closing-button" to="/publish"
        >发布我的闲置 <MarketIcon name="plus" :size="18"
      /></RouterLink>
    </section>
    <footer class="market-footer">
      <div>
        <RouterLink to="/">拾光闲置<span>.</span></RouterLink>
        <p>好物有下一站，生活有新可能。</p>
      </div>
      <span>LESS WASTE. MORE STORIES.</span
      ><small>Mock 展示 · 商品与价格均为示例</small>
    </footer>
    <FloatingDock />
  </div>
</template>
<style scoped>
.section-eyebrow {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 22px;
  color: #92938d;
  font-size: 11px;
}
.section-eyebrow > span:first-child {
  display: flex;
  align-items: center;
  gap: 9px;
  letter-spacing: 1.7px;
  font-size: 9px;
  font-weight: 550;
}
.section-eyebrow i {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--accent);
}
.discovery {
  display: grid;
  grid-template-columns: 210px minmax(0, 1fr);
  gap: 24px;
  align-items: stretch;
}
.editorial-hero {
  position: relative;
  overflow: hidden;
  min-height: 462px;
  border-radius: 16px;
  background: #e9e5db;
}
.hero-photograph {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: 62% center;
}
.hero-wash {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    90deg,
    #f0ebe2f5 0%,
    #f0ebe2e8 26%,
    #f0ebe269 53%,
    transparent 75%
  );
}
.hero-content {
  position: relative;
  padding: 47px 42px;
  z-index: 1;
}
.hero-kicker {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #686a5c;
  font-size: 10px;
  letter-spacing: 1.3px;
}
.hero-kicker > span {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #859177;
}
.hero-content h1 {
  font-size: clamp(32px, 3.35vw, 45px);
  font-weight: 550;
  letter-spacing: -2px;
  line-height: 1.5;
  margin: 28px 0 18px;
  color: #30382f;
}
.hero-content h1 > span {
  color: var(--accent);
}
.hero-content > p {
  color: #77796c;
  font-size: 12px;
  line-height: 2;
  margin: 0 0 25px;
}
.hero-button {
  display: flex;
  align-items: center;
  gap: 23px;
  background: #333e33;
  color: #fff;
  border-radius: 8px;
  padding: 14px 19px;
  font-size: 12px;
  transition:
    background 0.2s,
    transform 0.2s;
}
.hero-button:hover {
  background: #475946;
  transform: translateY(-2px);
}
.hero-caption {
  display: flex;
  align-items: center;
  gap: 17px;
  margin-top: 35px;
  font-size: 9px;
  color: #8b8c7b;
  letter-spacing: 1px;
}
.hero-caption > span:last-child {
  font-size: 9px;
  letter-spacing: 0;
  padding-left: 17px;
  border-left: 1px solid #bfbfac;
}
.hero-product-label {
  position: absolute;
  bottom: 30px;
  right: 25px;
  display: flex;
  gap: 11px;
  align-items: center;
  padding: 13px 15px;
  border: 1px solid #ffffff70;
  background: #ffffffe6;
  backdrop-filter: blur(12px);
  border-radius: 9px;
  font-size: 11px;
  color: #555b4d;
}
.label-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #899777;
}
.hero-product-label small {
  display: block;
  font-size: 9px;
  color: #92938b;
  margin-top: 4px;
}
.hero-product-label > svg {
  margin-left: 13px;
}
.trust-strip {
  display: flex;
  gap: 34px;
  align-items: center;
  padding: 23px 3px;
  margin-bottom: 36px;
  border-bottom: 1px solid var(--line);
  color: #8b8c83;
  font-size: 11px;
}
.trust-strip > span {
  display: flex;
  align-items: center;
  gap: 8px;
}
.trust-strip svg {
  color: #8d997e;
}
.trust-note {
  margin-left: auto;
  font-size: 9px;
  letter-spacing: 1.5px;
  color: #a0a098;
}
.section-heading {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 23px;
}
.overline {
  font-size: 9px;
  letter-spacing: 1.8px;
  color: #92958a;
  display: block;
  font-weight: 550;
}
.section-heading h2 {
  font-size: 25px;
  font-weight: 550;
  letter-spacing: -0.7px;
  margin: 10px 0 0;
}
.section-heading h2 > span {
  font-size: 11px;
  font-weight: 400;
  color: #999b92;
  margin-left: 18px;
  letter-spacing: 0;
}
.text-link {
  display: flex;
  align-items: center;
  gap: 15px;
  font-size: 11px;
  color: #686e61;
  padding: 4px 0;
}
.text-link:hover {
  color: var(--accent);
}
.collections {
  margin-bottom: 49px;
}
.collection-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 21px;
}
.collection-card {
  padding: 0;
  text-align: left;
  min-width: 0;
}
.collection-image {
  position: relative;
  height: 172px;
  overflow: hidden;
  border-radius: 12px;
  background: #eeeae2;
  transition:
    transform 0.25s,
    box-shadow 0.25s;
}
.collection-image :deep(img),
.collection-image :deep(svg) {
  transition: transform 0.5s;
}
.collection-card:hover .collection-image {
  transform: translateY(-3px);
  box-shadow: 0 14px 24px #31382b12;
}
.collection-card:hover .collection-image :deep(img),
.collection-card:hover .collection-image :deep(svg) {
  transform: scale(1.06);
}
.collection-number {
  position: absolute;
  left: 14px;
  top: 13px;
  background: #ffffffe5;
  border-radius: 4px;
  padding: 4px 6px;
  font-size: 8px;
  letter-spacing: 1px;
  color: #7d8172;
}
.collection-arrow {
  position: absolute;
  right: 13px;
  bottom: 13px;
  background: white;
  width: 30px;
  height: 30px;
  display: grid;
  place-items: center;
  border-radius: 50%;
  color: #777e6d;
}
.collection-copy {
  padding: 15px 2px 0;
}
.collection-copy h3 {
  font-size: 15px;
  letter-spacing: 0.3px;
  font-weight: 550;
  margin: 0;
}
.collection-copy p {
  margin: 7px 0 0;
  font-size: 11px;
  color: #989a90;
}
.feed-section {
  scroll-margin-top: 25px;
}
.feed-counter {
  font-size: 10px;
  color: #96988d;
  display: flex;
  align-items: center;
  gap: 7px;
  padding-bottom: 3px;
}
.feed-counter > span {
  background: #9daa8b;
  width: 5px;
  height: 5px;
  border-radius: 50%;
}
.feed-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid var(--line);
  margin-bottom: 25px;
  gap: 20px;
}
.feed-tabs {
  display: flex;
  gap: 28px;
  overflow: auto;
  scrollbar-width: none;
}
.feed-tabs > button {
  position: relative;
  white-space: nowrap;
  font-size: 12px;
  color: #92958b;
  padding: 0 0 16px;
  transition: color 0.2s;
}
.feed-tabs > button:hover {
  color: var(--accent);
}
.feed-tabs > button.selected {
  color: var(--accent);
  font-weight: 600;
}
.feed-tabs > button > span {
  position: absolute;
  bottom: 0;
  height: 2px;
  border-radius: 2px;
  background: var(--accent);
  left: 0;
  right: 0;
}
.feed-sort {
  display: flex;
  gap: 6px;
  align-items: center;
  white-space: nowrap;
  font-size: 10px;
  color: #999b92;
  padding-bottom: 16px;
}
.filter-summary {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 11px;
  color: #888e7e;
  margin-bottom: 22px;
}
.filter-summary button {
  color: var(--accent);
}
.goods-feed {
  display: grid;
  grid-template-columns: repeat(var(--feed-columns), minmax(0, 1fr));
  gap: 23px;
  align-items: start;
}
.goods-column {
  min-width: 0;
}
.feed-end {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 18px;
  padding: 32px 0 48px;
  color: #a5a69e;
  font-size: 10px;
}
.feed-end > span {
  width: 50px;
  height: 1px;
  background: var(--line);
}
.closing-note {
  display: flex;
  align-items: center;
  gap: 28px;
  padding: 34px 40px;
  border-radius: 14px;
  background: #e9ece3;
  margin-bottom: 43px;
}
.closing-symbol {
  font-size: 58px;
  line-height: 1;
  font-weight: 300;
  color: #899379;
}
.closing-note h2 {
  font-size: 22px;
  font-weight: 500;
  margin: 11px 0 9px;
  color: #44503b;
}
.closing-note p {
  margin: 0;
  font-size: 11px;
  color: #949b89;
}
.closing-button {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 18px;
  font-size: 12px;
  background: #ffffffb0;
  border: 1px solid #b5bba24d;
  border-radius: 7px;
  padding: 13px 18px;
  color: #606e52;
  white-space: nowrap;
}
.closing-button:hover {
  background: #fff;
  color: #34422d;
}
.market-footer {
  padding: 0 0 28px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
}
.market-footer > div > a {
  font-size: 22px;
  font-weight: 650;
  letter-spacing: -1px;
}
.market-footer > div > a span {
  color: var(--accent);
}
.market-footer p {
  font-size: 10px;
  color: #93968a;
  margin: 8px 0 0;
}
.market-footer > span {
  font-size: 9px;
  letter-spacing: 1.5px;
  color: #adaeaa;
}
.market-footer small {
  font-size: 9px;
  color: #adaeaa;
}
@media (max-width: 1100px) {
  .discovery {
    grid-template-columns: 185px minmax(0, 1fr);
    gap: 18px;
  }
  .hero-content {
    padding: 42px 29px;
  }
  .hero-content h1 {
    font-size: 35px;
  }
  .hero-product-label {
    bottom: 23px;
    right: 18px;
  }
  .hero-caption {
    gap: 12px;
  }
  .collection-grid {
    gap: 17px;
  }
  .collection-image {
    height: 155px;
  }
  .section-heading h2 > span {
    display: none;
  }
  .feed-tabs {
    gap: 22px;
  }
  .trust-strip {
    gap: 26px;
  }
  .trust-note {
    display: none !important;
  }
}
@media (max-width: 800px) {
  .discovery {
    grid-template-columns: 1fr;
  }
  .editorial-hero {
    min-height: 395px;
  }
  .hero-content {
    padding: 35px;
  }
  .hero-content h1 {
    font-size: 37px;
    margin-top: 24px;
  }
  .collection-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 25px 18px;
  }
  .collection-image {
    height: 195px;
  }
  .section-heading h2 {
    font-size: 23px;
  }
  .trust-strip {
    gap: 22px;
    justify-content: space-between;
    font-size: 10px;
    margin-bottom: 30px;
  }
  .feed-counter {
    font-size: 9px;
  }
  .goods-feed {
    gap: 18px;
  }
  .closing-note {
    padding: 27px;
    gap: 17px;
  }
  .closing-note h2 {
    font-size: 19px;
  }
  .market-footer > span {
    display: none;
  }
}
@media (max-width: 520px) {
  .section-eyebrow > span:last-child {
    display: none;
  }
  .section-eyebrow {
    margin-bottom: 17px;
  }
  .editorial-hero {
    min-height: 430px;
  }
  .hero-photograph {
    object-position: 65% center;
  }
  .hero-wash {
    background: linear-gradient(90deg, #f0ebe2ef, #f0ebe2b0 50%, #f0ebe245);
  }
  .hero-content {
    padding: 30px 25px;
  }
  .hero-content h1 {
    font-size: 31px;
    letter-spacing: -1px;
    margin-top: 27px;
  }
  .hero-content > p {
    font-size: 11px;
    max-width: 230px;
  }
  .hero-caption {
    margin-top: 24px;
    font-size: 8px;
    gap: 10px;
  }
  .hero-caption > span:last-child {
    padding-left: 10px;
    font-size: 8px;
  }
  .hero-product-label {
    bottom: 20px;
    right: 18px;
  }
  .trust-strip {
    gap: 12px;
    padding: 21px 0;
  }
  .trust-strip > span {
    font-size: 9px;
    gap: 5px;
  }
  .trust-strip svg {
    width: 14px;
  }
  .trust-strip > span:nth-child(3) {
    display: none;
  }
  .collection-image {
    height: 160px;
  }
  .collection-copy h3 {
    font-size: 14px;
  }
  .collection-copy p {
    font-size: 10px;
  }
  .collections {
    margin-bottom: 38px;
  }
  .section-heading h2 {
    font-size: 21px;
    margin-top: 10px;
  }
  .overline {
    font-size: 8px;
    letter-spacing: 1.3px;
  }
  .text-link {
    gap: 6px;
    font-size: 10px;
  }
  .feed-counter {
    display: none;
  }
  .feed-sort {
    display: none;
  }
  .feed-tabs {
    gap: 24px;
  }
  .feed-tabs > button {
    font-size: 11px;
  }
  .goods-feed {
    gap: 14px;
  }
  .closing-note {
    position: relative;
    align-items: flex-start;
    padding: 25px 22px 80px;
    gap: 12px;
  }
  .closing-symbol {
    font-size: 38px;
  }
  .closing-note h2 {
    font-size: 17px;
  }
  .closing-note .overline {
    font-size: 7px;
  }
  .closing-button {
    position: absolute;
    left: 72px;
    bottom: 22px;
    padding: 10px 15px;
    font-size: 11px;
  }
  .market-footer {
    align-items: flex-start;
    flex-direction: column;
    gap: 15px;
  }
  .market-footer > div > a {
    font-size: 20px;
  }
}
</style>
