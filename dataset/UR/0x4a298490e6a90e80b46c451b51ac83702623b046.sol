 

pragma solidity ^0.5.0;

contract Owned {
    address payable public owner;
    address payable public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract MetalTracker is Owned {
     
    mapping(string => uint) metal;
    
    event MetalBalanceUpdated(string metalName);
    
    function getMetalBalance(string memory metalName) public view returns (uint balance) {
        return metal[metalName];
    }
    
    function updateBalance(string memory metalName, uint newAmount) public onlyOwner {
        require(newAmount >= 0);
        emit MetalBalanceUpdated(metalName);
        metal[metalName] = newAmount;
    }
}