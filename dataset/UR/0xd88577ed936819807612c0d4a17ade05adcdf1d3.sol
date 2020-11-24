 

pragma solidity ^0.4.11;


 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      revert();
    }
  }
}
contract ZTRToken{
    function transfer(address _to, uint val);
}

contract ZTRTokenSale
{
    using SafeMath for uint;
    mapping (address => uint) public balanceOf;
    mapping (address => uint) public ethBalance;
    address public owner;
    address ZTRTokenContract;
    uint public fundingGoal;
    uint public fundingMax;
    uint public amountRaised;
    uint public start;
    uint public duration;
    uint public deadline;
    uint public unlockTime;
    uint public ZTR_ETH_initial_price;
    uint public ZTR_ETH_extra_price;
    uint public remaining;
    
    modifier admin { if (msg.sender == owner) _; }
    modifier afterUnlock { if(now>unlockTime) _;}
    modifier afterDeadline { if(now>deadline) _;}
    
    function ZTRTokenSale()
    {
        owner = msg.sender;
        ZTRTokenContract = 0x107bc486966eCdDAdb136463764a8Eb73337c4DF;
        fundingGoal = 5000 ether; 
        fundingMax = 30000 ether; 
        start = 1517702401; 
        duration = 3 weeks; 
        deadline = start + duration; 
        unlockTime = deadline + 16 weeks; 
        ZTR_ETH_initial_price = 45000; 
        ZTR_ETH_extra_price = 23000; 
        remaining = 800000000000000000000000000; 
    }
    function () payable public 
    {
        require(now>start);
        require(now<deadline);
        require(amountRaised + msg.value < fundingMax); 
        uint purchase = msg.value;
        ethBalance[msg.sender] = ethBalance[msg.sender].add(purchase); 
        if(amountRaised < fundingGoal) 
        {
            purchase = purchase.mul(ZTR_ETH_initial_price);
            amountRaised = amountRaised.add(msg.value);
            balanceOf[msg.sender] = balanceOf[msg.sender].add(purchase);
            remaining.sub(purchase);
        }
        else 
        {
            purchase = purchase.mul(ZTR_ETH_extra_price);
            amountRaised = amountRaised.add(msg.value);
            balanceOf[msg.sender] = balanceOf[msg.sender].add(purchase);
            remaining.sub(purchase);
        }
    }
    
    function withdrawBeneficiary() public admin afterDeadline 
    {
        ZTRToken t = ZTRToken(ZTRTokenContract);
        t.transfer(msg.sender, remaining);
        require(amountRaised >= fundingGoal); 
        owner.transfer(amountRaised);
    }
    
    function withdraw() afterDeadline 
    {
        if(amountRaised < fundingGoal) 
        {
            uint ethVal = ethBalance[msg.sender];
            ethBalance[msg.sender] = 0;
            msg.sender.transfer(ethVal);
        }
        else 
        {
            uint tokenVal = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            ZTRToken t = ZTRToken(ZTRTokenContract);
            t.transfer(msg.sender, tokenVal);
        }
    }
    
    function setDeadline(uint ti) public admin 
    {
        deadline = ti;
    }
    
    function setStart(uint ti) public admin 
    {
        start = ti;
    }
    
    function suicide() public afterUnlock  
    {
        selfdestruct(owner);
    }
}