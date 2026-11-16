import { expect, it } from "vitest";
import {
  goods,
  categories,
  hotSearches,
  filterGoods,
} from "./market.js";
import { categoryTypes, getTypeName } from "./categoryTypes.js";
it("每个一级分类都有完整商品类型，类型能单独筛选", () => {
  for (const category of categories) {
    const items = categoryTypes[category.id].flatMap((group) => group.items);
    expect(items.length).toBeGreaterThan(0);
    expect(new Set(items.map((item) => item.id)).size).toBe(items.length);
    for (const product of goods.filter(
      (item) => item.category === category.id,
    )) {
      expect(items.some((item) => item.id === product.kind)).toBe(true);
    }
  }
  expect(getTypeName("digital", "camera")).toBe("相机");
  expect(
    filterGoods({ category: "digital", type: "phone" }).map((item) => item.id),
  ).toEqual([6]);
  expect(filterGoods({ category: "fashion", type: "phone" })).toHaveLength(0);
});
it("商品 ID 唯一，商品指向有效分类", () => {
  expect(new Set(goods.map((item) => item.id)).size).toBe(goods.length);
  for (const item of goods)
    expect(categories.some((category) => category.id === item.category)).toBe(
      true,
    );

});
it("关键词与分类组合筛选，空结果不会回退到全部商品", () => {
  for (const query of hotSearches)
    expect(filterGoods({ query }).length).toBeGreaterThan(0);
  expect(filterGoods({ query: "  iphone  " }).map((item) => item.id)).toEqual([
    6,
  ]);
  expect(filterGoods({ query: "iPhone", category: "fashion" })).toHaveLength(0);
  expect(
    filterGoods({ category: "digital" }).every(
      (item) => item.category === "digital",
    ),
  ).toBe(true);
  expect(filterGoods({ query: "不存在的商品" })).toHaveLength(0);
  expect(filterGoods({ category: "personal" })).toHaveLength(goods.length);
});
