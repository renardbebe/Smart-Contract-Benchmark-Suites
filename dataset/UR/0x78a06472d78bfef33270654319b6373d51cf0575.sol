 

pragma solidity ^0.4.13;

contract Token {
   
   
  uint256 public totalSupply;

   
   
  function balanceOf(address _owner) constant returns (uint256 balance);

   
   
   
   
  function transfer(address _to, uint256 _value) returns (bool success);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

   
   
   
   
  function approve(address _spender, uint256 _value) returns (bool success);

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

  function transfer(address _to, uint256 _value) returns (bool success) {
     
     
     
     
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
     
     
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else { return false; }
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
}

contract EasyMineToken is StandardToken {

  string public constant name = "easyMINE Token";
  string public constant symbol = "EMT";
  uint8 public constant decimals = 18;

  function EasyMineToken(address _icoAddress,
                         address _preIcoAddress,
                         address _easyMineWalletAddress,
                         address _bountyWalletAddress) {
    require(_icoAddress != 0x0);
    require(_preIcoAddress != 0x0);
    require(_easyMineWalletAddress != 0x0);
    require(_bountyWalletAddress != 0x0);

    totalSupply = 33000000 * 10**18;                      

    uint256 icoTokens = 27000000 * 10**18;                

    uint256 preIcoTokens = 2000000 * 10**18;              

    uint256 easyMineTokens = 3000000 * 10**18;            
                                                          
                                                          
                                                          

    uint256 bountyTokens = 1000000 * 10**18;              

    assert(icoTokens + preIcoTokens + easyMineTokens + bountyTokens == totalSupply);

    balances[_icoAddress] = icoTokens;
    Transfer(0, _icoAddress, icoTokens);

    balances[_preIcoAddress] = preIcoTokens;
    Transfer(0, _preIcoAddress, preIcoTokens);

    balances[_easyMineWalletAddress] = easyMineTokens;
    Transfer(0, _easyMineWalletAddress, easyMineTokens);

    balances[_bountyWalletAddress] = bountyTokens;
    Transfer(0, _bountyWalletAddress, bountyTokens);
  }

  function burn(uint256 _value) returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      totalSupply -= _value;
      Transfer(msg.sender, 0x0, _value);
      return true;
    } else {
      return false;
    }
  }
}

contract EasyMineTokenWallet {

  uint256 constant public VESTING_PERIOD = 180 days;
  uint256 constant public DAILY_FUNDS_RELEASE = 15000 * 10**18;  

  address public owner;
  address public withdrawalAddress;
  Token public easyMineToken;
  uint256 public startTime;
  uint256 public totalWithdrawn;

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  function EasyMineTokenWallet() {
    owner = msg.sender;
  }

  function setup(address _easyMineToken, address _withdrawalAddress)
    public
    isOwner
  {
    require(_easyMineToken != 0x0);
    require(_withdrawalAddress != 0x0);

    easyMineToken = Token(_easyMineToken);
    withdrawalAddress = _withdrawalAddress;
    startTime = now;
  }

  function withdraw(uint256 requestedAmount)
    public
    isOwner
    returns (uint256 amount)
  {
    uint256 limit = maxPossibleWithdrawal();
    uint256 withdrawalAmount = requestedAmount;
    if (requestedAmount > limit) {
      withdrawalAmount = limit;
    }

    if (withdrawalAmount > 0) {
      if (!easyMineToken.transfer(withdrawalAddress, withdrawalAmount)) {
        revert();
      }
      totalWithdrawn += withdrawalAmount;
    }

    return withdrawalAmount;
  }

  function maxPossibleWithdrawal()
    public
    constant
    returns (uint256)
  {
    if (now < startTime + VESTING_PERIOD) {
      return 0;
    } else {
      uint256 daysPassed = (now - (startTime + VESTING_PERIOD)) / 86400;
      uint256 res = DAILY_FUNDS_RELEASE * daysPassed - totalWithdrawn;
      if (res < 0) {
        return 0;
      } else {
        return res;
      }
    }
  }

}