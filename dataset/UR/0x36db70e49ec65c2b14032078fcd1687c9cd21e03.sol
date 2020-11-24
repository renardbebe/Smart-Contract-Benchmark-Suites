 

pragma solidity ^0.4.23;

 

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 

 
contract OwnedPausableToken is StandardToken, Pausable {

   
  modifier whenNotPausedOrIsOwner() {
    require(!paused || msg.sender == owner);
    _;
  }

  function transfer(address _to, uint256 _value) public whenNotPausedOrIsOwner returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 

contract IDAVToken is ERC20 {

  function name() public view returns (string) {}
  function symbol() public view returns (string) {}
  function decimals() public view returns (uint8) {}
  function increaseApproval(address _spender, uint _addedValue) public returns (bool success);
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success);

  function owner() public view returns (address) {}
  function transferOwnership(address newOwner) public;

  function burn(uint256 _value) public;

  function pauseCutoffTime() public view returns (uint256) {}
  function paused() public view returns (bool) {}
  function pause() public;
  function unpause() public;
  function setPauseCutoffTime(uint256 _pauseCutoffTime) public;

}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

 
contract DAVToken is IDAVToken, BurnableToken, OwnedPausableToken {

   
  string public name = 'DAV Token';
  string public symbol = 'DAV';
  uint8 public decimals = 18;

   
  uint256 public pauseCutoffTime;

   
  constructor(uint256 _initialSupply) public {
    totalSupply_ = _initialSupply;
    balances[msg.sender] = totalSupply_;
  }

   
  function setPauseCutoffTime(uint256 _pauseCutoffTime) onlyOwner public {
     
     
    require(_pauseCutoffTime >= block.timestamp);
     
    require(pauseCutoffTime == 0);
     
    pauseCutoffTime = _pauseCutoffTime;
  }

   
  function pause() onlyOwner whenNotPaused public {
     
     
    require(pauseCutoffTime == 0 || pauseCutoffTime >= block.timestamp);
    paused = true;
    emit Pause();
  }

}

 

 
contract Identity {

  struct DAVIdentity {
    address wallet;
  }

  mapping (address => DAVIdentity) private identities;

  DAVToken private token;

   
  bytes28 private constant ETH_SIGNED_MESSAGE_PREFIX = '\x19Ethereum Signed Message:\n32';
  bytes25 private constant DAV_REGISTRATION_REQUEST = 'DAV Identity Registration';

   
  function Identity(DAVToken _davTokenContract) public {
    token = _davTokenContract;
  }

  function register(address _id, uint8 _v, bytes32 _r, bytes32 _s) public {
     
    require(
      identities[_id].wallet == 0x0
    );
     
    bytes32 prefixedHash = keccak256(ETH_SIGNED_MESSAGE_PREFIX, keccak256(DAV_REGISTRATION_REQUEST));
     
    require(
      ecrecover(prefixedHash, _v, _r, _s) == _id
    );

     
    identities[_id] = DAVIdentity({
      wallet: msg.sender
    });
  }

  function registerSimple() public {
     
    require(
      identities[msg.sender].wallet == 0x0
    );

     
    identities[msg.sender] = DAVIdentity({
      wallet: msg.sender
    });
  }

  function getBalance(address _id) public view returns (uint256 balance) {
    return token.balanceOf(identities[_id].wallet);
  }

  function verifyOwnership(address _id, address _wallet) public view returns (bool verified) {
    return identities[_id].wallet == _wallet;
  }

   
  function isRegistered(address _id) public view returns (bool) {
    return identities[_id].wallet != 0x0;
  }

   
  function getIdentityWallet(address _id) public view returns (address) {
    return identities[_id].wallet;
  }
}

 

 
contract BasicMission {

  uint256 private nonce;

  struct Mission {
    address seller;
    address buyer;
    uint256 cost;
    uint256 balance;
    bool isSigned;
    mapping (uint8 => bool) resolvers;
  }

  mapping (bytes32 => Mission) private missions;

  event Create(
    bytes32 id,
    address sellerId,
    address buyerId
  );

  event Signed(
    bytes32 id
  );

  DAVToken private token;
  Identity private identity;

   
  function BasicMission(Identity _identityContract, DAVToken _davTokenContract) public {
    identity = _identityContract;
    token = _davTokenContract;
  }

   
  function create(bytes32 _missionId, address _sellerId, address _buyerId, uint256 _cost) public {
     
    require(
      identity.verifyOwnership(_buyerId, msg.sender)
    );

     
    require(
      identity.getBalance(_buyerId) >= _cost
    );

     
    require(
      missions[_missionId].buyer == 0x0
    );

     
    token.transferFrom(msg.sender, this, _cost);

     
    missions[_missionId] = Mission({
      seller: _sellerId,
      buyer: _buyerId,
      cost: _cost,
      balance: _cost,
      isSigned: false
    });

     
    emit Create(_missionId, _sellerId, _buyerId);
  }

   
  function fulfilled(bytes32 _missionId, address _buyerId) public {
     
    require(
      identity.verifyOwnership(_buyerId, msg.sender)
    );
    
    require(
      missions[_missionId].isSigned == false
    );

    require(
      missions[_missionId].balance == missions[_missionId].cost
    );
    
    
     
    missions[_missionId].isSigned = true;
    missions[_missionId].balance = 0;
    token.approve(this, missions[_missionId].cost);
    token.transferFrom(this, identity.getIdentityWallet(missions[_missionId].seller), missions[_missionId].cost);

     
    emit Signed(_missionId);
  }

}