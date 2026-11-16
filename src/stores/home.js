import { defineStore } from 'pinia';
import { ref } from 'vue';
import { getRecommendationsApi } from '@/api/home.js';

export const useHomeStore = defineStore('home', () => {
  const data = ref(null);
  const loading = ref(false);
  const error = ref('');
  async function load() {
    if (loading.value) return;
    loading.value = true;
    error.value = '';
    try {
      const result = await getRecommendationsApi();
      if (!result || !Array.isArray(result.hotSearches)) {
        throw new Error('首页推荐数据格式不正确');
      }
      data.value = result;
    } catch (e) {
      error.value = e.message || '首页推荐加载失败';
    } finally {
      loading.value = false;
    }
  }
  return { data, loading, error, load };
});
