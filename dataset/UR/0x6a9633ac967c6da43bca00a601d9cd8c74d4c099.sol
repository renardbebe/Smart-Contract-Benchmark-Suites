 

pragma solidity 0.5.0;

 
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

 
contract HashStore is Ownable {
    mapping(bytes32 => uint256) private _hashes;
    event HashAdded(bytes32 hash);

    function addHash(bytes32 rootHash) external onlyOwner {
        require(_hashes[rootHash] == 0, "addHash: this hash was already deployed");

        _hashes[rootHash] = block.timestamp;
        emit HashAdded(rootHash);
    }

    function getHashTimestamp(bytes32 rootHash) external view returns (uint256) {
        return _hashes[rootHash];
    }
}