<script setup>
import { computed } from "vue";
import { goods } from "@/data/market.js";
import ProductVisual from "@/components/ProductVisual.vue";
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
  <div v-if="product" class="detail-page">
    <nav class="detail-breadcrumb" aria-label="商品路径"><button class="back-link" @click="goBack">返回商品列表</button><span aria-hidden="true">/</span><span>商品详情</span></nav>
    <article class="detail-card">
      <div class="detail-art"><ProductVisual :kind="product.kind" :color="product.color" :accent="product.accent" /></div>
      <div class="detail-info">
        <h1>{{ product.title }}</h1>
        <div class="detail-tags"><span>{{ product.condition }}</span><span>{{ product.location }}</span><span>{{ product.wanted }} 人想要</span></div>
        <p class="detail-price"><small>¥</small>{{ product.price.toLocaleString() }}<del>原价 ¥{{ product.original.toLocaleString() }}</del></p>
        <div class="detail-seller"><span :style="{ background: product.avatar }">{{ product.seller.slice(0, 1) }}</span><div><strong>{{ product.seller }}</strong><small>{{ product.location }} · 个人闲置</small></div></div>
        <h2>物品说明</h2>
        <p class="detail-description">成色：{{ product.condition }}。这件好物来自 {{ product.seller }} 的个人闲置，愿它在新的生活里继续发光。</p>
        <div class="availability-note"><strong>商品展示示例</strong><p>交易和联系卖家暂未开放，此页不会创建订单或收取费用。</p></div>
        <div class="detail-actions"><el-button type="primary" disabled>发起交易（尚未开放）</el-button><el-button disabled>联系卖家（尚未开放）</el-button></div>
        <p class="detail-help">购买前请核对成色、配件和瑕疵。</p>
      </div>
    </article>
  </div>
  <el-result v-else icon="info" title="暂时没有这件商品" sub-title="这件商品可能已移除，返回列表寻找其他好物。"><template #extra><el-button @click="$router.push('/')">返回集市</el-button></template></el-result>
</template>
<style scoped>
.detail-breadcrumb { display: flex; align-items: center; gap: 16px; margin-bottom: 16px; color: var(--text-secondary); font-size: 13px; }
.detail-card { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); overflow: hidden; }
.detail-art { min-height: 560px; }
.detail-art :deep(.product-photo) { object-fit: cover; }
.detail-info { min-width: 0; padding: 36px; }
.detail-info h1 { font-size: 26px; line-height: 1.6; font-weight: 600; margin-bottom: 16px; }
.detail-tags { display: flex; flex-wrap: wrap; gap: 12px; align-items: center; font-size: 13px; color: var(--text-secondary); }
.detail-tags > span:first-child { background: var(--active); color: var(--text); border-radius: 4px; padding: 3px 9px; }
.detail-price { display: flex; align-items: baseline; gap: 4px; font-size: 36px; color: var(--accent); font-weight: 650; font-variant-numeric: tabular-nums; margin: 24px 0; }
.detail-price small { font-size: 20px; font-weight: 500; }
.detail-price del { font-size: 13px; font-weight: 400; color: var(--text-secondary); margin-left: 12px; }
.detail-seller { display: flex; align-items: center; gap: 12px; padding-block: 20px; border-block: 1px solid var(--line); font-size: 14px; }
.detail-seller > span { display: grid; place-items: center; width: 40px; height: 40px; border-radius: 50%; color: #3d4236; }
.detail-seller strong { font-weight: 550; }
.detail-seller small { display: block; font-size: 12px; color: var(--text-secondary); margin-top: 3px; }
.detail-info h2 { font-size: 17px; margin: 24px 0 10px; }
.detail-description { font-size: 14px; line-height: 1.9; margin: 0 0 24px; }
.detail-actions { display: flex; gap: 12px; flex-wrap: wrap; margin-top: 24px; }
.detail-actions .el-button { margin: 0; }
.detail-help { font-size: 12px; color: var(--text-secondary); margin: 16px 0 0; }
@media (max-width: 1000px) { .detail-info { padding: 28px; } .detail-info h1 { font-size: 22px; } }
@media (max-width: 700px) { .detail-card { grid-template-columns: 1fr; } .detail-art { min-height: 0; aspect-ratio: 1.1; } .detail-info { padding: 24px; } .detail-info h1 { font-size: 22px; } .detail-price { font-size: 32px; } .detail-actions { flex-direction: column; } }
</style>
