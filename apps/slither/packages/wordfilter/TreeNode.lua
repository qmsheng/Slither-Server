
local TreeNode = cc.class("TreeNode")

function TreeNode:ctor()
    self.data = {}
	self._isLeaf = false
	--是否是敏感词的词尾字，敏感词树的叶子节点必然是词尾字，父节点不一定是
	self.isEnd = false;
	self.parent = nil
	self.value = ""
end

function TreeNode:getChild(name)
	return self.data[name];
end

function TreeNode:addChild(name)
	local node = TreeNode:new()
	self.data[name] = node;
	node.value = name;
	node.parent = self
	return node
end

function TreeNode:getFullWord()
    local rt = self.value;
    local node = self.parent;
    while node do
        rt = node.value .. rt;
        node = node.parent;
    end
    return rt;
end

function TreeNode:isLeaf()
	local index = 0;
    for k,v in pairs(self.data) do
        index = index +1
    end
	self._isLeaf = (index == 0)
	return self._isLeaf;
end

return TreeNode
