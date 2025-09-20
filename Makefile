DESTDIR ?= $(abspath ./dist)

quick: chars zrmdb chaifen opencc
dict: update-compact-dicts
all: quick dict

############
# 單字信息 #
############
chars_output := moran.chars.dict.yaml opencc/moran_chaifen.txt lua/zrmdb.txt
chars: moran.chars.dict.yaml
zrmdb: lua/zrmdb.txt
chaifen: opencc/moran_chaifen.txt

moran.chars.dict.yaml: tools/data/chars.txt tools/data/moran_chai.txt tools/gen_chars.py
	uv run tools/gen_chars.py > $@
lua/zrmdb.txt: tools/data/moran_chai.txt tools/gen_zrmdb.py
	uv run tools/gen_zrmdb.py > $@
opencc/moran_chaifen.txt: tools/data/moran_chai.txt tools/gen_chaifen_filter.py
	uv run tools/gen_chaifen_filter.py > $@

##########
# OpenCC #
##########
opencc: chaifen
	make -C opencc

########
# 詞庫 #
########
update-compact-dicts:
	uv run ./tools/update_compact_dicts.sh

sync-essay:
	uv run tools/sync_essay.py

########
# 其他 #
########
dazhu:
	uv run tools/dazhu.py > dazhu-hant2s.txt
	uv run tools/dazhu.py -c='' > dazhu-hant.txt
	uv run tools/dazhu.py -c='' --dict moran_fixed_simp.dict.yaml > dazhu-hans.txt

clean:
	rm -rf dist
	rm -f $(chars_output)
	rm -f dazhu*.txt
	make -C opencc clean

dist: quick
	mkdir -p $(DESTDIR)
	cp -a README*.md LICENSE etc $(DESTDIR)
	cp -a moran* $(DESTDIR)
	cp -a default.yaml key_bindings.yaml punctuation.yaml symbols.yaml $(DESTDIR)
	cp -a recipe.yaml recipes $(DESTDIR)
	cp -a squirrel.yaml $(DESTDIR)
	cp -a tiger.*.yaml zrlf.*.yaml $(DESTDIR)
	cp -a *.gram $(DESTDIR)

	mkdir -p $(DESTDIR)/lua
	cp -a lua/* $(DESTDIR)/lua

	mkdir -p $(DESTDIR)/opencc
	cp -a opencc/*.ocd2 opencc/*.json $(DESTDIR)/opencc
	cp -a opencc/moran_TSPhrases.txt $(DESTDIR)/opencc

test: dist
	mira -C /tmp/mira-cache tests/moran.test.yaml
	mira -C /tmp/mira-cache tests/moran.hint.test.yaml
	mira -C /tmp/mira-cache tests/moran.charset.test.yaml
	mira -C /tmp/mira-cache tests/moran_aux.test.yaml
	rm -rf /tmp/mira-cache

.PHONY: quick all dict chars zrmdb chaifen update-compact-dicts sync-essay dazhu opencc
