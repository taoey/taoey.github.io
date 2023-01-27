---
layout: post
title: linux调整history记录到最大
categories: [linux]
description: linux调整history记录到最大
keywords: linux,history
---

这个命令默认可以保存的命令数是1000,1000对于我们Linux玩家来说实在是太少了，那么我们如何调整history的保存条数呢？

在 /etc/profile 中添加如下语句

```bash
HISTTIMEFORMAT='%F %T'
HISTSIZE="100000"
```

只有执行 `source /etc/profile` 重新加载即可，最终效果如下

```bash
#1674186211
ls
#1674186212
cd 
#1674186213
ls
#1674186219
/etc/profile.d/
#1674186227
cat /etc/profile
```



参考资料

- https://blog.csdn.net/qq_38676353/article/details/101989639