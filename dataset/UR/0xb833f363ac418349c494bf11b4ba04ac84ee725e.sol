 

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
       revert();
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

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


 

contract LimitedTransferToken is ERC20 {

   
  modifier canTransfer(address _sender, uint _value) {
   if (_value > transferableTokens(_sender, uint64(now))) revert();
   _;
  }

   
  function transfer(address _to, uint _value) canTransfer(msg.sender, _value) {
    super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) {
    super.transferFrom(_from, _to, _value);
  }

   
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    time;
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
      revert();
    }

    if (tokenGrantsCount(_to) > MAX_GRANTS_PER_ADDRESS) revert();    

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
    TokenGrant storage grant = grants[_holder][_grantId];

    if (!grant.revokable) {  
      revert();
    }

    if (grant.granter != msg.sender) {  
      revert();
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
    TokenGrant storage grant = grants[_holder][_grantId];

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

 
 
 
 

 


contract DANSToken is VestedToken {
   
  string public name = "DAN-Service coin";
  string public symbol = "DANS";
  uint public decimals = 4;
  
   
   
  uint public constant CROWDSALE_DURATION = 60 days;
  uint public constant STAGE_ONE_TIME_END = 24 hours;  
  uint public constant STAGE_TWO_TIME_END = 1 weeks;  
  uint public constant STAGE_THREE_TIME_END = CROWDSALE_DURATION;
  
   
  uint private constant DECIMALS = 10000;

   
  uint public constant PRICE_STANDARD    = 900*DECIMALS;  
  uint public constant PRICE_STAGE_ONE   = PRICE_STANDARD * 130/100;  
  uint public constant PRICE_STAGE_TWO   = PRICE_STANDARD * 115/100;  
  uint public constant PRICE_STAGE_THREE = PRICE_STANDARD;

   
  uint public constant ALLOC_TEAM =         16000000*DECIMALS;  
  uint public constant ALLOC_BOUNTIES =      4000000*DECIMALS;
  uint public constant ALLOC_CROWDSALE =    80000000*DECIMALS;
  uint public constant PREBUY_PORTION_MAX = 20000000*DECIMALS;  
 
   
  uint public totalSupply = 100000000*DECIMALS; 
  
   
   
  uint public publicStartTime;  
  uint public privateStartTime;  
  uint public publicEndTime;  
  uint public hardcapInEth;

   
  address public multisigAddress;  
  address public danserviceTeamAddress;  
  address public ownerAddress;  
  address public preBuy1;  
  address public preBuy2;  
  address public preBuy3;  
  uint public preBuyPrice1;  
  uint public preBuyPrice2;  
  uint public preBuyPrice3;  

   
  uint public etherRaised;  
  uint public DANSSold;  
  uint public prebuyPortionTotal;  
  
   
  bool public halted;  

   
   
  modifier is_pre_crowdfund_period() {
    if (now >= publicStartTime || now < privateStartTime) revert();
    _;
  }

   
  modifier is_crowdfund_period() {
    if (now < publicStartTime) revert();
    if (isCrowdfundCompleted()) revert();
    _;
  }

   
  modifier is_crowdfund_completed() {
    if (!isCrowdfundCompleted()) revert();
    _;
  }
  function isCrowdfundCompleted() internal returns (bool) {
    if (now > publicEndTime || DANSSold >= ALLOC_CROWDSALE || etherRaised >= hardcapInEth) return true;
    return false;
  }

   
  modifier only_owner() {
    if (msg.sender != ownerAddress) revert();
    _;
  }

   
  modifier is_not_halted() {
    if (halted) revert();
    _;
  }

   
  event PreBuy(uint _amount);
  event Buy(address indexed _recipient, uint _amount);

   
  function DANSToken (
    address _multisig,
    address _danserviceTeam,
    uint _publicStartTime,
    uint _privateStartTime,
    uint _hardcapInEth,
    address _prebuy1, uint _preBuyPrice1,
    address _prebuy2, uint _preBuyPrice2,
    address _prebuy3, uint _preBuyPrice3
  )
    public
  {
    ownerAddress = msg.sender;
    publicStartTime = _publicStartTime;
    privateStartTime = _privateStartTime;
	publicEndTime = _publicStartTime + CROWDSALE_DURATION;
    multisigAddress = _multisig;
    danserviceTeamAddress = _danserviceTeam;

    hardcapInEth = _hardcapInEth;

    preBuy1 = _prebuy1;
    preBuyPrice1 = _preBuyPrice1;
    preBuy2 = _prebuy2;
    preBuyPrice2 = _preBuyPrice2;
    preBuy3 = _prebuy3;
    preBuyPrice3 = _preBuyPrice3;

    balances[danserviceTeamAddress] += ALLOC_BOUNTIES;

    balances[ownerAddress] += ALLOC_TEAM;

    balances[ownerAddress] += ALLOC_CROWDSALE;
  }

   
   
  function transfer(address _to, uint _value)
  {
    if (_to == msg.sender) return;  
    if (!isCrowdfundCompleted()) revert();
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

    if (o_amount > _remaining) revert();
    if (!multisigAddress.send(msg.value)) revert();

    balances[ownerAddress] = balances[ownerAddress].sub(o_amount);
    balances[msg.sender] = balances[msg.sender].add(o_amount);

    DANSSold += o_amount;
    etherRaised += msg.value;
  }

   
  function preBuy()
    payable
    is_pre_crowdfund_period
    is_not_halted
  {
     
    uint priceVested = 0;

    if (msg.sender == preBuy1) priceVested = preBuyPrice1;
    if (msg.sender == preBuy2) priceVested = preBuyPrice2;
    if (msg.sender == preBuy3) priceVested = preBuyPrice3;

    if (priceVested == 0) revert();

    uint amount = processPurchase(PRICE_STAGE_ONE + priceVested, SafeMath.sub(PREBUY_PORTION_MAX, prebuyPortionTotal));
    grantVestedTokens(msg.sender, calcAmount(msg.value, priceVested), 
      uint64(now), uint64(now) + 91 days, uint64(now) + 365 days, 
      false, false
    );
    prebuyPortionTotal += amount;
    PreBuy(amount);
  }

   
   
  function()
    payable
    is_crowdfund_period
    is_not_halted
  {
    uint amount = processPurchase(getPriceRate(), SafeMath.sub(ALLOC_CROWDSALE, DANSSold));
    Buy(msg.sender, amount);
  }

   
   
  function grantVested(address _danserviceTeamAddress, address _danserviceFundAddress)
    is_crowdfund_completed
    only_owner
    is_not_halted
  {
     
    grantVestedTokens(
      _danserviceTeamAddress, ALLOC_TEAM,
      uint64(now), uint64(now) + 91 days , uint64(now) + 365 days, 
      false, false
    );

     
    grantVestedTokens(
      _danserviceFundAddress, balances[ownerAddress],
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
    if (!ownerAddress.send(address(this).balance)) revert();
  }
}