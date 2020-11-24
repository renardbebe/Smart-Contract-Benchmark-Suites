 

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





contract ZillaToken is StandardToken, Ownable {
  uint256 constant zilla = 1 ether;

  string public name = 'Zilla Token';
  string public symbol = 'ZLA';
  uint public decimals = 18;
  uint256 public initialSupply = 60000000 * zilla;
  bool public tradeable;

  function ZillaToken() public {
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply;
    tradeable = false;
  }

   
  modifier isTradeable() {
    require( tradeable == true );
    _;
  }

   
  function allowTrading() public onlyOwner {
    require( tradeable == false );
    tradeable = true;
  }

   
  function crowdsaleTransfer(address _to, uint256 _value) public onlyOwner returns (bool) {
    require( tradeable == false );
    return super.transfer(_to, _value);
  } 

  function transfer(address _to, uint256 _value) public isTradeable returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public isTradeable returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public isTradeable returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public isTradeable returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public isTradeable returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}





 
contract ZillaCrowdsale is Ownable {
  using SafeMath for uint256;

   
  event StartCrowdsale();
  event FinalizeCrowdsale();
  event TokenSold(address recipient, uint eth_amount, uint zla_amount);
 
   
  uint256 constant presale_eth_to_zilla   = 1200;
  uint256 constant crowdsale_eth_to_zilla =  750;

   
  ZillaToken public token;

   
  uint256 public zilla_remaining;

   
  address public vault;

   
  enum CrowdsaleState { Waiting, Running, Ended }
  CrowdsaleState public state = CrowdsaleState.Waiting;
  uint256 public start;
  uint256 public unlimited;
  uint256 public end;

   
  struct Participant {
    bool    whitelist;
    uint256 remaining;
  }
  mapping (address => Participant) private participants;

   
  function ZillaCrowdsale() public {
    token = new ZillaToken();
    zilla_remaining = token.totalSupply();
  }

   
  modifier isStarted() {
    require( (state == CrowdsaleState.Running) );
    _;
  }

   
  modifier isRunning() {
    require( (state == CrowdsaleState.Running) && (now >= start) && (now < end) );
    _;
  }

   
  function startCrowdsale(uint256 _start, uint256 _unlimited, uint256 _end, address _vault) public onlyOwner {
    require(state == CrowdsaleState.Waiting);
    require(_start >= now);
    require(_unlimited > _start);
    require(_unlimited < _end);
    require(_end > _start);
    require(_vault != 0x0);

    start     = _start;
    unlimited = _unlimited;
    end       = _end;
    vault     = _vault;
    state     = CrowdsaleState.Running;
    StartCrowdsale();
  }

   
  function finalizeCrowdsale() public onlyOwner {
    require(state == CrowdsaleState.Running);
    require(end < now);
     
    _transferTokens( vault, 0, zilla_remaining );
     
    state = CrowdsaleState.Ended;
     
    token.allowTrading();
    FinalizeCrowdsale();
  }

   
  function setEndDate(uint256 _end) public onlyOwner {
    require(state == CrowdsaleState.Running);
    require(_end > now);
    require(_end > start);
    require(_end > end);

    end = _end;
  }

   
  function setVault(address _vault) public onlyOwner {
    require(_vault != 0x0);

    vault = _vault;    
  }

   
  function whitelistAdd(address[] _addresses) public onlyOwner {
    for (uint i=0; i<_addresses.length; i++) {
      Participant storage p = participants[ _addresses[i] ];
      p.whitelist = true;
      p.remaining = 15 ether;
    }
  }

   
  function whitelistRemove(address[] _addresses) public onlyOwner {
    for (uint i=0; i<_addresses.length; i++) {
      delete participants[ _addresses[i] ];
    }
  }

   
  function() external payable {
    buyTokens(msg.sender);
  }

   
  function _allocateTokens(uint256 eth) private view returns(uint256 tokens) {
    tokens = crowdsale_eth_to_zilla.mul(eth);
    require( zilla_remaining >= tokens );
  }

   
  function _allocatePresaleTokens(uint256 eth) private view returns(uint256 tokens) {
    tokens = presale_eth_to_zilla.mul(eth);
    require( zilla_remaining >= tokens );
  }

   
  function _transferTokens(address recipient, uint256 eth, uint256 zla) private {
    require( token.crowdsaleTransfer( recipient, zla ) );
    zilla_remaining = zilla_remaining.sub( zla );
    TokenSold(recipient, eth, zla);
  }

   
  function _grantPresaleTokens(address recipient, uint256 eth) private {
    uint256 tokens = _allocatePresaleTokens(eth);
    _transferTokens( recipient, eth, tokens );
  }

   
  function buyTokens(address recipient) public isRunning payable {
    Participant storage p = participants[ recipient ];    
    require( p.whitelist );
     
    if( unlimited > now ) {
      require( p.remaining >= msg.value );
      p.remaining.sub( msg.value );
    }
    uint256 tokens = _allocateTokens(msg.value);
    require( vault.send(msg.value) );
    _transferTokens( recipient, msg.value, tokens );
  }

   
  function grantTokens(address recipient, uint256 zla) public isStarted onlyOwner {
    require( zilla_remaining >= zla );
    _transferTokens( recipient, 0, zla );
  }

   
  function grantPresaleTokens(address[] recipients, uint256[] eths) public isStarted onlyOwner {
    require( recipients.length == eths.length );
    for (uint i=0; i<recipients.length; i++) {
      _grantPresaleTokens( recipients[i], eths[i] );
    }
  }

}