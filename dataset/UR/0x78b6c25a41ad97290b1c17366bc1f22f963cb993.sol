 

pragma solidity ^0.4.22;

 

 
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
     
     
     
    return a / b;
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

 
contract ERC20 {
  function transfer(address to, uint256 value) public returns (bool);
  function balanceOf(address _owner) public view returns (uint256 balance);
}

 
contract Ownable {

  address public owner;

  address public newOwner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }
}



 

 
contract GangTokenSale is Ownable{
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 indexed etherValue, uint256 tokenAmount);

   
  constructor (address _token, address _wallet, address _owner, uint256 _rate) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    owner = _owner;

    rate = _rate;
    wallet = _wallet;
    token = ERC20(_token);
  }



   
   
   

   
  function () external payable {
    require(buyTokens(msg.sender, msg.value));
  }

  function buyTokens(address _beneficiary, uint _value) internal returns(bool) {
    require(_value > 0);

     
    uint256 tokens = getTokenAmount(_value);

     
    weiRaised = weiRaised.add(_value);

     
    token.transfer(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, _value, tokens);

     
    wallet.transfer(address(this).balance);

    return true;
  }

   
   
   

   
  function getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
    return _weiAmount.mul(rate);
  }

  function getRemainingTokens () public view returns(uint) {
    return token.balanceOf(address(this));
  }
  
  function setNewRate (uint _rate) onlyOwner public {
    require(_rate > 0);
    rate = _rate;
  }

  function destroyContract () onlyOwner public {
    uint tokens = token.balanceOf(address(this));
    token.transfer(wallet, tokens);

    selfdestruct(wallet);
  }
}