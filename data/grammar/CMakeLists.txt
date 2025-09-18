include(FetchContent)

set(GRAMMAR_FILES
  "zh-${OCTAGRAM_DATA}-t-essay-bgw.gram"
  "zh-${OCTAGRAM_DATA}-t-essay-bgc.gram"
)

foreach(GRAM IN LISTS GRAMMAR_FILES)
  FetchContent_Declare(${GRAM}
    URL https://github.com/lotem/rime-octagram-data/raw/refs/heads/${OCTAGRAM_DATA}/${GRAM}
    DOWNLOAD_NO_EXTRACT ON)
  FetchContent_MakeAvailable(${GRAM})
  moran_copy_file(${${GRAM}_SOURCE_DIR}/${GRAM})
endforeach()
