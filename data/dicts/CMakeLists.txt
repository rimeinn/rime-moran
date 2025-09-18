function(add_dict dict)
  moran_add_file(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${dict}"
    INPUT "${CMAKE_CURRENT_SOURCE_DIR}/${dict}"
    COMMAND ${UV} run schemagen.py dict-from-py --rime-dict <INPUT> > <OUTPUT>
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}/tools"
    ${SIMPLIFY})
endfunction()

add_dict(moran.base.dict.yaml)
add_dict(moran.computer.dict.yaml)
add_dict(moran.moe.dict.yaml)
add_dict(moran.tencent.dict.yaml)
