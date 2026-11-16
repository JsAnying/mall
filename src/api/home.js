import request from '@/utils/request.js';

export const getRecommendationsApi = () => request.get('/home/recommendations', {
  skipAuth: true,
  authFailureRedirect: false,
  inlineError: true,
});
