require("..tools")
require("..debug")

local header = {0x46,0x49,0x4E,0x53,0xDF,0x00,0x0E,0x00,0x46,0x4D,0x14,
                0x00,0xF2,0x10,0x00,0x00,0x51,0x00,0x0F,0x00,0x40,0xFF,
                0x00,0x00,0x51,0x00,0x0F,0x00,0x40,0xFF,0x00,0x00,0x4D,
                0x41,0x0A,0x01,0x08,0x00,0x01,0xFF,0xFF,0xFF,0x00,0x41,
                0x00,0x01
}
local mider = {0xFF, 0x4F, 0x1F, 0x11, 0x02, 0x08, 0x00, 0x03, 0xFF, 0xFF, 0xFF, 0x00, 0x01, 0x00, 0x01} --yDM header

local mider2 = {0x06, 0xFF, 0xFF, 0xFF, 0x00, 0x01, 0x00, 0x01} --yTL header
local ender = {0xff}

local default_step = {} --默认步长
local compress_step = 0 --是否压缩步长
local last_yTL = {}
local last_yDM = {}
local note_to_pitch = {C = 0, D = 2, E = 4, F = 5, G = 7, A = 9, B = 11}
local current_pitch = 4
local current_note = 0

function process_note(pitch, note)
    local k = 1
    local note2 = string.sub(note, 1, 1)
    local temp = note_to_pitch[string.upper(note2)]
    if note2 ~= nil and temp ~= nil then
        if string.len(note) > 1 then
            local flag = string.sub(note, 2, 2)
            if flag == "+" then
                temp = temp + 1
            elseif flag == "-" then
                temp = temp - 1
            end
            k = k + 1
        end
        local tpitch = 12 * (pitch - 4)
        note = temp + tpitch
    end
    return k, note
end


