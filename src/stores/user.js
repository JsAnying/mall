import { computed, ref } from "vue";
import { defineStore } from "pinia";
import { loginApi } from "@/api/user.js";
import {
  clearSession,
  getToken,
  getUserInfo,
  saveSession,
} from "@/utils/auth.js";

export const useUserStore = defineStore("user", () => {
  const token = ref(getToken());
  const userInfo = ref(getUserInfo());
  const isLoggedIn = computed(() => Boolean(token.value));

  async function login(credentials, options = {}) {
    const data = await loginApi(credentials, options);
    if (!data || typeof data.token !== "string" || !data.token.trim()) {
      throw new Error("登录接口未返回有效 Token，请检查接口格式");
    }
    saveSession(data.token, data.userInfo ?? null);
    token.value = data.token;
    userInfo.value = data.userInfo ?? null;
    return data;
  }

  function logout() {
    clearSession();
    token.value = "";
    userInfo.value = null;
  }

  return { token, userInfo, isLoggedIn, login, logout };
});
