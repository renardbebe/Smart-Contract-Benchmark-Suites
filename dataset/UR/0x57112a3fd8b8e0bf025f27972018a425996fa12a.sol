 

pragma solidity ^0.4.24;

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
library SafeERC20Transfer {
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }
}

 
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
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
  using SafeERC20Transfer for IERC20;

   
  IERC20 private _token;

   
  address private _wallet;

   
  uint256 private _weiRaised;

   
  uint256 public privateICOrate = 4081;  
  uint256 public preICOrate = 3278;  
  uint256 public ICOrate = 1785;  
  uint32 public privateICObonus = 30;  
  uint256 public privateICObonusLimit = 20000;  
  uint32 public preICObonus = 25;  
  uint256 public preICObonusLimit = 10000;  
  uint32 public ICObonus = 15;  
  uint256 public ICObonusLimit = 10000;  
  uint256 public startPrivateICO = 1550188800;  
  uint256 public startPreICO = 1551830400;  
  uint256 public startICO = 1554595200;  
  uint256 public endICO = 1557273599;  

   
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(address newOwner, address wallet, IERC20 token) public {
    require(wallet != address(0));
    require(token != address(0));
    require(newOwner != address(0));
    transferOwnership(newOwner);
    _wallet = wallet;
    _token = token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function token() public view returns(IERC20) {
    return _token;
  }

   
  function wallet() public view returns(address) {
    return _wallet;
  }

   
  function weiRaised() public view returns (uint256) {
    return _weiRaised;
  }

   
  function sendTokens(address beneficiary, uint256 tokenAmount) public onlyOwner {
    require(beneficiary != address(0));
    require(tokenAmount > 0);
    _token.safeTransfer(beneficiary, tokenAmount);
  }

   
  function buyTokens(address beneficiary) public payable {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    _weiRaised = _weiRaised.add(weiAmount);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    _forwardFunds(weiAmount);
  }

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal pure
  {
    require(beneficiary != address(0));
    require(weiAmount > 0);
  }

   
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _token.safeTransfer(beneficiary, tokenAmount);
  }

   
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _deliverTokens(beneficiary, tokenAmount);
  }

   
  function _getTokenAmount(
    uint256 weiAmount
  )
    internal view returns (uint256)
  {
    uint256 tokens;
    uint256 bonusTokens;
    if (now >= startPrivateICO && now < startPreICO) {
      tokens = weiAmount.mul(privateICOrate).div(1e18);
      if (tokens > privateICObonusLimit) {
        bonusTokens = tokens.mul(privateICObonus).div(100);
        tokens = tokens.add(bonusTokens);
      }
    } else if (now >= startPreICO && now < startICO) {
      tokens = weiAmount.mul(preICOrate).div(1e18);
      if (tokens > preICObonusLimit) {
        bonusTokens = tokens.mul(preICObonus).div(100);
        tokens = tokens.add(bonusTokens);
      }
    } else if (now >= startICO && now <= endICO) {
      tokens = weiAmount.mul(ICOrate).div(1e18);
      if (tokens > ICObonusLimit) {
        bonusTokens = tokens.mul(ICObonus).div(100);
        tokens = tokens.add(bonusTokens);
      }      
    } else {
      tokens = weiAmount.mul(ICOrate).div(1e18);
    }
    return tokens;
  }

   
  function _forwardFunds(uint256 weiAmount_) internal {
    _wallet.transfer(weiAmount_);
  }
}