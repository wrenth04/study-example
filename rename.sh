#!/bin/bash

i=1
end=51
new_name="videoname"

while [ $i != $end ]; do
  id=$((i+100)); id=${id#1}
  name=$(ls | grep -i "ep$id")
  echo $name
  mv "$name" "$new_name-$id.mp4"
  i=$((i+1))
done