function parse_mml_line(channel, line)
    if line == nil or line == "" then
        return nil, nil
    end
    local yTL = {}
    local yDM = {}
    local tyTL = {}
    local tyDM = {}
    local arp = {}
    local strlen = string.len(line)
    local k = 1
    -- print ("line="..line)

    while k <= strlen do
        local v = string.sub(line, k, k)
        --print("v="..v.." "..k)
        if k == 0 then
        else
            if v == " " or v == "\n" or v == "\r" or v == "\t" then
            elseif string.match(line, "^([A-Ga-g][+-]?)", k) then --缺少O的情况处理
                current_note = string.match(line, "([A-Ga-g][+-]?)", k)
                --print("create note="..current_note.." current_pitch="..current_pitch)
                k = k + string.len(current_note)
                local off, tmp = process_note(current_pitch, current_note)
                table.insert(arp, tmp)
                k = k + off
                --dump(last_yTL, "last_yTL")
                --dump(last_yDM, "last_yDM")
                for i = 1, 4 do
                    if yTL[i] == nil then
                        yTL[i] = {}
                    end
                    if tyTL[i] == nil then
                        tyTL[i] = {last_yTL[i]}
                    end
                    yTL[i] = tyTL[i]

                    if yDM[i] == nil then
                        yDM[i] = {}
                    end
                    if tyDM[i] == nil then
                        tyDM[i] = {last_yDM[i]}
                    end
                    yDM[i] = tyDM[i]
                end
            elseif v == "O" or v == "o" then
                current_pitch, current_note = string.match(line, "(%d+)([A-Ga-g][+-]?)", k)
                --print("current_pitch="..current_pitch.." note="..current_note)
                k = k + string.len(current_pitch) + string.len(current_note)
                if current_note ~= nil then
                    local off, tmp = process_note(current_pitch, current_note)
                    table.insert(arp, tmp)
                    k = k + off
                    --print("note val="..current_note.." temp="..temp)
                    --遍历yTL和yDM,如果有缺失,则使用上一次的值填充
                    for i = 1, 4 do
                        if yTL[i] == nil then
                            yTL[i] = {}
                        end
                        if tyTL[i] == nil then
                            tyTL[i] = {last_yTL[i]}
                        end
                        yTL[i] = tyTL[i]

                        if yDM[i] == nil then
                            yDM[i] = {}
                        end
                        if tyDM[i] == nil then
                            tyDM[i] = {last_yDM[i]}
                        end
                        yDM[i] = tyDM[i]
                    end
                end
            elseif v == "&" then
            elseif v == "%" then
                local cur, skip = string.match(line, "(%d+)(@%d+T%d+)")
                if cur ~= nil then
                    default_step[channel] = math.floor(cur) - compress_step
                    if default_step[channel] <= 0 then
                        default_step[channel] = 1
                    end
                    --print("default_step1="..default_step[channel])
                    k = k + string.len(cur) + string.len(skip)
                end
            elseif v == "R" or v == "r" then
                for i = 1, 4 do
                    if yTL[i] == nil then
                        yTL[i] = {}
                    end
                    yTL[i] = {0}

                    if yDM[i] == nil then
                        yDM[i] = {}
                    end
                    yDM[i] = {0}
                end

                table.insert(arp, 0)
            else
                --print("cur_node="..string.sub(line,k))
                local idx, val = string.match(line, "^yTL,(%d+),(%d+)", k)
                if idx ~= nil then
                    --print ("node="..idx.." val="..val)
                    idx = tonumber(idx)
                    if tyTL[idx] == nil then
                        tyTL[idx] = {}
                    end
                    table.insert(tyTL[idx], tonumber(val))
                    last_yTL[idx] = tonumber(val)
                    k = k + string.len(idx) + string.len(val) + 4
                else
                    local idx, val = string.match(line, "^yDM,(%d+),(%d+)", k)
                    if idx ~= nil then
                        --print ("yDM="..idx.." val="..val)
                        idx = tonumber(idx)
                        if tyDM[idx] == nil then
                            tyDM[idx] = {}
                        end
                        table.insert(tyDM[idx], tonumber(val))
                        last_yDM[idx] = tonumber(val)
                        k = k + string.len(idx) + string.len(val) + 4
                    end
                end
            end
        end
        k = k + 1
        -- print("next="..string.sub(line,k))
    end

    --print("k="..k.." "..strlen)
    --dump(yTL, "yTL")
    --dump(yDM, "yDM")
    tyTL = nil
    tyDM = nil
    return yTL, yDM, arp
end

function fileWriteData(file, data, offset)
    if file then
        file:seek("set", tonumber(offset))
        for k, v in ipairs(data) do
            if file:write(string.char(v)) == nil then
                break
            end
        end
    end
end

--[[获取命令行参数,并解析输出目录]]
local argCount = #arg

local input = "..\\t1.txt"
local output = ".\\fui"
if argCount >= 2 then
    input = arg[1]
    if arg[2] ~= nil then
        output = arg[2] .. "\\"
        output = string.gsub(output, "\\", "\\\\")
        output = string.gsub(output, "[/\\]*$", "")
        if os.execute("cd " .. '"' .. output .. '" >nul 2>nul') ~= 0 then
            os.execute("mkdir " .. output)
        end
        output = output .. "\\"
    end

    --print(arg[3])
    if arg[3] ~= nil then
        compress_step = string.match(arg[3], "-r(%d+)")
        if compress_step ~= nil then
            compress_step = math.floor(compress_step)
            if compress_step < 0 or compress_step > 9 then
                compress_step = 0
            end
        else
            compress_step = 0
        end
    end
else
    local info = io.pathinfo(arg[0])
    print(info.filename .. "  input.txt output_dir")
    --print("-r[0~9] compress setp to 0~9,default is 0")
    return
end

--[[打开输入文件并读入内存]]
local infile = io.open(input, "r")
local content
local channel = {}
if infile == nil then
    return
end
content = infile:read("*all")
infile:close()

