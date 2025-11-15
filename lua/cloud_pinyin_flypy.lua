--[[
小鹤双拼 + 搜狗云输入
Ctrl+Shift+C 触发，上屏后自动写入用户词典
]]
local rime_user_path = rime_api.get_user_data_dir():gsub("\\", "/")
local cpath_dir = rime_user_path .. "/cpath/"
cpath_dir = cpath_dir:gsub("([^/])$", "%1/")
if cpath_dir ~= "" then
    package.cpath = package.cpath .. ";" .. cpath_dir .. "?.dll;" .. cpath_dir .. "?.so"
end

-- ==========  以下直接抄 sogou.lua 的依赖  ==========
local http   = require("simplehttp")
local iconv  = require("iconv")

-- 下面 4 个函数与 sogou.lua 完全一致
local function rc(x)
    local s = 0
    for i = 1, #x do s = s ~ string.byte(x, i) end
    return string.char(s)
end
local function serial_keys(keys)
    local tok = "\0\5\0\0\0\0\1"
    local tlen = #tok + #keys + 3
    local dat  = string.char(tlen) .. tok .. string.char(#keys) .. keys
    return dat .. rc(dat)
end
local function open_sogou(keys)
    local url = "http://shouji.sogou.com/web_ime/mobile.php?durtot=0&h=000000000000000&r=store_mf_wandoujia&v=3.7"
    return http.request(url, serial_keys(keys))
end
local function parse_result(bin)
    local words = {}
    if string.byte(bin,1)+2 ~= #bin then return words end
    local n = string.unpack("<H", bin:sub(0x12+1,0x12+2))
    if n==0 or n>32 then return words end
    local p = 0x14
    for i=1,n do
        local len = string.unpack("<H", bin:sub(p+1,p+2)); p=p+2
        if len>0 and len<0xFF then
            local w16 = bin:sub(p+1, p+len)
            local cd  = iconv.new("utf-8","utf-16le")
            local w,_ = cd:iconv(w16)
            if w then table.insert(words, w) end
        end
        p = p + len
        -- 跳过两个未知段
        len = string.unpack("<H", bin:sub(p+1,p+2)); p=p+2+len
        len = string.unpack("<H", bin:sub(p+1,p+2)); p=p+2+len+1
    end
    return words
end
local function get_cloud_words(keys)
    local body, code = open_sogou(keys)
    if code~=200 then return {} end
    return parse_result(body)
end
-- ==========  搜狗部分结束  ==========

-- 小鹤双拼 → 全拼 表（原文件已给出，此处省略，直接复用）
local flypy2qp_table = {
    ["aa"] = "a",
    ["ai"] = "ai",
    ["an"] = "an",
    ["ah"] = "ang",
    ["ao"] = "ao",
    ["ee"] = "e",
    ["ei"] = "ei",
    ["en"] = "en",
    ["eg"] = "eng",
    ["er"] = "er",
    ["oo"] = "o",
    ["ou"] = "ou",
    ["ba"] = "ba",
    ["bd"] = "bai",
    ["bj"] = "ban",
    ["bh"] = "bang",
    ["bk"] = "bao",
    ["bw"] = "bei",
    ["bf"] = "ben",
    ["bg"] = "beng",
    ["bi"] = "bi",
    ["bm"] = "bian",
    ["bl"] = "biang",
    ["bn"] = "biao",
    ["bp"] = "bie",
    ["bb"] = "bin",
    ["bk"] = "bing",
    ["bo"] = "bo",
    ["bu"] = "bu",
    ["ca"] = "ca",
    ["cd"] = "cai",
    ["cj"] = "can",
    ["ch"] = "cang",
    ["cc"] = "cao",
    ["ce"] = "ce",
    ["cw"] = "cei",
    ["cf"] = "cen",
    ["cg"] = "ceng",
    ["ia"] = "cha",
    ["id"] = "chai",
    ["ij"] = "chan",
    ["ih"] = "chang",
    ["ic"] = "chao",
    ["ie"] = "che",
    ["if"] = "chen",
    ["ig"] = "cheng",
    ["ii"] = "chi",
    ["is"] = "chong",
    ["iz"] = "chou",
    ["iu"] = "chu",
    ["ix"] = "chua",
    ["ik"] = "chuai",
    ["ir"] = "chuan",
    ["il"] = "chuang",
    ["iv"] = "chui",
    ["iy"] = "chun",
    ["io"] = "chuo",
    ["ci"] = "ci",
    ["cs"] = "cong",
    ["cb"] = "cou",
    ["cu"] = "cu",
    ["cr"] = "cuan",
    ["cv"] = "cui",
    ["cp"] = "cun",
    ["co"] = "cuo",
    ["da"] = "da",
    ["dd"] = "dai",
    ["dj"] = "dan",
    ["dh"] = "dang",
    ["dc"] = "dao",
    ["de"] = "de",
    ["dw"] = "dei",
    ["df"] = "den",
    ["dg"] = "deng",
    ["di"] = "di",
    ["dx"] = "dia",
    ["dm"] = "dian",
    ["dn"] = "diao",
    ["dt"] = "die",
    ["db"] = "din",
    ["dk"] = "ding",
    ["dq"] = "diu",
    ["ds"] = "dong",
    ["dz"] = "dou",
    ["du"] = "du",
    ["dr"] = "duan",
    ["dv"] = "dui",
    ["dp"] = "dun",
    ["do"] = "duo",
    ["fa"] = "fa",
    ["fj"] = "fan",
    ["fh"] = "fang",
    ["fw"] = "fei",
    ["ff"] = "fen",
    ["fg"] = "feng",
    ["fn"] = "fiao",
    ["fo"] = "fo",
    ["fs"] = "fong",
    ["fb"] = "fou",
    ["fu"] = "fu",
    ["ga"] = "ga",
    ["gd"] = "gai",
    ["gj"] = "gan",
    ["gh"] = "gang",
    ["gc"] = "gao",
    ["ge"] = "ge",
    ["gw"] = "gei",
    ["gf"] = "gen",
    ["gg"] = "geng",
    ["gs"] = "gong",
    ["gz"] = "gou",
    ["gu"] = "gu",
    ["gx"] = "gua",
    ["gk"] = "guai",
    ["gr"] = "guan",
    ["gl"] = "guang",
    ["gv"] = "gui",
    ["gp"] = "gun",
    ["go"] = "guo",
    ["ha"] = "ha",
    ["hd"] = "hai",
    ["hj"] = "han",
    ["hh"] = "hang",
    ["hc"] = "hao",
    ["he"] = "he",
    ["hw"] = "hei",
    ["hf"] = "hen",
    ["hg"] = "heng",
    ["hm"] = "hm",
    ["hs"] = "hong",
    ["hz"] = "hou",
    ["hu"] = "hu",
    ["hx"] = "hua",
    ["hk"] = "huai",
    ["hr"] = "huan",
    ["hl"] = "huang",
    ["hv"] = "hui",
    ["hp"] = "hun",
    ["ho"] = "huo",
    ["ji"] = "ji",
    ["jx"] = "jia",
    ["jm"] = "jian",
    ["jl"] = "jiang",
    ["jn"] = "jiao",
    ["jp"] = "jie",
    ["jb"] = "jin",
    ["jk"] = "jing",
    ["js"] = "jiong",
    ["jq"] = "jiu",
    ["ju"] = "ju",
    ["jr"] = "juan",
    ["jt"] = "jue",
    ["jy"] = "jun",
    ["ka"] = "ka",
    ["kd"] = "kai",
    ["kj"] = "kan",
    ["kh"] = "kang",
    ["kc"] = "kao",
    ["ke"] = "ke",
    ["kw"] = "kei",
    ["kf"] = "ken",
    ["kg"] = "keng",
    ["ks"] = "kong",
    ["kz"] = "kou",
    ["ku"] = "ku",
    ["kx"] = "kua",
    ["kk"] = "kuai",
    ["kr"] = "kuan",
    ["kl"] = "kuang",
    ["kv"] = "kui",
    ["kp"] = "kun",
    ["ko"] = "kuo",
    ["la"] = "la",
    ["ld"] = "lai",
    ["lj"] = "lan",
    ["lh"] = "lang",
    ["lc"] = "lao",
    ["le"] = "le",
    ["lw"] = "lei",
    ["lg"] = "leng",
    ["li"] = "li",
    ["lx"] = "lia",
    ["lm"] = "lian",
    ["ll"] = "liang",
    ["ln"] = "liao",
    ["lp"] = "lie",
    ["lb"] = "lin",
    ["lk"] = "ling",
    ["lq"] = "liu",
    ["ls"] = "long",
    ["lz"] = "lou",
    ["lu"] = "lu",
    ["lr"] = "luan",
    ["lt"] = "lue",
    ["lp"] = "lun",
    ["lo"] = "luo",
    ["lv"] = "lv",
    ["ma"] = "ma",
    ["md"] = "mai",
    ["mj"] = "man",
    ["mh"] = "mang",
    ["mc"] = "mao",
    ["me"] = "me",
    ["mw"] = "mei",
    ["mf"] = "men",
    ["mg"] = "meng",
    ["mi"] = "mi",
    ["mm"] = "mian",
    ["mn"] = "miao",
    ["mp"] = "mie",
    ["mb"] = "min",
    ["mk"] = "ming",
    ["mq"] = "miu",
    ["mo"] = "mo",
    ["mz"] = "mou",
    ["mu"] = "mu",
    ["na"] = "na",
    ["nd"] = "nai",
    ["nj"] = "nan",
    ["nh"] = "nang",
    ["nc"] = "nao",
    ["ne"] = "ne",
    ["nw"] = "nei",
    ["nf"] = "nen",
    ["ng"] = "neng",
    ["ni"] = "ni",
    ["nx"] = "nia",
    ["nm"] = "nian",
    ["nl"] = "niang",
    ["nn"] = "niao",
    ["np"] = "nie",
    ["nb"] = "nin",
    ["nk"] = "ning",
    ["nq"] = "niu",
    ["ns"] = "nong",
    ["nz"] = "nou",
    ["nu"] = "nu",
    ["nr"] = "nuan",
    ["nt"] = "nue",
    ["np"] = "nun",
    ["no"] = "nuo",
    ["nv"] = "nv",
    ["pa"] = "pa",
    ["pd"] = "pai",
    ["pj"] = "pan",
    ["ph"] = "pang",
    ["pc"] = "pao",
    ["pw"] = "pei",
    ["pf"] = "pen",
    ["pg"] = "peng",
    ["pi"] = "pi",
    ["px"] = "pia",
    ["pm"] = "pian",
    ["pn"] = "piao",
    ["pp"] = "pie",
    ["pb"] = "pin",
    ["pk"] = "ping",
    ["po"] = "po",
    ["pz"] = "pou",
    ["pu"] = "pu",
    ["qi"] = "qi",
    ["qx"] = "qia",
    ["qm"] = "qian",
    ["ql"] = "qiang",
    ["qn"] = "qiao",
    ["qp"] = "qie",
    ["qb"] = "qin",
    ["qk"] = "qing",
    ["qs"] = "qiong",
    ["qq"] = "qiu",
    ["qu"] = "qu",
    ["qr"] = "quan",
    ["qt"] = "que",
    ["qy"] = "qun",
    ["rj"] = "ran",
    ["rh"] = "rang",
    ["rc"] = "rao",
    ["re"] = "re",
    ["rf"] = "ren",
    ["rg"] = "reng",
    ["ri"] = "ri",
    ["rs"] = "rong",
    ["rz"] = "rou",
    ["ru"] = "ru",
    ["rx"] = "rua",
    ["rr"] = "ruan",
    ["rv"] = "rui",
    ["rp"] = "run",
    ["ro"] = "ruo",
    ["sa"] = "sa",
    ["sd"] = "sai",
    ["sj"] = "san",
    ["sh"] = "sang",
    ["sc"] = "sao",
    ["se"] = "se",
    ["sw"] = "sei",
    ["sf"] = "sen",
    ["sg"] = "seng",
    ["ua"] = "sha",
    ["ud"] = "shai",
    ["uj"] = "shan",
    ["uh"] = "shang",
    ["uc"] = "shao",
    ["ue"] = "she",
    ["uw"] = "shei",
    ["uf"] = "shen",
    ["ug"] = "sheng",
    ["ui"] = "shi",
    ["uz"] = "shou",
    ["uu"] = "shu",
    ["ux"] = "shua",
    ["uk"] = "shuai",
    ["ur"] = "shuan",
    ["ul"] = "shuang",
    ["uv"] = "shui",
    ["up"] = "shun",
    ["uo"] = "shuo",
    ["si"] = "si",
    ["ss"] = "song",
    ["sz"] = "sou",
    ["su"] = "su",
    ["sr"] = "suan",
    ["sv"] = "sui",
    ["sp"] = "sun",
    ["so"] = "suo",
    ["ta"] = "ta",
    ["td"] = "tai",
    ["tj"] = "tan",
    ["th"] = "tang",
    ["tc"] = "tao",
    ["te"] = "te",
    ["tw"] = "tei",
    ["tg"] = "teng",
    ["ti"] = "ti",
    ["tm"] = "tian",
    ["tn"] = "tiao",
    ["tp"] = "tie",
    ["tk"] = "ting",
    ["ts"] = "tong",
    ["tz"] = "tou",
    ["tu"] = "tu",
    ["tr"] = "tuan",
    ["tv"] = "tui",
    ["tp"] = "tun",
    ["to"] = "tuo",
    ["wa"] = "wa",
    ["wd"] = "wai",
    ["wj"] = "wan",
    ["wh"] = "wang",
    ["ww"] = "wei",
    ["wf"] = "wen",
    ["wg"] = "weng",
    ["wo"] = "wo",
    ["ws"] = "wong",
    ["wu"] = "wu",
    ["xi"] = "xi",
    ["xx"] = "xia",
    ["xm"] = "xian",
    ["xl"] = "xiang",
    ["xn"] = "xiao",
    ["xp"] = "xie",
    ["xb"] = "xin",
    ["xk"] = "xing",
    ["xs"] = "xiong",
    ["xq"] = "xiu",
    ["xu"] = "xu",
    ["xr"] = "xuan",
    ["xt"] = "xue",
    ["xy"] = "xun",
    ["ya"] = "ya",
    ["yd"] = "yai",
    ["yj"] = "yan",
    ["yh"] = "yang",
    ["yc"] = "yao",
    ["ye"] = "ye",
    ["yi"] = "yi",
    ["yb"] = "yin",
    ["yk"] = "ying",
    ["yo"] = "yo",
    ["ys"] = "yong",
    ["yz"] = "you",
    ["yu"] = "yu",
    ["yr"] = "yuan",
    ["yt"] = "yue",
    ["yp"] = "yun",
    ["za"] = "za",
    ["zd"] = "zai",
    ["zj"] = "zan",
    ["zh"] = "zang",
    ["zc"] = "zao",
    ["ze"] = "ze",
    ["zw"] = "zei",
    ["zf"] = "zen",
    ["zg"] = "zeng",
    ["va"] = "zha",
    ["vd"] = "zhai",
    ["vj"] = "zhan",
    ["vh"] = "zhang",
    ["vc"] = "zhao",
    ["ve"] = "zhe",
    ["vw"] = "zhei",
    ["vf"] = "zhen",
    ["vg"] = "zheng",
    ["vi"] = "zhi",
    ["vs"] = "zhong",
    ["vz"] = "zhou",
    ["vu"] = "zhu",
    ["vx"] = "zhua",
    ["vk"] = "zhuai",
    ["vr"] = "zhuan",
    ["vl"] = "zhuang",
    ["vv"] = "zhui",
    ["vp"] = "zhun",
    ["vo"] = "zhuo",
    ["zi"] = "zi",
    ["zs"] = "zong",
    ["zz"] = "zou",
    ["zu"] = "zu",
    ["zr"] = "zuan",
    ["zv"] = "zui",
    ["zp"] = "zun",
    ["zo"] = "zuo"
}
local function flypy_2_qp(input)
    local t = {}
    for i=1,#input,2 do
        local p = input:sub(i,i+1)
        if i+1>#input then p=input:sub(i) end
        table.insert(t, flypy2qp_table[p] or p)
    end
    return table.concat(t)
end

local flag = false
local function processor(key, env)
    local ctx = env.engine.context
    if key:repr()=="Control+q" and ctx:is_composing() then
        flag = true
        ctx:refresh_non_confirmed_composition()
        return 1
    end
    return 2
end

local translator = {}
function translator.init(env)
    env.mem = Memory(env.engine, env.engine.schema)
    env.notifier = env.engine.context.commit_notifier:connect(function(ctx)
        local c = ctx.commit_history:back()
        if c and c.type:sub(1,6)=="cloud:" then
            local code = c.type:sub(7)
            local e = DictEntry()
            e.text = c.text
            e.custom_code = code.." "
            env.mem:start_session()
            env.mem:update_userdict(e,1,"")
            env.mem:finish_session()
        end
    end)
end
function translator.fini(env)
    env.notifier:disconnect()
    env.mem:disconnect()
    env.mem = nil
    collectgarbage()
end

function translator.func(input, seg, env)
    if not flag then return end
    flag = false
    local qp = flypy_2_qp(input)
    local list = get_cloud_words(qp)      -- 改用搜狗
    for _,w in ipairs(list) do
        local c = Candidate("cloud:"..qp, seg.start, seg._end, w, "☁️搜狗")
        c.quality = 2
        c.preedit = qp
        c.type = "sougouyun"
        yield(c)
    end
end

return { processor = processor, translator = translator }