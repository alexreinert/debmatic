if _G.bit32 then
  return _G.bit32;
else
  local ok, bitop = pcall(require, "bit32")
  if ok then
    return bitop;
  end
end

do
  local ok, bitop = pcall(require, "bitnative")
  if ok then
    return bitop;
  end
end

do
  local ok, bitop = pcall(require, "bit")
  if ok then
    return bitop;
  end
end

error "No bit compatible bit module found.";

