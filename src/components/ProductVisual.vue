<script setup>
import { computed, ref, watch } from "vue";
import ProductArt from "./ProductArt.vue";
const props = defineProps({
  kind: { type: String, default: "camera" },
  color: String,
  accent: String,
});
const photos = {
  camera: "/images/camera.png",
  headphones: "/images/headphones.png",
  bag: "/images/tote.png",
  lamp: "/images/lamp.png",
  toy: "/images/toy.png",
  shoe: "/images/shoe.png",
  phone: "/images/phone.png",
};
const source = computed(() => photos[props.kind]);
const failed = ref(false);
const loaded = ref(false);
watch(source, () => {
  failed.value = false;
  loaded.value = false;
});
</script>
<template>
  <div
    class="product-frame"
    :class="{ 'image-pending': source && !failed && !loaded }"
    :aria-busy="Boolean(source && !failed && !loaded)"
  >
    <img
      v-if="source && !failed"
      class="product-photo"
      :src="source"
      alt=""
      loading="lazy"
      @error="failed = true"
      @load="loaded = true"
    />
    <ProductArt v-else :kind="kind" :color="color" :accent="accent" />
    <span v-if="failed" class="image-fallback">图片暂不可用 · 示意图</span>
  </div>
</template>
<style scoped>
.product-photo {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.product-frame {
  width: 100%;
  height: 100%;
  position: relative;
  overflow: hidden;
  background: var(--raised);
}
.product-frame > svg {
  width: 100%;
  height: 100%;
}
.image-pending::after {
  content: "";
  position: absolute;
  inset: 0;
  background: var(--active);
  animation: image-loading 1.4s infinite;
}
.image-fallback {
  position: absolute;
  bottom: 8px;
  left: 8px;
  padding: 5px 8px;
  background: var(--surface);
  font-size: 12px;
  border-radius: 5px;
  color: var(--text-secondary);
}
@keyframes image-loading {
  50% { opacity: 0.5; }
}
</style>
