function(add_opencc_ocd2 name)
  cmake_parse_arguments(ARG "" "" "DEPENDS" ${ARGN})
  if(ARG_DEPENDS)
    set(depends_clause DEPENDS ${ARG_DEPENDS})
  else()
    set(depends_clause)
  endif()
  moran_add_file(
    BASE opencc
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${name}.ocd2"
    INPUT "${CMAKE_CURRENT_SOURCE_DIR}/${name}.txt"
    COMMAND "${OPENCC_DICT}" -i <INPUT> -o <OUTPUT> -f text -t ocd2
    ${depends_clause})
endfunction()

################################################################################
# OpenCC 配置文件
################################################################################
moran_copy_glob(GLOB *.json BASE opencc)

################################################################################
# OpenCC 數據文件
################################################################################
add_opencc_ocd2(moran_dzing_variants)

add_opencc_ocd2(moran_pinyinhint)

add_opencc_ocd2(moran_TSCharacters)

add_opencc_ocd2(moran_chaifen moran_chaifen.txt)

moran_copy_file(moran_TSPhrases.txt BASE opencc)

if(MORAN_VARIANT STREQUAL trad)
  add_opencc_ocd2(moran_emoji)
else()
  # 轉換後的文件需要去重
  moran_add_file(FILE opencc/moran_emoji.ocd2
    INPUT   "${CMAKE_CURRENT_SOURCE_DIR}/moran_emoji.txt"
    COMMAND sort -k 1,1 -u "<INPUT>" > "${CMAKE_CURRENT_BINARY_DIR}/moran_emoji.txt.uniq" &&
            "${OPENCC_DICT}" -i "${CMAKE_CURRENT_BINARY_DIR}/moran_emoji.txt.uniq" -o "<OUTPUT>" -f text -t ocd2
    ${SIMPLIFY})
endif()
