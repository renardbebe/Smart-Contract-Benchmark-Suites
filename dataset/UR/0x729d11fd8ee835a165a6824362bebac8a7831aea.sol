 

pragma solidity ^0.4.11;

contract Controller {

   
   
   
  function proxyPayment(address _owner) payable returns(bool) {
    return false;
  }

   
   
   
   
   
   
  function onTransfer(address _from, address _to, uint _amount) returns(bool) {
    return false;
  }

   
   
   
   
   
   
  function onApprove(address _owner, address _spender, uint _amount) returns(bool) {
    return false;
  }
}

 
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

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping (address => uint) balances;

   
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

contract Controlled {

  address public controller;

  function Controlled() {
    controller = msg.sender;
  }

  function changeController(address _controller) onlyController {
    controller = _controller;
  }

  modifier onlyController {
    if (msg.sender != controller) throw;
    _;
  }
}


 
contract MintableToken is StandardToken, Controlled {

  event Mint(address indexed to, uint value);
  event MintFinished();

  bool public mintingFinished = false;
  uint public totalSupply = 0;

   
  function mint(address _to, uint _amount) onlyController canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyController returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

  modifier canMint() {
    if (mintingFinished) throw;
    _;
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
      nonVested = nonVested.add(nonVestedTokens(grants[holder][i], time));
    }

     
    uint256 vestedTransferable = balanceOf(holder).sub(nonVested);

     
     
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

       
       
       

       
      uint256 vestedTokens = tokens.mul(time.sub(start)).div(vesting.sub(start));
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


 
contract Artcoin is MintableToken, VestedToken {

  string public constant name = 'Artcoin';
  string public constant symbol = 'ART';
  uint public constant decimals = 18;

  function() public payable {
    if (isContract(controller)) {
      if (!Controller(controller).proxyPayment.value(msg.value)(msg.sender)) throw;
    } else {
      throw;
    }
  }

  function isContract(address _addr) constant internal returns(bool) {
    uint size;
    if (_addr == address(0)) return false;
    assembly {
      size := extcodesize(_addr)
    }
    return size > 0;
  }
}