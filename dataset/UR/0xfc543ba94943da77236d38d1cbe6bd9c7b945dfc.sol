 

pragma solidity ^0.4.18;


 
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


 
contract BasicToken is ERC20Basic {

  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract Releasable is Ownable {

  event Release();

  bool public released = false;

  modifier afterReleased() {
    require(released);
    _;
  }

  function release() onlyOwner public {
    require(!released);
    released = true;
    Release();
  }

}


contract Managed is Releasable {

  mapping (address => bool) public manager;
  event SetManager(address _addr);
  event UnsetManager(address _addr);

  function Managed() public {
    manager[msg.sender] = true;
  }

  modifier onlyManager() {
    require(manager[msg.sender]);
    _;
  }

  function setManager(address _addr) public onlyOwner {
    require(_addr != address(0) && manager[_addr] == false);
    manager[_addr] = true;

    SetManager(_addr);
  }

  function unsetManager(address _addr) public onlyOwner {
    require(_addr != address(0) && manager[_addr] == true);
    manager[_addr] = false;

    UnsetManager(_addr);
  }

}


contract ReleasableToken is StandardToken, Managed {

  function transfer(address _to, uint256 _value) public afterReleased returns (bool) {
    return super.transfer(_to, _value);
  }

  function saleTransfer(address _to, uint256 _value) public onlyManager returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public afterReleased returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public afterReleased returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public afterReleased returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public afterReleased returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}


contract BurnableToken is ReleasableToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) onlyManager public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

}


 
contract GanaToken is BurnableToken {

  string public constant name = "GANA";
  string public constant symbol = "GANA";
  uint8 public constant decimals = 18;

  event ClaimedTokens(address manager, address _token, uint256 claimedBalance);

  function GanaToken() public {
    totalSupply = 2400000000 * 1 ether;
    balances[msg.sender] = totalSupply;
  }

  function claimTokens(address _token, uint256 _claimedBalance) public onlyManager afterReleased {
    ERC20Basic token = ERC20Basic(_token);
    uint256 tokenBalance = token.balanceOf(this);
    require(tokenBalance >= _claimedBalance);

    address manager = msg.sender;
    token.transfer(manager, _claimedBalance);
    ClaimedTokens(manager, _token, _claimedBalance);
  }

}


 
contract Whitelist is Ownable {

   mapping (address => bool) public whitelist;
   event Registered(address indexed _addr);
   event Unregistered(address indexed _addr);

   modifier onlyWhitelisted(address _addr) {
     require(whitelist[_addr]);
     _;
   }

   function isWhitelist(address _addr) public view returns (bool listed) {
     return whitelist[_addr];
   }

   function registerAddress(address _addr) public onlyOwner {
     require(_addr != address(0) && whitelist[_addr] == false);
     whitelist[_addr] = true;
     Registered(_addr);
   }

   function registerAddresses(address[] _addrs) public onlyOwner {
     for(uint256 i = 0; i < _addrs.length; i++) {
       require(_addrs[i] != address(0) && whitelist[_addrs[i]] == false);
       whitelist[_addrs[i]] = true;
       Registered(_addrs[i]);
     }
   }

   function unregisterAddress(address _addr) public onlyOwner onlyWhitelisted(_addr) {
       whitelist[_addr] = false;
       Unregistered(_addr);
   }

   function unregisterAddresses(address[] _addrs) public onlyOwner {
     for(uint256 i = 0; i < _addrs.length; i++) {
       require(whitelist[_addrs[i]]);
       whitelist[_addrs[i]] = false;
       Unregistered(_addrs[i]);
     }
   }

}


 
contract GanaTokenPublicSale is Ownable {
  using SafeMath for uint256;

  GanaToken public gana;
  Whitelist public whitelist;
  address public wallet;
  uint256 public hardCap   = 50000 ether;  
  uint256 public weiRaised = 0;
  uint256 public defaultRate = 20000;
  uint256 public startTime;
  uint256 public endTime;

  event TokenPurchase(address indexed sender, address indexed buyer, uint256 weiAmount, uint256 ganaAmount);
  event Refund(address indexed buyer, uint256 weiAmount);
  event TransferToSafe();
  event BurnAndReturnAfterEnded(uint256 burnAmount, uint256 returnAmount);

  function GanaTokenPublicSale(address _gana, address _wallet, address _whitelist, uint256 _startTime, uint256 _endTime) public {
    require(_wallet != address(0));
    gana = GanaToken(_gana);
    whitelist = Whitelist(_whitelist);
    wallet = _wallet;
    startTime = _startTime;
    endTime = _endTime;
  }

  modifier onlyWhitelisted() {
    require(whitelist.isWhitelist(msg.sender));
    _;
  }

   
  function () external payable {
    buyGana(msg.sender);
  }

  function buyGana(address buyer) public onlyWhitelisted payable {
    require(!hasEnded());
    require(afterStart());
    require(buyer != address(0));
    require(msg.value > 0);
    require(buyer == msg.sender);

    uint256 weiAmount = msg.value;
     
    uint256 preCalWeiRaised = weiRaised.add(weiAmount);
    uint256 ganaAmount;
    uint256 rate = getRate();

    if(preCalWeiRaised <= hardCap){
       
      ganaAmount = weiAmount.mul(rate);
      gana.saleTransfer(buyer, ganaAmount);
      weiRaised = preCalWeiRaised;
      TokenPurchase(msg.sender, buyer, weiAmount, ganaAmount);
    }else{
       
      uint256 refundWeiAmount = preCalWeiRaised.sub(hardCap);
      uint256 fundWeiAmount =  weiAmount.sub(refundWeiAmount);
      ganaAmount = fundWeiAmount.mul(rate);
      gana.saleTransfer(buyer, ganaAmount);
      weiRaised = weiRaised.add(fundWeiAmount);
      TokenPurchase(msg.sender, buyer, fundWeiAmount, ganaAmount);
      buyer.transfer(refundWeiAmount);
      Refund(buyer,refundWeiAmount);
    }
  }

  function getRate() public view returns (uint256) {
    if(weiRaised < 15000 ether){
      return 22000;
    }else if(weiRaised < 30000 ether){
      return 21000;
    }else if(weiRaised < 45000 ether){
      return 20500;
    }else{
      return 20000;
    }
  }

   
  function hasEnded() public view returns (bool) {
    bool hardCapReached = weiRaised >= hardCap;  
    return hardCapReached || afterEnded();
  }

  function afterEnded() internal constant returns (bool) {
    return now > endTime;
  }

  function afterStart() internal constant returns (bool) {
    return now >= startTime;
  }

  function transferToSafe() onlyOwner public {
    require(hasEnded());
    wallet.transfer(this.balance);
    TransferToSafe();
  }

   
  function burnAndReturnAfterEnded(address reserveWallet) onlyOwner public {
    require(reserveWallet != address(0));
    require(hasEnded());
    uint256 unsoldWei = hardCap.sub(weiRaised);
    uint256 ganaBalance = gana.balanceOf(this);
    require(ganaBalance > 0);

    if(unsoldWei > 0){
       
      uint256 unsoldGanaAmount = ganaBalance;
      uint256 burnGanaAmount = unsoldWei.mul(defaultRate);
      uint256 bonusGanaAmount = unsoldGanaAmount.sub(burnGanaAmount);
      gana.burn(burnGanaAmount);
      gana.saleTransfer(reserveWallet, bonusGanaAmount);
      BurnAndReturnAfterEnded(burnGanaAmount, bonusGanaAmount);
    }else{
       
      gana.saleTransfer(reserveWallet, ganaBalance);
      BurnAndReturnAfterEnded(0, ganaBalance);
    }
  }

   
  function returnGanaBeforeSale(address returnAddress) onlyOwner public {
    require(returnAddress != address(0));
    require(weiRaised == 0);
    uint256 returnGana = gana.balanceOf(this);
    gana.saleTransfer(returnAddress, returnGana);
  }

}