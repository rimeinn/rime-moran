OCD2_FILES=\
	moran_chaifen.ocd2 \
	moran_dzing_variants.ocd2 \
	moran_emoji.ocd2 \
	moran_pinyinhint.ocd2 \
	moran_TSCharacters.ocd2

all: $(OCD2_FILES)

%.ocd2: %.txt
	opencc_dict -i $< -o $@ -f text -t ocd2

clean:
	rm -f $(OCD2_FILES)

.PHONY: all clean
