import axios from "axios";
import { ElMessage } from "element-plus";
import { getToken } from "./auth.js";

const request = axios.create({ baseURL: "/api", timeout: 15000 });
let unauthorizedHandler = async () => {};
let unauthorizedTask = null;

// 在 main.js 中注入，避免 request -> router -> store -> api 的循环依赖。
export function setUnauthorizedHandler(handler) {
  unauthorizedHandler = handler;
}

async function reportError(error, config = {}) {
  if (axios.isCancel(error)) throw error;
  if (Number(error.status) === 401 && config.authFailureRedirect !== false) {
    if (!unauthorizedTask) {
      ElMessage.error("登录已失效，请重新登录");
      unauthorizedTask = Promise.resolve()
        .then(unauthorizedHandler)
        .finally(() => {
          unauthorizedTask = null;
        });
    }
    await unauthorizedTask;
  } else if (!config.inlineError) {
    ElMessage.error(error.message || "请求失败，请稍后重试");
  }
  throw error;
}

request.interceptors.request.use((config) => {
  const token = getToken();
  if (token && config.skipAuth !== true)
    config.headers.set("Authorization", `Bearer ${token}`);
  return config;
});

request.interceptors.response.use(
  (response) => {
    const body = response.data;
    // 约定业务包裹格式 { code: 0 或 200, message, data }，也兼容普通 JSON。
    if (body && typeof body === "object" && Object.hasOwn(body, "code")) {
      if (![0, 200].includes(Number(body.code))) {
        const error = new Error(body.message || "操作失败");
        error.status = Number(body.code);
        error.response = response;
        return reportError(error, response.config);
      }
      return body.data;
    }
    return body;
  },
  (error) => {
    if (axios.isCancel(error)) return Promise.reject(error);
    error.status = error.response?.status;
    const messages = {
      400: "请求参数有误",
      401: "账号或密码错误，或登录已失效",
      403: "没有操作权限",
      404: "请求的资源不存在",
      500: "服务器异常，请稍后重试",
    };
    error.message =
      error.response?.data?.message ||
      (error.code === "ECONNABORTED" ? "请求超时，请稍后重试" : null) ||
      messages[error.status] ||
      (error.response
        ? "请求失败，请稍后重试"
        : "网络连接失败，请检查网络或后端服务");
    return reportError(error, error.config);
  },
);

export default request;
