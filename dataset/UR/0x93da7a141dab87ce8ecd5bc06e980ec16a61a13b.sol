 

pragma solidity ^0.4.23;

 

 
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

 

contract Serialize {
    using SafeMath for uint256;
    function addAddress(uint _offst, bytes memory _output, address _input) internal pure returns(uint _offset) {
      assembly {
        mstore(add(_output, _offst), _input)
      }
      return _offst.sub(20);
    }

    function addUint(uint _offst, bytes memory _output, uint _input) internal pure returns (uint _offset) {
      assembly {
        mstore(add(_output, _offst), _input)
      }
      return _offst.sub(32);
    }

    function addUint8(uint _offst, bytes memory _output, uint _input) internal pure returns (uint _offset) {
      assembly {
        mstore(add(_output, _offst), _input)
      }
      return _offst.sub(1);
    }

    function addUint16(uint _offst, bytes memory _output, uint _input) internal pure returns (uint _offset) {
      assembly {
        mstore(add(_output, _offst), _input)
      }
      return _offst.sub(2);
    }

    function addUint64(uint _offst, bytes memory _output, uint _input) internal pure returns (uint _offset) {
      assembly {
        mstore(add(_output, _offst), _input)
      }
      return _offst.sub(8);
    }

    function getAddress(uint _offst, bytes memory _input) internal pure returns (address _output, uint _offset) {
      assembly {
        _output := mload(add(_input, _offst))
      }
      return (_output, _offst.sub(20));
    }

    function getUint(uint _offst, bytes memory _input) internal pure returns (uint _output, uint _offset) {
      assembly {
          _output := mload(add(_input, _offst))
      }
      return (_output, _offst.sub(32));
    }

    function getUint8(uint _offst, bytes memory _input) internal pure returns (uint8 _output, uint _offset) {
      assembly {
        _output := mload(add(_input, _offst))
      }
      return (_output, _offst.sub(1));
    }

    function getUint16(uint _offst, bytes memory _input) internal pure returns (uint16 _output, uint _offset) {
      assembly {
        _output := mload(add(_input, _offst))
      }
      return (_output, _offst.sub(2));
    }

    function getUint64(uint _offst, bytes memory _input) internal pure returns (uint64 _output, uint _offset) {
      assembly {
        _output := mload(add(_input, _offst))
      }
      return (_output, _offst.sub(8));
    }
}

 

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
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

 

 
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

 

 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

 

 
