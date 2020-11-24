 

pragma solidity ^0.4.11;



 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


 

contract LimitedTransferToken is ERC20 {

   
  modifier canTransfer(address _sender, uint256 _value) {
   require(_value <= transferableTokens(_sender, uint64(now)));
   _;
  }

   
  function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    return balanceOf(holder);
  }
}


 
contract VestedToken is StandardToken, LimitedTransferToken {

  uint256 MAX_GRANTS_PER_ADDRESS = 20;

  struct TokenGrant {
    address granter;      
    uint256 value;        
    uint64 cliff;
    uint64 vesting;
    uint64 start;         
    bool revokable;
    bool burnsOnRevoke;   
  }  

  mapping (address => TokenGrant[]) public grants;

  event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint256 grantId);

   
  function grantVestedTokens(
    address _to,
    uint256 _value,
    uint64 _start,
    uint64 _cliff,
    uint64 _vesting,
    bool _revokable,
    bool _burnsOnRevoke
  ) public {

     
    require(_cliff >= _start && _vesting >= _cliff);

    require(tokenGrantsCount(_to) < MAX_GRANTS_PER_ADDRESS);    

    uint256 count = grants[_to].push(
                TokenGrant(
                  _revokable ? msg.sender : 0,  
                  _value,
                  _cliff,
                  _vesting,
                  _start,
                  _revokable,
                  _burnsOnRevoke
                )
              );

    transfer(_to, _value);

    NewTokenGrant(msg.sender, _to, _value, count - 1);
  }

   
  function revokeTokenGrant(address _holder, uint256 _grantId) public {
    TokenGrant grant = grants[_holder][_grantId];

    require(grant.revokable);
    require(grant.granter == msg.sender);  

    address receiver = grant.burnsOnRevoke ? 0xdead : msg.sender;

    uint256 nonVested = nonVestedTokens(grant, uint64(now));

     
    delete grants[_holder][_grantId];
    grants[_holder][_grantId] = grants[_holder][grants[_holder].length.sub(1)];
    grants[_holder].length -= 1;

    balances[receiver] = balances[receiver].add(nonVested);
    balances[_holder] = balances[_holder].sub(nonVested);

    Transfer(_holder, receiver, nonVested);
  }


   
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    uint256 grantIndex = tokenGrantsCount(holder);

    if (grantIndex == 0) return super.transferableTokens(holder, time);  

     
    uint256 nonVested = 0;
    for (uint256 i = 0; i < grantIndex; i++) {
      nonVested = SafeMath.add(nonVested, nonVestedTokens(grants[holder][i], time));
    }

     
    uint256 vestedTransferable = SafeMath.sub(balanceOf(holder), nonVested);

     
     
    return Math.min256(vestedTransferable, super.transferableTokens(holder, time));
  }

   
  function tokenGrantsCount(address _holder) constant returns (uint256 index) {
    return grants[_holder].length;
  }

   
  function calculateVestedTokens(
    uint256 tokens,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) constant returns (uint256)
    {
       
      if (time < cliff) return 0;
      if (time >= vesting) return tokens;

       
       
       

       
      uint256 vestedTokens = SafeMath.div(
                                    SafeMath.mul(
                                      tokens,
                                      SafeMath.sub(time, start)
                                      ),
                                    SafeMath.sub(vesting, start)
                                    );

      return vestedTokens;
  }

   
  function tokenGrant(address _holder, uint256 _grantId) constant returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke) {
    TokenGrant grant = grants[_holder][_grantId];

    granter = grant.granter;
    value = grant.value;
    start = grant.start;
    cliff = grant.cliff;
    vesting = grant.vesting;
    revokable = grant.revokable;
    burnsOnRevoke = grant.burnsOnRevoke;

    vested = vestedTokens(grant, uint64(now));
  }

   
  function vestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
    return calculateVestedTokens(
      grant.value,
      uint256(time),
      uint256(grant.start),
      uint256(grant.cliff),
      uint256(grant.vesting)
    );
  }

   
  function nonVestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
    return grant.value.sub(vestedTokens(grant, time));
  }

   
  function lastTokenIsTransferableDate(address holder) constant public returns (uint64 date) {
    date = uint64(now);
    uint256 grantIndex = grants[holder].length;
    for (uint256 i = 0; i < grantIndex; i++) {
      date = Math.max64(grants[holder][i].vesting, date);
    }
  }
}


