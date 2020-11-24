 

 

pragma solidity >0.4.0 <0.6.0;

contract Ownable {

  address payable public owner;

  constructor () public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  
  function transferOwnership(address payable newOwner) external onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

 

pragma solidity ^0.5.0;

contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

 

pragma solidity ^0.5.0;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;





interface Invest2Fulcrum1xShortBTC {
    function LetsInvest2Fulcrum1xShortBTC(address _towhomtoissue) external payable;
}

interface Invest2Fulcrum {
    function LetsInvest2Fulcrum(address _towhomtoissue) external payable;
}


 
contract ETHMaximalist is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    
     
    
    
     
    uint public ShortBTCAllocation = 50;
    Invest2Fulcrum public Invest2FulcrumContract = Invest2Fulcrum(0xAB58BBF6B6ca1B064aa59113AeA204F554E8fBAe);
    Invest2Fulcrum1xShortBTC public Invest2Fulcrum1xShortBTCContract = Invest2Fulcrum1xShortBTC(0xa2C3e380E6c082A003819a2a69086748fe3D15Dd);

    
    
     
    uint public balance = address(this).balance;
    
     
    bool private stopped = false;

    
     
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}

    constructor () public {
    }
    
    function toggleContractActive() onlyOwner public {
    stopped = !stopped;
    }
    
    function change_cDAIAllocation(uint _numberPercentageValue) public onlyOwner {
        require(_numberPercentageValue > 1 && _numberPercentageValue < 100);
        ShortBTCAllocation = _numberPercentageValue;
    }
    
    
     
    function ETHMaximalistZAP() stopInEmergency payable public returns (bool) {
        require(msg.value>10000000000000);
        uint investment_amt = msg.value;
        uint investAmt2ShortBTC = SafeMath.div(SafeMath.mul(investment_amt,ShortBTCAllocation), 100);
        uint investAmt2c1xLongETH = SafeMath.sub(investment_amt, investAmt2ShortBTC);
        require (SafeMath.sub(investment_amt,SafeMath.add(investAmt2ShortBTC, investAmt2c1xLongETH)) == 0);
        Invest2Fulcrum1xShortBTCContract.LetsInvest2Fulcrum1xShortBTC.value(investAmt2ShortBTC)(msg.sender);
        Invest2FulcrumContract.LetsInvest2Fulcrum.value(investAmt2c1xLongETH)(msg.sender);
        
    }
     
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    
     
    function() external payable {
        if (msg.sender == owner) {
            depositETH();
        } else {
            ETHMaximalistZAP();
        }
    }
    
     
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    

}