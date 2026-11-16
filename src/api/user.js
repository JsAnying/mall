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

export const getProfileApi = () => request.get('/users/me', { inlineError: true });
export const updateProfileApi = (data) => request.patch('/users/me', data, { inlineError: true });
export const uploadAvatarApi = (file) => {
  const data = new FormData();
  data.append('file', file);
  return request.post('/users/me/avatar', data, { inlineError: true });
};
