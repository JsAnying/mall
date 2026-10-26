<script setup>
import { computed, reactive, ref, watch, onBeforeUnmount } from "vue";
import { useRoute, useRouter, onBeforeRouteLeave } from "vue-router";
import { ElMessage } from "element-plus";
import { useUserStore } from "@/stores/user.js";
import { registerApi } from "@/api/user.js";
import { safeRedirect } from "@/utils/auth.js";
import axios from "axios";
const props = defineProps({ register: Boolean });
const route = useRoute(),
  router = useRouter(),
  user = useUserStore();
const formRef = ref(),
  loading = ref(false),
  error = ref("");
const form = reactive({ username: "", password: "", confirmation: "" });
let controller;
const stopped = ref(false);
function cancelRequest() {
  stopped.value = true;
  controller?.abort();
}
onBeforeRouteLeave(cancelRequest);
onBeforeUnmount(cancelRequest);
const destination = computed(() => safeRedirect(route.query.redirect));
const purpose = computed(() =>
  destination.value.startsWith("/publish")
    ? "登录后继续准备发布信息"
    : destination.value.startsWith("/user/orders")
      ? "登录后查看你的买入和卖出记录"
      : "登录后管理你的闲置和订单",
);
const rules = computed(() => ({
  username: [
    {
      required: true,
      whitespace: true,
      message: "请输入用户名",
      trigger: ["blur", "change"],
    },
    ...(props.register
      ? [
          {
            pattern: /^[a-zA-Z0-9_]{3,32}$/,
            message: "用户名需为 3–32 位字母、数字或下划线",
            trigger: ["blur", "change"],
          },
        ]
      : []),
  ],
  password: [
    { required: true, whitespace: true, message: "请输入非空白密码", trigger: ["blur", "change"] },
    ...(props.register
      ? [
          {
            min: 6,
            max: 64,
            message: "密码长度为 6–64 位",
            trigger: ["blur", "change"],
          },
          {
            validator: (_, value, cb) =>
              cb(
                new TextEncoder().encode(value).length <= 72
                  ? undefined
                  : new Error("密码最多 72 个 UTF-8 字节，请缩短密码"),
              ),
            trigger: "blur",
          },
        ]
      : []),
  ],
  confirmation: [
    {
      validator: (_, value, cb) =>
        cb(
          value && value === form.password
            ? undefined
            : new Error("两次密码不一致，请重新确认"),
        ),
      trigger: ["blur", "change"],
    },
  ],
}));
watch(
  () => form.password,
  () => {
    if (props.register && form.confirmation)
      formRef.value?.validateField("confirmation").catch(() => {});
  },
);
async function submit() {
  if (loading.value) return;
  error.value = "";
  form.username = form.username.trim();
  if (!(await formRef.value.validate().catch(() => false))) return;
  formRef.value.clearValidate();
  loading.value = true;
  stopped.value = false;
  controller = new AbortController();
  try {
    const credentials = {
      username: form.username.trim(),
      password: form.password,
    };
    if (props.register) {
      await registerApi(credentials, { signal: controller.signal });
      ElMessage.success("注册成功，账号已创建；登录服务暂未开放");
      await router.replace({
        path: "/login",
        query: route.query.redirect ? { redirect: destination.value } : {},
      });
    } else {
      await user.login(credentials, { signal: controller.signal });
      ElMessage.success("登录成功");
      await router.replace(destination.value);
    }
  } catch (problem) {
    if (axios.isCancel(problem)) return;
    error.value =
      !problem.response && problem.config
        ? "暂时无法连接账号服务，请稍后重试。"
        : problem.message || "暂时无法完成，请稍后重试";
  } finally {
    loading.value = false;
  }
}
</script>
<template>
  <div class="account-layout">
    <aside class="account-intro">
      <h1>
        {{ register ? "让好物，继续被喜欢。" : "欢迎回来，继续你的发现。" }}
      </h1>
      <p>买入喜欢的，整理闲置的。<br />从一个简单的账号开始。</p>
      <img src="/images/tote.png" alt="自然光下的棕色手提包" /><RouterLink
        to="/"
        >← 返回首页，继续浏览</RouterLink
      >
    </aside>
    <section class="account-panel" :aria-busy="loading">
      <nav class="account-tabs" aria-label="账号操作">
        <RouterLink
          :class="{ active: !register }"
          :to="{ path: '/login', query: route.query }"
          >登录</RouterLink
        ><RouterLink
          :class="{ active: register }"
          :to="{ path: '/register', query: route.query }"
          >注册</RouterLink
        >
      </nav>
      <h2>{{ register ? "创建你的账号" : "登录账号" }}</h2>
      <p class="supporting-text">
        {{ register ? "创建账号，让每一份喜欢有新的开始。" : purpose }}
      </p>
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-position="top"
        @submit.prevent="submit"
      >
        <el-form-item label="用户名" prop="username"
          ><el-input
            v-model="form.username"
            autocomplete="username"
            :maxlength="register ? 32 : undefined"
            placeholder="请输入用户名"
            :aria-describedby="register ? 'username-hint' : undefined"
            :disabled="loading"
        /></el-form-item>
        <p v-if="register" id="username-hint" class="field-hint">
          3–32 位字母、数字或下划线，例如 xiaolin_01。
        </p>
        <el-form-item label="密码" prop="password"
          ><el-input
            v-model="form.password"
            type="password"
            show-password
            :autocomplete="register ? 'new-password' : 'current-password'"
            :maxlength="register ? 64 : undefined"
            placeholder="请输入密码"
            :aria-describedby="register ? 'password-hint' : undefined"
            :disabled="loading"
        /></el-form-item>
        <p v-if="register" id="password-hint" class="field-hint">
          6–64 位非空白密码，UTF-8 最多 72 字节；首尾空格会保留。
        </p>
        <el-form-item v-if="register" label="确认密码" prop="confirmation"
          ><el-input
            v-model="form.confirmation"
            type="password"
            show-password
            autocomplete="new-password"
            placeholder="再次输入密码"
            :disabled="loading"
        /></el-form-item>
        <div v-if="error" class="error-panel" role="alert">
          <strong>{{ register ? "注册未完成" : "登录未完成" }}</strong>
          <p>{{ error }}</p>
          <p>请核对输入后重试；服务暂时不可用时，可以返回首页浏览。</p>
          <button type="button" class="text-link" @click="submit">
            重试{{ register ? "注册" : "登录" }}
          </button>
        </div>
        <el-button
          class="full-width"
          type="primary"
          native-type="submit"
          :loading="loading"
          >{{
            loading
              ? register
                ? "正在创建账号…"
                : "正在登录…"
              : register
                ? "注册账号"
                : "登录并继续"
          }}</el-button
        >
        <el-button v-if="loading" class="full-width" @click="cancelRequest"
          >停止等待，继续编辑</el-button
        >
        <p class="operation-status" role="status" aria-live="polite">
          {{
            loading
              ? "正在连接账号服务，请稍候。"
              : stopped
                ? "已停止等待，输入仍保留。注册请求可能已被处理，如账号已存在可尝试登录。"
                : register ? "注册功能已开放；登录服务暂未开放。" : "登录服务暂未开放，你仍可以浏览商品。"
          }}
        </p>
      </el-form>
      <RouterLink class="secondary-exit" to="/"
        >暂不{{ register ? "注册" : "登录" }}，继续浏览</RouterLink
      >
    </section>
  </div>
