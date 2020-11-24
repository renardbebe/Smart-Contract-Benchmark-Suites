 

 

pragma solidity ^0.5.2;

 
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

 

 
 
pragma solidity 0.5.7;


contract Utils {
     
    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "invalid address");
        _;
    }
}

 

 
 
 pragma solidity 0.5.7;



contract Manageable is Ownable, Utils {
    mapping(address => bool) public isManager;      

     
    event ChangedManager(address indexed manager, bool active);

     
    modifier onlyManager() {
        require(isManager[msg.sender], "is not manager");
        _;
    }

     
    constructor() public {
        setManager(msg.sender, true);
    }

     
    function setManager(address _manager, bool _active) public onlyOwner onlyValidAddress(_manager) {
        isManager[_manager] = _active;
        emit ChangedManager(_manager, _active);
    }

     
    function renounceOwnership() public onlyOwner {
        revert("Cannot renounce ownership");
    }
}

 

 

pragma solidity 0.5.7;




contract GlobalWhitelist is Ownable, Manageable {
    mapping(address => bool) public isWhitelisted;  
    bool public isWhitelisting = true;              

     
    event ChangedWhitelisting(address indexed registrant, bool whitelisted);
    event GlobalWhitelistDisabled(address indexed manager);
    event GlobalWhitelistEnabled(address indexed manager);

     
    function addAddressToWhitelist(address _address) public onlyManager onlyValidAddress(_address) {
        isWhitelisted[_address] = true;
        emit ChangedWhitelisting(_address, true);
    }

     
    function addAddressesToWhitelist(address[] calldata _addresses) external {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addAddressToWhitelist(_addresses[i]);
        }
    }

     
    function removeAddressFromWhitelist(address _address) public onlyManager onlyValidAddress(_address) {
        isWhitelisted[_address] = false;
        emit ChangedWhitelisting(_address, false);
    }

     
    function removeAddressesFromWhitelist(address[] calldata _addresses) external {
        for (uint256 i = 0; i < _addresses.length; i++) {
            removeAddressFromWhitelist(_addresses[i]);
        }
    }

     
    function toggleWhitelist() external onlyOwner {
        isWhitelisting = isWhitelisting ? false : true;

        if (isWhitelisting) {
            emit GlobalWhitelistEnabled(msg.sender);
        } else {
            emit GlobalWhitelistDisabled(msg.sender);
        }
    }
}