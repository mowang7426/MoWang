# MoWang 越狱软件源

GitHub Pages 托管的 Cydia / Sileo APT 软件源。

## 正确目录结构

```text
mowang/
├── CydiaIcon.png
├── Release
├── Packages
├── Packages.gz
├── Packages.bz2
├── Packages.xz
├── Packages.zst
├── build.sh
├── check-debs.sh
├── validate-repo.sh
├── .github/workflows/build.yml
└── debs/
    ├── *.deb
    └── ...
```

**重要：所有 `.deb` 必须放在 `debs/` 目录。** `Packages` 中的 `Filename:` 会自动使用 `debs/<文件名>.deb`，不要手工编辑 `Packages`。

## 发布到 GitHub Pages

1. 将整个目录上传到 GitHub 仓库根目录。
2. GitHub → Settings → Pages → Deploy from a branch → `main` → `/ (root)`。
3. 等 Pages 部署完成后，在 Sileo 添加：

```text
https://mowang7426.github.io/mowang/
```

## 本地重建索引

把新的 `.deb` 放入 `debs/` 后运行：

```bash
./build.sh
```

然后检查：

```bash
./validate-repo.sh
```

脚本会自动生成：

- `Packages`
- `Packages.gz`
- `Packages.bz2`
- `Packages.xz`
- `Packages.zst`（系统有 zstd 时）
- `Release`

其中 `Release` 使用正确的 `Architectures:` 字段，并自动写入索引文件的 MD5/SHA256 校验值。

## GitHub Actions

`.github/workflows/build.yml` 会在 `debs/` 或构建脚本发生变化时自动重建索引并提交生成文件；也支持手动 `Run workflow`。

## 当前架构

```text
iphoneos-arm
iphoneos-arm64
iphoneos-arm64e
```

仓库里的包会按照 `.deb` 控制信息中的 `Architecture` 自动索引。不同架构的同一个 Package/Version 可以同时存在，例如：

```text
com.minis.rainbowkeyboard 1.0.8 iphoneos-arm64
com.minis.rainbowkeyboard 1.0.8 iphoneos-arm64e
```

## 注意

只发布你自己开发或获得授权分发的插件。不要手工修改 `Packages` / `Release`；新增或删除 `.deb` 后重新运行 `build.sh` 即可。