</template>
<style scoped>
.account-layout { max-width: 1040px; margin: 32px auto; display: grid; grid-template-columns: 1fr 1fr; border: 1px solid var(--line); border-radius: var(--radius); overflow: hidden; background: var(--surface); }
.account-intro { padding: 40px; display: flex; flex-direction: column; background: var(--active); }
.account-intro h1 { font-size: 30px; line-height: 1.5; font-weight: 600; margin: 0 0 16px; }
.account-intro p { margin: 0 0 28px; color: var(--text-secondary); font-size: 14px; line-height: 1.9; }
.account-intro img { width: 100%; aspect-ratio: 1.2; object-fit: cover; border-radius: 12px; }
.account-intro > a { display: flex; align-items: center; min-height: 44px; margin-top: 24px; color: var(--text-secondary); font-size: 13px; }
.account-panel { min-width: 0; padding: 36px 40px; }
.account-tabs { display: flex; gap: 28px; margin-bottom: 28px; border-bottom: 1px solid var(--line); }
.account-tabs a { display: flex; align-items: center; min-height: 44px; padding-block: 8px; font-size: 14px; color: var(--text-secondary); }
.account-tabs .active { color: var(--text); border-bottom: 2px solid var(--accent); font-weight: 600; }
.account-panel h2 { font-size: 24px; font-weight: 600; margin: 0 0 8px; }
.supporting-text { font-size: 14px; margin: 0 0 24px; }
.field-hint { margin: -10px 0 20px; font-size: 12px; line-height: 1.7; }
.secondary-exit { display: flex; align-items: center; justify-content: center; min-height: 44px; margin-top: 8px; font-size: 13px; color: var(--text-secondary); }
.operation-status { margin-top: 16px; font-size: 12px; color: var(--text-secondary); line-height: 1.7; }
.error-panel { margin-bottom: 20px; }
.el-button + .el-button.full-width { margin: 12px 0 0; }
@media (max-width: 800px) { .account-layout { margin: 16px auto; } .account-intro, .account-panel { padding: 28px; } .account-intro h1 { font-size: 26px; } }
@media (max-width: 650px) {
  .account-layout { grid-template-columns: 1fr; margin: 0 auto; }
  .account-intro { padding: 24px; background: var(--raised); }
  .account-intro h1 { font-size: 22px; margin: 0; }
  .account-intro p, .account-intro img, .account-intro > a { display: none; }
  .account-panel { padding: 20px 24px 24px; }
  .account-tabs { margin-bottom: 24px; }
}
</style>
