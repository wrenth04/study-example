#!/bin/bash

GET() {
  wget -U "Mozilla" $@
}

gen_list() {
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

get_video() {
  while read video_link name; do
    video_name=$(echo "$name.mp4" | sed "s/ /_/g")
    is_exists=$(gdrive list -q "trashed = false and '$FID' in parents and name = '$video_name'" | wc -l)
    if [ $is_exists != 1 ]; then continue; fi

    html=$(GET -O - "$video_link")
    html=${html#*microohvideo};
    video=${html#*src=\"}; video=${video%%\"*}

    GET -c -O "$video_name" "$video"
    gdrive upload -p $FID "$video_name"
    rm "$video_name"
  done
}

get_course() {
  cat course.txt | while read course_link img title; do
    img_name=$(echo "$title.jpg" | sed "s/ /_/g")
    GET -O "$img_name" "$img"
    gdrive upload -p $FID "$img_name"
    rm "$img_name"
    
    html=$(GET -O - "$course_link" | sed "s/&nbsp;/ /g")

    html=${html#*playlist}; html=${html%%mc-interact*}
    data=${html#*href=\"}

    while [ "$data" != "$html" ]; do
      lesson_link="http://www.maiziedu.com${data%%\"*}"
      lesson=${data#*>}; lesson=${lesson%%<*}
      echo "$lesson_link $title-$lesson"

      html="$data"
      data=${html#*href=\"}
    done | get_video
  done
}

#gen_list
get_course
