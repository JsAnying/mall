<script setup>
defineProps({
  name: { type: String, default: "star" },
  size: { type: [Number, String], default: 22 },
});
const paths = {
  close: "m6 6 12 12 M6 18 18 6",
  grid: "M3 3h7v7H3V3 M14 3h7v7h-7V3 M3 14h7v7H3v-7 M14 14h7v7h-7v-7",
  filter: "M3 5h18 M6 12h12 M10 19h4",
  search: "m21 21-5-5 M17 10a7 7 0 1 1-14 0 7 7 0 0 1 14 0",
  phone:
    "M8 2h8a2 2 0 0 1 2 2v16a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2 M10 5h4 M11 19h2",
  bag: "M5 7h14l2 14H3L5 7 M8 8V6a4 4 0 0 1 8 0v2",
  star: "m12 3 2.8 5.7 6.2.9-4.5 4.4 1 6.2-5.5-2.9-5.5 2.9 1-6.2L2 9.6l6.2-.9L12 3",
  spark: "m12 2 3 7 7 3-7 3-3 7-3-7-7-3 7-3 3-7",
  book: "M12 5v16 M12 5C9 2 4 3 2 4v15c4-1 7-1 10 2 3-3 6-3 10-2V4c-2-1-7-2-10 1",
  home: "m3 10 9-8 9 8 M5 9v12h14V9 M9 21v-8h6v8",
  bike: "M8 7h5l4 10 M6 17l5-10 M9 4h4 M16 5h3 M9 17a4 4 0 1 1-8 0 4 4 0 0 1 8 0 M23 17a4 4 0 1 1-8 0 4 4 0 0 1 8 0",
  music:
    "M9 18V5l12-3v13 M9 18a3 3 0 1 1-6 0 3 3 0 0 1 6 0 M21 15a3 3 0 1 1-6 0 3 3 0 0 1 6 0 M9 9l12-3",
  user: "M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0 M4 21v-2a8 8 0 0 1 16 0v2",
  order: "M6 3h12v18H6V3 M9 7h6 M9 11h6 M9 15h4",
  plus: "M12 5v14 M5 12h14",
  message:
    "M21 11a9 9 0 0 1-9 9H3l2-5a9 9 0 1 1 16-4 M8 11h.1 M12 11h.1 M16 11h.1",
  feedback: "M4 3h16v14H9l-5 4V3 M8 7h8 M8 11h5",
  up: "m5 14 7-7 7 7 M5 3h14",
  arrow: "M4 12h16 m-6-6 6 6-6 6",
  chevron: "m9 5 7 7-7 7",
  shield: "m12 2 8 3v7c0 5-8 10-8 10S4 17 4 12V5l8-3 m-4 10 3 3 5-6",
  heart: "M20 4c-3-3-7-1-8 2-1-3-5-5-8-2-5 5 2 11 8 16 6-5 13-11 8-16",
};
</script>
<template>
  <svg
    :width="size"
    :height="size"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="1.7"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
  >
    <path :d="paths[name] || paths.star" />
  </svg>
</template>
