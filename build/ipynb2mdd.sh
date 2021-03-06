MD="mdd" 
CH="ch.md"

[ -e $MD ] && rm -rf $MD
mkdir $MD

# Collect files.
cp index.md $MD/
cp -R img $MD/
for f in chapter*/*; do
	dir=$(dirname "$f")
	if [ "${f##*.}" = "md" ] || [ "${f##*.}" = "ipynb" ]; then
		mkdir -p $MD/$dir
		cp $f $MD/$f
	fi
done

# ipynb to md.
for f in $MD/chapter*/*ipynb; do
    base=$(basename $f)
    jupyter nbconvert --to markdown $f --output "${base%%.*}.md" 
	rm $f
done

for f in $MD/chapter*/*md; do
	dir=$(dirname "$f")
	# Remove inner link. 
	sed -i 's/\[\([^]]*\)\]([^\)]*.md)/\1/' $f
	# Refer pdf instead of svg.
	sed -i s/\.svg/\.pdf/ $f
	# Refer img in the same level. 
	sed -i 's/\](..\/img/\](img/' $f
	if [ "$f" != "$dir/index.md" ]; then
		sed -i s/#\ /##\ / $f
	fi
done

# Convert svg to pdf.
for f in $MD/img/*svg; do
	rsvg-convert -f pdf -o "${f%%.*}.pdf" $f
	rm $f
done

# Concat sections in each chapter.
for f in $MD/chapter*/index.md; do
	sections=$(python -c 'import mdd_utils; print(mdd_utils.get_sections())' $f)
	dir=$(dirname "$f")
	chapter=$dir/$CH
	cat $f $sections > $chapter
	perl -i -0777 -pe 's/```eval_rst[^`]+```//ge' $chapter
done

chapters=$(python -c 'import mdd_utils; print(mdd_utils.get_chapters())' $MD/index.md)
i=1
for chapter in $chapters; do
	# Move matplotlib plots outside.
	mv $MD/$chapter/*_files $MD/
	# Move ch.md to ../ch0x.md 
	mv $MD/$chapter/$CH $MD/ch$(printf %02d $i).md
	rm -rf $MD/$chapter
	i=$((i + 1))		
done

rm $MD/index.md

# zip files.
[ -e "$MD.zip" ] && rm "$MD.zip"
zip -r "$MD.zip" $MD 
[ -e $MD ] && rm -rf $MD 
