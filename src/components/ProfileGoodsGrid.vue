<script setup>
import { RouterLink } from 'vue-router'
import ProductVisual from '@/components/ProductVisual.vue'

defineProps({
  items: { type: Array, required: true },
  linkToGoods: Boolean,
})

const priceFormat = new Intl.NumberFormat('zh-CN', { maximumFractionDigits: 2 })
</script>

<template>
  <ul class="profile-goods">
    <li v-for="item in items" :key="item.id">
      <component
        :is="linkToGoods ? RouterLink : 'article'"
        :to="linkToGoods ? { name: 'goods-detail', params: { id: item.id }, query: { demo: '1' } } : undefined"
        class="profile-good"
      >
        <div class="profile-good-cover">
          <ProductVisual :kind="item.kind" :image-url="item.imageUrl" :color="item.color" :accent="item.accent" />
          <div v-if="item.status === 'SOLD'" class="sold-stamp">
            <svg viewBox="0 0 100 100" fill="none" aria-hidden="true">
              <circle cx="50" cy="50" r="46" fill="#24302b" fill-opacity=".84" />
              <circle cx="50" cy="50" r="45" stroke="#fff" stroke-width="3" stroke-dasharray="1 4" />
              <circle cx="50" cy="50" r="39" stroke="#fff" stroke-width="1.5" />
              <circle cx="50" cy="50" r="34" stroke="#fff" stroke-opacity=".7" />
            </svg>
            <strong>卖掉了</strong>
            <small lang="en">SOLD OUT</small>
          </div>
        </div>
        <h3 :title="item.title">{{ item.title }}</h3>
        <p class="profile-good-price">¥{{ priceFormat.format(item.price) }}</p>
        <p class="profile-good-seller">
          <span class="seller-initial" :style="{ backgroundColor: item.avatar }" aria-hidden="true">{{ item.seller.slice(0, 1) }}</span>
          <span class="seller-name">{{ item.seller }}</span>
        </p>
      </component>
    </li>
  </ul>
</template>

<style scoped>
.profile-goods {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 24px 20px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.profile-good { display: block; border-radius: 12px; }
.profile-good-cover {
  position: relative;
  aspect-ratio: 1;
  overflow: hidden;
  border-radius: 12px;
  background: var(--raised);
}
.profile-good h3 {
  margin: 10px 0 2px;
  overflow: hidden;
  font-size: 14px;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.profile-good-price {
  margin: 0;
  color: #bc391e;
  font-size: 18px;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
}
.profile-good-seller {
  display: flex;
  align-items: center;
  gap: 6px;
  margin: 6px 0 0;
  color: var(--text-secondary);
  font-size: 13px;
}
.seller-initial {
  display: grid;
  flex: 0 0 22px;
  height: 22px;
  place-items: center;
  border-radius: 50%;
  color: var(--text);
  font-size: 12px;
}
.seller-name { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.sold-stamp {
  position: absolute;
  inset: 50% auto auto 50%;
  display: flex;
  width: 68%;
  max-width: 108px;
  aspect-ratio: 1;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  transform: translate(-50%, -50%) rotate(-15deg);
  color: #fff;
  line-height: 1.25;
  text-align: center;
}
.sold-stamp svg { position: absolute; inset: 0; width: 100%; height: 100%; }
.sold-stamp strong, .sold-stamp small { position: relative; }
.sold-stamp strong { font-size: clamp(13px, 2vw, 19px); }
.sold-stamp small { margin-top: 2px; font-size: 11px; font-weight: 700; }

@media (max-width: 1000px) {
  .profile-goods { grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 20px 14px; }
}
@media (max-width: 580px) {
  .profile-goods { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
</style>
