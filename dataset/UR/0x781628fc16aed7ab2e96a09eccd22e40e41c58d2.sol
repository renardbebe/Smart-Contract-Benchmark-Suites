 

pragma solidity ^0.4.21;

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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



contract Crowdsale is Ownable {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

  
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

  
  function () external payable {
    buyTokens(msg.sender);
  }

  
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );   

    _forwardFunds();
   
  }

   
   
   

  
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) pure internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }  
  

  
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }   

  
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {

    uint256 tokensIssued = _weiAmount.mul(rate);
    
    if( 20 * (10 ** 18) < tokensIssued && 100 * (10 ** 18) > tokensIssued ) tokensIssued = tokensIssued * 103 / 100;

    else if( 100 * (10 ** 18) <= tokensIssued && 500 * (10 ** 18) > tokensIssued ) tokensIssued = tokensIssued * 105 / 100;

    else if( 500 * (10 ** 18) <= tokensIssued && 1000 * (10 ** 18) > tokensIssued ) tokensIssued = tokensIssued * 107 / 100;

    else if( 1000 * (10 ** 18) <= tokensIssued && 5000 * (10 ** 18) > tokensIssued ) tokensIssued = tokensIssued * 110 / 100;

    else if( 5000 * (10 ** 18) <= tokensIssued && 10000 * (10 ** 18) > tokensIssued ) tokensIssued = tokensIssued * 115 / 100;

    else if( 10000 * (10 ** 18) <= tokensIssued ) tokensIssued = tokensIssued * 120 / 100;

    return tokensIssued;
   
  }
  
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }

}