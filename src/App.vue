<script setup>
import AppHeader from "@/components/AppHeader.vue";
import HelpPanel from "@/components/HelpPanel.vue";
</script>

<template>
  <a class="skip-link" href="#main-content">跳至主要内容</a>
  <AppHeader />
  <main id="main-content" class="page" tabindex="-1"><RouterView /></main>
  <footer class="app-support">
    <span>示例浏览 · 交易服务尚未开放</span><HelpPanel />
  </footer>
</template>
