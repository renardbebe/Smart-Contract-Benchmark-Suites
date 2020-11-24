 

 

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





interface Invest2Fulcrum2xLongBTC {
    function LetsInvest2Fulcrum2xLongBTC(address _towhomtoissue) external payable;
}

 
interface Invest2Fulcrum2xLongETH {
    function LetsInvest2Fulcrum(address _towhomtoissue) external payable;
}


 
contract DoubleBullZap is Ownable {
    using SafeMath for uint;
     
    
    
     
    uint public BTC2xLongPercentage = 50;
    Invest2Fulcrum2xLongETH public Invest2Fulcrum2xLong_ETHContract = Invest2Fulcrum2xLongETH(0xAB58BBF6B6ca1B064aa59113AeA204F554E8fBAe);
    Invest2Fulcrum2xLongBTC public Invest2Fulcrum2xLong_BTCContract = Invest2Fulcrum2xLongBTC(0xd455e7368BcaB144C2944aD679E4Aa10bB3766c1);

    
     
    uint public balance = address(this).balance;
    
     
    bool private stopped = false;

    
     
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
 

     
    function set_Invest2Fulcrum2xLong_ETHContract (Invest2Fulcrum2xLongETH _Invest2Fulcrum2xLong_ETHContract) onlyOwner public {
        Invest2Fulcrum2xLong_ETHContract = _Invest2Fulcrum2xLong_ETHContract;
    }
    
     
    function set_Invest2Fulcrum2xLong_BTCContract (Invest2Fulcrum2xLongBTC _Invest2Fulcrum2xLong_BTCContract) onlyOwner public {
        Invest2Fulcrum2xLong_BTCContract = _Invest2Fulcrum2xLong_BTCContract;
    }
    
     
    function set_BTC2xLongPercentage (uint32 _BTC2xLongPercentage) onlyOwner public {
        BTC2xLongPercentage = _BTC2xLongPercentage;
    }
    
     
    function LetsInvest() public payable returns(uint) {
        require (msg.value > 100000000000000);
        require (msg.sender != address(0));
        uint invest_amt = msg.value;
        address payable investor = address(msg.sender);
        uint BTC2xLongPortion = SafeMath.div(SafeMath.mul(invest_amt,BTC2xLongPercentage),100);
        uint ETH2xLongPortion = SafeMath.sub(invest_amt, BTC2xLongPortion);
        require (SafeMath.sub(invest_amt, SafeMath.add(BTC2xLongPortion, ETH2xLongPortion)) ==0 );
        Invest2Fulcrum2xLong_BTCContract.LetsInvest2Fulcrum2xLongBTC.value(BTC2xLongPortion)(investor);
        Invest2Fulcrum2xLong_ETHContract.LetsInvest2Fulcrum.value(ETH2xLongPortion)(investor);
    }
    
    
    
     
    
     
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    
     
    function() external payable {
        if (msg.sender == owner) {
            depositETH();
        } else {
            LetsInvest();
        }
    }
    
     
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    
}