--print(content)
content = string.trim(content)
content = string.gsub(content, "\n\n", "\n") --删除空行
content = string.gsub(content, "^\t", "") --删除开头空行
content = string.gsub(content, "^\n", "") --删除开头空行
content = string.gsub(content, "^\r", "") --删除开头空行
content = string.gsub(content, "^\t", "") --删除开头空行
content = string.gsub(content, "^\r\n", "") --删除开头空行
--print(content)
local line = string.split(content, "\n")

local flag
for k, v in pairs(line) do
    flag = string.sub(v, 1, 1)
    -- print("flag="..flag)
    if flag ~= "A" and flag ~= "B" and flag ~= "C" then
        line[k] = ""
    end
end

--清除空行
local tmp_line = {}
for k, v in pairs(line) do
    if #v > 0 then
        table.insert(tmp_line, v)
    end
end
line = tmp_line

--针对代码中有[r]x的情况,将其扩展为x个r
tmp_line={}
for k, v in pairs(line) do
    local sp = string.split(v, " ")
    local cur= string.match(sp[2], "%[r%](%d+)")
    if cur ~= nil then
        for i=1,tonumber(cur) do
            table.insert( tmp_line, sp[1].. " ".."r" )
        end
    else
       table.insert( tmp_line, v )
    end
end
line = tmp_line
--dump(line)


