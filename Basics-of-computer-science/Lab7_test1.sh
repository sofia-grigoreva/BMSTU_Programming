#!/bin/bash
sleep 100
```

Файл `2.sh`:

```bash
#!/bin/bash

project=$1
c=0

loop(){
    for f in $1/* ; do
	if [ -d "$f" ] ; then
		loop "$f"
	elif [[ -f "$f" && ( ${f: -2} == ".c" || ${f: -2} == ".h" ) ]] ; then
		c=$(($c + $(grep -cve '^\s*$' "$f")))
	fi
done
