<script setup>
import { computed, reactive, ref, watch, onMounted, onUnmounted } from "vue";
import { useRoute, onBeforeRouteLeave, onBeforeRouteUpdate } from "vue-router";
import { ElMessage, ElMessageBox } from "element-plus";
import { categories, goods } from "@/data/market.js";
import { categoryTypes } from "@/data/categoryTypes.js";
import { useUserStore } from "@/stores/user.js";
import { readPreference, writePreference } from "@/utils/preferences.js";
const route = useRoute(),
  user = useUserStore();
const formRef = ref(),
  preview = ref(false),
  saving = ref(false),
  status = ref("尚未保存"),
  failure = ref(""),
  removed = ref(null);
const blank = () => ({
  category: "",
  type: "",
  title: "",
  description: "",
  condition: "",
  price: "",
  location: "",
});
const form = reactive(blank());
const draftKey = computed(
  () =>
    "market_draft_" +
    String(user.userInfo?.id || user.userInfo?.username) +
    "_" +
    String(route.query.id || "new"),
);
const snapshot = ref("");
function initialize() {
  Object.assign(form, blank());
  const saved = readPreference(draftKey.value, null);
  if (saved?.fields) {
    for (const key of Object.keys(blank()))
      if (typeof saved.fields[key] === "string") form[key] = saved.fields[key];
    status.value = "已恢复本机草稿";
  } else {
    const item = goods.find((item) => String(item.id) === route.query.id);
    if (item)
      Object.assign(form, {
        category: item.category,
        type: item.kind,
        title: item.title,
        description: "",
        condition: item.condition,
        price: String(item.price),
        location: item.location,
      });
    status.value = "尚未保存";
  }
  snapshot.value = JSON.stringify(form);
}
initialize();
watch(() => route.query.id, initialize);
const dirty = computed(() => JSON.stringify(form) !== snapshot.value);
const types = computed(
  () => categoryTypes[form.category]?.flatMap((group) => group.items) || [],
);
const conditions = ["全新", "几乎全新", "99新", "95新", "9成新", "有使用痕迹"];
const completed = computed(
  () =>
    [
      form.category && form.type,
      form.title.trim().length >= 2 && form.description.trim().length >= 10,
      form.condition && Number(form.price) > 0 && form.location.trim(),
    ].filter(Boolean).length,
);
const rules = {
  category: [{ required: true, message: "请选择一级分类", trigger: "change" }],
  type: [{ required: true, message: "请选择具体商品类型", trigger: "change" }],
  title: [
    {
      required: true,
      min: 2,
      whitespace: true,
      max: 80,
      message: "标题需为 2–80 位，请写明品牌或商品名称",
      trigger: ["blur", "change"],
    },
  ],
  description: [
    {
      required: true,
      min: 10,
      whitespace: true,
      max: 2000,
      message: "请用至少 10 位文字描述使用情况和瑕疵",
      trigger: "blur",
    },
  ],
  condition: [{ required: true, message: "请选择成色", trigger: "change" }],
  price: [
    {
      validator: (_, value, cb) =>
        cb(
          /^\d{1,6}(\.\d{1,2})?$/.test(value) &&
            Number(value) > 0 &&
            Number(value) <= 999999.99
            ? undefined
            : new Error("请输入大于 0 的价格，最多两位小数"),
        ),
      trigger: ["blur", "change"],
    },
  ],
  location: [
    {
      required: true,
      whitespace: true,
      max: 50,
      message: "请输入所在城市，最多 50 位",
      trigger: "blur",
    },
  ],
};
function changeCategory() {
  form.type = "";
}
function saveDraft() {
  if (saving.value) return false;
  saving.value = true;
  failure.value = "";
  const ok = writePreference(draftKey.value, {
    fields: { ...form },
    savedAt: new Date().toISOString(),
  });
  if (ok) {
    snapshot.value = JSON.stringify(form);
    status.value =
      "已保存至本机 · " +
      new Date().toLocaleTimeString("zh-CN", {
        hour: "2-digit",
        minute: "2-digit",
      });
    ElMessage.success("草稿已保存，没有上架商品");
  } else
    failure.value =
      "草稿保存失败。请检查浏览器存储设置，或复制已填写的内容后再离开。";
  saving.value = false;
  return ok;
}
async function showPreview() {
  if (await formRef.value.validate().catch(() => false)) preview.value = true;
}
async function clearDraft() {
  try {
    await ElMessageBox.confirm(
      "将清除这个草稿的全部内容。清除后可以立即撤销。",
      "清除草稿",
      {
        confirmButtonText: "清除草稿",
        cancelButtonText: "继续编辑",
        type: "warning",
      },
    );
  } catch {
    return;
  }
  if (!writePreference(draftKey.value, null)) {
    failure.value = "无法清除草稿，请检查浏览器存储设置后重试。";
    return;
  }
  removed.value = { ...form };
  Object.assign(form, blank());
  snapshot.value = JSON.stringify(form);
  status.value = "草稿已清除";
}
function undoClear() {
  Object.assign(form, removed.value);
  removed.value = null;
  saveDraft();
}
async function leave() {
  if (!dirty.value) return true;
  try {
    await ElMessageBox.confirm(
      "有尚未保存的修改。保存至本机后再离开，下次可以继续填写。",
      "保存修改？",
      {
        confirmButtonText: "保存草稿并离开",
        cancelButtonText: "继续编辑",
        closeOnClickModal: false,
      },
    );
    return saveDraft();
  } catch {
    return false;
  }
}
onBeforeRouteLeave(leave);
onBeforeRouteUpdate(async (to) => {
  if (to.query.id === route.query.id) return true;
  return leave();
});
function beforeUnload(event) {
  if (dirty.value) {
    event.preventDefault();
    event.returnValue = "";
  }
}
onMounted(() => window.addEventListener("beforeunload", beforeUnload));
onUnmounted(() => window.removeEventListener("beforeunload", beforeUnload));
</script>
<template>
  <div class="workspace-layout">
    <section class="workspace-main">
      <RouterLink class="back-action" to="/">← 返回首页</RouterLink>
      <div class="workspace-heading">
        <div>
          <span class="eyebrow">我的闲置</span>
          <h1>{{ route.query.id ? "准备编辑信息" : "准备发布闲置" }}</h1>
          <p>写清使用情况，让下一位使用者放心挑选。</p>
        </div>
        <span class="draft-status" role="status" aria-live="polite">{{
          dirty ? "有未保存的修改" : status
        }}</span>
      </div>
      <div class="availability-note">
        <strong>当前可保存草稿，正式发布尚未开放</strong>
        <p>草稿仅保存在这个浏览器，未上传图片，也不会生成在售商品。</p>
      </div>
      <div class="form-progress" aria-label="填写进度">
        <span>已填写 {{ completed }} / 3 组信息</span
        ><el-progress
          :percentage="Math.round((completed / 3) * 100)"
          :show-text="false"
        />
      </div>
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-position="top"
        @submit.prevent="showPreview"
      >
        <section class="form-section">
          <h2><span>1</span>选择商品分类</h2>
          <div class="form-row">
            <el-form-item label="一级分类" prop="category"
              ><el-select
                v-model="form.category"
                placeholder="请选择分类"
                @change="changeCategory"
                ><el-option
                  v-for="item in categories"
                  :key="item.id"
                  :label="item.name"
                  :value="item.id" /></el-select></el-form-item
            ><el-form-item label="商品类型" prop="type"
              ><el-select
                v-model="form.type"
                :disabled="!form.category"
                :placeholder="
                  form.category ? '请选择具体类型' : '先选择一级分类'
                "
                ><el-option
                  v-for="item in types"
                  :key="item.id"
                  :label="item.name"
                  :value="item.id" /></el-select
            ></el-form-item>
          </div>
        </section>
        <section class="form-section">
          <h2><span>2</span>描述你的闲置</h2>
          <el-form-item label="商品标题" prop="title"
            ><el-input
              v-model="form.title"
              maxlength="80"
              show-word-limit
              placeholder="例如：米白降噪耳机，个人自用，配件齐全" /></el-form-item
          ><el-form-item label="使用情况与瑕疵" prop="description"
            ><el-input
              v-model="form.description"
              type="textarea"
              :rows="5"
              maxlength="2000"
              show-word-limit
              placeholder="使用多久？有哪些配件？是否有划痕或维修？请如实说明。"
          /></el-form-item>
          <p class="field-hint">
            10–2000 位，不填写手机号、详细住址等敏感信息。
          </p>
          <div class="upload-placeholder">
            <strong>商品照片</strong>
            <p>
              图片上传尚未开放。正式发布时需要 1–9 张清晰照片，首张作为封面。
            </p>
            <el-button disabled>添加照片（尚未开放）</el-button>
          </div>
        </section>
        <section class="form-section">
          <h2><span>3</span>填写成色与价格</h2>
          <el-form-item label="商品成色" prop="condition"
            ><el-radio-group v-model="form.condition"
              ><el-radio-button
                v-for="item in conditions"
                :key="item"
                :value="item"
                >{{ item }}</el-radio-button
              ></el-radio-group
            ></el-form-item
          >
          <div class="form-row">
            <el-form-item label="出售价格（元）" prop="price"
              ><el-input
                v-model="form.price"
                inputmode="decimal"
                maxlength="9"
                placeholder="例如：239.00"
                ><template #prepend>¥</template></el-input
              ></el-form-item
            ><el-form-item label="所在城市" prop="location"
              ><el-input
                v-model="form.location"
                maxlength="50"
                placeholder="例如：杭州"
            /></el-form-item>
          </div>
        </section>
        <div v-if="failure" class="error-panel" role="alert">
          <p>{{ failure }}</p>
          <button type="button" @click="saveDraft">重新保存草稿</button>
        </div>
        <div v-if="removed" class="undo-bar" role="status">
          草稿已清除 <button type="button" @click="undoClear">撤销清除</button>
        </div>
        <div class="form-actions">
          <el-button type="primary" :loading="saving" @click="saveDraft"
            >保存草稿</el-button
          ><el-button native-type="submit">预览信息</el-button
          ><button type="button" class="text-link" @click="clearDraft">
            清除草稿</button
          ><RouterLink to="/">取消并返回</RouterLink>
        </div>
      </el-form>
    </section>
    <aside class="workspace-aside">
      <span class="eyebrow">填写小提示</span>
      <h2>让好物被放心选择</h2>
      <ul>
        <li>标题写出品牌、型号和关键特点。</li>
        <li>瑕疵如实说明，避免误解。</li>
        <li>价格用人民币元填写，不包含运费。</li>
        <li>保存草稿后可以随时返回继续编辑。</li>
      </ul>
      <p>想看完整说明？页面底部随时可以打开使用帮助。</p>
    </aside>
    <el-dialog v-model="preview" title="发布信息预览" width="min(560px, 92vw)"
      ><span class="eyebrow">本机草稿 · 尚未发布</span>
      <h2>{{ form.title }}</h2>
      <p class="preview-price">¥{{ Number(form.price).toLocaleString() }}</p>
      <p>{{ form.condition }} · {{ form.location }}</p>
      <p class="preview-description">{{ form.description }}</p>
      <p class="field-hint">正式发布还需上传商品照片；当前无法创建在售商品。</p>
      <template #footer
        ><el-button @click="preview = false">返回编辑</el-button
        ><el-button type="primary" @click="saveDraft"
          >保存草稿</el-button
        ></template
      ></el-dialog
    >
  </div>
