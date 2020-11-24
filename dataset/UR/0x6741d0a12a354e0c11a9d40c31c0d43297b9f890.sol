 

pragma solidity ^0.4.23;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns(uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    if(a==0){
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

  function sub(uint256 a, uint256 b) internal pure returns (uint256){
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256){
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) internal balances;
  uint256 internal totalSupply_;
  
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer (address _to, uint256 _value) public returns (bool){
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns(uint256 balance){
    return balances[_owner];
  }
}

contract BurnableToken is BasicToken {
  event Burn(address indexed burner, uint256 value);

  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract DRToken is BurnableToken {
  string public constant name = "DrawingRun";
  string public constant symbol = "DR";
  uint8 public constant decimals = 18;
  uint256 public totalSupply;

  constructor() public{
    totalSupply = 30000000000 * 10**uint256(decimals);
    balances[msg.sender] = totalSupply;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
  }
}

contract DRCrowdsale is Ownable {
  using SafeMath for uint256;

  DRToken public token;   
  address public wallet;   
  
  uint256 public saleStart;   
  uint256 public saleEnd;   
  uint256 public price = 2;  
  uint256 public constant increasedPrice = 2;   
  uint256 public constant rate = 100000;   
  uint256 public tokens;

  constructor(address _token, address _wallet) public {
    require(_token != address(0));
    require(_wallet != address(0));
    token = DRToken(_token);
    wallet = _wallet;
    saleStart = now;
    saleEnd = now;
  }
  
   
  function setSaleEnd(uint256 newSaleEnd) onlyOwner public {
    saleEnd = newSaleEnd;
  }
  
  function getTokenBalance(address _token) public view onlyOwner returns (uint256){
      return token.balanceOf(_token);
  }
   
  function getStatus() public view onlyOwner returns(bool){
      return now < saleEnd;
  }

  function _buyTokens() internal {
     
    if(now.sub(saleStart) > 10 * 24 * 3600){  
        saleStart = now;
        price = price.add(increasedPrice);
    }
    require(price >= increasedPrice);
    uint256 weiAmount = msg.value;
    tokens = weiAmount.mul(rate).div(price);
    bool success = token.transfer(msg.sender, tokens);
    require(success);
    wallet.transfer(msg.value);
  }

   
  function () public payable{
    require(msg.sender != address(0));
    require(msg.value > 0);
    require(now < saleEnd);

    _buyTokens();
  }

  function burningTokens() public onlyOwner{
    if(now > saleEnd){
      token.burn(tokens);
    }
  }
}