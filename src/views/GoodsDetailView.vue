<script setup>
import { computed } from "vue";
import { goods } from "@/data/market.js";
import ProductArt from "@/components/ProductVisual.vue";
import { useRouter } from "vue-router";
const router = useRouter();
function goBack() {
  const back = router.options.history.state.back;
  if (
    typeof back === "string" &&
    back.startsWith("/") &&
    !back.startsWith("//")
  )
    router.back();
  else router.push("/");
}
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
      <button class="back-link" @click="goBack">← 返回商品列表</button>
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
        title="此商品为展示示例，交易与联系卖家尚未开放。"
        type="info"
        :closable="false"
      />
      <div class="detail-actions">
        <el-button type="primary" disabled>发起交易（尚未开放）</el-button
        ><el-button disabled>联系卖家（尚未开放）</el-button>
      </div>
      <p class="detail-help">
        购买前请核对成色、配件和瑕疵。此页不会创建订单或收取费用。
      </p>
    </div>
  </div>
  <el-result
    v-else
    icon="info"
    title="暂时没有这件商品"
    sub-title="这件商品可能已移除，返回列表寻找其他好物。"
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
