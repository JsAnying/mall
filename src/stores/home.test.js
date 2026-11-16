import { beforeEach, expect, it, vi } from 'vitest';
import { createPinia, setActivePinia } from 'pinia';

vi.mock('@/api/home.js', () => ({ getRecommendationsApi: vi.fn() }));
import { getRecommendationsApi } from '@/api/home.js';
import { useHomeStore } from './home.js';

beforeEach(() => setActivePinia(createPinia()));

it('读取服务端推荐并支持失败后重试', async () => {
  const response = { hotSearches: ['相机'], banner: null };
  getRecommendationsApi.mockRejectedValueOnce(new Error('服务不可用')).mockResolvedValueOnce(response);
  const home = useHomeStore();
  await home.load();
  expect(home.error).toBe('服务不可用');
  await home.load();
  expect(home.error).toBe('');
  expect(home.data).toEqual(response);
  expect(home.loading).toBe(false);
});
