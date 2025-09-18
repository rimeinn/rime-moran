cmake_minimum_required(VERSION 3.30)
project(moran NONE)


################################################################################
# 構建選項
################################################################################
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${CMAKE_SOURCE_DIR}/dist" CACHE PATH "Install prefix" FORCE)
endif()

set(MORAN_VARIANT "trad" CACHE STRING "Moran variant: simp or trad")
set_property(CACHE MORAN_VARIANT PROPERTY STRINGS "simp" "trad")
message(STATUS "Build variant: ${MORAN_VARIANT}")

if(MORAN_VARIANT STREQUAL simp)
  set(SIMPLIFY SIMPLIFY)
  set(SIMPLIFIER_ON_LABEL  漢字)
  set(SIMPLIFIER_OFF_LABEL 汉字)
  set(SIMPLIFIER_OPTION traditionalization)
  set(SIMPLIFIER_OPTION_VALUE_WHEN_SIMPLIFIED false)
  set(SIMPLIFIER_OPENCC_CONFIG s2t.json)
  set(OCTAGRAM_DATA hans)
else()
  set(SIMPLIFY)
  set(SIMPLIFIER_ON_LABEL  汉字)
  set(SIMPLIFIER_OFF_LABEL 漢字)
  set(SIMPLIFIER_OPTION simplification)
  set(SIMPLIFIER_OPENCC_CONFIG moran_t2s.json)
  set(SIMPLIFIER_OPTION_VALUE_WHEN_SIMPLIFIED true)
  set(OCTAGRAM_DATA hant)
endif()

################################################################################
# 檢查依賴
################################################################################
find_program(OPENCC opencc REQUIRED)
find_program(OPENCC_DICT opencc_dict REQUIRED)
find_program(UV uv REQUIRED)

################################################################################
# 輔助函數
################################################################################

function(moran_add_file)
  cmake_parse_arguments(ARG "SIMPLIFY;COPY;CONFIGURE" "OUTPUT;INPUT;WORKING_DIRECTORY;BASE;RENAME" "COMMAND;DEPENDS" ${ARGN})

  if(NOT ARG_BASE)
    set(ARG_BASE .)
  endif()

  if(NOT ARG_DEPENDS)
    set(depends "${ARG_INPUT}")
  else()
    set(depends ${ARG_DEPENDS})
  endif()

  # 若有 SIMPLIFY，則首先轉換之
  if(ARG_SIMPLIFY)
    file(RELATIVE_PATH relpath "${CMAKE_CURRENT_SOURCE_DIR}" "${ARG_INPUT}")
    set(VIA "${CMAKE_CURRENT_BINARY_DIR}/${relpath}.simplified")
    add_custom_command(
      OUTPUT "${VIA}"
      COMMAND "${OPENCC}" -c t2s.json -i "${ARG_INPUT}" -o "${VIA}"
      DEPENDS ${depends})
    set(ARG_INPUT "${VIA}")

    if(NOT ARG_DEPENDS)
      set(depends "${ARG_INPUT}")
    else()
      set(depends ${ARG_DEPENDS})
    endif()
  endif()

  if(ARG_COPY)
    if(ARG_RENAME)
      set(rename_clause RENAME ${ARG_RENAME})
    endif()
    install(FILES "${ARG_INPUT}" ${rename_clause} DESTINATION ${ARG_BASE})
  elseif(ARG_COMMAND)
    if(NOT ARG_OUTPUT)
      set(ARG_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${relpath}")
    endif()
    string(REPLACE "<INPUT>" "${ARG_INPUT}" cmd1 "${ARG_COMMAND}")
    string(REPLACE "<OUTPUT>" "${ARG_OUTPUT}" cmd2 "${cmd1}")
    add_custom_command(
      OUTPUT "${ARG_OUTPUT}"
      COMMAND ${cmd2}
      DEPENDS "${ARG_INPUT}" ${ARG_DEPENDS}
      WORKING_DIRECTORY "${ARG_WORKING_DIRECTORY}")
    get_filename_component(target_name "${ARG_OUTPUT}" NAME)
    add_custom_target("gen-${target_name}" ALL DEPENDS "${ARG_OUTPUT}")
    install(FILES "${ARG_OUTPUT}" DESTINATION ${ARG_BASE})
  endif()
endfunction()

function(moran_copy_file file)
  cmake_parse_arguments(ARG "SIMPLIFY" "BASE;RENAME" "" ${ARGN})
  get_filename_component(absfile "${file}" ABSOLUTE)
  moran_add_file(INPUT "${absfile}" BASE "${ARG_BASE}" RENAME "${ARG_RENAME}" COPY ${ARG_SIMPLIFY})
endfunction()

function(moran_copy_glob)
  cmake_parse_arguments(ARG "SIMPLIFY" "GLOB;BASE" "EXCLUDE" ${ARGN})
  file(GLOB FILES "${ARG_GLOB}")
  list(REMOVE_ITEM FILES ${EXCLUDE})
  foreach(path ${FILES})
    moran_add_file(COPY ${ARG_SIMPLIFY}
      INPUT ${path}
      BASE "${ARG_BASE}")
  endforeach()
endfunction()

function(moran_configure file)
  cmake_parse_arguments(ARG "" "BASE" "" ${ARGN})
  set(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${file}")
  configure_file("${CMAKE_CURRENT_SOURCE_DIR}/${file}.in" "${OUTPUT}" @ONLY)
  if (NOT ARG_BASE)
    set(ARG_BASE ".")
  endif()
  install(FILES "${OUTPUT}" DESTINATION "${ARG_BASE}")
endfunction()

################################################################################
# 生成方案
################################################################################
add_subdirectory(moran)             # 方案定義、碼表和部分詞庫
add_subdirectory(lua)               # Lua 腳本
add_subdirectory(data)              # 拆分數據、附加詞庫等
add_subdirectory(external)          # 引用其他項目數據
add_subdirectory(custom)            # rime-prelude 和其他定製
add_subdirectory(plum)              # 東風破配方
add_subdirectory(opencc)            # OpenCC 定義和源數據

moran_copy_file(LICENSE)
moran_copy_file(README.md)
moran_copy_file(README-en.md)
moran_copy_glob(GLOB etc/* BASE etc)
