 

pragma solidity ^0.4.23;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor () public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract EasyInvest6 is Ownable
{   
    using SafeMath for uint;
    
    mapping (address => uint) public invested;
    mapping (address => uint) public lastInvest;
    address[] public investors;
    
    address private m1;
    address private m2;
    
    
    function getInvestorsCount() public view returns(uint) 
    {   
        return investors.length;
    }
    
    function () external payable 
    {   
        if(msg.value > 0) 
        {   
            require(msg.value >= 10 finney, "require minimum 0.01 ETH");  
            
            uint fee = msg.value.mul(7).div(100).add(msg.value.div(200));  
            if(m1 != address(0)) m1.transfer(fee);
            if(m2 != address(0)) m2.transfer(fee);
        }
    
        payWithdraw(msg.sender);
        
        if (invested[msg.sender] == 0) 
        {
            investors.push(msg.sender);
        }
        
        lastInvest[msg.sender] = now;
        invested[msg.sender] += msg.value;
    }
    
    function getNumberOfPeriods(uint startTime, uint endTime) public pure returns (uint)
    {
        return endTime.sub(startTime).div(1 days);
    }
    
    function getWithdrawAmount(uint investedSum, uint numberOfPeriods) public pure returns (uint)
    {
        return investedSum.mul(6).div(100).mul(numberOfPeriods);
    }
    
    function payWithdraw(address to) internal
    {
        if (invested[to] != 0) 
        {
            uint numberOfPeriods = getNumberOfPeriods(lastInvest[to], now);
            uint amount = getWithdrawAmount(invested[to], numberOfPeriods);
            to.transfer(amount);
        }
    }
    
    function batchWithdraw(address[] to) onlyOwner public 
    {
        for(uint i = 0; i < to.length; i++)
        {
            payWithdraw(to[i]);
        }
    }
    
    function batchWithdraw(uint startIndex, uint length) onlyOwner public 
    {
        for(uint i = startIndex; i < length; i++)
        {
            payWithdraw(investors[i]);
        }
    }
    
    function setM1(address addr) onlyOwner public 
    {
        m1 = addr;
    }
    
    function setM2(address addr) onlyOwner public 
    {
        m2 = addr;
    }
}