window.summarizeWin = (ach) ->
  ret = ""
  if ach.desc?
    ret += ach.desc
  if ach.points?
    if ret != ""
      ret += " and "
    ret += ""+ach.points+" points"
  ret
