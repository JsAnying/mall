<script setup>
import { computed, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { ElMessage } from "element-plus";
import { getGoodsDetailApi } from "@/api/goods.js";
import { goods } from "@/data/market.js";
import { useUserStore } from "@/stores/user.js";
import { DEMO_FAVORITES_KEY, readPreference, writePreference } from "@/utils/preferences.js";
import MarketIcon from "@/components/MarketIcon.vue";
import ProductVisual from "@/components/ProductVisual.vue";

const props = defineProps({ id: { type: String, required: true } });
const route = useRoute();
const router = useRouter();
const user = useUserStore();
const isDemo = computed(() => route.query.demo === "1");
const detail = ref(null);
const loading = ref(false);
const loadError = ref("");
const retry = ref(0);
const product = computed(() => isDemo.value
  ? goods.find((item) => String(item.id) === props.id)
  : detail.value);
const gallery = computed(() => {
  const item = product.value;
  return item?.images?.length ? item.images : [{ label: "商品主图", url: item?.imageUrl }];
});
const activeIndex = ref(0);
const activePhoto = computed(() => gallery.value[activeIndex.value] ?? gallery.value[0]);

const sellerMeta = computed(() => {
  const item = product.value;
  if (!item) return [];
  return [
    item.location,
    item.sellerActivity,
    item.sellerDays != null && `来拾光 ${item.sellerDays} 天`,
    item.sellerSold != null && `卖出 ${item.sellerSold} 件宝贝`,
    item.sellerReviewRate != null && `好评率 ${item.sellerReviewRate}%`,
  ].filter(Boolean);
});
const paragraphs = computed(() => {
  if (product.value?.description) return product.value.description.split(/\n+/);
  return ["个人闲置，成色、配件和瑕疵以卖家提供的信息为准。"];
});

const numberFormat = new Intl.NumberFormat("zh-CN", { maximumFractionDigits: 2 });
const storedFavorites = readPreference(DEMO_FAVORITES_KEY, []);
const favorites = ref(Array.isArray(storedFavorites) ? storedFavorites : []);
const favorited = computed(() => user.isLoggedIn && (isDemo.value
  ? favorites.value.includes(props.id)
  : product.value?.favorited === true));
const isSeller = computed(() => user.userInfo?.id != null
  && product.value?.sellerId === String(user.userInfo.id));
const canPurchase = computed(() => Boolean(product.value)
  && (isDemo.value || product.value.status === "ON_SALE") && !isSeller.value);

watch([() => props.id, isDemo, () => user.token, retry], async ([id, demo], _, onCleanup) => {
  activeIndex.value = 0;
  detail.value = null;
  loadError.value = "";
  loading.value = !demo;
  if (demo) return;

  const controller = new AbortController();
  onCleanup(() => controller.abort());
  try {
    const data = await getGoodsDetailApi(id, { signal: controller.signal });
    if (controller.signal.aborted) return;
    if (!data?.seller || !data.images?.length) throw new Error("商品详情数据不完整");
    detail.value = {
      ...data,
      kind: data.typeId,
      condition: data.conditionLabel,
      seller: data.seller.nickname,
      sellerId: data.seller.id,
      sellerAvatarUrl: data.seller.avatarUrl,
      sellerCredit: data.seller.creditLabel,
      sellerSold: data.seller.soldCount,
      sellerReviewRate: data.seller.positiveReviewRate,
    };
  } catch (error) {
    if (!controller.signal.aborted && error.status !== 404) {
      loadError.value = error.message || "商品详情加载失败，请重试";
    }
  } finally {
    if (!controller.signal.aborted) loading.value = false;
  }
}, { immediate: true });

function withLogin(action) {
  if (!user.isLoggedIn) {
    router.replace({ name: "login", query: { redirect: route.fullPath } });
    return;
  }
  action();
}

function toggleFavorite() {
  if (!isDemo.value) {
    showUnavailable("账号收藏操作暂未开放。");
    return;
  }
  const next = favorited.value
    ? favorites.value.filter((id) => id !== props.id)
    : [...favorites.value, props.id];
  if (!writePreference(DEMO_FAVORITES_KEY, next)) {
    ElMessage.warning("本次收藏未保存，请检查浏览器存储设置。");
    return;
  }
  favorites.value = next;
}

function showUnavailable(message) {
  ElMessage.info(message);
}

function goBack() {
  const back = router.options.history.state.back;
  if (typeof back === "string" && back.startsWith("/") && !back.startsWith("//")) {
    router.back();
  } else {
    router.push("/");
  }
}
</script>

<template>
  <div v-if="product" class="detail-page">
    <nav class="detail-breadcrumb" aria-label="商品路径">
      <button type="button" class="back-link" @click="goBack">返回商品列表</button>
      <span aria-hidden="true">/</span>
      <span aria-current="page">商品详情</span>
    </nav>

    <article class="detail-card" aria-labelledby="detail-title">
      <header class="seller-bar">
        <div class="seller-identity">
          <img v-if="product.sellerAvatarUrl" class="seller-avatar" :src="product.sellerAvatarUrl" alt="" />
          <span v-else class="seller-avatar" :style="{ backgroundColor: product.avatar }" aria-hidden="true">{{ product.seller.slice(0, 1) }}</span>
          <div class="seller-copy">
            <div class="seller-heading">
              <strong>{{ product.seller }}</strong>
              <span v-if="product.sellerCredit" class="seller-credit">{{ product.sellerCredit }}</span>
            </div>
            <ul v-if="sellerMeta.length" class="seller-meta" aria-label="卖家信息">
              <li v-for="entry in sellerMeta" :key="entry">{{ entry }}</li>
            </ul>
          </div>
        </div>
        <button type="button" class="seller-profile" @click="showUnavailable('卖家个人主页暂未开放。')">
          <MarketIcon name="user" :size="16" />个人主页
        </button>
      </header>

      <div class="detail-grid">
        <div class="detail-gallery">
          <div class="detail-preview" id="detail-preview" :role="product.galleryUrl ? undefined : 'img'" :aria-label="product.galleryUrl ? undefined : `${product.title}，第 ${activeIndex + 1} 张图`">
            <img
              v-if="product.galleryUrl"
              class="gallery-sheet"
              :src="product.galleryUrl"
              :style="{ '--photo-x': activePhoto.x, '--photo-y': activePhoto.y }"
              :alt="`${product.title}：${activePhoto.label}`"
              fetchpriority="high"
            />
            <ProductVisual v-else :kind="product.kind" :image-url="activePhoto.url" :color="product.color" :accent="product.accent" />
            <span v-if="product.galleryUrl" class="preview-note">示意图</span>
          </div>

          <div class="detail-thumbnails" role="group" aria-label="选择商品图片">
            <button
              v-for="(photo, index) in gallery"
              :key="photo.fileId ?? index"
              type="button"
              class="detail-thumb"
              :aria-label="photo.label ?? `第 ${index + 1} 张图`"
              :aria-pressed="activeIndex === index"
              aria-controls="detail-preview"
              @pointerenter="$event.pointerType === 'mouse' && (activeIndex = index)"
              @click="activeIndex = index"
            >
              <img
                v-if="product.galleryUrl"
                class="gallery-sheet"
                :src="product.galleryUrl"
                :style="{ '--photo-x': photo.x, '--photo-y': photo.y }"
                alt=""
              />
              <ProductVisual v-else :kind="product.kind" :image-url="photo.url" :color="product.color" :accent="product.accent" />
            </button>
          </div>
        </div>

        <div class="detail-info">
          <div class="detail-summary">
            <div class="detail-price">
              <strong class="sale-price"><span>¥</span>{{ numberFormat.format(product.price) }}</strong>
              <span v-if="product.freeShipping" class="shipping">包邮</span>
            </div>
            <span v-if="product.viewCount != null" class="detail-views">{{ numberFormat.format(product.viewCount) }} 次浏览</span>
          </div>

          <div class="detail-copy">
            <h1 id="detail-title"><span v-if="product.condition" class="detail-condition">{{ product.condition }}</span>{{ product.title }}</h1>
            <p v-for="(paragraph, index) in paragraphs" :key="index">{{ paragraph }}</p>
          </div>

          <div class="detail-bottom">
            <div class="detail-actions">
              <div class="purchase-actions" role="group" aria-label="交易操作">
                <button type="button" class="add-cart" :disabled="!canPurchase" @click="withLogin(() => showUnavailable('购物车暂未开放。'))">
                  <MarketIcon name="bag" :size="17" />加入购物车
                </button>
                <button type="button" class="buy-now" :disabled="!canPurchase" @click="withLogin(() => showUnavailable('下单暂未开放，当前商品仅供浏览。'))">立即购买</button>
              </div>
              <button type="button" class="detail-favorite" aria-label="收藏商品" :aria-pressed="favorited" @click="withLogin(toggleFavorite)">
                <MarketIcon name="star" :size="18" />{{ favorited ? "已收藏" : "收藏" }}
              </button>
            </div>
            <p v-if="isDemo" class="detail-note">示例商品 · 交易暂未开放 · 示例收藏保存在本机</p>
            <p v-else-if="isSeller" class="detail-note">这是你发布的商品。</p>
            <p v-else-if="!canPurchase" class="detail-note">该商品当前不可购买。</p>
          </div>
        </div>
      </div>
    </article>
  </div>

  <el-result v-else-if="loading" title="正在加载商品详情" role="status" />
  <el-result v-else-if="loadError" icon="warning" title="商品详情加载失败" :sub-title="loadError" role="alert">
    <template #extra><el-button @click="retry++">重试</el-button><el-button @click="goBack">返回商品列表</el-button></template>
  </el-result>
  <el-result v-else icon="info" title="暂时没有这件商品" sub-title="这件商品可能已移除，返回列表寻找其他好物。">
    <template #extra><el-button @click="goBack">返回商品列表</el-button></template>
  </el-result>
</template>

<style scoped>
.detail-page {
  max-width: 1160px;
  margin: 20px auto;
}
.detail-breadcrumb {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
  color: var(--text-secondary);
  font-size: 13px;
}
.detail-breadcrumb .back-link {
  padding: 0;
  font-size: inherit;
}
.detail-breadcrumb .back-link:hover {
  color: var(--accent);
  text-decoration: underline;
  text-underline-offset: 4px;
}
.detail-card {
  padding: 24px 28px;
  background: var(--surface);
  border-radius: 20px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.03);
}
.seller-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px 20px;
  padding-bottom: 20px;
  margin-bottom: 20px;
  border-bottom: 1px solid #f2f3f5;
}
.seller-identity {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}
.seller-avatar {
  display: grid;
  flex: 0 0 44px;
  place-items: center;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: var(--accent-soft);
  color: var(--primary);
  object-fit: cover;
  font-size: 16px;
  font-weight: 650;
}
.seller-heading {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 4px 8px;
}
.seller-heading strong {
  font-size: 16px;
}
.seller-credit {
  padding: 2px 8px;
  border-radius: 6px;
  background: var(--accent-soft);
  color: var(--accent);
  font-size: 12px;
  font-weight: 550;
}
.seller-meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 2px 8px;
  padding: 0;
  margin: 3px 0 0;
  list-style: none;
  color: var(--text-secondary);
  font-size: 12px;
}
.seller-meta li {
  white-space: nowrap;
}
.seller-meta li + li::before {
  content: "";
  display: inline-block;
  width: 1px;
  height: 10px;
  margin-inline-end: 8px;
  background: var(--control-border);
  vertical-align: -1px;
}
.seller-profile {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: none;
  gap: 6px;
  min-height: 44px;
  padding: 6px 14px;
  border: 1px solid #e5e6eb;
  border-radius: 999px;
  font-size: 13px;
  white-space: nowrap;
}
.seller-profile:hover {
  background: var(--raised);
  color: var(--accent);
}
.detail-grid {
  display: grid;
  grid-template-columns: minmax(0, 520px) minmax(0, 1fr);
  align-items: start;
  gap: 40px;
}
.detail-gallery {
  position: relative;
  padding-left: 90px;
}
.detail-preview {
  position: relative;
  aspect-ratio: 1;
  overflow: hidden;
  border-radius: 16px;
  background: #f7f8fa;
}
.detail-preview :deep(.product-photo) {
  object-fit: contain;
}
.gallery-sheet {
  position: absolute;
  top: 0;
  left: 0;
  width: 200%;
  max-width: none;
  height: 200%;
  transform: translate(var(--photo-x), var(--photo-y));
}
.preview-note {
  position: absolute;
  right: 10px;
  bottom: 10px;
  padding: 2px 7px;
  border-radius: 4px;
  background: var(--surface);
  color: var(--text-secondary);
  font-size: 12px;
}
.detail-thumbnails {
  position: absolute;
  inset: 0 auto 0 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 76px;
  overflow: auto;
  scrollbar-width: thin;
}
.detail-thumb {
  position: relative;
  flex: 0 0 76px;
  width: 76px;
  height: 76px;
  padding: 0;
  overflow: hidden;
  border: 2px solid transparent;
  border-radius: 10px;
  background: #f7f8fa;
}
.detail-thumb[aria-pressed="true"] {
  border-color: #1f2329;
}
.detail-thumb:focus-visible,
.purchase-actions button:focus-visible {
  outline-offset: -4px;
}
.detail-info {
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 430px;
}
.detail-summary,
.detail-price {
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
}
.detail-summary {
  justify-content: space-between;
  gap: 6px 16px;
  margin-bottom: 20px;
}
.detail-price {
  gap: 6px 9px;
  color: var(--text-secondary);
  font-size: 13px;
}
.sale-price {
  color: var(--accent);
  font-size: 30px;
  font-weight: 750;
  font-variant-numeric: tabular-nums;
  line-height: 1.2;
}
.sale-price span {
  margin-right: 2px;
  font-size: 20px;
}
.shipping {
  padding-left: 8px;
  border-left: 1px solid var(--control-border);
  color: var(--text);
}
.detail-views {
  color: var(--text-secondary);
  font-size: 13px;
}
.detail-copy {
  font-size: 15px;
  line-height: 1.75;
}
.detail-copy h1 {
  margin: 0 0 8px;
  overflow-wrap: anywhere;
  font-size: 18px;
  font-weight: 700;
  line-height: 1.55;
  text-wrap: initial;
}
.detail-condition {
  display: inline-block;
  padding: 1px 7px;
  margin-right: 8px;
  border-radius: 6px;
  background: var(--raised);
  color: var(--text-secondary);
  vertical-align: 2px;
  font-size: 12px;
  font-weight: 550;
}
.detail-copy p {
  margin: 0 0 12px;
}
.detail-copy p:last-child {
  margin-bottom: 0;
}
.detail-bottom {
  padding-top: 32px;
  margin-top: auto;
}
.detail-actions,
.purchase-actions,
.detail-favorite {
  display: flex;
  align-items: center;
}
.detail-actions {
  flex-wrap: wrap;
  gap: 10px 14px;
}
.purchase-actions {
  overflow: hidden;
  border-radius: 999px;
}
.purchase-actions button,
.detail-favorite {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  min-height: 46px;
  white-space: nowrap;
}
.purchase-actions button {
  width: 135px;
  font-weight: 700;
}
.add-cart {
  background: #d9ecb8;
  color: var(--primary);
}
.add-cart:hover {
  background: #cce3a5;
}
.buy-now {
  background: #1b3b2b;
  color: #fff;
}
.buy-now:hover {
  background: var(--accent);
}
.buy-now:focus-visible {
  outline-color: #fff;
}
.detail-favorite {
  min-width: 106px;
  padding: 0 18px;
  border-radius: 999px;
  background: #f4f5f7;
  color: var(--text);
  font-weight: 550;
}
.detail-favorite:hover,
.detail-favorite[aria-pressed="true"] {
  background: var(--accent-soft);
  color: var(--accent);
}
.detail-favorite[aria-pressed="true"] svg {
  fill: currentColor;
}
.detail-note {
  margin: 10px 0 0;
  color: var(--text-secondary);
  font-size: 12px;
}
@media (max-width: 1120px) {
  .detail-grid {
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
    gap: 24px;
  }
  .detail-info {
    min-height: 0;
  }
}
@media (max-width: 820px) {
  .detail-grid {
    grid-template-columns: minmax(0, 1fr);
  }
  .detail-gallery {
    width: 100%;
    max-width: 520px;
    margin-inline: auto;
  }
}
@media (max-width: 560px) {
  .detail-page {
    margin: 12px auto;
  }
  .detail-card {
    padding: 16px;
  }
  .seller-bar {
    align-items: start;
    gap: 10px;
    padding-bottom: 12px;
    margin-bottom: 16px;
  }
  .seller-identity {
    align-items: start;
  }
  .seller-meta li + li::before {
    display: none;
  }
  .seller-profile {
    padding-inline: 10px;
  }
  .detail-grid {
    gap: 20px;
  }
  .detail-gallery {
    display: flex;
    flex-direction: column;
    gap: 8px;
    padding-left: 0;
  }
  .detail-thumbnails {
    position: static;
    flex-direction: row;
    width: 100%;
  }
  .detail-thumb {
    flex-basis: 58px;
    width: 58px;
    height: 58px;
  }
  .detail-bottom {
    padding-top: 24px;
  }
  .detail-actions {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    gap: 8px;
  }
  .purchase-actions button {
    flex: 1;
    width: auto;
    padding-inline: 8px;
    font-size: 13px;
  }
  .detail-favorite {
    min-width: 76px;
    padding-inline: 8px;
    font-size: 13px;
  }
}
@media (max-width: 355px) {
  .detail-actions {
    grid-template-columns: 1fr;
  }
  .detail-favorite {
    justify-self: start;
  }
}
</style>
