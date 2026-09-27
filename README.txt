MoWang 源修复 V4

替换：
1. build.sh
2. validate-repo.sh

不要删除 debs/ 中的历史版本。
不要删除同一插件的旧版本。

build.sh 使用 dpkg-scanpackages -m 保留多版本，允许：
Package 相同 + Version 不同 + Architecture 相同
同时存在，用于 Sileo/Apt 降级。

完全相同 Package/Version/Architecture 的重复文件只警告，不阻止构建。

validate-repo.sh 使用 bash ./check-debs.sh，避免 GitHub Actions 因脚本没有执行权限而出现 exit code 126。
