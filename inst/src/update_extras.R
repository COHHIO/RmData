if (!exists("dirs"))
  dirs <- clarity.looker::dirs
cl_api$get_folder_looks(cl_api$folders, .write = TRUE, path = dirs$extras)
beepr::beep(3)
