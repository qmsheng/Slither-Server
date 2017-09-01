local SensitiveWordFilter = cc.class("SensitiveWordFilter")
local TreeNode = cc.import(".TreeNode")
local treeRoot
local utf8 = require("utf8")


function SensitiveWordFilter:ctor()
end

function SensitiveWordFilter:get_chinese_char(str, index)
	local start = (index-1) * 3 + 1
	return str:sub(start, start + 2)
end

function SensitiveWordFilter:get_char(str, index)
    local start = (index-1) * 1 + 1
    return str:sub(start, start)
end

function SensitiveWordFilter:regSensitiveWords(words)
	--这是一个预处理步骤，生成敏感词索引树，功耗大于查找时使用的方法，但只在程序开始时调用一次。
	treeRoot = TreeNode:new()
	treeRoot.value = "";
	local words_len = #words
    for i=1,words_len do
        local word = string.upper(words[i]);
        local _, count = string.gsub(word, "[^\128-\193]", "")
        local len = count
        local currentBranch = treeRoot;

        local utfcode = {utf8.byte(word,1,-1)}

        for i=1,len do
            local char
            if utfcode[i] <= 127 then
               char = self:get_char(word,i)
            elseif utfcode[i] <= 65535 then
               char = self:get_chinese_char(word,i)
            end

			local tmp = currentBranch:getChild(char);
            if tmp then
				currentBranch = tmp
			else
				currentBranch = currentBranch:addChild(char);
			end
        end
        currentBranch.isEnd = true;
    end
end


function SensitiveWordFilter:get_chinese_char2(str, index)
    local start = index
    return str:sub(start, start + 2)
end

function SensitiveWordFilter:get_char2(str, index)
    local start = index
    return str:sub(start, start)
end


function SensitiveWordFilter:replaceSensitiveWord(dirtyWords)
    local char
    local curTree = treeRoot
    local childTree
    local curEndWordTree
    local dirtyWord
	local hasDirty = false
    local c = 1          --循环索引
    local endIndex = 1   --词尾索引
    local headIndex = -1 --敏感词词首索引
	dirtyWords = string.upper(dirtyWords)
    local _, count = string.gsub(dirtyWords, "[^\128-\193]", "")
    local utfcode = {utf8.byte(dirtyWords,1,-1)}

    local getWordIndex = function (index , utfcode)
        if index == 1 then
            return 1
        end
        local wordIndex = 1
        for i=1 , index-1 do
           if utfcode[i] <= 127 then
              wordIndex = wordIndex + 1
           elseif utfcode[i] <= 65535 then
              wordIndex = wordIndex + 3
           end
        end
        return wordIndex
    end

    while c <= count do
        local wordLen
        if utfcode[c] <= 127 then
            local w = getWordIndex(c , utfcode)
            char = self:get_char2(dirtyWords,w)
            wordLen = 1
        elseif utfcode[c] <= 65535 then
             local w = getWordIndex(c , utfcode)
            char = self:get_chinese_char2(dirtyWords,w)
            wordLen = 3
        end
--          print(char)

--    	char = self:get_chinese_char(dirtyWords,c)
    	childTree = curTree:getChild(char);
    	if childTree then
    		if childTree.isEnd then
    			curEndWordTree = childTree;
    			endIndex = c;
    		end
    		if headIndex == -1 then
    			headIndex = c;
    		end
    		curTree = childTree;
    		c = c + 1
    	else
    		if curEndWordTree then--如果之前有遍历到词尾，则替换该词尾所在的敏感词，然后设置循环索引为该词尾索引
    			dirtyWord = curEndWordTree:getFullWord();
				dirtyWords = string.gsub(dirtyWords , dirtyWord , self:getReplaceWord(wordLen))
    			c = endIndex;
				hasDirty = true
    		elseif curTree ~= treeRoot then--如果之前有遍历到敏感词非词尾，匹配部分未完全匹配，则设置循环索引为敏感词词首索引
    			c = headIndex;
    			headIndex = -1;
    		end
    		curTree = treeRoot;
    		curEndWordTree = nil;
    		c = c + 1
    	end
    end

    --循环结束时，如果最后一个字符满足敏感词词尾条件，此时满足条件，但未执行替换，在这里补加
    if curEndWordTree then

    	dirtyWord = curEndWordTree:getFullWord();
		dirtyWords = string.gsub(dirtyWords , dirtyWord , self:getReplaceWord(#dirtyWord))
		hasDirty = true
    end

    return hasDirty,dirtyWords;
end

function SensitiveWordFilter:getReplaceWord(len)
	local replaceWord = "";
    for i=1,len do
        replaceWord = replaceWord .. "*";
    end
	return replaceWord;
end

return SensitiveWordFilter
