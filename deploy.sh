#!/usr/bin/env sh

# abort on errors
set -e

yarn run docs:build

cd docs/.vuepress/dist

git init
git add -A
git commit -m 'deploy'

git push -f https://github.com/zowe/docs.git master:gh-pages

cd -