</template>
<style scoped>
.form-progress {
  margin: 24px 0;
  font-size: 14px;
}
.form-progress .el-progress {
  margin-top: 12px;
}
.form-section {
  padding: 24px 0;
  border-top: 1px solid var(--line);
}
.form-section h2 {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 19px;
  margin: 0 0 24px;
}
.form-section h2 span {
  background: #edf0e7;
  color: #485c38;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 14px;
}
.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}
.el-select {
  width: 100%;
}
.upload-placeholder {
  padding: 20px;
  border: 1px dashed #bdc5b5;
  border-radius: 12px;
  background: #f8f9f4;
}
.upload-placeholder p {
  font-size: 14px;
  line-height: 1.7;
  color: var(--text-secondary);
}
.field-hint {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.7;
}
.el-radio-group {
  gap: 6px;
  flex-wrap: wrap;
}
.form-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  border-top: 1px solid var(--line);
  padding-top: 24px;
}
.form-actions a {
  font-size: 14px;
  margin-left: auto;
  padding: 12px;
}
.draft-status {
  font-size: 13px;
  color: var(--text-secondary);
}
.preview-price {
  font-size: 28px;
  color: var(--accent);
}
.preview-description {
  white-space: pre-wrap;
  line-height: 1.8;
  overflow-wrap: anywhere;
}
@media (max-width: 600px) {
  .form-row {
    grid-template-columns: 1fr;
    gap: 0;
  }
  .form-actions a {
    margin: 0;
  }
  .draft-status {
    display: block;
  }
}
</style>
