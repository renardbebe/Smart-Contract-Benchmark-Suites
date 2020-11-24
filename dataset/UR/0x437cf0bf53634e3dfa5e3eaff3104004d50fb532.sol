 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

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

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}




 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


 

contract LimitedTransferToken is ERC20 {

   
  modifier canTransfer(address _sender, uint _value) {
   if (_value > transferableTokens(_sender, uint64(now))) throw;
   _;
  }

   
  function transfer(address _to, uint _value) canTransfer(msg.sender, _value) {
    super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) {
    super.transferFrom(_from, _to, _value);
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

     
    if (_cliff < _start || _vesting < _cliff) {
      throw;
    }

    if (tokenGrantsCount(_to) > MAX_GRANTS_PER_ADDRESS) throw;    

    uint count = grants[_to].push(
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

   
  function revokeTokenGrant(address _holder, uint _grantId) public {
    TokenGrant grant = grants[_holder][_grantId];

    if (!grant.revokable) {  
      throw;
    }

    if (grant.granter != msg.sender) {  
      throw;
    }

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

    if (grantIndex == 0) return balanceOf(holder);  

     
    uint256 nonVested = 0;
    for (uint256 i = 0; i < grantIndex; i++) {
      nonVested = SafeMath.add(nonVested, nonVestedTokens(grants[holder][i], time));
    }

     
    uint256 vestedTransferable = SafeMath.sub(balanceOf(holder), nonVested);

     
     
    return SafeMath.min256(vestedTransferable, super.transferableTokens(holder, time));
  }

   
  function tokenGrantsCount(address _holder) constant returns (uint index) {
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

   
  function tokenGrant(address _holder, uint _grantId) constant returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke) {
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
      date = SafeMath.max64(grants[holder][i].vesting, date);
    }
  }
}

 
 
 

 


contract BTN is VestedToken {
   
  string public name = "BETNetwork";
  string public symbol = "BTN";
  uint public decimals = 4;

  uint public constant STAGE_PRESALE_ETHRaised = 3500*1 ether;  
  uint public constant STAGE_TWO_ETHRaised = 8500*1 ether;  
  uint public constant STAGE_THREE_ETHRaised = 14000*1 ether;
  uint public constant STAGE_FOUR_ETHRaised = 20000*1 ether;
  
   
  uint private constant DECIMALS = 10000;

   
  uint public constant PRICE_STANDARD    = 3128*DECIMALS;  
  uint public constant PRICE_STAGE_PRESALE   = PRICE_STANDARD * 140/100;  
  uint public constant PRICE_STAGE_TWO   = PRICE_STANDARD * 125/100;  
  uint public constant PRICE_STAGE_THREE = PRICE_STANDARD * 115/100;  
  uint public constant PRICE_STAGE_FOUR = PRICE_STANDARD * 105/100;  
  
   
  uint public constant ALLOC_TEAM =         22500000*DECIMALS;  
  uint public constant ALLOC_RES =         22500000*DECIMALS;  
  uint public constant ALLOC_CROWDSALE =    105000000*DECIMALS;
  
   
   
  uint public publicStartTime;  
  uint public publicEndTime;  
  uint public hardcapInEth=30000* 1 ether;

   
  address public multisigAddress=0x2DD016668BD409B7E1988dFddC08388e448f1E90;  
  address public BETNetworkTeamAddress=0xdCE5999988a40AF0f9E6b73EAF9D5a1DC01a24E9;  
  address public ownerAddress;  


   
  uint public etherRaised;  
  uint public BTNSold;  
  
   
  bool public halted;  

   
   
  modifier is_pre_crowdfund_period() {
    if (now >= publicStartTime ) throw;
    _;
  }

   
  modifier is_crowdfund_period() {
    if (now < publicStartTime) throw;
    if (isCrowdfundCompleted()) throw;
    _;
  }

   
  modifier is_crowdfund_completed() {
    if (!isCrowdfundCompleted()) throw;
    _;
  }
  function isCrowdfundCompleted() internal returns (bool) {
    if (now > publicEndTime || BTNSold >= ALLOC_CROWDSALE || etherRaised >= hardcapInEth) return true;
    return false;
  }

   
  modifier only_owner() {
    if (msg.sender != ownerAddress) throw;
    _;
  }

   
  modifier is_not_halted() {
    if (halted) throw;
    _;
  }

   
  event Buy(address indexed _recipient, uint _amount);

   
  function BTN() {
    ownerAddress = msg.sender;
    publicStartTime = now;
    publicEndTime = now + 6 weeks;
    balances[BETNetworkTeamAddress] += ALLOC_TEAM;
    balances[ownerAddress] += ALLOC_RES;
    balances[ownerAddress] += ALLOC_CROWDSALE;
  }

   
   
  function transfer(address _to, uint _value)
  {
    if (_to == msg.sender) return;  
    if (!isCrowdfundCompleted()) throw;
    super.transfer(_to, _value);
  }

   
   
  function transferFrom(address _from, address _to, uint _value)
    is_crowdfund_completed
  {
    super.transferFrom(_from, _to, _value);
  }

   
  function getPriceRate()
      constant
      returns (uint o_rate)
  {
      uint delta = etherRaised;
      if (delta < STAGE_PRESALE_ETHRaised) return PRICE_STAGE_PRESALE;
      if (delta < STAGE_TWO_ETHRaised) return PRICE_STAGE_TWO;
      if (delta < STAGE_THREE_ETHRaised) return PRICE_STAGE_THREE;
       if (delta < STAGE_FOUR_ETHRaised) return PRICE_STAGE_FOUR;
      return (PRICE_STANDARD);
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

    if (o_amount > _remaining) throw;
    if (!multisigAddress.send(msg.value)) throw;

    balances[ownerAddress] = balances[ownerAddress].sub(o_amount);
    balances[msg.sender] = balances[msg.sender].add(o_amount);

    BTNSold += o_amount;
    etherRaised += msg.value;
  }

   
   
  function()
    payable
    is_crowdfund_period
    is_not_halted
  {
    uint amount = processPurchase(getPriceRate(), SafeMath.sub(ALLOC_CROWDSALE, BTNSold));
    Buy(msg.sender, amount);
  }

   
   
  function grantVested(address _BETNetworkTeamAddress, address _BETNetworkFundAddress)
    is_crowdfund_completed
    only_owner
    is_not_halted
  {
     
    grantVestedTokens(
      _BETNetworkTeamAddress, ALLOC_TEAM,
      uint64(now), uint64(now) + 91 days , uint64(now) + 365 days, 
      false, false
    );

     
    grantVestedTokens(
      _BETNetworkFundAddress, balances[ownerAddress],
      uint64(now), uint64(now) + 182 days , uint64(now) + 730 days, 
      false, false
    );
  }

   
  function toggleHalt(bool _halted)
    only_owner
  {
    halted = _halted;
  }

   
  function drain()
    only_owner
  {
    if (!ownerAddress.send(this.balance)) throw;
  }
}