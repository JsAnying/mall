import { createRouter, createWebHistory } from 'vue-router'
import { pinia } from '@/stores/index.js'
import { useUserStore } from '@/stores/user.js'
import { scrollBehavior } from './scrollBehavior.js'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  scrollBehavior,
  routes: [
    { path: '/', name: 'home', component: () => import('@/views/HomeView.vue'), meta: { title: '闲置集市' } },
    { path: '/login', name: 'login', component: () => import('@/views/LoginView.vue'), meta: { title: '登录' } },
    { path: '/register', name: 'register', component: () => import('@/views/RegisterView.vue'), meta: { title: '注册' } },
    { path: '/goods/:id', name: 'goods-detail', props: true, component: () => import('@/views/GoodsDetailView.vue'), meta: { title: '商品详情' } },
    { path: '/publish', name: 'publish', component: () => import('@/views/PublishView.vue'), meta: { title: '发布闲置', requiresAuth: true } },
    { path: '/user/orders', name: 'orders', component: () => import('@/views/OrdersView.vue'), meta: { title: '我的订单', requiresAuth: true } },
    { path: '/:pathMatch(.*)*', name: 'not-found', component: () => import('@/views/NotFoundView.vue'), meta: { title: '页面不存在' } },
  ],
})

router.beforeEach((to) => {
  const user = useUserStore(pinia)
  if (to.meta.requiresAuth && !user.isLoggedIn) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
})
router.afterEach((to) => { document.title = `${to.meta.title || '闲置集市'} · 拾光闲置` })

export default router
