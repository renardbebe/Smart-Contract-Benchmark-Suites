 

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

interface ITransferPolicy {
    function isTransferPossible(address from, address to, uint256 amount) 
        external view returns (bool);
    
    function isBehalfTransferPossible(address sender, address from, address to, uint256 amount) 
        external view returns (bool);
}

contract WhitelistTransferPolicy is ITransferPolicy, Ownable {
    mapping (address => bool) private whitelist;

    event AddressWhitelisted(address address_);
    event AddressUnwhitelisted(address address_);

    constructor() Ownable() public {}

    function isTransferPossible(address from, address to, uint256) public view returns (bool) {
        return (whitelist[from] && whitelist[to]);
    }

    function isBehalfTransferPossible(address sender, address from, address to, uint256) public view returns (bool) {
        return (whitelist[from] && whitelist[to] && whitelist[sender]);
    }

    function isWhitelisted(address address_) public view returns (bool) {
        return whitelist[address_];
    }

    function unwhitelistAddress(address address_) public onlyOwner returns (bool) {
        removeFromWhitelist(address_);
        return true;
    }

    function whitelistAddress(address address_) public onlyOwner returns (bool) {
        addToWhitelist(address_);
        return true;
    }

    function whitelistAddresses(address[] memory addresses) public onlyOwner returns (bool) {
        uint256 len = addresses.length;
        for (uint256 i; i < len; i++) {
            addToWhitelist(addresses[i]);
        }
        return true;
    }

    function unwhitelistAddresses(address[] memory addresses) public onlyOwner returns (bool) {
        uint256 len = addresses.length;
        for (uint256 i; i < len; i++) {
            removeFromWhitelist(addresses[i]);
        }
        return true;
    }

    function addToWhitelist(address address_) internal {
        whitelist[address_] = true;
        emit AddressWhitelisted(address_);
    }


    function removeFromWhitelist(address address_) internal {
        whitelist[address_] = false;
        emit AddressUnwhitelisted(address_);
    }
}