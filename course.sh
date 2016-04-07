#!/bin/bash

#http://www.maiziedu.com/course/list/?catagory=all&career=all&sort_by=new

GET() {
  wget -U "Mozilla" $@
}

genList() {
  for page in {1..31}; do
    echo "LOG >> get page $page"
    url="http://www.maiziedu.com/course/list/?catagory=all&career=all&sort_by=new&page=$page"
    html=$(GET -O - "$url"); html=${html#*zy_course_list}
    data=${html#*title=\"}
    while [ "$data" != "$html" ]; do
      title=${data%%\"*}; data=${data#*href=\"}
      link="http://www.maiziedu.com${data%%\"*}"; data=${data#*src=\"}
      img="http://www.maiziedu.com${data%%\"*}"
      echo "$link $img $title" >> course.txt

      html="$data"
      data=${html#*title=\"}
    done
  done
}

genList
