<template>
  <el-result icon="info" title="没有找到这个页面" sub-title="链接可能已失效。返回首页，继续浏览商品。">
    <template #extra
      ><el-button type="primary" @click="$router.replace('/')"
        >返回首页</el-button
      ></template
    >
  </el-result>
</template>
