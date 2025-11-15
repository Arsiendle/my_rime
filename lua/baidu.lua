local json = require("json")

-- 获取 Rime 用户目录并统一用“/”
local rime_user_path = rime_api.get_user_data_dir():gsub("\\", "/")

-- 拼出 cpath 目录，确保结尾有“/”
local cpath_dir = rime_user_path .. "/cpath/"
cpath_dir = cpath_dir:gsub("([^/])$", "%1/")

-- 把 cpath 目录加入 DLL 搜索路径
if cpath_dir ~= "" then
    package.cpath = package.cpath .. ";" .. cpath_dir .. "?.dll;" .. cpath_dir .. "?.so"
end

local http = require("simplehttp")
http.TIMEOUT = 0.5

local function make_url(input, bg, ed)
   return 'https://olime.baidu.com/py?input=' .. input ..
      '&inputtype=py&bg='.. bg .. '&ed='.. ed ..
      '&result=hanzi&resultcoding=utf-8&ch_en=0&clientinfo=web&version=1'
end

local function translator(input, seg)
   local url = make_url(input, 0, 5)
   local reply = http.request(url)
   local _, j = pcall(json.decode, reply)
   if j.status == "T" and j.result and j.result[1] then
      for i, v in ipairs(j.result[1]) do
	 local c = Candidate("simple", seg.start, seg.start + v[2], v[1], "(百度云拼音)")
	 c.quality = 2
	 if string.gsub(v[3].pinyin, "'", "") == string.sub(input, 1, v[2]) then
	    c.preedit = string.gsub(v[3].pinyin, "'", " ")
	 end
	 yield(c)
      end
   end
end

return translator
