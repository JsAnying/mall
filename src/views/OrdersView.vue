<script setup>
import { computed } from "vue";
import { useRoute, useRouter } from "vue-router";
const route = useRoute(),
  router = useRouter();
const tab = computed({
  get: () => (route.query.role === "sell" ? "sell" : "buy"),
  set: (value) =>
    router.replace({
      path: route.path,
      query: { ...route.query, role: value },
    }),
});
</script>
<template>
  <div class="workspace-layout">
    <section class="workspace-main">
      <RouterLink class="back-action" to="/">← 返回首页</RouterLink>
      <div class="workspace-heading">
        <div>
          <span class="eyebrow">个人中心</span>
          <h1>我的订单</h1>
          <p>买入和卖出分开查看，交易进度清楚可见。</p>
        </div>
      </div>
      <el-tabs v-model="tab"
        ><el-tab-pane label="我买到的" name="buy" /><el-tab-pane
          label="我卖出的"
          name="sell"
      /></el-tabs>
      <div class="availability-note" role="status">
        <strong>订单服务尚未开放</strong>
        <p>
          当前无法读取{{
            tab === "buy" ? "买入" : "卖出"
          }}记录，不代表你没有订单。这里不会生成示例交易。
        </p>
      </div>
      <div class="service-empty">
        <span class="empty-symbol">▤</span>
        <h2>开放后，在这里跟进每笔交易</h2>
        <p>
          {{
            tab === "buy"
              ? "查看卖家确认情况，并在交付后确认完成。"
              : "查看买家的交易请求，确认交易并跟进交付。"
          }}
        </p>
        <RouterLink
          class="primary-link"
          :to="tab === 'buy' ? '/' : '/publish'"
          >{{ tab === "buy" ? "先逛逛商品" : "先准备发布草稿" }}</RouterLink
        >
      </div>
    </section>
    <aside class="workspace-aside">
      <span class="eyebrow">交易流程</span>
      <h2>每一步都有记录</h2>
      <ol>
        <li>买家发起交易</li>
        <li>卖家确认交易</li>
        <li>双方完成交付</li>
        <li>买家确认完成</li>
      </ol>
      <p>支付、物流和聊天服务尚未开放。请勿将展示页面视为付款凭证。</p>
    </aside>
  </div>
</template>
