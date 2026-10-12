import request from "@/utils/request.js";

export const loginApi = (credentials, { signal } = {}) =>
  request.post("/auth/login", credentials, {
    skipAuth: true,
    authFailureRedirect: false,
    inlineError: true,
    signal,
  });
export const registerApi = (data, { signal } = {}) =>
  request.post("/auth/register", data, {
    skipAuth: true,
    authFailureRedirect: false,
    inlineError: true,
    signal,
  });
