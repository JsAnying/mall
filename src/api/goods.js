import request from "@/utils/request.js";

export function getGoodsDetailApi(id, { signal } = {}) {
  return request.get(`/goods/${encodeURIComponent(id)}`, { signal, inlineError: true });
}
