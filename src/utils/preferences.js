// 浏览器存储不可用时，交互仍可继续；写入失败必须向调用方返回结果。
export function readPreference(key, fallback) {
  try {
    return JSON.parse(localStorage.getItem(key) || "null") ?? fallback;
  } catch {
    return fallback;
  }
}
export function writePreference(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
    return true;
  } catch {
    return false;
  }
}
export function rememberSearch(history, keyword) {
  const text = keyword.trim().slice(0, 100);
  return text
    ? [text, ...history.filter((item) => item !== text)].slice(0, 6)
    : history;
}
