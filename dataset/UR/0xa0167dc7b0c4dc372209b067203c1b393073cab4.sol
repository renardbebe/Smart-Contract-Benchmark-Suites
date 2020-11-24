 

pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
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
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

 

contract TokenExchange is Owned {

    uint256 internal  constant initialBuyPrice = 1400000000000000;


    uint256 internal  priceIncrement =         550000000;
    uint256 internal  buyPrice;

    StandardToken internal  token;

    event BuyEvent(
        address wallet,
        uint256 amount
    );

     
    constructor() public {
        buyPrice = initialBuyPrice;
    }

    function setCurrency(address _tokenContract) public onlyOwner {
        token = StandardToken(_tokenContract);
    }

    function withdraw() onlyOwner public {
        owner.transfer(address(this).balance);
    }

     
     
    function setBuyPrice(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;
    }

    function setPriceIncrement(uint256 _newPriceIncrement) onlyOwner public{
        priceIncrement=_newPriceIncrement;
    }

     
    function buy(uint256 amount) payable public {
        require(msg.value == getTotalCost(amount));
        token.increaseApproval(this, amount);
        token.transferFrom(this, msg.sender, amount);
         
        buyPrice = SafeMath.add(buyPrice, SafeMath.mul(priceIncrement, amount));
        emit BuyEvent(msg.sender, amount);
    }


     
    function getTotalCost(uint256 amount) public view returns (uint256){
        return SafeMath.add(
            SafeMath.mul(buyPrice, amount),
            SafeMath.div(SafeMath.mul(priceIncrement, SafeMath.mul(SafeMath.add(amount, 1), amount)), 2));
    }

     

    function getBuyPrice() view public returns (uint){
        return buyPrice;
    }


    function getBalance() view public returns (uint ethBalance, uint tokenBalance){
        return (address(this).balance, token.balanceOf(this));
    }
}

 

contract PurchaseRuleManager is Owned {


    TokenExchange priceProvider;
    StandardToken internal  token;

    uint256 unlockPrice = 320000000000000000;
    mapping(address=>bool) unlocked;

    constructor() public {
    }

    function unlock(address tokenOwner) public onlyOwner {
        unlocked[tokenOwner]=true;
    }

    function lock(address tokenOwner) public onlyOwner {
        unlocked[tokenOwner]=false;
    }

    function setCurrency(address _tokenContract) public onlyOwner {
        token = StandardToken(_tokenContract);
    }

    function isUnlocked(address tokenOwner) public view returns (bool){
        return unlocked[tokenOwner];
    }

    function setPriceProvider(address _gameContract) public onlyOwner{
        priceProvider=TokenExchange(_gameContract);
    }

    function buyUnlock(address _buyerAddress) public payable{
        require(!unlocked[_buyerAddress]);
        require(msg.value==unlockPrice);
        unlocked[_buyerAddress]=true;
        uint distributed=SafeMath.div(msg.value,priceProvider.getBuyPrice());
        token.transfer(_buyerAddress,distributed);
    }

    function getUnlockPrice() public view returns (uint256){
        return unlockPrice;
    }

    function setUnlockPrice(uint256 _value) public onlyOwner{
        unlockPrice=_value;
    }

    function withdraw() onlyOwner public returns (bool){
        owner.transfer(address(this).balance);
        return true;
    }
}

 

contract NeonToken is Owned, MintableToken {
     
    string public name="NeonToken";
    string public symbol="NET";
    uint8 public decimals = 0;

    PurchaseRuleManager ruleProvider;

     
    constructor() public {
    }

    function setRuleProvider(address _contract) public onlyOwner{
        ruleProvider=PurchaseRuleManager(_contract);
    }

    function transfer(address to, uint256 value) public returns (bool){
        require(ruleProvider!=address(0x0));
        require(ruleProvider.isUnlocked(msg.sender));
        return super.transfer(to,value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(ruleProvider!=address(0x0));
        require(ruleProvider.isUnlocked(_from));
        return super.transferFrom(_from,_to,_value);
    }

}