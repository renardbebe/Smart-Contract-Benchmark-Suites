 

pragma solidity ^0.4.24;

 
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

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

contract NodeList is Ownable {
  event NodeListed(address publicKey, uint256 epoch, uint256 position);

  struct Details {
    string declaredIp;
    uint256 position;
    uint256 pubKx;
    uint256 pubKy;
    string nodePort;
  }

  mapping (uint256 => mapping (address => bool)) whitelist;

  mapping (address => mapping (uint256 => Details)) public addressToNodeDetailsLog;  
  mapping (uint256 => address[]) public nodeList;  
  uint256 latestEpoch = 0;  

  constructor() public {
  }

   
  function viewNodes(uint256 epoch) external view  returns (address[], uint256[]) {
    uint256[] memory positions = new uint256[](nodeList[epoch].length);
    for (uint256 i = 0; i < nodeList[epoch].length; i++) {
      positions[i] = addressToNodeDetailsLog[nodeList[epoch][i]][epoch].position;
    }
    return (nodeList[epoch], positions);
  }

  function viewNodeListCount(uint256 epoch) external view returns (uint256) {
    return nodeList[epoch].length;
  }

  function viewLatestEpoch() external view returns (uint256) {
    return latestEpoch;
  }

  function viewNodeDetails(uint256 epoch, address node) external view  returns (string declaredIp, uint256 position, string nodePort) {
    declaredIp = addressToNodeDetailsLog[node][epoch].declaredIp;
    position = addressToNodeDetailsLog[node][epoch].position;
    nodePort = addressToNodeDetailsLog[node][epoch].nodePort;
  }

  function viewWhitelist(uint256 epoch, address nodeAddress) public view returns (bool) {
    return whitelist[epoch][nodeAddress];
  }

  modifier whitelisted(uint256 epoch) {
    require(whitelist[epoch][msg.sender]);
    _;
  }

  function updateWhitelist(uint256 epoch, address nodeAddress, bool allowed) public onlyOwner {
    whitelist[epoch][nodeAddress] = allowed;
  }

  function listNode(uint256 epoch, string declaredIp, uint256 pubKx, uint256 pubKy, string nodePort) external whitelisted(epoch) {
    nodeList[epoch].push(msg.sender); 
    addressToNodeDetailsLog[msg.sender][epoch] = Details({
      declaredIp: declaredIp,
      position: nodeList[epoch].length,  
      pubKx: pubKx,
      pubKy: pubKy,
      nodePort: nodePort
      });
     
    if (latestEpoch < epoch) {
      latestEpoch = epoch;
    }
    emit NodeListed(msg.sender, epoch, nodeList[epoch].length);
  }
}