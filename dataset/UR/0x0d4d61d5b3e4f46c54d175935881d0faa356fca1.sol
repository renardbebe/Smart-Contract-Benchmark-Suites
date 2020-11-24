 

pragma solidity ^0.4.24;

contract Robocalls  {
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {}
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
}

contract RobocallsTokenSale  is Owned {
    uint   public startDate;
    uint   public bonusEnds;
    uint   public endDate;
    address public main_addr;
    address public tokenOwner;
    Robocalls r;
    
    
    constructor() public {
        bonusEnds = now + 8 weeks;
        endDate = now + 8 weeks;
        startDate = now;
        main_addr = 0xAD7615B0524849918AEe77e6c2285Dd7e8468650;
        tokenOwner = 0x6ec4dd24d36d94e96cc33f1ea84ad3e44008c628;
        r = Robocalls(main_addr);
    }
    
    
    function setEndDate(uint _newEndDate ) public {
        require(msg.sender==owner);
        endDate =  _newEndDate;
    } 
    
    function setBonusEndDate(uint _newBonusEndDate ) public {
        require(msg.sender==owner);
        bonusEnds =  _newBonusEndDate;
    } 
    
     
     
     
    function () public payable {
        require(now >= startDate && now <= endDate);
        uint tokens;
        if (now <= bonusEnds) {
            tokens = msg.value * 13000000;
        } else {
            tokens = msg.value * 10000000;
        }
        r.transferFrom(tokenOwner,msg.sender, tokens);
        owner.transfer(msg.value);
    }

}