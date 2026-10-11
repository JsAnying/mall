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
watch(source, () => {
  failed.value = false;
});
</script>
<template>
  <img
    v-if="source && !failed"
    class="product-photo"
    :src="source"
    alt=""
    loading="lazy"
    @error="failed = true"
  />
  <ProductArt v-else :kind="kind" :color="color" :accent="accent" />
</template>
<style scoped>
.product-photo {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
</style>
