 

 

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

interface fulcrumInterface {
    function mintWithEther(address receiver, uint256 maxPriceAllowed) external payable returns (uint256 mintAmount);
    function mint(address receiver, uint256 amount) external returns (uint256 mintAmount);
    function burnToEther(address receiver, uint256 burnAmount, uint256 minPriceAllowed) external returns (uint256 loanAmountPaid);
}

interface IKyberNetworkProxy {
    function swapEtherToToken(ERC20 token, uint minRate) external payable returns (uint);
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
}

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    
}




contract Invest2Fulcrum_iDAI is Ownable, ReentrancyGuard {
    using SafeMath for uint;
 
    
     
    uint public balance;
    IKyberNetworkProxy public kyberNetworkProxyContract = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    ERC20 constant public ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    ERC20 public DAI_TOKEN_ADDRESS = ERC20(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
    

    
    fulcrumInterface public fulcrumInterfaceContract = fulcrumInterface(0x14094949152EDDBFcd073717200DA82fEd8dC960);
    
     
    event AmountInvested(string successmessage, uint numberOfTokensIssued);
    
     
    
      
    function set_fulcrumInterface(fulcrumInterface _fulcrumInterfaceContract) onlyOwner public {
        fulcrumInterfaceContract = _fulcrumInterfaceContract;
    }
    
    function set_kyberNetworkProxyContract(IKyberNetworkProxy _kyberNetworkProxyContract) onlyOwner public {
        kyberNetworkProxyContract = _kyberNetworkProxyContract;
    }
    
     
    function set_DAI_TOKEN_ADDRESS(ERC20 _DAI_TOKEN_ADDRESS) onlyOwner public {
        DAI_TOKEN_ADDRESS = _DAI_TOKEN_ADDRESS;
    }
    
     
    function LetsInvest2FulcrumiDAI(address _towhomtoissue) public payable {
        require(_towhomtoissue != address(0));
        require(msg.value > 0);
        uint minConversionRate;
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(ETH_TOKEN_ADDRESS, DAI_TOKEN_ADDRESS, msg.value);
        uint destAmount = kyberNetworkProxyContract.swapEtherToToken.value(msg.value)(DAI_TOKEN_ADDRESS, minConversionRate);
        uint qty2approve = SafeMath.mul(destAmount, 3);
        require(DAI_TOKEN_ADDRESS.approve(address(fulcrumInterfaceContract), qty2approve));
        fulcrumInterfaceContract.mint(_towhomtoissue, destAmount); 
    }
    
     
    function inCaseDAIgetsStuck() onlyOwner public {
        uint qty = DAI_TOKEN_ADDRESS.balanceOf(address(this));
        DAI_TOKEN_ADDRESS.transfer(owner, qty);
    }
    

     
    
     
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    
     
    function() external payable {
        if (msg.sender == owner) {
            depositETH();
        } else {
            LetsInvest2FulcrumiDAI(msg.sender);
        }
    }
    
     
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    
    
}