contract ERC721BasicToken is ERC721Basic, Pausable {
  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  function transferBatch(address _from, address _to, uint[] _tokenIds) public {
    require(_from != address(0));
    require(_to != address(0));

    for(uint i=0; i<_tokenIds.length; i++) {
      require(isApprovedOrOwner(msg.sender, _tokenIds[i]));
      clearApproval(_from,  _tokenIds[i]);
      removeTokenFrom(_from, _tokenIds[i]);
      addTokenTo(_to, _tokenIds[i]);

      emit Transfer(_from, _to, _tokenIds[i]);
    }
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal whenNotPaused {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal whenNotPaused{
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 

 
contract GirlBasicToken is ERC721BasicToken, Serialize {

  event CreateGirl(address owner, uint256 tokenID, uint256 genes, uint64 birthTime, uint64 cooldownEndTime, uint16 starLevel);
  event CoolDown(uint256 tokenId, uint64 cooldownEndTime);
  event GirlUpgrade(uint256 tokenId, uint64 starLevel);

  struct Girl{
     
    uint genes;

     
    uint64 birthTime;

     
    uint64 cooldownEndTime;
     
    uint16 starLevel;
  }

  Girl[] girls;


  function totalSupply() public view returns (uint256) {
    return girls.length;
  }

  function getGirlGene(uint _index) public view returns (uint) {
    return girls[_index].genes;
  }

  function getGirlBirthTime(uint _index) public view returns (uint64) {
    return girls[_index].birthTime;
  }

  function getGirlCoolDownEndTime(uint _index) public view returns (uint64) {
    return girls[_index].cooldownEndTime;
  }

  function getGirlStarLevel(uint _index) public view returns (uint16) {
    return girls[_index].starLevel;
  }

  function isNotCoolDown(uint _girlId) public view returns(bool) {
    return uint64(now) > girls[_girlId].cooldownEndTime;
  }

  function _createGirl(
      uint _genes,
      address _owner,
      uint16 _starLevel
  ) internal returns (uint){
      Girl memory _girl = Girl({
          genes:_genes,
          birthTime:uint64(now),
          cooldownEndTime:0,
          starLevel:_starLevel
      });
      uint256 girlId = girls.push(_girl) - 1;
      _mint(_owner, girlId);
      emit CreateGirl(_owner, girlId, _genes, _girl.birthTime, _girl.cooldownEndTime, _girl.starLevel);
      return girlId;
  }

  function _setCoolDownTime(uint _tokenId, uint _coolDownTime) internal {
    girls[_tokenId].cooldownEndTime = uint64(now.add(_coolDownTime));
    emit CoolDown(_tokenId, girls[_tokenId].cooldownEndTime);
  }

  function _LevelUp(uint _tokenId) internal {
    require(girls[_tokenId].starLevel < 65535);
    girls[_tokenId].starLevel = girls[_tokenId].starLevel + 1;
    emit GirlUpgrade(_tokenId, girls[_tokenId].starLevel);
  }

   
   
   
  uint8 constant public GIRLBUFFERSIZE = 50;   

  struct HashLockContract {
    address sender;
    address receiver;
    uint tokenId;
    bytes32 hashlock;
    uint timelock;
    bytes32 secret;
    States state;
    bytes extraData;
  }

  enum States {
    INVALID,
    OPEN,
    CLOSED,
    REFUNDED
  }

  mapping (bytes32 => HashLockContract) private contracts;

  modifier contractExists(bytes32 _contractId) {
    require(_contractExists(_contractId));
    _;
  }

  modifier hashlockMatches(bytes32 _contractId, bytes32 _secret) {
    require(contracts[_contractId].hashlock == keccak256(_secret));
    _;
  }

  modifier closable(bytes32 _contractId) {
    require(contracts[_contractId].state == States.OPEN);
    require(contracts[_contractId].timelock > now);
    _;
  }

  modifier refundable(bytes32 _contractId) {
    require(contracts[_contractId].state == States.OPEN);
    require(contracts[_contractId].timelock <= now);
    _;
  }

  event NewHashLockContract (
    bytes32 indexed contractId,
    address indexed sender,
    address indexed receiver,
    uint tokenId,
    bytes32 hashlock,
    uint timelock,
    bytes extraData
  );

  event SwapClosed(bytes32 indexed contractId);
  event SwapRefunded(bytes32 indexed contractId);

  function open (
    address _receiver,
    bytes32 _hashlock,
    uint _duration,
    uint _tokenId
  ) public
    onlyOwnerOf(_tokenId)
    returns (bytes32 contractId)
  {
    uint _timelock = now.add(_duration);

     
    bytes memory _extraData = new bytes(GIRLBUFFERSIZE);
    uint offset = GIRLBUFFERSIZE;

    offset = addUint16(offset, _extraData, girls[_tokenId].starLevel);
    offset = addUint64(offset, _extraData, girls[_tokenId].cooldownEndTime);
    offset = addUint64(offset, _extraData, girls[_tokenId].birthTime);
    offset = addUint(offset, _extraData, girls[_tokenId].genes);

    contractId = keccak256 (
      msg.sender,
      _receiver,
      _tokenId,
      _hashlock,
      _timelock,
      _extraData
    );

     
    require(!_contractExists(contractId));

     
     
    clearApproval(msg.sender, _tokenId);
    removeTokenFrom(msg.sender, _tokenId);
    addTokenTo(address(this), _tokenId);


    contracts[contractId] = HashLockContract(
      msg.sender,
      _receiver,
      _tokenId,
      _hashlock,
      _timelock,
      0x0,
      States.OPEN,
      _extraData
    );

    emit NewHashLockContract(contractId, msg.sender, _receiver, _tokenId, _hashlock, _timelock, _extraData);
  }

  function close(bytes32 _contractId, bytes32 _secret)
    public
    contractExists(_contractId)
    hashlockMatches(_contractId, _secret)
    closable(_contractId)
    returns (bool)
  {
    HashLockContract storage c = contracts[_contractId];
    c.secret = _secret;
    c.state = States.CLOSED;

     
     
    removeTokenFrom(address(this), c.tokenId);
    addTokenTo(c.receiver, c.tokenId);

    emit SwapClosed(_contractId);
    return true;
  }

  function refund(bytes32 _contractId)
    public
    contractExists(_contractId)
    refundable(_contractId)
    returns (bool)
  {
    HashLockContract storage c = contracts[_contractId];
    c.state = States.REFUNDED;

     
     
    removeTokenFrom(address(this), c.tokenId);
    addTokenTo(c.sender, c.tokenId);


    emit SwapRefunded(_contractId);
    return true;
  }

  function _contractExists(bytes32 _contractId) internal view returns (bool exists) {
    exists = (contracts[_contractId].sender != address(0));
  }

  function checkContract(bytes32 _contractId)
    public
    view
    contractExists(_contractId)
    returns (
      address sender,
      address receiver,
      uint amount,
      bytes32 hashlock,
      uint timelock,
      bytes32 secret,
      bytes extraData
    )
  {
    HashLockContract memory c = contracts[_contractId];
    return (
      c.sender,
      c.receiver,
      c.tokenId,
      c.hashlock,
      c.timelock,
      c.secret,
      c.extraData
    );
  }


}

 

contract GenesFactory{
    function mixGenes(uint256 gene1, uint gene2) public returns(uint256);
    function getPerson(uint256 genes) public pure returns (uint256 person);
    function getRace(uint256 genes) public pure returns (uint256);
    function getRarity(uint256 genes) public pure returns (uint256);
    function getBaseStrengthenPoint(uint256 genesMain,uint256 genesSub) public pure returns (uint256);

    function getCanBorn(uint256 genes) public pure returns (uint256 canBorn,uint256 cooldown);
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

 

contract AtomicSwappableToken is StandardToken {
  struct HashLockContract {
    address sender;
    address receiver;
    uint amount;
    bytes32 hashlock;
    uint timelock;
    bytes32 secret;
    States state;
  }

  enum States {
    INVALID,
    OPEN,
    CLOSED,
    REFUNDED
  }

  mapping (bytes32 => HashLockContract) private contracts;

  modifier futureTimelock(uint _time) {
     
     
     
    require(_time > now);
    _;
}

  modifier contractExists(bytes32 _contractId) {
    require(_contractExists(_contractId));
    _;
  }

  modifier hashlockMatches(bytes32 _contractId, bytes32 _secret) {
    require(contracts[_contractId].hashlock == keccak256(_secret));
    _;
  }

  modifier closable(bytes32 _contractId) {
    require(contracts[_contractId].state == States.OPEN);
    require(contracts[_contractId].timelock > now);
    _;
  }

  modifier refundable(bytes32 _contractId) {
    require(contracts[_contractId].state == States.OPEN);
    require(contracts[_contractId].timelock <= now);
    _;
  }

  event NewHashLockContract (
    bytes32 indexed contractId,
    address indexed sender,
    address indexed receiver,
    uint amount,
    bytes32 hashlock,
    uint timelock
  );

  event SwapClosed(bytes32 indexed contractId);
  event SwapRefunded(bytes32 indexed contractId);


  function open (
    address _receiver,
    bytes32 _hashlock,
    uint _timelock,
    uint _amount
  ) public
    futureTimelock(_timelock)
    returns (bytes32 contractId)
  {
    contractId = keccak256 (
      msg.sender,
      _receiver,
      _amount,
      _hashlock,
      _timelock
    );

     
    require(!_contractExists(contractId));

     
    require(transfer(address(this), _amount));

    contracts[contractId] = HashLockContract(
      msg.sender,
      _receiver,
      _amount,
      _hashlock,
      _timelock,
      0x0,
      States.OPEN
    );

    emit NewHashLockContract(contractId, msg.sender, _receiver, _amount, _hashlock, _timelock);
  }

  function close(bytes32 _contractId, bytes32 _secret)
    public
    contractExists(_contractId)
    hashlockMatches(_contractId, _secret)
    closable(_contractId)
    returns (bool)
  {
    HashLockContract storage c = contracts[_contractId];
    c.secret = _secret;
    c.state = States.CLOSED;
    require(this.transfer(c.receiver, c.amount));
    emit SwapClosed(_contractId);
    return true;
  }

  function refund(bytes32 _contractId)
    public
    contractExists(_contractId)
    refundable(_contractId)
    returns (bool)
  {
    HashLockContract storage c = contracts[_contractId];
    c.state = States.REFUNDED;
    require(this.transfer(c.sender, c.amount));
    emit SwapRefunded(_contractId);
    return true;
  }

  function _contractExists(bytes32 _contractId) internal view returns (bool exists) {
    exists = (contracts[_contractId].sender != address(0));
  }

  function checkContract(bytes32 _contractId)
    public
    view
    contractExists(_contractId)
    returns (
      address sender,
      address receiver,
      uint amount,
      bytes32 hashlock,
      uint timelock,
      bytes32 secret
    )
  {
    HashLockContract memory c = contracts[_contractId];
    return (
      c.sender,
      c.receiver,
      c.amount,
      c.hashlock,
      c.timelock,
      c.secret
    );
  }

}

 

contract TokenReceiver {
  function receiveApproval(address from, uint amount, address tokenAddress, bytes data) public;
}

 

contract BaseEquipment is Ownable, AtomicSwappableToken {

  event Mint(address indexed to, uint256 amount);

   
  uint256 public cap;

   
  uint[] public properties;


  address public controller;

  modifier onlyController { require(msg.sender == controller); _; }

  function setController(address _newController) public onlyOwner {
    controller = _newController;
  }

  constructor(uint256 _cap, uint[] _properties) public {
    cap = _cap;
    properties = _properties;
  }

  function setProperty(uint256[] _properties) public onlyOwner {
    properties = _properties;
  }


  function _mint(address _to, uint _amount) internal {
    require(cap==0 || totalSupply_.add(_amount) <= cap);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(address(0), _to, _amount);
  }


  function mint(address _to, uint256 _amount) onlyController public returns (bool) {
    _mint(_to, _amount);
    return true;
  }


  function mintFromOwner(address _to, uint256 _amount) onlyOwner public returns (bool) {
    _mint(_to, _amount);
    return true;
  }


  function approveAndCall(address _spender, uint _amount, bytes _data) public {
    if(approve(_spender, _amount)) {
      TokenReceiver(_spender).receiveApproval(msg.sender, _amount, address(this), _data);
    }
  }


  function checkCap(uint256 _amount) public view returns (bool) {
  	return (cap==0 || totalSupply_.add(_amount) <= cap);
  }




}

 

contract AvatarEquipments is Pausable{

    event SetEquipment(address user, uint256 girlId, address tokenAddress, uint256 amount, uint validationDuration);

    struct Equipment {
        address BackgroundAddress;
        uint BackgroundAmount;
        uint64 BackgroundEndTime;

        address photoFrameAddress;
        uint photoFrameAmount;
        uint64 photoFrameEndTime;

        address armsAddress;
        uint armsAmount;
        uint64 armsEndTime;

        address petAddress;
        uint petAmount;
        uint64 petEndTime;
    }
    GirlBasicToken girlBasicToken;
    GenesFactory genesFactory;
   
    mapping (uint256 => Equipment) public GirlIndexToEquipment;

    mapping (address => bool) public equipmentToStatus;

    constructor(address _girlBasicToken, address _GenesFactory) public{
        require(_girlBasicToken != address(0x0));
        girlBasicToken = GirlBasicToken(_girlBasicToken);
        genesFactory = GenesFactory(_GenesFactory);
    }

 

    function addTokenToWhitelist(address _eq) public onlyOwner {
      equipmentToStatus[_eq] = true;
    }


    function removeFromWhitelist(address _eq) public onlyOwner {
      equipmentToStatus[_eq] = false;
    }

    function addManyToWhitelist(address[] _eqs) public onlyOwner {
      for(uint i=0; i<_eqs.length; i++) {
        equipmentToStatus[_eqs[i]] = true;
      }
    }

     
    function withdrawEquipment(uint _girlId, address _equipmentAddress) public {
       BaseEquipment baseEquipment = BaseEquipment(_equipmentAddress);
       uint _validationDuration = baseEquipment.properties(0);
       require(_validationDuration == 18446744073709551615);  
       Equipment storage equipment = GirlIndexToEquipment[_girlId];
       uint location = baseEquipment.properties(1);
       address owner = girlBasicToken.ownerOf(_girlId);
       uint amount;
       if (location == 1 && equipment.BackgroundAddress == _equipmentAddress) {
          amount = equipment.BackgroundAmount;
          
          equipment.BackgroundAddress = address(0); 
          equipment.BackgroundAmount = 0; 
          equipment.BackgroundEndTime = 0;          
       } else if (location == 2 && equipment.photoFrameAddress == _equipmentAddress) {
          amount = equipment.photoFrameAmount;
          
          equipment.photoFrameAddress = address(0); 
          equipment.photoFrameAmount= 0; 
          equipment.photoFrameEndTime = 0;
       } else if (location == 3 && equipment.armsAddress == _equipmentAddress) {
          amount = equipment.armsAmount;
          
          equipment.armsAddress = address(0); 
          equipment.armsAmount = 0; 
          equipment.armsEndTime = 0; 
       } else if (location == 4 && equipment.petAddress == _equipmentAddress) {
          amount = equipment.petAmount;
          
          equipment.petAddress = address(0); 
          equipment.petAmount = 0; 
          equipment.petEndTime = 0; 
       } else {
          revert();
       }
       require(amount > 0);
       baseEquipment.transfer(owner, amount);
    }

    function setEquipment(address _sender, uint _girlId, uint _amount, address _equipmentAddress, uint256[] _properties) whenNotPaused public {
        require(isValid(_sender, _girlId , _amount, _equipmentAddress));
        Equipment storage equipment = GirlIndexToEquipment[_girlId];

        require(_properties.length >= 3);
        uint _validationDuration = _properties[0];
        uint _location = _properties[1];
        uint _applicableType = _properties[2];

        if(_applicableType < 16){
          uint genes = girlBasicToken.getGirlGene(_girlId);
          uint race = genesFactory.getRace(genes);
          require(race == uint256(_applicableType));
        }

        uint _count = _amount / (1 ether);

        if (_location == 1) {
            if(_validationDuration == 18446744073709551615) {  
              equipment.BackgroundEndTime = 18446744073709551615;
            } else if((equipment.BackgroundAddress == _equipmentAddress) && equipment.BackgroundEndTime > now ) {
                equipment.BackgroundEndTime  += uint64(_count * _validationDuration);
            } else {
                equipment.BackgroundEndTime = uint64(now + (_count * _validationDuration));
            }
            equipment.BackgroundAddress = _equipmentAddress;
            equipment.BackgroundAmount = _amount;
        } else if (_location == 2){
            if(_validationDuration == 18446744073709551615) {
              equipment.photoFrameEndTime = 18446744073709551615;
            } else if((equipment.photoFrameAddress == _equipmentAddress) && equipment.photoFrameEndTime > now ) {
                equipment.photoFrameEndTime  += uint64(_count * _validationDuration);
            } else {
                equipment.photoFrameEndTime = uint64(now + (_count * _validationDuration));
            }
            equipment.photoFrameAddress = _equipmentAddress;
            equipment.photoFrameAmount = _amount;
        } else if (_location == 3) {
            if(_validationDuration == 18446744073709551615) {
              equipment.armsEndTime = 18446744073709551615;
            } else if((equipment.armsAddress == _equipmentAddress) && equipment.armsEndTime > now ) {
              equipment.armsEndTime  += uint64(_count * _validationDuration);
            } else {
              equipment.armsEndTime = uint64(now + (_count * _validationDuration));
            }
            equipment.armsAddress = _equipmentAddress;
            equipment.armsAmount = _count;
        } else if (_location == 4) {
            if(_validationDuration == 18446744073709551615) {
              equipment.petEndTime = 18446744073709551615;
            } else if((equipment.petAddress == _equipmentAddress) && equipment.petEndTime > now ) {
              equipment.petEndTime  += uint64(_count * _validationDuration);
            } else {
              equipment.petEndTime = uint64(now + (_count * _validationDuration));
            }
            equipment.petAddress = _equipmentAddress;
            equipment.petAmount = _amount;
        } else{
            revert();
        }
        emit SetEquipment(_sender, _girlId, _equipmentAddress, _amount, _validationDuration);
    }

    function isValid (address _from, uint _GirlId, uint _amount, address _tokenContract) public returns (bool) {
        BaseEquipment baseEquipment = BaseEquipment(_tokenContract);
        require(equipmentToStatus[_tokenContract]);
         
        require(_amount >= 1 ether);
        require(_amount % 1 ether == 0);  
        require(girlBasicToken.ownerOf(_GirlId) == _from || owner == _from);  
        require(baseEquipment.transferFrom(_from, this, _amount));
        return true;
    }

    function getGirlEquipmentStatus(uint256 _girlId) public view returns(
        address BackgroundAddress,
        uint BackgroundAmount,
        uint BackgroundEndTime,

        address photoFrameAddress,
        uint photoFrameAmount,
        uint photoFrameEndTime,

        address armsAddress,
        uint armsAmount,
        uint armsEndTime,

        address petAddress,
        uint petAmount,
        uint petEndTime
  ){
        Equipment storage equipment = GirlIndexToEquipment[_girlId];
        if (equipment.BackgroundEndTime >= now) {
            BackgroundAddress = equipment.BackgroundAddress;
            BackgroundAmount = equipment.BackgroundAmount;
            BackgroundEndTime = equipment.BackgroundEndTime;
        }

        if (equipment.photoFrameEndTime >= now) {
            photoFrameAddress = equipment.photoFrameAddress;
            photoFrameAmount = equipment.photoFrameAmount;
            photoFrameEndTime = equipment.photoFrameEndTime;
        }

        if (equipment.armsEndTime >= now) {
            armsAddress = equipment.armsAddress;
            armsAmount = equipment.armsAmount;
            armsEndTime = equipment.armsEndTime;
        }

        if (equipment.petEndTime >= now) {
            petAddress = equipment.petAddress;
            petAmount = equipment.petAmount;
            petEndTime = equipment.petEndTime;
        }
    }
}

 

contract EquipmentToken is BaseEquipment {
    string public name;                 
    string public symbol;               
    uint8 public decimals;            


    constructor (
        string _name,
        string _symbol,
        uint256 _cap,
        uint[] _properties
    ) public BaseEquipment(_cap, _properties) {

        name = _name;
        symbol = _symbol;
        decimals = 18;   
    }

    function setEquipment(address _target, uint _GirlId, uint256 _amount) public returns (bool success) {
        AvatarEquipments eq = AvatarEquipments(_target);
        if (approve(_target, _amount)) {
            eq.setEquipment(msg.sender, _GirlId, _amount, this, properties);
            return true;
        }
    }
}