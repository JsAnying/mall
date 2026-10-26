<script setup>
import AppHeader from "@/components/AppHeader.vue";
import HelpPanel from "@/components/HelpPanel.vue";
</script>

<template>
  <a class="skip-link" href="#main-content">跳至主要内容</a>
  <AppHeader />
  <main id="main-content" class="page" tabindex="-1"><RouterView /></main>
  <footer class="app-support">
    <div class="footer-brand"><strong>拾光闲置</strong><span>好物有下一站，生活有新可能。</span></div>
    <span>商品与价格为展示示例 · 交易暂未开放</span><HelpPanel />
  </footer>
</template>
