 

pragma solidity 0.4.24;


 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Can only be called by the owner");
        _;
    }

    modifier onlyValidAddress(address addr) {
        require(addr != address(0), "Address cannot be zero");
        _;
    }

     
    constructor() public {
        owner = msg.sender;
    }

     
    function transferOwnership(address newOwner)
        public
        onlyOwner
        onlyValidAddress(newOwner)
    {
        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;
    }
}


 
contract Migrations is Ownable {
     
    uint256 public last_completed_migration;

    function setCompleted(uint256 completed) public onlyOwner {
        last_completed_migration = completed;
    }

     
    function upgrade(address new_address) public onlyOwner {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}