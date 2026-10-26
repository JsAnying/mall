<script setup>
import ProductVisual from "./ProductVisual.vue";
import MarketIcon from "./MarketIcon.vue";
defineProps({ goods: { type: Object, required: true } });
</script>
<template>
  <RouterLink class="goods-card" :to="'/goods/' + goods.id">
    <div class="goods-image">
      <ProductVisual :kind="goods.kind" :color="goods.color" :accent="goods.accent" />
      <span class="condition">{{ goods.condition }}</span>
      <span class="image-action" aria-hidden="true"><MarketIcon name="arrow" :size="19" /></span>
    </div>
    <div class="goods-body">
      <h3>{{ goods.title }}</h3>
      <div class="price-row"><span class="price"><small>¥</small>{{ goods.price.toLocaleString() }}</span><span class="original-price">¥{{ goods.original.toLocaleString() }}</span></div>
      <div class="goods-meta"><span>{{ goods.location }}</span><span>{{ goods.wanted }} 人想要</span></div>
      <div class="seller"><span class="seller-avatar" :style="{ background: goods.avatar }">{{ goods.seller.slice(0, 1) }}</span><span class="seller-name">{{ goods.seller }}</span><span class="seller-type">个人闲置</span></div>
    </div>
  </RouterLink>
</template>
<style scoped>
.goods-card { display: flex; flex-direction: column; min-width: 0; color: var(--text); }
.goods-card:hover { color: var(--text); }
.goods-image { position: relative; aspect-ratio: 1.1; overflow: hidden; border-radius: 12px; background: var(--raised); }
.goods-image :deep(img) { transition: transform 300ms var(--ease); }
.goods-card:hover .goods-image :deep(img) { transform: scale(1.035); }
.condition { position: absolute; top: 12px; left: 12px; background: var(--surface); padding: 3px 8px; font-size: 12px; border-radius: 4px; color: var(--text); }
.image-action { position: absolute; bottom: 12px; right: 12px; display: grid; place-items: center; width: 36px; height: 36px; background: var(--surface); color: var(--accent); border-radius: 50%; opacity: 0; transition: opacity 160ms; }
.goods-card:hover .image-action, .goods-card:focus-visible .image-action { opacity: 1; }
.goods-body { padding-top: 14px; }
.goods-body h3 { font-size: 14px; line-height: 1.7; font-weight: 500; margin: 0 0 10px; min-height: 48px; overflow: hidden; display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 2; }
.goods-card:hover h3 { color: var(--accent); }
.price-row { display: flex; align-items: baseline; gap: 10px; min-height: 34px; font-variant-numeric: tabular-nums; }
.price { font-size: 24px; line-height: 1.3; font-weight: 650; letter-spacing: -0.02em; color: var(--accent); }
.price small { font-size: 14px; font-weight: 500; margin-right: 3px; }
.original-price { font-size: 12px; color: var(--text-secondary); text-decoration: line-through; }
.goods-meta { display: flex; justify-content: space-between; gap: 8px; margin-top: 6px; font-size: 13px; color: var(--text-secondary); }
.seller { display: flex; align-items: center; gap: 7px; margin-top: 14px; font-size: 13px; color: var(--text-secondary); }
.seller-avatar { display: grid; place-items: center; flex-shrink: 0; width: 23px; height: 23px; border-radius: 50%; color: #3d4236; font-size: 11px; }
.seller-name { overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
.seller-type { margin-left: auto; white-space: nowrap; font-size: 12px; }
@media (max-width: 1100px) { .seller-type { display: none; } }
@media (max-width: 450px) { .goods-body { padding-top: 10px; } .goods-body h3 { font-size: 14px; min-height: 48px; margin-bottom: 8px; } .condition { top: 8px; left: 8px; font-size: 12px; } .price { font-size: 22px; } .price-row { gap: 6px; flex-wrap: wrap; } .original-price { font-size: 12px; } .goods-meta { font-size: 12px; gap: 4px; } .seller { margin-top: 10px; font-size: 12px; } }
</style>
