title=$1
date=`date +%F`
file_name=$date"-"$title".md"
# echo $file_name
# touch $date-$article_name.markdown
touch $file_name
if [ -f $file_name ]; then
    echo "\033[32m文件\"$file_name\"创建成功\033[0m"
else
    echo "\033[31mError:文件创建失败\033[0m"
    exit
fi
category=''
if [ ! -n "$2" ];then
    echo "\033[33mWarning:未填写分类 \033[0m"
    category="未分类"
    # echo $category
else
    category=$2
    # echo $category
fi

if [ ! -n "$3" ];then
	image=""
else
image="image:
  feature:
  credit:
  creditlink:
"
fi

datetime=`date +%Y-%m-%d\ %H:%M:%S`

boundary="---"

template="
layout: post
title:  "$title"
description: ""
modified:   $datetime
tags: [$category]
"
template=$boundary$template$image$boundary
echo "$template" > $file_name
