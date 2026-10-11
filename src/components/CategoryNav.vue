<script setup>
import { computed, ref } from "vue";
import { categories } from "@/data/market.js";
import { categoryTypes } from "@/data/categoryTypes.js";
import MarketIcon from "./MarketIcon.vue";
defineProps({
  activeCategory: { type: String, default: "all" },
  activeType: { type: String, default: "" },
});
const emit = defineEmits(["select"]);
const openId = ref("");
const openCategory = computed(() =>
  categories.find((category) => category.id === openId.value),
);
function closeOnFocusOut(event) {
  if (!event.currentTarget.contains(event.relatedTarget)) openId.value = "";
}
function select(type) {
  emit("select", { category: openId.value, type });
  openId.value = "";
}
</script>
<template>
  <aside
    class="category-panel"
    aria-label="商品分类"
    @mouseleave="openId = ''"
    @focusout="closeOnFocusOut"
    @keydown.esc.stop.prevent="openId = ''"
  >
    <div class="category-heading">
      <span class="category-grid">▦</span>
      <h2>好物分类</h2>
      <span>发现所爱</span>
    </div>
    <button
      v-for="category in categories"
      :key="category.id"
      class="category-item"
      :class="{
        active: activeCategory === category.id || openId === category.id,
      }"
      :aria-expanded="openId === category.id"
      :aria-controls="`category-types-${category.id}`"
      @mouseenter="openId = category.id"
      @focus="openId = category.id"
      @click="openId = category.id"
    >
      <span class="category-icon"
        ><MarketIcon :name="category.icon" :size="21" /></span
      ><span class="category-name"
        >{{ category.name }}<small>{{ category.hint }}</small></span
      ><MarketIcon class="category-chevron" name="chevron" :size="12" />
    </button>
    <div class="category-foot">
      <span class="live-dot"></span>发现所爱，慢慢挑选
    </div>
    <Transition name="flyout">
      <section
        v-if="openCategory"
        :id="`category-types-${openId}`"
        class="category-flyout"
        :aria-label="`${openCategory.name}商品类型`"
      >
        <div class="flyout-heading">
          <div>
            <span>发现更多好物</span>
            <h3>
              <MarketIcon :name="openCategory.icon" :size="23" />{{
                openCategory.name
              }}
            </h3>
          </div>
          <button class="view-all" @click="select()">
            查看全部 <MarketIcon name="arrow" :size="15" />
          </button>
        </div>
        <div
          v-for="group in categoryTypes[openId]"
          :key="group.title"
          class="type-group"
        >
          <h4>{{ group.title }}</h4>
          <div class="type-links">
            <button
              v-for="type in group.items"
              :key="type.id"
              :class="{
                selected: activeCategory === openId && activeType === type.id,
              }"
              @click="select(type.id)"
            >
              {{ type.name }}
            </button>
          </div>
        </div>
        <div class="flyout-foot">
          <MarketIcon
            name="spark"
            :size="15"
          />点击商品类型，发现属于你的心动闲置
        </div>
      </section>
    </Transition>
  </aside>
</template>
<style scoped>
.category-panel {
  position: relative;
  z-index: 10;
  background: #fffefa;
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 17px 10px 12px;
}
.category-heading {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 9px 13px;
  border-bottom: 1px solid #f3f3f5;
  margin-bottom: 5px;
}
.category-grid {
  color: var(--accent);
  font-size: 23px;
}
.category-heading h2 {
  font-size: 15px;
  margin: 0;
}
.category-heading > span:last-child {
  margin-left: auto;
  font-size: 9px;
  color: #b0afb6;
}
.category-item {
  width: 100%;
  text-align: left;
  display: flex;
  align-items: center;
  gap: 11px;
  border-radius: 9px;
  padding: 9px 9px;
  transition: background 0.2s;
}
.category-item:hover,
.category-item.active {
  background: #f6eee5;
  color: var(--accent);
}
.category-icon {
  color: #696874;
  display: flex;
}
.category-item.active .category-icon {
  color: var(--accent);
}
.category-name {
  font-size: 12px;
  font-weight: 550;
}
.category-name small {
  display: block;
  font-size: 9px;
  color: #aaa9b1;
  margin-top: 5px;
  font-weight: 400;
}
.category-chevron {
  color: #bdbcc2;
  margin-left: auto;
}
.category-foot {
  margin: 10px 9px 0;
  border-top: 1px solid #f1f1f3;
  padding-top: 14px;
  font-size: 10px;
  color: #a1a0a9;
  display: flex;
  align-items: center;
  gap: 7px;
}
.live-dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: #78ad8a;
}
.category-flyout {
  position: absolute;
  top: -1px;
  left: calc(100% + 12px);
  width: min(580px, calc(100vw - 310px));
  padding: 26px;
  background: #fffefa;
  border: 1px solid var(--line);
  border-radius: 16px;
  box-shadow: 0 18px 48px #35252c24;
  z-index: 11;
}
.category-flyout::before {
  content: "";
  position: absolute;
  left: -14px;
  top: 0;
  width: 14px;
  height: 100%;
}
.flyout-heading {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 20px;
  border-bottom: 1px solid #f2eff1;
}
.flyout-heading > div > span {
  font-size: 10px;
  color: #a39ba3;
  letter-spacing: 1px;
}
.flyout-heading h3 {
  display: flex;
  align-items: center;
  gap: 9px;
  margin: 8px 0 0;
  font-size: 21px;
}
.flyout-heading h3 svg {
  color: var(--accent);
}
.view-all {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: var(--accent);
}
.type-group {
  display: grid;
  grid-template-columns: 85px minmax(0, 1fr);
  gap: 15px;
  padding: 23px 0;
  border-bottom: 1px solid #f4f2f4;
}
.type-group h4 {
  font-size: 12px;
  margin: 6px 0 0;
  color: #57505e;
}
.type-links {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 10px;
}
.type-links button {
  font-size: 12px;
  color: #827987;
  background: #f3f4ed;
  border-radius: 7px;
  padding: 7px 10px;
  transition:
    background 0.15s,
    color 0.15s;
}
.type-links button:hover,
.type-links button.selected {
  color: var(--accent);
  background: #f6eee5;
}
.flyout-foot {
  display: flex;
  gap: 7px;
  align-items: center;
  color: #b0a7b0;
  font-size: 10px;
  padding-top: 19px;
}
.flyout-enter-active,
.flyout-leave-active {
  transition:
    opacity 0.12s,
    transform 0.12s;
}
.flyout-enter-from,
.flyout-leave-to {
  opacity: 0;
  transform: translateX(-5px);
}
@media (max-width: 800px) {
  .category-panel {
    padding: 12px;
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
  .category-heading,
  .category-foot,
  .category-chevron,
  .category-name small {
    display: none;
  }
  .category-item {
    padding: 9px 6px;
    gap: 7px;
  }
  .category-name {
    font-size: 11px;
  }
  .category-flyout {
    top: calc(100% + 8px);
    left: 0;
    width: 100%;
    padding: 20px;
  }
  .category-flyout::before {
    left: 0;
    top: -10px;
    height: 10px;
    width: 100%;
  }
}
@media (max-width: 520px) {
  .category-icon svg {
    width: 18px;
  }
  .type-group {
    grid-template-columns: 1fr;
    gap: 10px;
    padding: 16px 0;
  }
  .flyout-heading h3 {
    font-size: 18px;
  }
  .type-links {
    gap: 7px;
  }
  .category-flyout {
    padding: 18px;
  }
}
</style>
