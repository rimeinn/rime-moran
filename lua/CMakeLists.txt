################
# Simplification
################
moran_configure(moran_processor.lua BASE lua)

set(USER_FACING
  moran_shijian.lua
  moran_charset_comment_filter.lua
  moran_pin.lua)
foreach(lua ${USER_FACING})
  moran_copy_file(${lua} BASE lua ${ARG_SIMPLIFY})
endforeach()

##################
# Normal lua files
##################
moran_copy_glob(GLOB *.lua EXCLUDE ${USER_FACING} BASE lua)
