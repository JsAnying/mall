<script setup>
import { computed, ref } from "vue";
import { categories } from "@/data/market.js";
import { categoryTypes } from "@/data/categoryTypes.js";
import MarketIcon from "./MarketIcon.vue";
defineProps({ activeCategory: { type: String, default: "all" }, activeType: { type: String, default: "" } });
const emit = defineEmits(["select"]);
const openId = ref("");
const openCategory = computed(() => categories.find((category) => category.id === openId.value));
const triggerRefs = ref({});
function closeOnFocusOut(event) {
  if (!event.currentTarget.contains(event.relatedTarget)) openId.value = "";
}
function select(category, type) {
  emit("select", { category, type });
  openId.value = "";
}
function closeMenu() {
  const trigger = triggerRefs.value[openId.value];
  openId.value = "";
  trigger?.focus();
}
function openOnHover(id) {
  if (window.matchMedia("(hover: hover) and (pointer: fine)").matches) openId.value = id;
}
function closeOnMouseLeave() {
  if (window.matchMedia("(hover: hover) and (pointer: fine)").matches) openId.value = "";
}
</script>
<template>
  <aside class="category-panel" aria-label="商品分类" @mouseleave="closeOnMouseLeave" @focusout="closeOnFocusOut" @keydown.esc.stop.prevent="closeMenu">
    <h2>好物分类</h2>
    <div class="category-list">
      <button class="category-all" :class="{ active: activeCategory === 'all' }" :aria-pressed="activeCategory === 'all'" @click="select('all')"><MarketIcon name="grid" :size="18" />全部好物</button>
      <div v-for="category in categories" :key="category.id" class="category-entry" @mouseenter="openOnHover(category.id)">
        <button :ref="(el) => { if (el) triggerRefs[category.id] = el; }" class="category-item" :class="{ active: activeCategory === category.id, expanded: openId === category.id }" :aria-expanded="openId === category.id" :aria-controls="openId === category.id ? `category-types-${category.id}` : undefined" @click="openId = category.id">
          <MarketIcon :name="category.icon" :size="18" /><span>{{ category.name }}<small>{{ category.hint }}</small></span><MarketIcon class="category-chevron" name="chevron" :size="13" />
        </button>
        <section v-if="openCategory && openId === category.id" :id="`category-types-${category.id}`" class="category-flyout" :aria-label="`${category.name}商品类型`">
          <div class="flyout-heading"><h3>{{ category.name }}</h3><button class="view-all" @click="select(category.id)">查看全部<MarketIcon name="arrow" :size="16" /></button><button class="close-flyout" aria-label="关闭商品分类" @click="closeMenu"><MarketIcon name="close" :size="18" /></button></div>
          <div v-for="group in categoryTypes[category.id]" :key="group.title" class="type-group">
            <h4>{{ group.title }}</h4>
            <div class="type-links"><button v-for="type in group.items" :key="type.id" :class="{ selected: activeCategory === category.id && activeType === type.id }" :aria-pressed="activeCategory === category.id && activeType === type.id" @click="select(category.id, type.id)">{{ type.name }}</button></div>
          </div>
        </section>
      </div>
    </div>
    <div class="category-note"><MarketIcon name="heart" :size="18" /><p>喜欢可以继续，<br />生活可以轻一点。</p></div>
  </aside>
</template>
<style scoped>
.category-panel { position: relative; z-index: 20; min-width: 0; padding-top: 10px; }
.category-panel h2 { font-size: 14px; margin: 0 12px 16px; font-weight: 650; }
.category-list { display: grid; gap: 4px; }
.category-all, .category-item { display: flex; align-items: center; gap: 12px; width: 100%; min-height: 50px; padding: 10px 12px; border-radius: var(--control-radius); text-align: left; font-size: 14px; color: var(--text-secondary); transition: background 150ms; }
.category-all { margin-bottom: 4px; }
.category-item > span { min-width: 0; }
.category-item small { display: block; font-size: 11px; margin-top: 4px; font-weight: 400; color: var(--text-secondary); white-space: nowrap; }
.category-item.active, .category-all.active { background: var(--active); color: var(--text); font-weight: 600; }
.category-item:hover, .category-item.expanded, .category-all:hover { background: #e8eeeb; color: var(--text); }
.category-chevron { margin-left: auto; }
.category-note { display: flex; align-items: flex-start; gap: 10px; margin: 24px 12px 0; color: var(--text-secondary); }
.category-note p { font-size: 12px; margin: 0; line-height: 1.9; }
.category-note svg { margin-top: 3px; }
.category-flyout { position: absolute; left: calc(100% + 12px); top: 0; width: min(540px, calc(100vw - 280px)); padding: 24px; border-radius: var(--radius); background: var(--surface); box-shadow: 0 12px 40px #182c1f24; }
.category-flyout::before { content: ''; position: absolute; left: -14px; top: 0; width: 14px; height: 100%; }
.flyout-heading { display: flex; align-items: center; gap: 12px; margin-bottom: 12px; }
.flyout-heading h3 { margin: 0 auto 0 0; font-size: 20px; }
.view-all { display: inline-flex; align-items: center; gap: 8px; min-height: 44px; font-size: 13px; color: var(--accent); }
.close-flyout { display: inline-grid; place-items: center; width: 44px; min-height: 44px; color: var(--text-secondary); }
.type-group { display: grid; grid-template-columns: 72px minmax(0, 1fr); gap: 12px; padding: 16px 0; border-top: 1px solid var(--line); }
.type-group h4 { font-size: 13px; margin: 12px 0 0; color: var(--text-secondary); font-weight: 500; }
.type-links { display: flex; flex-wrap: wrap; gap: 4px 8px; }
.type-links button { min-height: 44px; padding: 8px 12px; border-radius: var(--control-radius); font-size: 14px; }
.type-links button:hover, .type-links button.selected { background: var(--active); color: var(--accent); }
@media (max-width: 1100px) { .category-item { padding-inline: 8px; gap: 9px; } .category-item small { font-size: 11px; } }
@media (max-width: 800px) {
  .category-panel { padding: 0; }
  .category-panel h2, .category-note, .category-item small, .category-chevron { display: none; }
  .category-list { display: flex; gap: 6px; overflow-x: auto; scrollbar-width: thin; padding-bottom: 8px; }
  .category-entry { flex-shrink: 0; }
  .category-all, .category-item { min-height: 44px; width: auto; padding: 8px 12px; white-space: nowrap; gap: 8px; font-size: 13px; }
  .category-all { margin: 0; flex-shrink: 0; }
  .category-flyout { top: calc(100% + 4px); left: 0; width: 100%; max-height: 65vh; overflow-y: auto; padding: 20px; }
  .category-flyout::before { display: none; }
}
@media (max-width: 450px) { .type-group { grid-template-columns: 1fr; gap: 8px; } .type-group h4 { margin: 0; } .flyout-heading { gap: 4px; } .flyout-heading h3 { font-size: 18px; } .type-links button { padding-inline: 10px; } }
</style>
