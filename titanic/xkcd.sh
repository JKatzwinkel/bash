sed -n 's/.*<span class=.ref.><span class=.refnum.>\[\([0-9]*\)\]<\/span><span class=.refbody.>\(.*\)<\/span><\/span>.*/\1 \2/gp' out.html
