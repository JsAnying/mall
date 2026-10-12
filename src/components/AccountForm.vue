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
    { required: true, message: "请输入密码", trigger: ["blur", "change"] },
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
      ElMessage.success("注册成功，请使用刚才的账号登录");
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
      <span class="eyebrow">拾光闲置 · 账号</span>
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
        {{ register ? "填写账号信息，注册后再登录。" : purpose }}
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
            :disabled="loading"
        /></el-form-item>
        <p v-if="register" class="field-hint">
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
            :disabled="loading"
        /></el-form-item>
        <p v-if="register" class="field-hint">
          6–64 位；可点击眼睛图标核对输入。请勿使用其他网站的密码。
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
                : "账号服务需开放后才能完成登录或注册。"
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
.account-layout {
  max-width: 960px;
  margin: 42px auto;
  display: grid;
  grid-template-columns: 1fr 1fr;
  border: 1px solid var(--line);
  border-radius: 16px;
  overflow: hidden;
  background: var(--surface);
}
.account-intro {
  background: #eaece1;
  padding: 38px;
  display: flex;
  flex-direction: column;
  gap: 18px;
}
.account-intro h1 {
  font-size: 30px;
  line-height: 1.5;
  margin: 0;
}
.account-intro p {
  line-height: 1.8;
  color: var(--text-secondary);
  margin: 0;
}
.account-intro img {
  width: 100%;
  max-height: 220px;
  object-fit: cover;
  border-radius: 12px;
}
.account-intro a {
  margin-top: auto;
  min-height: 44px;
  display: flex;
  align-items: center;
  font-size: 14px;
}
.account-panel {
  padding: 36px;
}
.account-tabs {
  display: flex;
  gap: 26px;
  border-bottom: 1px solid var(--line);
  margin-bottom: 28px;
}
.account-tabs a {
  padding: 12px 0;
  min-height: 44px;
}
.account-tabs .active {
  color: var(--accent);
  border-bottom: 2px solid var(--accent);
  font-weight: 600;
}
.account-panel h2 {
  font-size: 24px;
  margin: 0 0 8px;
}
.supporting-text {
  margin: 0 0 26px;
  color: var(--text-secondary);
  line-height: 1.6;
}
.field-hint {
  font-size: 13px;
  line-height: 1.6;
  margin: -6px 0 18px;
  color: var(--text-secondary);
}
.secondary-exit {
  display: block;
  text-align: center;
  min-height: 44px;
  padding: 12px;
  font-size: 14px;
}
.operation-status {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.6;
}
.error-panel {
  margin-bottom: 20px;
}
@media (max-width: 700px) {
  .account-layout {
    grid-template-columns: 1fr;
    margin: 0 auto;
  }
  .account-intro {
    padding: 22px;
  }
  .account-intro img,
  .account-intro p {
    display: none;
  }
  .account-intro h1 {
    font-size: 24px;
  }
  .account-panel {
    padding: 24px;
  }
  .account-intro a {
    margin: 0;
  }
}
</style>
