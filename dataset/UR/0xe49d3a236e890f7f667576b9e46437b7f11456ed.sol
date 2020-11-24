 

pragma solidity ^0.4.24;

 

 
contract IOwned {
     
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 

 
contract IAddressList {
    mapping (address => bool) public listedAddresses;
}

 

 
contract NonStandardTokenRegistry is IAddressList, Owned {

    mapping (address => bool) public listedAddresses;

     
    constructor() public {

    }

    function setAddress(address token, bool register) public ownerOnly {
        listedAddresses[token] = register;
    }
}