 

pragma solidity ^0.4.24;
 
 
 
 
 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

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

contract Management is Ownable {

   
  event Pause();
  event Unpause();

   
  event OpenAutoFree(address indexed admin, address indexed who);
  event CloseAutoFree(address indexed admin, address indexed who);
  event OpenForceAutoFree(address indexed admin, address indexed who);

   
  event AddAdministrator(address indexed admin);
  event DelAdministrator(address indexed admin);

   
  bool public paused = false;
  mapping(address => bool) public autoFreeLockBalance;           
  mapping(address => bool) public forceAutoFreeLockBalance;      
  mapping(address => bool) public adminList;

   
  constructor() public {
  }

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  modifier whenAdministrator(address who) {
    require(adminList[who]);
    _;
  }

   
  modifier whenNotAdministrator(address who) {
    require(!adminList[who]);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

   
  function openAutoFree(address who) whenAdministrator(msg.sender) public {
    delete autoFreeLockBalance[who];
    emit OpenAutoFree(msg.sender, who);
  }

   
  function closeAutoFree(address who) whenAdministrator(msg.sender) public {
    autoFreeLockBalance[who] = true;
    emit CloseAutoFree(msg.sender, who);
  }

   
  function openForceAutoFree(address who) onlyOwner public {
    forceAutoFreeLockBalance[who] = true;
    emit OpenForceAutoFree(msg.sender, who);
  }

   
  function addAdministrator(address who) onlyOwner public {
    adminList[who] = true;
    emit AddAdministrator(who);
  }

   
  function delAdministrator(address who) onlyOwner public {
    delete adminList[who];
    emit DelAdministrator(who);
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

   
  mapping(address => uint256) balances;

   
  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
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

   
   
   
   
   
  event TransferFrom(address indexed spender,
                     address indexed from,
                     address indexed to,
                     uint256 value);


   
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
    uint _addedValue
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
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract SibbayHealthToken is StandardToken, Management {

  string public constant name = "Sibbay Health Token";  
  string public constant symbol = "SHT";  
  uint8 public constant decimals = 18;  

   
  uint256 constant internal MAGNITUDE = 10 ** uint256(decimals);

  uint256 public constant INITIAL_SUPPLY = 1000000000 * MAGNITUDE;

   
  event SetSellPrice(address indexed admin, uint256 price);
   
  event TransferByDate(address indexed from, address indexed to, uint256[] values, uint256[] dates);
  event TransferFromByDate(address indexed spender, address indexed from, address indexed to, uint256[] values, uint256[] dates);
   
  event CloseSell(address indexed who);
   
  event Sell(address indexed from, address indexed to, uint256 tokenValue, uint256 etherValue);
   
  event Withdraw(address indexed who, uint256 etherValue);
   
  event AddTokenToFund(address indexed who, address indexed from, uint256 value);
   
  event Refresh(address indexed from, address indexed who);

   
  struct Element {
    uint256 value;
    uint256 next;
  }

   
  struct Account {
    uint256 lockedBalances;
    mapping(uint256 => Element) lockedElement;
    uint256 start_date;
    uint256 end_date;
  }

   
  mapping(address => Account) public accounts;

   
  uint256 public sellPrice;
  address public fundAccount;
  bool public sellFlag;

   
  uint256 public curYear;
  uint256 constant internal YEAR = 365 * 24 * 3600;
  uint256 public vault;
  uint256 constant internal VAULT_FLOOR_VALUE = 10000000 * MAGNITUDE;

   
  constructor(address _owner, address _fund) public {
     
    require(_owner != address(0));
    require(_fund != address(0));

     
    owner = _owner;
    fundAccount = _fund;

     
    adminList[owner] = true;

     
    totalSupply_ = INITIAL_SUPPLY;
    balances[owner] = INITIAL_SUPPLY;
    emit Transfer(0x0, owner, INITIAL_SUPPLY);

     
    sellPrice = 0;
    sellFlag = true;

     
    vault = totalSupply_.mul(10).div(100);
    curYear = 1514736000;
  }

   
  function () external payable {
  }

   
  modifier whenOpenSell()
  {
    require(sellFlag);
    _;
  }

   
  modifier whenCloseSell()
  {
    require(!sellFlag);
    _;
  }

   
  function refreshVault(address _who, uint256 _value) internal
  {
    uint256 balance;

     
    if (_who != owner)
      return ;
     
    balance = balances[owner];
     
    if (now >= (curYear + YEAR))
    {
      if (balance <= VAULT_FLOOR_VALUE)
        vault = balance;
      else
        vault = balance.mul(10).div(100);
      curYear = curYear.add(YEAR);
    }

     
    require(vault >= _value);
    vault = vault.sub(_value);
    return ;
  }

   
  function refreshlockedBalances(address _who, bool _update) internal returns (uint256)
  {
    uint256 tmp_date = accounts[_who].start_date;
    uint256 tmp_value = accounts[_who].lockedElement[tmp_date].value;
    uint256 tmp_balances = 0;
    uint256 tmp_var;

     
    if (!forceAutoFreeLockBalance[_who])
    {
       
      if(autoFreeLockBalance[_who])
      {
         
        return 0;
      }
    }

     
    while(tmp_date != 0 &&
          tmp_date <= now)
    {
       
      tmp_balances = tmp_balances.add(tmp_value);

       
      tmp_var = tmp_date;

       
      tmp_date = accounts[_who].lockedElement[tmp_date].next;
      tmp_value = accounts[_who].lockedElement[tmp_date].value;

       
      if (_update)
        delete accounts[_who].lockedElement[tmp_var];
    }

     
    if(!_update)
      return tmp_balances;

     
    accounts[_who].start_date = tmp_date;
    accounts[_who].lockedBalances = accounts[_who].lockedBalances.sub(tmp_balances);
    balances[_who] = balances[_who].add(tmp_balances);

     
    if (accounts[_who].start_date == 0)
        accounts[_who].end_date = 0;

    return tmp_balances;
  }

   
  function transferAvailableBalances(
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
     
    require(_value <= balances[_from]);

     
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);

     
    if(_from == msg.sender)
      emit Transfer(_from, _to, _value);
    else
      emit TransferFrom(msg.sender, _from, _to, _value);
  }

   
  function transferLockedBalances(
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
     
    require(_value <= balances[_from]);

     
    balances[_from] = balances[_from].sub(_value);
    accounts[_to].lockedBalances = accounts[_to].lockedBalances.add(_value);
  }

   
  function transferEther(
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
     
    if (_to != fundAccount)
        return ;

     
    require(sellFlag);

     
    require(_value > 0);

     
    uint256 evalue = _value.mul(sellPrice).div(MAGNITUDE);
    require(evalue <= address(this).balance);

     
    if (evalue > 0)
    {
      _from.transfer(evalue);
      emit Sell(_from, _to, _value, evalue);
    }
  }

   
  function withdraw() public onlyOwner {
    uint256 value = address(this).balance;
    owner.transfer(value);
    emit Withdraw(msg.sender, value);
  }

   
  function addTokenToFund(address _from, uint256 _value) 
    whenNotPaused
    public
  {
    if (_from != msg.sender)
    {
       
      require(_value <= allowed[_from][msg.sender]);

       
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    }

     
    refreshVault(_from, _value);

     
    transferAvailableBalances(_from, fundAccount, _value);
    emit AddTokenToFund(msg.sender, _from, _value);
  }

   
  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
     
    require(_to != address(0));

     
    refreshlockedBalances(msg.sender, true);
    refreshlockedBalances(_to, true);

     
    refreshVault(msg.sender, _value);

     
    transferAvailableBalances(msg.sender, _to, _value);

     
    transferEther(msg.sender, _to, _value);

    return true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
     
    require(_to != fundAccount);

     
    require(_to != address(0));

     
    refreshlockedBalances(_from, true);
    refreshlockedBalances(_to, true);

     
    require(_value <= allowed[_from][msg.sender]);

     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

     
    refreshVault(_from, _value);

     
    transferAvailableBalances(_from, _to, _value);

    return true;
  }

   
  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

   
  function batchTransfer(
    address[] _receivers,
    uint256[] _values
  )
    public
    whenNotPaused
  {
     
    require(_receivers.length > 0 && _receivers.length == _values.length);

     
    refreshlockedBalances(msg.sender, true);

     
    uint32 i = 0;
    uint256 total = 0;
    for (i = 0; i < _values.length; i ++)
    {
      total = total.add(_values[i]);
    }
    require(total <= balances[msg.sender]);

     
    refreshVault(msg.sender, total);

     
    for (i = 0; i < _receivers.length; i ++)
    {
       
      require(_receivers[i] != fundAccount);

       
      require(_receivers[i] != address(0));

      refreshlockedBalances(_receivers[i], true);
       
      transferAvailableBalances(msg.sender, _receivers[i], _values[i]);
    }
  }

   
  function batchTransferFrom(
    address _from,
    address[] _receivers,
    uint256[] _values
  )
    public
    whenNotPaused
  {
     
    require(_receivers.length > 0 && _receivers.length == _values.length);

     
    refreshlockedBalances(_from, true);

     
    uint32 i = 0;
    uint256 total = 0;
    for (i = 0; i < _values.length; i ++)
    {
      total = total.add(_values[i]);
    }
    require(total <= balances[_from]);

     
    require(total <= allowed[_from][msg.sender]);

     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(total);

     
    refreshVault(_from, total);

     
    for (i = 0; i < _receivers.length; i ++)
    {
       
      require(_receivers[i] != fundAccount);

       
      require(_receivers[i] != address(0));

      refreshlockedBalances(_receivers[i], true);
       
      transferAvailableBalances(_from, _receivers[i], _values[i]);
    }
  }

   
  function transferByDate(
    address _receiver,
    uint256[] _values,
    uint256[] _dates
  )
    public
    whenNotPaused
  {
     
    require(_values.length > 0 &&
        _values.length == _dates.length);

     
    require(_receiver != fundAccount);

     
    require(_receiver != address(0));

     
    refreshlockedBalances(msg.sender, true);
    refreshlockedBalances(_receiver, true);

     
    uint32 i = 0;
    uint256 total = 0;
    for (i = 0; i < _values.length; i ++)
    {
      total = total.add(_values[i]);
    }
    require(total <= balances[msg.sender]);

     
    refreshVault(msg.sender, total);

     
    for(i = 0; i < _values.length; i ++)
    {
      transferByDateSingle(msg.sender, _receiver, _values[i], _dates[i]);
    }

    emit TransferByDate(msg.sender, _receiver, _values, _dates);
  }

   
  function transferFromByDate(
    address _from,
    address _receiver,
    uint256[] _values,
    uint256[] _dates
  )
    public
    whenNotPaused
  {
     
    require(_values.length > 0 &&
        _values.length == _dates.length);

     
    require(_receiver != fundAccount);

     
    require(_receiver != address(0));

     
    refreshlockedBalances(_from, true);
    refreshlockedBalances(_receiver, true);

     
    uint32 i = 0;
    uint256 total = 0;
    for (i = 0; i < _values.length; i ++)
    {
      total = total.add(_values[i]);
    }
    require(total <= balances[_from]);

     
    require(total <= allowed[_from][msg.sender]);

     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(total);

     
    refreshVault(_from, total);

     
    for(i = 0; i < _values.length; i ++)
    {
      transferByDateSingle(_from, _receiver, _values[i], _dates[i]);
    }

    emit TransferFromByDate(msg.sender, _from, _receiver, _values, _dates);
  }

   
  function transferByDateSingle(
    address _from,
    address _to,
    uint256 _value,
    uint256 _date
  )
    internal
  {
    uint256 start_date = accounts[_to].start_date;
    uint256 end_date = accounts[_to].end_date;
    uint256 tmp_var = accounts[_to].lockedElement[_date].value;
    uint256 tmp_date;

    if (_value == 0)
    {
         
        return ;
    }

    if (_date <= now)
    {
       
       
      transferAvailableBalances(_from, _to, _value);

      return ;
    }

    if (start_date == 0)
    {
       
       
      accounts[_to].start_date = _date;
      accounts[_to].end_date = _date;
      accounts[_to].lockedElement[_date].value = _value;
    }
    else if (tmp_var > 0)
    {
       
      accounts[_to].lockedElement[_date].value = tmp_var.add(_value);
    }
    else if (_date < start_date)
    {
       
       
      accounts[_to].lockedElement[_date].value = _value;
      accounts[_to].lockedElement[_date].next = start_date;
      accounts[_to].start_date = _date;
    }
    else if (_date > end_date)
    {
       
       
      accounts[_to].lockedElement[_date].value = _value;
      accounts[_to].lockedElement[end_date].next = _date;
      accounts[_to].end_date = _date;
    }
    else
    {
       
      tmp_date = start_date;
      tmp_var = accounts[_to].lockedElement[tmp_date].next;
      while(tmp_var < _date)
      {
        tmp_date = tmp_var;
        tmp_var = accounts[_to].lockedElement[tmp_date].next;
      }

       
      accounts[_to].lockedElement[_date].value = _value;
      accounts[_to].lockedElement[_date].next = tmp_var;
      accounts[_to].lockedElement[tmp_date].next = _date;
    }

     
    transferLockedBalances(_from, _to, _value);

    return ;
  }

   
  function sell(uint256 _value) public whenOpenSell whenNotPaused {
    transfer(fundAccount, _value);
  }

   
  function setSellPrice(uint256 price) public whenAdministrator(msg.sender) {
    require(price > 0);
    sellPrice = price;

    emit SetSellPrice(msg.sender, price);
  }

   
  function closeSell() public whenOpenSell onlyOwner {
    sellFlag = false;
    emit CloseSell(msg.sender);
  }

   
  function refresh(address _who) public whenNotPaused {
    refreshlockedBalances(_who, true);
    emit Refresh(msg.sender, _who);
  }

   
  function availableBalanceOf(address _owner) public view returns (uint256) {
    return (balances[_owner] + refreshlockedBalances(_owner, false));
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner] + accounts[_owner].lockedBalances;
  }

   
  function lockedBalanceOf(address _who) public view returns (uint256) {
    return (accounts[_who].lockedBalances - refreshlockedBalances(_who, false));
  }

   
  function lockedBalanceOfByDate(address _who, uint256 date) public view returns (uint256, uint256) {
    return (accounts[_who].lockedElement[date].value, accounts[_who].lockedElement[date].next);
  }

}