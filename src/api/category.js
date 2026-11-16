import request from "@/utils/request.js";

export const getCategoriesApi = () => request.get("/categories", {
  skipAuth: true,
  authFailureRedirect: false,
  inlineError: true,
});
