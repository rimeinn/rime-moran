##############
# Schema files
##############
moran_configure(moran.yaml)
moran_configure(moran_aux.schema.yaml)
moran_configure(moran_fixed.schema.yaml)
moran_configure(moran.schema.yaml)
moran_configure(moran_sentence.schema.yaml)

#######################
# moran.words.dict.yaml
#######################
moran_add_file(SIMPLIFY
  OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/moran.words.dict.yaml"
  INPUT "${CMAKE_CURRENT_SOURCE_DIR}/moran.words.dict.yaml"
  COMMAND ${UV} run schemagen.py update-compact-dict --rime-dict <INPUT> > <OUTPUT>
  WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}/tools")

#######################
# moran_fixed.dict.yaml
#######################
if(MORAN_VARIANT STREQUAL trad)
  moran_add_file(COPY RENAME moran_fixed.dict.yaml INPUT moran_fixed_trad.dict.yaml)
else()
  moran_add_file(COPY RENAME moran_fixed.dict.yaml INPUT moran_fixed_simp.dict.yaml)
endif()

################
# Custom phrases
################
moran_copy_file(moran_custom_phrases.txt ${SIMPLIFY})

#############
# other files
#############
set(DICTS
  moran.words.dict.yaml
  moran_fixed_trad.dict.yaml
  moran_fixed_simp.dict.yaml)
moran_copy_glob(GLOB moran*.yaml EXCLUDE ${DICTS})
