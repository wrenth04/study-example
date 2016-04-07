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

getVideo() {
  while read link name; do
    videoName=$(echo "$name.mp4" | sed "s/ /_/g")
    isExists=$(gdrive list -q "trashed = false and '$FID' in parents and name = '$videoName'" | wc -l)
    if [ $isExists != 1 ]; then continue; fi

    html=$(GET -O - "$link")
    html=${html#*microohvideo};
    video=${html#*src=\"}; video=${video%%\"*}

    GET -c -O "$videoName" "$video"
    gdrive upload -p $FID "$videoName"
    rm "$videoName"
  done
}

getCourse() {
  cat course.txt | while read link img title; do
    imgName=$(echo "$title.jpg" | sed "s/ /_/g")
    GET -O "$imgName" "$img"
    gdrive upload -p $FID "$imgName"
    rm "$imgName"
    
    html=$(GET -O - "$link" | sed "s/&nbsp;/ /g")

    html=${html#*playlist}; html=${html%%mc-interact*}
    data=${html#*href=\"}

    while [ "$data" != "$html" ]; do
      link="http://www.maiziedu.com${data%%\"*}"
      lesson=${data#*>}; lesson=${lesson%%<*}
      echo "$link $title-$lesson"

      html="$data"
      data=${html#*href=\"}
    done | getVideo
  done
}

#genList
getCourse
