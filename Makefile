kjv: kjv.sh kjv.awk data/kjv.tsv
	cat kjv.sh > $@
	echo 'exit 0' >> $@
	echo '#EOF' >> $@
	tar cz kjv.awk -C data kjv.tsv >> $@
	chmod +x $@

darby: darby.sh kjv.awk data/darby.tsv
	cat darby.sh > $@
	echo 'exit 0' >> $@
	echo '#EOF' >> $@
	tar cz kjv.awk -C data darby.tsv >> $@
	chmod +x $@

chiuns: chiuns.sh kjv.awk data/chiuns.tsv
	cat chiuns.sh > $@
	echo 'exit 0' >> $@
	echo '#EOF' >> $@
	tar cz kjv.awk -C data chiuns.tsv >> $@
	chmod +x $@

cuv: cuv.sh kjv.awk data/cuv.tsv
	cat cuv.sh > $@
	echo 'exit 0' >> $@
	echo '#EOF' >> $@
	tar cz kjv.awk -C data cuv.tsv >> $@
	chmod +x $@

kjv-nav: kjv-nav.sh kjv-nav.awk data/kjv.tsv
	cat kjv-nav.sh > $@
	echo 'exit 0' >> $@
	echo '#EOF' >> $@
	tar cz kjv-nav.awk -C data kjv.tsv >> $@
	chmod +x $@

test: kjv.sh kjv-nav.sh
	shellcheck -s sh kjv.sh
	shellcheck -s sh kjv-nav.sh

.PHONY: test
