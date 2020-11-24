 

pragma solidity ^0.4.17;



 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 
contract ERC20Basic {
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    function balanceOf(address _owner) public constant returns (uint256) { return balances[_owner]; }
     
     
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract GimmerPreSale is ERC20Basic, Pausable {
    using SafeMath for uint256;

     
    struct Supporter {
        uint256 weiSpent;    
        bool hasKYC;         
    }

    mapping(address => Supporter) public supportersMap;  
    address public fundWallet;       
    address public kycManager;       
    uint256 public tokensSold;       
    uint256 public weiRaised;        

    uint256 public constant ONE_MILLION = 1000000;
     
    uint256 public constant PRE_SALE_GMRP_TOKEN_CAP = 15 * ONE_MILLION * 1 ether;  

     
    uint256 public constant PRE_SALE_30_ETH     = 30 ether;   
    uint256 public constant PRE_SALE_300_ETH    = 300 ether;  
    uint256 public constant PRE_SALE_3000_ETH   = 3000 ether; 

     
    uint256 public constant TOKEN_RATE_25_PERCENT_BONUS = 1250;  
    uint256 public constant TOKEN_RATE_30_PERCENT_BONUS = 1300;  
    uint256 public constant TOKEN_RATE_40_PERCENT_BONUS = 1400;  

     
    uint256 public constant START_TIME  = 1511524800;    
    uint256 public constant END_TIME    = 1514894400;    

     
    string public constant name = "GimmerPreSale Token";
    string public constant symbol = "GMRP";
    uint256 public constant decimals = 18;

     
    modifier onlyKycManager() {
        require(msg.sender == kycManager);
        _;
    }

     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

     
    event Mint(address indexed to, uint256 amount);

     
    event KYC(address indexed user, bool isApproved);

     
    function GimmerPreSale(address _fundWallet, address _kycManagerWallet) public {
        require(_fundWallet != address(0));
        require(_kycManagerWallet != address(0));

        fundWallet = _fundWallet;
        kycManager = _kycManagerWallet;
    }

     
    function () whenNotPaused public payable {
        buyTokens();
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= START_TIME && now <= END_TIME;
        bool higherThanMin30ETH = msg.value >= PRE_SALE_30_ETH;
        return withinPeriod && higherThanMin30ETH;
    }

     
    function buyTokens() whenNotPaused public payable {
        address sender = msg.sender;

         
        require(userHasKYC(sender));
        require(validPurchase());

         
        uint256 weiAmountSent = msg.value;
        uint256 rate = getRate(weiAmountSent);
        uint256 newTokens = weiAmountSent.mul(rate);

         
        uint256 totalTokensSold = tokensSold.add(newTokens);
        require(totalTokensSold <= PRE_SALE_GMRP_TOKEN_CAP);

         
        Supporter storage sup = supportersMap[sender];
        uint256 totalWei = sup.weiSpent.add(weiAmountSent);
        sup.weiSpent = totalWei;

         
        weiRaised = weiRaised.add(weiAmountSent);
        tokensSold = totalTokensSold;

         
        mint(sender, newTokens);
        TokenPurchase(sender, weiAmountSent, newTokens);

         
        forwardFunds();
    }

     
    function getRate(uint256 weiAmount) public pure returns (uint256) {
        if (weiAmount >= PRE_SALE_3000_ETH) {
            return TOKEN_RATE_40_PERCENT_BONUS;
        } else if(weiAmount >= PRE_SALE_300_ETH) {
            return TOKEN_RATE_30_PERCENT_BONUS;
        } else if(weiAmount >= PRE_SALE_30_ETH) {
            return TOKEN_RATE_25_PERCENT_BONUS;
        } else {
            return 0;
        }
    }

     
    function forwardFunds() internal {
        fundWallet.transfer(msg.value);
    }

     
    function hasEnded() public constant returns (bool) {
        return now > END_TIME;
    }

     
    function approveUserKYC(address _user) onlyKycManager public {
        Supporter storage sup = supportersMap[_user];
        sup.hasKYC = true;
        KYC(_user, true);
    }

     
    function disapproveUserKYC(address _user) onlyKycManager public {
        Supporter storage sup = supportersMap[_user];
        sup.hasKYC = false;
        KYC(_user, false);
    }

     
    function setKYCManager(address _newKYCManager) onlyOwner public {
        require(_newKYCManager != address(0));
        kycManager = _newKYCManager;
    }

     
    function userHasKYC(address _user) public constant returns (bool) {
        return supportersMap[_user].hasKYC;
    }

     
    function userWeiSpent(address _user) public constant returns (uint256) {
        return supportersMap[_user].weiSpent;
    }

     
    function mint(address _to, uint256 _amount) internal returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }
}