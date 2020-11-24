 

pragma solidity 0.4.18;

 

 
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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 

contract Crowdsale is Ownable, Pausable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  address public wallet;

   
  address public supplier;

   
  uint256 public purposeWeiRate = 6;
  uint256 public etherWeiRate = 1;

   
  uint256 public weiRaised = 0;

   
  uint256 public weiTokensRaised = 0;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function Crowdsale(address _wallet, address _supplier, address _token, uint256 _purposeWeiRate, uint256 _etherWeiRate) public {
    require(_token != address(0));
    require(_supplier != address(0));

    changeWallet(_wallet);
    supplier = _supplier;
    token = ERC20(_token);
    changeRate(_purposeWeiRate, _etherWeiRate);
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function changeWallet(address _wallet) public onlyOwner {
    require(_wallet != address(0));

    wallet = _wallet;
  }

   
  function changeRate(uint256 _purposeWeiRate, uint256 _etherWeiRate) public onlyOwner {
    require(_purposeWeiRate > 0);
    require(_etherWeiRate > 0);
    
    purposeWeiRate = _purposeWeiRate;
    etherWeiRate = _etherWeiRate;
  }

   
  function buyTokens(address beneficiary) public payable whenNotPaused {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.div(etherWeiRate).mul(purposeWeiRate);

     
    weiRaised = weiRaised.add(weiAmount);
    weiTokensRaised = weiTokensRaised.add(tokens);

     
    token.safeTransferFrom(supplier, beneficiary, tokens);

     
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

     
    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    return !paused && nonZeroPurchase;
  }
}