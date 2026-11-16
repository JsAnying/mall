<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { filterGoods } from '@/data/market.js';
import { getCategoriesApi } from '@/api/category.js';
import GoodsCard from '@/components/GoodsCard.vue';

const route = useRoute();
const router = useRouter();
const categories = ref([]);
const error = ref('');
async function load() {
  error.value = '';
  try { categories.value = await getCategoriesApi(); }
  catch (e) { error.value = e.message || '分类加载失败'; }
}
onMounted(load);
const category = computed(() => typeof route.query.category === 'string' ? route.query.category : 'all');
const type = computed(() => typeof route.query.type === 'string' ? route.query.type : '');
const group = computed(() => typeof route.query.group === 'string' ? route.query.group : '');
const current = computed(() => categories.value.find(item => item.id === category.value));
const groupTypes = computed(() => current.value?.groups?.find(item => item.title === group.value)?.items || []);
const title = computed(() => type.value ? current.value?.groups?.flatMap(g => g.items).find(t => t.id === type.value)?.name || type.value : group.value || current.value?.name || '全部好物');
const sort = computed(() => typeof route.query.sort === 'string' ? route.query.sort : 'recommended');
const goods = computed(() => {
  let result = filterGoods({ category: category.value, type: type.value });
  if (group.value && !type.value) result = result.filter(item => groupTypes.value.some(t => t.id === item.kind));
  if (sort.value === 'priceAsc') result = [...result].sort((a, b) => a.price - b.price);
  if (sort.value === 'priceDesc') result = [...result].sort((a, b) => b.price - a.price);
  return result;
});
function setSort(event) { router.replace({ path: '/browse', query: { ...route.query, sort: event.target.value === 'recommended' ? undefined : event.target.value } }); }
</script>

<template>
  <section class="browse" aria-labelledby="browse-title">
    <RouterLink to="/" class="back-link">← 返回首页</RouterLink>
    <div class="heading"><div><h1 id="browse-title">{{ title }}</h1><p>展示商品 · 交易暂未开放</p></div><span>{{ goods.length }} 件好物</span></div>
    <div v-if="error" class="error-panel" role="alert"><p>{{ error }}</p><button @click="load">重新加载分类</button></div>
    <div class="toolbar"><span>商品列表</span><label>排序 <select :value="sort" @change="setSort"><option value="recommended">默认推荐</option><option value="priceAsc">价格从低到高</option><option value="priceDesc">价格从高到低</option></select></label></div>
    <div v-if="goods.length" class="goods-grid"><GoodsCard v-for="item in goods" :key="item.id" :goods="item" /></div>
    <div v-else class="empty"><h2>暂时没有找到好物</h2><p>试试其他分类，或浏览全部商品。</p><RouterLink class="text-link" to="/browse">查看全部好物 →</RouterLink></div>
  </section>
</template>

<style scoped>
.browse { background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); padding: 24px; }
.heading { display:flex; justify-content:space-between; align-items:end; gap:16px; margin:16px 0 24px; }
.heading h1 { margin:0; } .heading p,.heading span { color:var(--text-secondary); margin:4px 0 0; }
.toolbar { display:flex; justify-content:space-between; align-items:center; gap:16px; border-block:1px solid var(--line); padding:14px 0; margin-bottom:24px; font-weight:600; }
.toolbar label { font-weight:400; color:var(--text-secondary); } select { min-height:44px; margin-left:8px; padding:8px; border:1px solid var(--control-border); border-radius:8px; background:var(--surface); }
.goods-grid { display:grid; grid-template-columns:repeat(5,minmax(0,1fr)); gap:32px 20px; }
.empty { padding:48px 0; color:var(--text-secondary); } .empty h2 { color:var(--text); }
@media(max-width:1100px) { .goods-grid { grid-template-columns:repeat(3,minmax(0,1fr)); } }
@media(max-width:600px) { .browse { padding:16px; } .goods-grid { grid-template-columns:repeat(2,minmax(0,1fr)); gap:24px 12px; } }
</style>
