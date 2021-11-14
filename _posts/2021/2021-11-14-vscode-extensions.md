---
layout: post
title: vscode插件--效率开发必备(持续更新中...)
categories: [vscode,工具]
description: vscode插件--效率开发必备
keywords: #vscode
---


慢慢的感觉vscode是一个比较灵敏轻量的代码编辑器，后期代码将慢慢使用vscode进行编写



## 1、Paste Image
<img src="http://beangogo.cn/assets/images/artcles/2021-11-14-vscode-extensions.assets/2021-11-14-15-38-49.png" style="zoom:25%;" />

在vscode的markdown中黏贴图片更方便，可以用于代替Typora
黏贴快捷键：option+command+c

个人习惯配置
```json
{
  "pasteImage.basePath": "${projectRoot}",
  "pasteImage.path": "${projectRoot}/assets/images/artcles/${currentFileNameWithoutExt}.assets",
  "pasteImage.prefix": "http://beangogo.cn/"
}
```

## 2、git 相关

### 2.1 Git Graph
用于查看git提交记录图
<img src="http://beangogo.cn/assets/images/artcles/2021-11-14-vscode-extensions.assets/2021-11-14-15-41-53.png" style="zoom:33%;" />

### 2.2 GitLens
主要用于显示当前行的最近提交
<img src="http://beangogo.cn/assets/images/artcles/2021-11-14-vscode-extensions.assets/2021-11-14-15-45-24.png" style="zoom:33%;" />

### 2.3 Git History
<img src="http://beangogo.cn/assets/images/artcles/2021-11-14-vscode-extensions.assets/2021-11-14-15-46-03.png" style="zoom:33%;" />




## 总配置

```json
{
    "editor.fontSize": 15,
    "files.autoSave": "onFocusChange",
    "terminal.integrated.fontSize": 14,
    "workbench.editorAssociations": {
        "*.ipynb": "jupyter.notebook.ipynb"
    },
    "workbench.colorTheme": "Monokai",
    "go.formatTool": "gofmt",
    "go.goroot": "/usr/local/go",
    "explorer.confirmDelete": false,
    "leetcode.endpoint": "leetcode-cn",
    "leetcode.hint.configWebviewMarkdown": false,
    "leetcode.workspaceFolder": "/Users/tao/Documents/nut_files/github/1_projects/learning-python/algorithm/leetcode",
    "leetcode.defaultLanguage": "python3",
    "go.toolsManagement.autoUpdate": true,
    "security.workspace.trust.untrustedFiles": "open",
    "git.confirmSync": false,
    "git.ignoreLegacyWarning": true,
    "pasteImage.basePath": "${projectRoot}",
    "pasteImage.path": "${projectRoot}/assets/images/artcles/${currentFileNameWithoutExt}.assets",
    "pasteImage.prefix": "http://beangogo.cn/",
}
```