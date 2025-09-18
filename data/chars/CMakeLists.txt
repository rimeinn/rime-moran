if(MORAN_VARIANT STREQUAL simp)
  set(FLAG "--simplified")
else()
  set(FLAG "")
endif()

# 單字表
moran_add_file(
  OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/moran.chars.dict.yaml"
  COMMAND ${UV} run gen_chars.py ${FLAG} > <OUTPUT>
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

# 拆分濾鏡
# opencc 構建中會使用該 txt 文件
set(OUTPUT "${PROJECT_SOURCE_DIR}/opencc/moran_chaifen.txt")
add_custom_command(
  OUTPUT "${OUTPUT}"
  COMMAND "${UV}" run gen_chaifen_filter.py > "${OUTPUT}"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/moran_chai.txt"
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
add_custom_target(moran_chaifen.txt ALL DEPENDS "${OUTPUT}")

# zrmdb
moran_add_file(
  BASE lua
  OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/zrmdb.txt"
  COMMAND "${UV}" run gen_zrmdb.py > <OUTPUT>
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
