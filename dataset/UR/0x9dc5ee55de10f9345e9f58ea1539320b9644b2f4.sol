 

 

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




interface ERC20 {
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
}


interface Invest2_sBTC {
    function LetsInvestin_sBTC(address payable _investor) external payable returns(uint);
}

interface Invest2_sETH {
    function LetsInvestin_sETH(address payable _investor) external payable returns(uint);
}



contract ModerateBullZap is Ownable {
    using SafeMath for uint;
    
    Invest2_sBTC public Invest2_sBTCContract;
    Invest2_sETH public Invest2_sETHContract;
    
    ERC20 public sBTCContract = ERC20(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6);
    ERC20 public sETHContract = ERC20(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb);
    
    uint32 public sBTCPercentage = 50;


     
    uint public balance;

     
    function set_Invest2_sETHContract (Invest2_sETH _Invest2_sETHContract) onlyOwner public {
        Invest2_sETHContract = _Invest2_sETHContract;
    }
    
     
    function set_Invest2_sBTCContract (Invest2_sBTC _Invest2_sBTCContract) onlyOwner public {
        Invest2_sBTCContract = _Invest2_sBTCContract;
    }
    
     
    function set_sBTCContract(ERC20 _sBTCContract) onlyOwner public {
        sBTCContract = _sBTCContract;
    }
    
     
    function set_sETHContract(ERC20 _sETHContract) onlyOwner public {
        sETHContract = _sETHContract;
    }
    
     
    function set_sBTCPercentage (uint32 _sBTCPercentage) onlyOwner public {
        sBTCPercentage = _sBTCPercentage;
    }
    
     
    function LetsInvest() public payable returns(uint) {
        require (msg.value > 100000000000000);
        require (msg.sender != address(0));
        uint invest_amt = msg.value;
        address payable investor = address(msg.sender);
        uint sBTCPortion = SafeMath.div(SafeMath.mul(invest_amt,sBTCPercentage),100);
        uint sETHPortion = SafeMath.sub(invest_amt, sBTCPortion);
        require (SafeMath.sub(invest_amt, SafeMath.add(sBTCPortion, sETHPortion)) ==0 );
        Invest2_sBTCContract.LetsInvestin_sBTC.value(sBTCPortion)(investor);
        Invest2_sETHContract.LetsInvestin_sETH.value(sETHPortion)(investor);
    }
    
     
    function checkAndWithdraw_sBTC() onlyOwner public {
        uint sBTCUnits = sBTCContract.balanceOf(address(this));
        sBTCContract.transfer(owner,sBTCUnits);
    }
    
    function checkAndWithdraw_sETH() onlyOwner public {
        uint sETHUnits = sETHContract.balanceOf(address(this));
        sETHContract.transfer(owner,sETHUnits);
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