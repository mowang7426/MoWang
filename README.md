# jailbreak-repo — 我的越狱软件源

在 GitHub Pages 上免费托管的 Cydia / Sileo 软件源（APT 仓库）。
添加源地址后，越狱设备即可安装本源的插件。

## 目录结构

```
jailbreak-repo/
├── debs/                      # 放 .deb 插件包
│   └── com.example.hellotweak_1.0-1_iphoneos-arm.deb   # 示例包（可删除）
├── Packages                   # 包索引
├── Packages.gz / .bz2 / .xz   # 压缩索引
├── Release                    # 源描述（含校验和）
├── build.sh                   # 一键重建索引脚本
└── .github/workflows/build.yml # 推送后自动重建（可选）
```

## 首次部署（约 5 分钟）

1. 在 GitHub 新建一个仓库（名字随意，本说明以 `jailbreak-repo` 为例），可见性选 **Public**。
2. 把本目录里的**所有文件**上传到仓库：
   - 网页端：仓库首页 → **Add file → Upload files**，把文件拖进去（要包含隐藏目录 `.github`）；
   - 或电脑上用 git：
     ```bash
     git init
     git add -A
     git commit -m "init"
     git branch -M main
     git remote add origin https://github.com/你的用户名/jailbreak-repo.git
     git push -u origin main
     ```
3. 打开仓库 **Settings → Pages**，Build and deployment 选 **Deploy from a branch**，分支选 `main`、目录选 `/ (root)`，保存。等待 1–2 分钟部署完成。
4. 在已越狱的 iPhone 上：
   - Cydia：底部 **Sources → Edit → Add**；
   - Sileo：右上角 **+ → Add Source**。
   输入（结尾带 `/`）：
   ```
   https://你的用户名.github.io/jailbreak-repo/
   ```
5. 看到 `com.example.hellotweak` 示例插件即为成功，可以删掉它。

## 更新插件

1. 把新的 `.deb` 放进 `debs/` 目录；
2. 本地运行 `./build.sh` 重建索引（会自动重写 Packages 及 Release 校验和）；
3. `git add -A && git commit -m "add tweak" && git push`。

> 不想每次手动跑？仓库已内置 GitHub Actions：只要推送对 `debs/` 的修改，工作流会自动重建并提交索引。

## 修改源信息

编辑 `build.sh` 顶部的 `ORIGIN / LABEL / DESCRIPTION`，重新运行 `./build.sh` 即可（Release 会同步更新）。也可以直接改 `Release` 文件。

## 可选：GPG 签名（推荐但非必需）

防止源被篡改：

```bash
gpg --gen-key                      # 生成密钥（按提示操作）
gpg -abs -o Release.gpg Release    # 签名 Release
gpg --export --armor > apt-key.gpg # 公钥放到仓库根目录
```

用户首次添加源后，需要导入你的公钥 `apt-key.gpg` 才能通过签名校验。

## 注意事项

- **只放你自己开发或有授权分发的插件。** 收录盗版、破解应用违反 GitHub 服务条款，仓库会被下架、账号可能被封，并有法律风险。
- GitHub Pages 适合个人小规模源；包很多、体积大时建议换自己的服务器或 Cloudflare Pages。
- 源地址由 GitHub 用户名和仓库名决定，改名后地址会变，需重新添加。
