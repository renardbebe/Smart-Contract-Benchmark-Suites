 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

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

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns(bool) {
    super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns(bool) {
    super.transferFrom(_from, _to, _value);
  }
}


 
contract ACOCoin is PausableToken {

  using SafeMath for uint256;
  string public constant name = "ACOCoin";
  string public constant symbol = "ACO";
  uint8 public constant decimals = 18;

  uint256 public constant initialSupply_ = 1000000000 * (10 ** uint256(decimals));
  uint256 public tokensForPublicSale = 200000000 * (10 ** 18);
  uint256 public pricePerToken = (10 ** 16);  

  uint256 minETH = 0 * (10**18);  
  uint256 maxETH = 1000 * (10**18);  
  
   
  bool public isCrowdsaleOpen=false;
  
   
  constructor() public {
    totalSupply_ = initialSupply_;
    balances[msg.sender] = balances[msg.sender].add(initialSupply_);
    emit Transfer(address(0), msg.sender, initialSupply_);
  }
  
   function startCrowdSale() public onlyOwner {
     isCrowdsaleOpen=true;
  }

   function stopCrowdSale() public onlyOwner {
     isCrowdsaleOpen=false;
  }
  
  function sendToInvestor(address _to, uint256 _value) public onlyOwner {
    transfer(_to, _value);
  }

 
 
 
  function setPublicSaleParams(uint256 _tokensForPublicSale, uint256 _min, uint256 _max, uint256 _pricePerToken ) public onlyOwner {
    require(_tokensForPublicSale > 0);
    require (_tokensForPublicSale <= totalSupply_);
    require(_pricePerToken > 0);
    require(_min >= 0);
    require(_max > 0);
    pricePerToken = 0; 
    pricePerToken = pricePerToken.add(_pricePerToken);
    tokensForPublicSale = 0;
    tokensForPublicSale = tokensForPublicSale.add(_tokensForPublicSale);
    minETH = 0;
    minETH = minETH.add(_min);
    maxETH = 0;
    maxETH = maxETH.add(_max);
 }

  
  function buyTokens() public payable returns(uint tokenAmount) {

    uint256 _tokenAmount;
    uint256 multiplier = (10 ** 18);
    uint256 weiAmount = msg.value;

    require(isCrowdsaleOpen);

    require(weiAmount >= minETH);
    require(weiAmount <= maxETH);

    _tokenAmount =  weiAmount.mul(multiplier).div(pricePerToken);

    require(_tokenAmount > 0);

     
    tokensForPublicSale = tokensForPublicSale.sub(_tokenAmount);
     
    require(_tokenAmount <= balances[owner]);
    balances[owner] = balances[owner].sub(_tokenAmount);
    balances[msg.sender] = balances[msg.sender].add(_tokenAmount);
    emit Transfer(owner, msg.sender, _tokenAmount);
     
    require(owner.send(weiAmount));

    return _tokenAmount;

  }

   

  function() public payable {
      buyTokens();
  }

}