contract EGLToken is VestedToken {
   
  string public name = "eGold";
  string public symbol = "EGL";
  uint public decimals = 4;
  
   
   
  uint public constant STAGE_ONE_TIME_END = 24 hours;  
  uint public constant STAGE_TWO_TIME_END = 1 weeks;  
  uint public constant STAGE_THREE_TIME_END = 28 days;  
  
   
  uint private constant MULTIPLIER = 10000;

   
  uint public constant PRICE_STANDARD    =  888 *MULTIPLIER;  
  uint public constant PRICE_PREBUY      = 1066 *MULTIPLIER;  
  uint public constant PRICE_STAGE_ONE   = 1021 *MULTIPLIER;  
  uint public constant PRICE_STAGE_TWO   =  976 *MULTIPLIER;  
  uint public constant PRICE_STAGE_THREE =  888 *MULTIPLIER;

   
  uint public constant ALLOC_TEAM =          4444444 *MULTIPLIER;  
  uint public constant ALLOC_CROWDSALE =    (4444444-266666) *MULTIPLIER;
  uint public constant ALLOC_SC = 	          266666 *MULTIPLIER;
  
  uint public constant ALLOC_MAX_PRE =        888888 *MULTIPLIER;
  
   
  uint public totalSupply =                  8888888 *MULTIPLIER; 
  
   
   
  uint public publicStartTime;  
  uint public publicEndTime;  
  uint public hardcapInWei;

   
  address public multisigAddress;  
  address public ownerAddress;  

   
  uint public weiRaised;  
  uint public EGLSold;  
  uint public prebuyPortionTotal;  
  
   
  bool public halted;  

   
  function isCrowdfundCompleted()
    internal
    returns (bool) 
  {
    if (
      now > publicEndTime
      || EGLSold >= ALLOC_CROWDSALE
      || weiRaised >= hardcapInWei
    ) return true;

    return false;
  }

   

   
  modifier only_owner() {
    require(msg.sender == ownerAddress);
    _;
  }

   
  modifier is_not_halted() {
    require(!halted);
    _;
  }

   
  event Buy(address indexed _recipient, uint _amount);

   
  function EGLToken(
    address _multisig,
    uint _publicStartTime,
    uint _hardcapInWei
  ) {
    ownerAddress = msg.sender;
    publicStartTime = _publicStartTime;
    publicEndTime = _publicStartTime + 28 days;
    multisigAddress = _multisig;

    hardcapInWei = _hardcapInWei;
    
    balances[0x8c6a58B551F38d4D51C0db7bb8b7ad29f7488702] += ALLOC_SC;

     
    balances[ownerAddress] += ALLOC_TEAM;

    balances[ownerAddress] += ALLOC_CROWDSALE;
  }

   
   
  function transfer(address _to, uint _value)
    returns (bool)
  {
    if (_to == msg.sender) return;  
    require(isCrowdfundCompleted());
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value)
    returns (bool)
  {
    require(isCrowdfundCompleted());
    return super.transferFrom(_from, _to, _value);
  }

   
  function getPriceRate()
      constant
      returns (uint o_rate)
  {
      uint delta = SafeMath.sub(now, publicStartTime);

      if (delta > STAGE_TWO_TIME_END) return PRICE_STAGE_THREE;
      if (delta > STAGE_ONE_TIME_END) return PRICE_STAGE_TWO;

      return (PRICE_STAGE_ONE);
  }

   
  function calcAmount(uint _wei, uint _rate) 
    constant
    returns (uint) 
  {
    return SafeMath.div(SafeMath.mul(_wei, _rate), 1 ether);
  } 
  
   
   
   
  function processPurchase(uint _rate, uint _remaining)
    internal
    returns (uint o_amount)
  {
    o_amount = calcAmount(msg.value, _rate);

    require(o_amount <= _remaining);
    require(multisigAddress.send(msg.value));

    balances[ownerAddress] = balances[ownerAddress].sub(o_amount);
    balances[msg.sender] = balances[msg.sender].add(o_amount);

    EGLSold += o_amount;
    weiRaised += msg.value;
  }

   
   
  function()
    payable
    is_not_halted
  {
    require(!isCrowdfundCompleted());

    uint amount;

    if (now < publicStartTime) {
       
      amount = processPurchase(PRICE_PREBUY, SafeMath.sub(ALLOC_MAX_PRE, prebuyPortionTotal));
      prebuyPortionTotal += amount;
    } else {
      amount = processPurchase(getPriceRate(), SafeMath.sub(ALLOC_CROWDSALE, EGLSold));
    }
    
    Buy(msg.sender, amount);
  }

   
  function toggleHalt(bool _halted)
    only_owner
  {
    halted = _halted;
  }

   
  function drain()
    only_owner
  {
    require(ownerAddress.send(this.balance));
  }

   
  function getStatus() 
    constant
    public
    returns (string)
  {
    if (EGLSold >= ALLOC_CROWDSALE) return "tokensSoldOut";
    if (weiRaised >= hardcapInWei) return "hardcapReached";
    
    if (now < publicStartTime) {
       
      if (prebuyPortionTotal >= ALLOC_MAX_PRE) return "presaleSoldOut";
      return "presale";
    } else if (now < publicEndTime) {
       
      return "public";
    } else {
      return "saleOver";
    }
  }
}