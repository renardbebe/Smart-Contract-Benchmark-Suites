 

pragma solidity ^0.5.0;

 
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

contract AddressWhitelist is Ownable {
    enum Status { None, In, Out }
    mapping(address => Status) private whitelist;

    address[] private whitelistIndices;

     
    function addToWhitelist(address newElement) external onlyOwner {
         
        if (whitelist[newElement] == Status.In) {
            return;
        }

         
        if (whitelist[newElement] == Status.None) {
            whitelistIndices.push(newElement);
        }

        whitelist[newElement] = Status.In;

        emit AddToWhitelist(newElement);
    }

     
    function removeFromWhitelist(address elementToRemove) external onlyOwner {
        if (whitelist[elementToRemove] != Status.Out) {
            whitelist[elementToRemove] = Status.Out;
            emit RemoveFromWhitelist(elementToRemove);
        }
    }

     
    function isOnWhitelist(address elementToCheck) external view returns (bool) {
        return whitelist[elementToCheck] == Status.In;
    }

     
     
     
     
     
     
    function getWhitelist() external view returns (address[] memory activeWhitelist) {
         
        uint activeCount = 0;
        for (uint i = 0; i < whitelistIndices.length; i++) {
            if (whitelist[whitelistIndices[i]] == Status.In) {
                activeCount++;
            }
        }

         
        activeWhitelist = new address[](activeCount);
        activeCount = 0;
        for (uint i = 0; i < whitelistIndices.length; i++) {
            address addr = whitelistIndices[i];
            if (whitelist[addr] == Status.In) {
                activeWhitelist[activeCount] = addr;
                activeCount++;
            }
        }
    }

    event AddToWhitelist(address indexed addedAddress);
    event RemoveFromWhitelist(address indexed removedAddress);
}