--[[解析拆分原始数据到通道数组]]
for k, v in ipairs(line) do
    --dump(v,k)
    sp = string.split(v, " ")

    if sp ~= nil and sp[1] ~= "" then
        if default_step[sp[1]] == nil then
            default_step[sp[1]] = 1
        end
        if channel[sp[1]] == nil then
            channel[sp[1]] = {yTL = {}, yDM = {}, arp = {}}
        end

        local yTL, yDM, arp = parse_mml_line(sp[1], sp[2])
        if yTL ~= nil and yDM ~= nil then
            for m, n in ipairs(yTL) do
                if channel[sp[1]].yTL[m] == nil then
                    channel[sp[1]].yTL[m] = {}
                end
                table.insertTo(channel[sp[1]].yTL[m], n, #channel[sp[1]].yTL[m] + 1)
            end
            for m, n in ipairs(yDM) do
                if channel[sp[1]].yDM[m] == nil then
                    channel[sp[1]].yDM[m] = {}
                end

                table.insertTo(channel[sp[1]].yDM[m], n, #channel[sp[1]].yDM[m] + 1)
            end
            --for i=1,4 do
            table.insertTo(channel[sp[1]].arp, arp, #channel[sp[1]].arp + 1)
        --end
        end
    end
    --dump(channel)
end
--dump(channel,"channel")
--bp.bp()

--[[将解析后的通道数据分别写入txt文件和缓存数组
txt按照原始格式,每个类型最多255个数据,每个数据占一行,数据间用空格隔开
缓存数组按照fui格式,每个通道一个文件,每个文件包含header,vol,mider,arp,ender
fui每通道最大数据量只有255字节,所以先将数据按照255个数据分割,然后存入临时数组备用,
最后将临时数组写入fui文件
]]
local start = 0
local bin_yTL = {}
local bin_yDM = {}
local bin_arp = {}
local idx = {}

for k, v in pairs(channel) do
    local temp = io.open(output .. "channel_" .. k .. ".txt", "w")
    bin_yTL[k] = {}
    bin_yDM[k] = {}
    bin_arp[k] = {}
    idx[k] = 1
    print("Ch=" .. k .. " arp " .. (#v.arp))

    for m = 1, #v.arp, 255 do
        bin_arp[k][idx[k]] = {}
        temp:write("arp\n")
        for i = 1, 255 do
            local dat = v.arp[i + m - 1]
            if dat == nil then
                dat = 0
            end
            temp:write(dat .. " ")
            dat = tonumber(dat)

            if dat < 0 then --负数使用补码方式存储
                dat = 256 + dat
            end
            table.insert(bin_arp[k][idx[k]], dat)
        end
        temp:write("\n")

        for j = 1, 4 do
            if bin_yTL[k][j] == nil then
                bin_yTL[k][j] = {}
            end
            if bin_yTL[k][j][idx[k]] == nil then
                bin_yTL[k][j][idx[k]] = {}
            end
            temp:write("yTL" .. j .. "\n")
            for i = 1, 255 do
                local dat = v.yTL[j][i + m - 1]
                if dat == nil then
                    --break
                    dat = 0
                end
                temp:write(dat .. " ")
                dat = tonumber(dat)
                if dat < 0 then --负数使用补码方式存储
                    dat = 256 + dat
                end
                table.insert(bin_yTL[k][j][idx[k]], dat)
            end
            temp:write("\n")
        end
        for j = 1, 4 do
            if bin_yDM[k][j] == nil then
                bin_yDM[k][j] = {}
            end
            if bin_yDM[k][j][idx[k]] == nil then
                bin_yDM[k][j][idx[k]] = {}
            end
            temp:write("yDM" .. j .. "\n")
            for i = 1, 255 do
                local dat = v.yDM[j][i + m - 1]
                if dat == nil then
                    --break
                    dat = 0
                end
                temp:write(dat .. " ")
                dat = tonumber(dat)
                if dat < 0 then --负数使用补码方式存储
                    dat = 256 + dat
                end
                table.insert(bin_yDM[k][j][idx[k]], dat)
            end
            temp:write("\n")
        end

        idx[k] = idx[k] + 1
    end
    io.close(temp)
    --break

    --dump(bin_yTL["C"][1])
end

--dump(bin_yDM)

for k, v in pairs(channel) do
    for m, n in ipairs(bin_arp[k]) do
        print("m=" .. m)
        local idx = string.format("%02d", m)
        local filenameA = output .. idx .. "-A-ch-" .. k .. ".fui"
        local filenameB = output .. idx .. "-B-ch-" .. k .. ".fui"
        local fileA = io.open(filenameA, "w+b")
        local fileB = io.open(filenameB, "w+b")
        local offset = {}

        offset[1] = 0
        offset[2] = #header
        offset[3] = offset[2] + #n

        fileWriteData(fileA, header, offset[1])
        fileWriteData(fileA, n, offset[2])
        fileWriteData(fileB, header, offset[1])
        fileWriteData(fileB, n, offset[2])

        local lenA = offset[3]
        local lenB = offset[3]
        local serial = {1, 2, 3, 4} --写入数据顺序不是顺向的,2和3要交换位置
        for i, j in ipairs(serial) do
            mider[3] = 0x30 + i  --更新数据id,这个是fui的标准格式定义的
            if j>=3 then
               mider[3]=mider[3]-2  --两组数据的id是分别计算的,所以B组的id要减2
               fileWriteData(fileB, mider, lenB)            
               lenB = lenB + #mider    
               fileWriteData(fileB, bin_yDM[k][j][m], lenB)
               lenB = lenB + #bin_yDM[k][j][m]
               fileWriteData(fileB, mider2, lenB)
               lenB = lenB + #mider2
               fileWriteData(fileB, bin_yTL[k][j][m], lenB)
               lenB = lenB + #bin_yTL[k][j][m]
            else
               fileWriteData(fileA, mider, lenA)
               lenA = lenA + #mider
               fileWriteData(fileA, bin_yDM[k][j][m], lenA)
               lenA = lenA + #bin_yDM[k][j][m]
               fileWriteData(fileA, mider2, lenA)
               lenA = lenA + #mider2
               fileWriteData(fileA, bin_yTL[k][j][m], lenA)
               lenA = lenA + #bin_yTL[k][j][m]               
            end
        end

        fileWriteData(fileA, ender, lenA)
        fileWriteData(fileB, ender, lenB)
        io.close(fileA)
        io.close(fileB)
    end
end
