<script setup>
import { ref } from "vue";
import { ElMessage } from "element-plus";
import MarketIcon from "./MarketIcon.vue";
const panel = ref("");
const feedback = ref("");
const submitted = ref(false);
function openPanel(name) {
  panel.value = name;
  submitted.value = false;
}
function submitFeedback() {
  if (!feedback.value.trim()) {
    ElMessage.warning("请先填写你的建议");
    return;
  }
  try {
    const previous = JSON.parse(
      localStorage.getItem("market_feedback") || "[]",
    );
    const entries = Array.isArray(previous) ? previous : [];
    localStorage.setItem(
      "market_feedback",
      JSON.stringify([
        ...entries,
        { content: feedback.value.trim(), createdAt: new Date().toISOString() },
      ]),
    );
    feedback.value = "";
    submitted.value = true;
  } catch {
    ElMessage.error("本地保存失败，请检查浏览器存储设置");
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
      ><el-empty description="暂时没有新消息" :image-size="90" />
      <p class="dialog-note">
        当前为离线展示，聊天消息将在后端接入后开放。
      </p></template
    >
    <template v-if="panel === 'mobile'"
      ><div class="mobile-symbol"><MarketIcon name="phone" :size="64" /></div>
      <p>在手机浏览器打开本站地址，即可使用移动端布局。</p>
      <p class="dialog-note">
        本地开发时，请用
        <code>npm run dev -- --host</code> 启动，并在同一局域网内访问电脑 IP
        与端口。暂无独立 App。
      </p></template
    >
    <template v-if="panel === 'feedback'"
      ><el-result
        v-if="submitted"
        icon="success"
        title="建议已保存在本机"
        sub-title="感谢你的建议！后端接入后可启用在线提交。"
      />
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
        <el-button type="primary" native-type="submit">保存建议</el-button>
      </form></template
    >
  </el-dialog>
</template>

<style scoped>
.floating-dock {
  position: fixed;
  right: 17px;
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
  z-index: 30;
  background: #fffefaed;
  border: 1px solid #e5e8dc;
  border-radius: 14px;
  backdrop-filter: blur(15px);
  padding: 8px 5px;
  width: 56px;
  box-shadow: 0 6px 24px #3c4c2910;
}
.floating-dock > button,
.dock-publish {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  font-size: 8px;
  padding: 11px 0;
  border-radius: 8px;
  width: 100%;
  color: #9ba38d;
  transition:
    background 0.2s,
    color 0.2s;
}
.floating-dock > button:hover {
  background: #f3f3e9;
  color: var(--accent);
}
.floating-dock > button svg {
  width: 19px;
  height: 19px;
}
.dock-publish {
  padding: 0 0 8px;
  color: var(--accent);
}
.dock-publish > span {
  display: grid;
  place-items: center;
  width: 37px;
  height: 37px;
  border-radius: 10px;
  background: #f4e9df;
  border: 1px solid #ead6c5;
  color: var(--accent);
  transition: background 0.2s;
}
.dock-publish:hover > span {
  background: #ecddd0;
}
.dock-publish > span svg {
  width: 23px;
  height: 23px;
}
.dock-publish b {
  font-size: 8px;
  font-weight: 450;
}
.dock-top {
  border-top: 1px solid var(--line);
  border-radius: 0 !important;
}
.dialog-note {
  font-size: 12px;
  line-height: 1.8;
  color: #929a87;
}
.mobile-symbol {
  display: grid;
  place-items: center;
  color: var(--accent);
  padding: 20px;
}
.feedback-label {
  display: block;
  margin-bottom: 12px;
  font-size: 13px;
}
@media (max-width: 800px) {
  .floating-dock {
    top: auto;
    bottom: 18px;
    right: 14px;
    transform: none;
    padding: 5px;
    width: 47px;
    border-radius: 12px;
  }
  .floating-dock > button {
    display: none;
  }
  .dock-publish {
    padding: 0;
  }
  .dock-publish b {
    font-size: 7px;
  }
  .dock-publish > span {
    width: 35px;
    height: 35px;
  }
}
</style>
