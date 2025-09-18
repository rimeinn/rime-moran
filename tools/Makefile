quick: gen-zrmdb gen-chai-filter opencc

all: gen-zrmdb gen-chai-filter update-compact-dicts opencc

gen-zrmdb:
	python3 gen_zrmdb.py > data/zrmdb.txt

gen-chai-filter:
	python3 gen_chaifen_filter.py > ./data/opencc/moran_chaifen.txt

dict: update-compact-dicts

update-compact-dicts:
	./update_compact_dicts.sh

dazhu:
	uv run dazhu.py > dazhu-hant2s.txt
	uv run dazhu.py -c='' > dazhu-hant.txt
	uv run dazhu.py -c='' --dict ../moran_fixed_simp.dict.yaml > dazhu-hans.txt

sync-essay:
	python3 sync_essay.py

opencc:
	bash update_opencc.sh

.PHONY: quick all dict gen-zrmdb gen-chai-filter update-compact-dicts dazhu sync-essay opencc
