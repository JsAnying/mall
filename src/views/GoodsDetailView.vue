<script setup>
import { computed } from "vue";
import { goods } from "@/data/market.js";
import ProductArt from "@/components/ProductVisual.vue";
const props = defineProps({ id: { type: String, required: true } });
const product = computed(() =>
  goods.find((item) => String(item.id) === props.id),
);
</script>
<template>
  <div v-if="product" class="detail-card">
    <div class="detail-art">
      <ProductArt
        :kind="product.kind"
        :color="product.color"
        :accent="product.accent"
      />
    </div>
    <div class="detail-info">
      <RouterLink class="back-link" to="/">← 返回集市</RouterLink>
      <p class="detail-label">个人闲置 · {{ product.condition }}</p>
      <h1>{{ product.title }}</h1>
      <p class="detail-price">
        <small>¥</small>{{ product.price.toLocaleString()
        }}<del>原价 ¥{{ product.original }}</del>
      </p>
      <div class="detail-seller">
        <span :style="{ background: product.avatar }">{{
          product.seller.slice(0, 1)
        }}</span>
        <div>
          {{ product.seller
          }}<small>{{ product.location }} · {{ product.wanted }} 人想要</small>
        </div>
      </div>
      <h2>好物的下一站，是你吗？</h2>
      <p class="detail-description">
        成色：{{ product.condition }}。这件好物来自
        {{ product.seller }} 的个人闲置，愿它在新的生活里继续发光。
      </p>
      <el-alert
        title="Mock 商品展示，交易与联系卖家功能待后端接入。"
        type="info"
        :closable="false"
      />
    </div>
  </div>
  <el-result
    v-else
    icon="info"
    title="暂时没有这件商品"
    sub-title="该商品不在当前 Mock 数据中"
    ><template #extra
      ><el-button @click="$router.push('/')">返回集市</el-button></template
    ></el-result
  >
</template>
<style scoped>
.detail-card {
  display: grid;
  grid-template-columns: 1fr 1fr;
  background: white;
  border-radius: 16px;
  overflow: hidden;
  border: 1px solid #eae9ee;
}
.detail-art {
  min-height: 450px;
}
.detail-info {
  padding: 40px;
}
.back-link {
  font-size: 12px;
  color: #92909b;
}
.detail-label {
  color: #ef4741;
  font-size: 12px;
  margin-top: 30px;
}
.detail-info h1 {
  font-size: 25px;
  line-height: 1.6;
}
.detail-price {
  font-size: 36px;
  color: #ef4741;
  font-weight: 700;
}
.detail-price small {
  font-size: 20px;
  margin-right: 5px;
}
.detail-price del {
  color: #b1aeb7;
  font-size: 12px;
  margin-left: 15px;
  font-weight: 400;
}
.detail-seller {
  display: flex;
  align-items: center;
  gap: 12px;
  border-block: 1px solid #f0eff3;
  padding: 18px 0;
  font-size: 13px;
}
.detail-seller > span {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: grid;
  place-items: center;
}
.detail-seller small {
  display: block;
  color: #a4a0ac;
  font-size: 11px;
  margin-top: 5px;
}
.detail-info h2 {
  font-size: 16px;
  margin-top: 25px;
}
.detail-description {
  font-size: 13px;
  line-height: 1.9;
  color: #97939f;
  margin-bottom: 24px;
}
@media (max-width: 700px) {
  .detail-card {
    grid-template-columns: 1fr;
  }
  .detail-art {
    min-height: 0;
    aspect-ratio: 1;
  }
  .detail-info {
    padding: 24px;
  }
}
</style>
