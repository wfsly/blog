---
layout: post
title:  golang的slice切片陷阱
description: 
modified:   2019-08-28 10:37:42
tags: [golang]
---

参考自[切片陷阱][slice]

```golang
package main
import "fmt"

func main() {
	// slice迷之更新1
	// 因为slice赋值是使用的引用，所以a和b都会指向相同的底层数组地址
	a := []int{1, 2}
	b := a[:1]		/*[1]	*/
	b[0] = 42		/*[42]	*/
	fmt.Println(a)	/*[42, 2]*/
}
```

```golang
package main
import "fmt"

func main() {
	// slice迷之更新2                                                                                                  
	// 当数据被追加到b，底层数组有足够的容量来保存额外的两个元素，所以append不会重新分配, 这意味着，数据追加到b之后会改变c。
	a := []int{1, 2, 3, 4}
	b := a[:2]			/* [1, 2]	*/
	c := a[2:]			/* [3, 4] 	*/
	b = append(b, 5)	/* [1, 2, 5]*/
	fmt.Println(a)		/* [1, 2, 5, 4]*/
	fmt.Println(b)		/* [1, 2, 5]*/
	fmt.Println(c)		/* [5, 4]	*/
}
```

```golang
package main
import "fmt"

func main() {
	// slice迷之更新3
	a := []int{0}		/* [0]		*/
	a = append(a, 0)	/* [0, 0]	*/
	b := a[:]			/* [0, 0]	*/
	a = append(a, 2)	/* [0, 0, 2]*/
	b = append(b, 1)	/* [0, 0, 1]*/
	fmt.Println(a[2]) 	/* 2 <-对的 */

	c := []int{0, 0}	/* [0, 0] len=2,cap=2		*/
	c = append(c, 0)	/* [0, 0, 0] len=3,cap=4	*/
	d := c[:]			/* [0, 0, 0] len=3,cap=4	*/d和c使用的相同的底层数组地址
	c = append(c, 2)	/* [0, 0, 0, 2] len=3,cap=4 */底层数组不需要重新分配内存
	d = append(d, 1)	/* [0, 0, 0, 1] len=3,cap=4 */底层数组不需要重新分配内存
	fmt.Println(c)		/* 1 <-	*/

	/*
	这个奇怪的行为的原因是，当 slice 变得比某个确切的阈值要大时，Go 停止线性增长并开始分配一个大小翻倍的 slice。这取决于 slice 类型的大小。
	分析更多的细节 :
	 1. 第一个在 a 上的 append 复制前一个 0 到一个 cap==2 的 slice, 然后在 a[1] 上填一个 0.
	 2. 从 a 拿到了一个 slice, len(b) == cap(b) == 2.
	 3. 第二个在 a 上的 append 复制前面的 0 到一个 cap==4 的 slice, 然后在 a[2] 上填上 2
	 4. 在这里，b 依然还是 cap == 2, 所以在 b 上 append, 分配了一个新的底层数组.
	 
	 同样的过程，以初始 cap 为 2 的 slice 开始，产生了不一样的结果，因为当我们拿到 slice c 时，它已经增长到 cap == 4
	*/

}
```

[slice]: https://mp.weixin.qq.com/s/VT8mzbq3qIuqBRd_twih7w
