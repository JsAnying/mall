<script setup>
import ProductVisual from "./ProductVisual.vue";
import MarketIcon from "./MarketIcon.vue";
defineProps({ goods: { type: Object, required: true } });
</script>
<template>
  <RouterLink class="goods-card" :to="'/goods/' + goods.id">
    <div class="goods-image">
      <ProductVisual
        :kind="goods.kind"
        :color="goods.color"
        :accent="goods.accent"
      /><span class="condition">{{ goods.condition }}</span
      ><span class="image-badge"><MarketIcon name="arrow" :size="17" /></span>
    </div>
    <div class="goods-body">
      <div class="card-eyebrow">
        <span>个人闲置</span><span>{{ goods.location }}</span>
      </div>
      <h3>{{ goods.title }}</h3>
      <div class="price-row">
        <span class="price"
          ><small>¥</small>{{ goods.price.toLocaleString() }}</span
        ><span class="wanted">{{ goods.wanted }} 人想要</span>
      </div>
      <div class="seller">
        <span class="seller-avatar" :style="{ background: goods.avatar }">{{
          goods.seller.slice(0, 1)
        }}</span
        ><span class="seller-name">{{ goods.seller }}</span
        ><span class="seller-dot"></span>
      </div>
    </div>
  </RouterLink>
</template>
<style scoped>
.goods-card {
  display: block;
  background: #fffefa;
  overflow: hidden;
  border-radius: 12px;
  margin-bottom: 24px;
  border: 1px solid #eeeee5;
  color: #383e31;
  transition:
    transform 0.25s,
    box-shadow 0.25s;
}
.goods-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 14px 35px #3743290e;
  color: #383e31;
}
.goods-image {
  position: relative;
  aspect-ratio: 1.07;
  overflow: hidden;
  background: #eeeae2;
}
.goods-image :deep(img),
.goods-image :deep(svg) {
  transition: transform 0.5s;
}
.goods-card:hover .goods-image :deep(img),
.goods-card:hover .goods-image :deep(svg) {
  transform: scale(1.045);
}
.condition {
  position: absolute;
  top: 13px;
  left: 13px;
  border-radius: 5px;
  background: #fffefaeb;
  font-size: 9px;
  letter-spacing: 0.5px;
  color: #777e6b;
  padding: 5px 8px;
}
.image-badge {
  position: absolute;
  bottom: 13px;
  right: 13px;
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background: #fffefade;
  color: #869073;
  opacity: 0;
  transform: translateY(5px);
  transition:
    opacity 0.2s,
    transform 0.2s;
}
.goods-card:hover .image-badge {
  opacity: 1;
  transform: none;
}
.goods-body {
  padding: 15px 17px 16px;
}
.card-eyebrow {
  display: flex;
  justify-content: space-between;
  font-size: 9px;
  color: #a4a894;
  margin-bottom: 8px;
}
h3 {
  margin: 0 0 13px;
  font-size: 12px;
  line-height: 1.8;
  font-weight: 450;
  height: 43px;
  overflow: hidden;
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
}
.price-row {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 5px;
}
.price {
  font-size: 22px;
  color: var(--accent);
  font-weight: 550;
  letter-spacing: -0.4px;
}
.price small {
  font-size: 11px;
  margin-right: 3px;
}
.wanted {
  font-size: 9px;
  color: #b0b3a5;
  white-space: nowrap;
}
.seller {
  display: flex;
  gap: 7px;
  align-items: center;
  border-top: 1px solid #f0f0e8;
  padding-top: 12px;
  margin-top: 13px;
  font-size: 10px;
  color: #9a9f8e;
}
.seller-avatar {
  display: grid;
  place-items: center;
  flex-shrink: 0;
  width: 23px;
  height: 23px;
  font-size: 9px;
  color: #827d6f;
  border-radius: 50%;
}
.seller-name {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.seller-dot {
  margin-left: auto;
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: #b2baa1;
}
@media (max-width: 520px) {
  .goods-card {
    margin-bottom: 15px;
    border-radius: 10px;
  }
  .goods-image {
    aspect-ratio: 1;
  }
  .goods-body {
    padding: 12px;
  }
  .condition {
    top: 9px;
    left: 9px;
    font-size: 8px;
    padding: 4px 6px;
  }
  h3 {
    font-size: 11px;
    height: 40px;
    margin-bottom: 10px;
  }
  .price {
    font-size: 20px;
  }
  .wanted {
    font-size: 8px;
  }
  .seller {
    font-size: 9px;
  }
  .card-eyebrow {
    font-size: 8px;
  }
}
</style>
