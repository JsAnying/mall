<script setup>
import { ref } from "vue";
import { ElMessage } from "element-plus";
import MarketIcon from "./MarketIcon.vue";
const panel = ref("");
const feedback = ref("");
const submitted = ref(false);
const error = ref("");
const savedId = ref("");
function openPanel(name) {
  panel.value = name;
  submitted.value = false;
  error.value = "";
}
function submitFeedback() {
  if (!feedback.value.trim()) {
    error.value = "请先填写建议，最多 500 位。";
    return;
  }
  try {
    const previous = JSON.parse(
      localStorage.getItem("market_feedback") || "[]",
    );
    const entries = Array.isArray(previous) ? previous : [];
    savedId.value = crypto.randomUUID();
    localStorage.setItem(
      "market_feedback",
      JSON.stringify([
        ...entries,
        {
          id: savedId.value,
          content: feedback.value.trim(),
          createdAt: new Date().toISOString(),
        },
      ]),
    );
    feedback.value = "";
    submitted.value = true;
  } catch {
    error.value = "建议未保存，请检查浏览器存储设置后重试。内容已保留。";
  }
}
function undoFeedback() {
  try {
    const entries = JSON.parse(localStorage.getItem("market_feedback") || "[]");
    const last = entries.find((item) => item.id === savedId.value);
    localStorage.setItem(
      "market_feedback",
      JSON.stringify(entries.filter((item) => item.id !== savedId.value)),
    );
    feedback.value = last?.content || "";
    submitted.value = false;
    savedId.value = "";
    error.value = "";
    ElMessage.success("已撤销保存，可以继续修改建议");
  } catch {
    error.value = "无法撤销，请检查浏览器存储设置后重试。";
  }
}
function backToTop() {
  window.scrollTo({ top: 0, behavior: "smooth" });
}
</script>
<template>
  <aside class="floating-dock" aria-label="快捷操作">
    <RouterLink class="dock-publish" to="/publish"
      ><span><MarketIcon name="plus" :size="28" /></span
      ><b>发布闲置</b></RouterLink
    >
    <button @click="openPanel('messages')">
      <MarketIcon name="message" /><span>消息</span></button
    ><button @click="openPanel('mobile')">
      <MarketIcon name="phone" /><span>手机端</span></button
    ><button @click="openPanel('feedback')">
      <MarketIcon name="feedback" /><span>反馈</span></button
    ><button class="dock-top" @click="backToTop">
      <MarketIcon name="up" /><span>回到顶部</span>
    </button>
  </aside>
  <el-dialog
    :model-value="Boolean(panel)"
    :title="
      {
        messages: '消息中心',
        mobile: '手机也能逛好物',
        feedback: '你的建议，我们在听',
      }[panel]
    "
    width="min(440px, 90vw)"
    @close="panel = ''"
  >
    <template v-if="panel === 'messages'"
      ><el-empty description="消息服务尚未开放" :image-size="90" />
      <p class="dialog-note">
        当前为离线展示，聊天消息将在后端接入后开放。
      </p></template
    >
    <template v-if="panel === 'mobile'"
      ><div class="mobile-symbol"><MarketIcon name="phone" :size="64" /></div>
      <p>在手机浏览器打开本站地址，即可使用移动端布局。</p>
      <p class="dialog-note">
        当前没有独立 App。搜索、分类和商品详情均支持手机浏览。
      </p></template
    >
    <template v-if="panel === 'feedback'"
      ><el-result
        v-if="submitted"
        icon="success"
        title="建议已保存在本机"
        sub-title="建议仅在此浏览器保存，没有发送给平台。"
        ><template #extra
          ><el-button @click="undoFeedback">撤销保存，继续修改</el-button
          ><el-button @click="panel = ''">关闭</el-button></template
        ></el-result
      >
      <form v-else @submit.prevent="submitFeedback">
        <label class="feedback-label" for="feedback-text"
          >你想让拾光变得更好的一点是？</label
        ><el-input
          id="feedback-text"
          v-model="feedback"
          type="textarea"
          :rows="5"
          maxlength="500"
          show-word-limit
          placeholder="页面体验、功能建议，或任何小想法……"
        />
        <p class="dialog-note">此版本仅保存至本机浏览器，不发送至服务器。</p>
        <div v-if="error" class="error-panel" role="alert">{{ error }}</div>
        <el-button
          type="primary"
          native-type="submit"
          :disabled="!feedback.trim()"
          >保存到本机</el-button
        ><el-button @click="panel = ''">取消</el-button>
      </form></template
    >
    <div v-if="submitted && error" class="error-panel" role="alert">
      {{ error }}
    </div>
  </el-dialog>
</template>

<style scoped>
.floating-dock { grid-column: 2; display: flex; align-items: center; justify-content: flex-end; gap: 24px; padding: 8px 0; }
.floating-dock > button, .dock-publish { display: inline-flex; align-items: center; justify-content: center; gap: 7px; min-height: 44px; padding: 4px; font-size: 12px; color: var(--text-secondary); }
.floating-dock svg { width: 17px; height: 17px; }
.floating-dock b { font-size: 12px; font-weight: 500; }
.dock-publish > span { display: flex; }
.floating-dock > button:hover, .dock-publish:hover { color: var(--accent); }
.dialog-note { font-size: 13px; line-height: 1.8; color: var(--text-secondary); }
.mobile-symbol { display: flex; justify-content: center; color: var(--accent); padding: 20px; }
.feedback-label { display: block; margin-bottom: 12px; font-size: 14px; }
@media (max-width: 800px) { .floating-dock { grid-column: 1; justify-content: space-between; gap: 8px; padding: 8px 4px; } }
@media (max-width: 450px) { .floating-dock > button, .dock-publish { flex-direction: column; gap: 3px; font-size: 11px; min-width: 44px; } .floating-dock b { font-size: 11px; } }
</style>
