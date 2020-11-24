 

pragma solidity ^0.5.3;

 

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

contract Approvable is Ownable {
    mapping(address => bool) private _approvedAddress;


    modifier onlyApproved() {
        require(isApproved());
        _;
    }

    function isApproved() public view returns(bool) {
        return _approvedAddress[msg.sender] || isOwner();
    }

    function approveAddress(address _address) public onlyOwner {
        _approvedAddress[_address] = true;
    }

    function revokeApproval(address _address) public onlyOwner {
        _approvedAddress[_address] = false;
    }
}

 

contract StoringCreationMeta {
    uint public creationBlock;
    uint public creationTime;

    constructor() internal {
        creationBlock = block.number;
        creationTime = block.timestamp;
    }
}

 

contract NodeRegistry is StoringCreationMeta, Approvable {
    mapping(address => string) public nodeIp;
    mapping(address => string) public nodeWs;

    mapping(address => uint) public nodeCountLimit;

    struct NodeList {
        address[] items;
        mapping(address => uint) position;
    }
    mapping(address => NodeList) userNodes;
    NodeList availableNodes;

    modifier onlyRegisteredNode() {
        require(
            availableNodes.position[msg.sender] > 0,
            "Node not registered."
        );
        _;
    }

    function registerNodes(address[] memory _nodeAddresses) public {
        NodeList storage _nodes = userNodes[msg.sender];

        require(
            nodeCountLimit[msg.sender] >=
            _nodes.items.length + _nodeAddresses.length,
            "Over the limit."
        );

        for(uint i = 0; i < _nodeAddresses.length; i++) {
             
            if(_nodes.position[_nodeAddresses[i]] == 0) {
                registerNode(_nodeAddresses[i]);
            }
        }
    }

    function deregisterNodes(address[] memory _nodeAddresses) public {
        for(uint i = 0; i < _nodeAddresses.length; i++) {
            deregisterNode(_nodeAddresses[i]);
        }
    }

    function deregisterNode(address _nodeAddress) private {
        NodeList storage _nodes = userNodes[msg.sender];

        if(_nodes.position[_nodeAddress] == 0) {
            revert("Node not registered.");
        }

        removeFromList(_nodes, _nodeAddress);
        removeFromList(availableNodes, _nodeAddress);

        delete nodeIp[_nodeAddress];
        delete nodeWs[_nodeAddress];
    }

    function removeFromList(NodeList storage _nodes, address _item) private {
        uint nIndex = _nodes.position[_item] - 1;
        uint lastIndex = _nodes.items.length - 1;
        address lastItem = _nodes.items[lastIndex];

        _nodes.items[nIndex] = lastItem;
        _nodes.position[lastItem] = nIndex + 1;
        _nodes.position[_item] = 0;

        _nodes.items.pop();
    }

    function registerNode(address _nodeAddress) private {
        NodeList storage _nodes = userNodes[msg.sender];

        if(availableNodes.position[_nodeAddress] != 0) {
            revert("Node already registered by another user.");
        }

         
        _nodes.items.push(_nodeAddress);
        _nodes.position[_nodeAddress] = _nodes.items.length;

         
        availableNodes.items.push(_nodeAddress);
        availableNodes.position[_nodeAddress] = availableNodes.items.length;
    }

    function getAvailableNodes() public view returns(address[] memory) {
        return availableNodes.items;
    }

    function getUserNodes(address _user) public view returns(address[] memory) {
        return userNodes[_user].items;
    }

    function setNodeLimits(address[] memory _users, uint[] memory _limits) public onlyApproved {
        require(_users.length == _limits.length, "Length mismatch.");

        for(uint i = 0; i < _users.length; ++i) {
            _setNodeLimit(_users[i], _limits[i]);
        }
    }

    function _setNodeLimit(address _user, uint _limit) private {
        nodeCountLimit[_user] = _limit;

        _pruneUserNodes(_user, _limit);
    }

    function _pruneUserNodes(address _user, uint _limit) private view {
        if (_limit >= nodeCountLimit[_user]) {
            return;
        }
    }

    function registerNodeIp(string memory _ip) public onlyRegisteredNode {
        nodeIp[msg.sender] = _ip;
    }

    function registerNodeWs(string memory _ws) public onlyRegisteredNode {
        nodeWs[msg.sender] = _ws;
    }

    function registerNodeIpAndWs(string memory _ip, string memory _ws) public onlyRegisteredNode {
        nodeIp[msg.sender] = _ip;
        nodeWs[msg.sender] = _ws;
    }

    function getNodeIpAndWs(address _node) public view returns(string memory, string memory) {
        return (nodeIp[_node], nodeWs[_node]);
    }
}