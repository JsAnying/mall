<script setup>
import { computed, ref } from "vue";
import { useRoute } from "vue-router";
const opened = ref(false);
const route = useRoute();
const topic = computed(() =>
  route.path === "/publish"
    ? "publish"
    : route.path.includes("orders")
      ? "orders"
      : route.path.includes("login") || route.path.includes("register")
        ? "account"
        : "browse",
);
const topics = {
  browse: {
    title: "找到适合你的闲置",
    steps: [
      "输入商品名或品牌，按 Enter 搜索。",
      "选择分类，再按价格排序；点击筛选条件可以单独移除。",
      "进入详情查看成色、价格和所在城市，返回后继续浏览。",
    ],
  },
  account: {
    title: "登录与注册",
    steps: [
      "已有账号直接登录；新用户先注册。",
      "用户名为 3–32 位字母、数字或下划线；密码为 6–64 位。",
      "登录失败后内容仍保留，请核对信息后重试。账号服务尚未开放时，可以返回首页浏览。",
    ],
  },
  publish: {
    title: "准备发布信息",
    steps: [
      "依次填写分类、商品信息、成色与价格。描述中注明使用情况和瑕疵。",
      "点击“保存草稿”保存至此浏览器，下次可继续填写。",
      "用“预览信息”检查内容。当前可准备草稿，正式发布尚未开放。",
    ],
  },
  orders: {
    title: "查看买入和卖出记录",
    steps: [
      "“我买到的”查看买入，“我卖出的”查看卖出。",
      "订单服务尚未开放，此页面不会生成或显示虚构的交易记录。",
      "开放后：买家发起交易 → 卖家确认 → 买家确认完成。",
    ],
  },
};
</script>
<template>
  <button class="help-trigger" @click="opened = true">帮助与使用说明</button>
  <el-drawer v-model="opened" title="使用帮助" size="min(420px, 100vw)">
    <h2>{{ topics[topic].title }}</h2>
    <ol class="help-steps">
      <li v-for="step in topics[topic].steps" :key="step">{{ step }}</li>
    </ol>
    <el-divider />
    <h3>常见问题</h3>
    <el-collapse>
      <el-collapse-item title="为什么无法交易或发布？" name="availability"
        >当前商品为展示示例。交易、聊天、图片上传和正式发布尚未开放；保存草稿不会上架商品。</el-collapse-item
      >
      <el-collapse-item title="草稿和搜索记录存在哪里？" name="storage"
        >仅保存在当前浏览器。清理浏览器数据或更换设备后可能丢失，请勿在草稿中填写敏感信息。</el-collapse-item
      >
      <el-collapse-item title="如何更快地搜索？" name="shortcut"
        >在非输入区域按 /，或按 Ctrl / ⌘ + K，可聚焦搜索框；按 Escape
        关闭搜索建议。</el-collapse-item
      >
    </el-collapse>
    <el-button class="help-close" @click="opened = false"
      >关闭帮助，继续操作</el-button
    >
  </el-drawer>
</template>
<style scoped>
.help-trigger {
  font-size: 14px;
  text-decoration: underline;
  text-underline-offset: 4px;
  min-height: 44px;
  color: var(--text-secondary);
}
.help-steps {
  padding-left: 24px;
  line-height: 1.8;
}
.help-steps li {
  padding: 8px 0;
}
.help-close {
  margin-top: 28px;
}
.el-collapse {
  line-height: 1.8;
}
</style>
