 

pragma solidity ^0.4.23;

 

 
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

 

contract TrustedContractControl is Ownable{
  using AddressUtils for address;

  mapping (address => bool) public trustedContractList;

  modifier onlyTrustedContract(address _contractAddress) {
    require(trustedContractList[_contractAddress]);
    _;
  }

  event AddTrustedContract(address contractAddress);
  event RemoveTrustedContract(address contractAddress);


  function addTrustedContracts(address[] _contractAddress) onlyOwner public {
    for(uint i=0; i<_contractAddress.length; i++) {
      require(addTrustedContract(_contractAddress[i]));
    }
  }


   
  function addTrustedContract(address _contractAddress) onlyOwner public returns (bool){
    require(!trustedContractList[_contractAddress]);
    require(_contractAddress.isContract());
    trustedContractList[_contractAddress] = true;
    emit AddTrustedContract(_contractAddress);
    return true;
  }

  function removeTrustedContract(address _contractAddress) onlyOwner public {
    require(trustedContractList[_contractAddress]);
    trustedContractList[_contractAddress] = false;
    emit RemoveTrustedContract(_contractAddress);
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

 

contract GirlOps is GirlBasicToken, TrustedContractControl {

  string public name = "Cryptogirl";
  string public symbol = "CG";
  
  function createGirl(uint _genes, address _owner, uint16 _starLevel)
      onlyTrustedContract(msg.sender) public returns (uint) {
      require (_starLevel > 0);
      return _createGirl(_genes, _owner, _starLevel);
  }

  function createPromotionGirl(uint[] _genes, address _owner, uint16 _starLevel) onlyOwner public {
  	require (_starLevel > 0);
    for (uint i=0; i<_genes.length; i++) {
      _createGirl(_genes[i], _owner, _starLevel);
    }
  }

  function burnGirl(address _owner, uint _tokenId) onlyTrustedContract(msg.sender) public {
      _burn(_owner, _tokenId);
  }

  function setCoolDownTime(uint _tokenId, uint _coolDownTime)
      onlyTrustedContract(msg.sender) public {
      _setCoolDownTime(_tokenId, _coolDownTime);
  }

  function levelUp(uint _tokenId)
      onlyTrustedContract(msg.sender) public {
      _LevelUp(_tokenId);
  }

  function safeTransferFromWithData(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  ) public {
      safeTransferFrom(_from,_to,_tokenId,_data);
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

 

contract AccessControl is Ownable{
    address CFO;
     

    modifier onlyCFO{
        require(msg.sender == CFO);
        _;
    }

    function setCFO(address _newCFO)public onlyOwner {
        CFO = _newCFO;
    }

     

}

 

contract ServerControl is AccessControl{

    event AddServerAddress(address contractAddress);
    event RemoveServerAddress(address contractAddress);

    mapping (address => bool) public serverAddressList;

    modifier onlyServer {
        require(serverAddressList[msg.sender]);
        _;
    }

    function addServerAddress(address _serverAddress) onlyOwner public returns (bool){
        serverAddressList[_serverAddress] = true;
        emit AddServerAddress(_serverAddress);
        return true;
    }

    function removeServerAddress(address _serverAddress) onlyOwner public {
        require(serverAddressList[_serverAddress]);
        serverAddressList[_serverAddress] = false;
        emit RemoveServerAddress(_serverAddress);
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

 

contract PrizePool is Ownable {

  event SendPrized(address equipementAddress, address to);

  address[] public magicBoxes;
  mapping(address => bool) public magicBoxList;

  address[] public equipments;
  GirlOps public girlOps;

  event SendEquipment(address to, address prizeAddress, uint time);
  event EquipmentOutOfStock(address eqAddress);

  modifier onlyMagicBox() {
    require(magicBoxList[msg.sender]);
    _;
  }

  constructor(address _girlOpsAddress) public {
    girlOps = GirlOps(_girlOpsAddress);
  }

  function sendPrize(address _to, uint _index) public onlyMagicBox returns (bool) {
     
     
     
    address prizeAddress = equipments[_index];
    BaseEquipment baseEquipment = BaseEquipment(prizeAddress);
    if(baseEquipment.checkCap(1 ether)) {
      baseEquipment.mint(_to, 1 ether);
      emit SendEquipment(_to, prizeAddress, now);
      return true;
    } else {
      emit EquipmentOutOfStock(prizeAddress);
      return false;
    }
  }

  function mintGirl(address to, uint gene, uint16 _level) public onlyMagicBox returns (bool) {
    girlOps.createGirl(gene, to, _level);
    return true;
  }

  function setEquipments(address[] _equipments) public onlyOwner {
    equipments = _equipments;
  }


  function addMagicBox(address addr) public onlyOwner returns (bool) {
    if (!magicBoxList[addr]) {
      magicBoxList[addr] = true;
      magicBoxes.push(addr);
      return true;
    } else {
      return false;
    }
  }

  function addMagicBoxes(address[] addrs) public onlyOwner returns (bool) {
    for (uint i=0; i<addrs.length; i++) {
      require(addMagicBox(addrs[i]));
    }
    return true;
  }

  function removeMagicBox(address addr) public onlyOwner returns (bool) {
    require(magicBoxList[addr]);
    for (uint i=0; i<magicBoxes.length - 1; i++) {
      if (magicBoxes[i] == addr) {
        magicBoxes[i] = magicBoxes[magicBoxes.length -1];
        break;
      }
    }
    magicBoxes.length -= 1;
    magicBoxList[addr] = false;
    return true;
  }

}

 

contract SRNG is Ownable {

    string welcome = "Hi, I know I cannot hide from you ;) Before creating your script to guess out what is your next prize in the box. Wait a minute ! We have a gift for you. We haved created a special crypto girl to this contract, submit your answer at 0x.... the girl is yours. And sadly we will have to create a more complicated puzzle next time. Happy hacking ! lol";

    mapping (address => bool) public whitelist;
    uint rand;

    function addBoxToWhitelist(address _box) public;

    function removeFromWhitelist(address _box) public;
    
    function addManyToWhitelist(address[] _boxes) public;

    function _getRandom() internal returns (uint);

    function getRandomFromBox() public returns (uint);

}

 

contract SRNMagicBox is ServerControl, TokenReceiver {
  GirlOps girlOps;
  GenesFactory genesFactory;
  SRNG SRNGInstance;

  string public name;                 
  uint public keyRequired;
  address public keyAddress;
  address public prizePoolAddress;
  uint public boxPrice;               

  uint[] public prizeIndex;
  uint[] public prizeRange;

  uint[] public NCards;
  uint[] public RCards;
  uint[] public SRCards;
  uint[] public SSRCards;

  event SendGirlFail(address _to, uint _type); 

  constructor(string _name, address _girlAddress, address _SRNGAddress, address _genesFactoryAddress, address _prizePoolAddress, address _keyAddress, uint _keyRequired, uint _boxPrice) public {
    name = _name;
    girlOps = GirlOps(_girlAddress);
    SRNGInstance = SRNG(_SRNGAddress);
    genesFactory = GenesFactory(_genesFactoryAddress);
    prizePoolAddress = _prizePoolAddress;
    keyAddress = _keyAddress;
    keyRequired = _keyRequired;
    boxPrice = _boxPrice;
  }


  function setupPrize(uint[] _prizeIndex, uint[] _prizeRange) public onlyOwner {
    prizeIndex = _prizeIndex;
    prizeRange = _prizeRange;
  }

  function getPrizeIndex(uint random) public view returns (uint) {
    uint maxRange = prizeRange[prizeRange.length -1];
    uint n = random % maxRange;

    uint start = 0;
    uint mid = 0;
    uint end = prizeRange.length-1;

    if (prizeRange[0]>n){
      return 0;
    }
    if (prizeRange[end-1]<=n){
      return end;
    }

    while (start <= end) {
      mid = start + (end - start) / 2;
      if (prizeRange[mid]<=n && n<prizeRange[mid+1]){
          return mid+1;
      } else if (prizeRange[mid+1] <= n) {
        start = mid+1;
      } else {
        end = mid;
      }
    }

    return start;
  }

  function _sendGirl(address _to, uint _random, uint[] storage collection) internal returns (bool) {
    uint index;
    uint length = collection.length;
    if(length > 0) {
      index = _random % length;
      girlOps.createGirl(collection[index], _to, 1);
       
      collection[index] = collection[length -1];
      collection.length = length - 1;
      return true;
    } else {
      return false;
    }
  }
  
  function _openBox(address _to, uint _random) internal returns (bool) {
    uint index = getPrizeIndex(_random);
    PrizePool pl = PrizePool(prizePoolAddress);
    uint count = 0;
    while(count < prizeIndex.length) {
      if(prizeIndex[index] == 0) {  
        if(_sendGirl(_to, _random, NCards)) {  
          return true;
        } else {
          emit SendGirlFail(_to, 0);
        }
      } else if(prizeIndex[index] == 1) {
        if(_sendGirl(_to, _random, RCards)){   
          return true;
        } else {
          emit SendGirlFail(_to, 1);
        }
      } else if(prizeIndex[index] == 2) {
        if(_sendGirl(_to, _random, SRCards)){   
          return true;
        } else {
          emit SendGirlFail(_to, 2);
        }
      } else if(prizeIndex[index] == 3) {
        if(_sendGirl(_to, _random, SSRCards)) {   
          return true;
        } else {
          emit SendGirlFail(_to, 3);
        }
      }  else if (pl.sendPrize(_to, prizeIndex[index] - 10)) {  
        return true;
      }

      count = count + 1;
      index = index + 1;
      if(index == prizeIndex.length) index = 0;

    }

     
    return false;
  }

  function setKeyAddress(address _key) public onlyOwner {
    keyAddress = _key;
  }
  
  function setGirls(uint[] _tokenIds) public onlyOwner {
    uint _rarity;
    for(uint i=0; i<_tokenIds.length; i++) {
      _rarity = genesFactory.getRarity(_tokenIds[i]);
      if(_rarity == 0) {
        NCards.push(_tokenIds[i]);
      } else if(_rarity == 1) {
        RCards.push(_tokenIds[i]);
      } else if(_rarity == 2) {
        SRCards.push(_tokenIds[i]);
      } else if(_rarity == 3) {
        SSRCards.push(_tokenIds[i]);
      } else {
        revert();
      }
    }
  }

  function setSRNG(address _SRNGAddress) public onlyOwner {
    SRNGInstance = SRNG(_SRNGAddress);
  }

  function getNCardsNumber() public view returns (uint) {
    return NCards.length;
  }

  function getRCardsNumber() public view returns (uint) {
    return RCards.length;
  }

  function getSRCardsNumber() public view returns (uint) {
    return SRCards.length;
  }

  function getSSRCardsNumber() public view returns (uint) {
    return SSRCards.length;
  }


   
  function() public payable {
     require(boxPrice > 0, 'this mode is not supported');
     require(msg.value == boxPrice);   
     uint rand = SRNGInstance.getRandomFromBox();
     _openBox(msg.sender, rand);
  }


  function receiveApproval(address _from, uint _amount, address _tokenAddress, bytes _data) public {
   require(keyRequired > 0, 'this mode is not supported');
   require(_tokenAddress == keyAddress);  
   require(_amount == keyRequired);  
   require(StandardToken(_tokenAddress).transferFrom(_from, address(this), _amount));
   uint rand = SRNGInstance.getRandomFromBox();
   _openBox(_from, rand);
  }


  function withDrawToken(uint _amount) public onlyCFO {
    StandardToken(keyAddress).transfer(CFO, _amount);
  }

  function withDrawBalance(uint256 amount) public onlyCFO {
    require(address(this).balance >= amount);
    if (amount==0){
      CFO.transfer(address(this).balance);
    } else {
      CFO.transfer(amount);
    }
  }

  function setupBoxPrice(uint256 _boxPrice) public onlyOwner {
    boxPrice = _boxPrice;
  }

  function setupKeyRequired(uint256 _keyRequired) public onlyOwner {
    keyRequired = _keyRequired;
  }

  function setPrizePoolAddress(address _prizePoolAddress) public onlyOwner {
    prizePoolAddress = _prizePoolAddress;
  }

  function setGirlOps(address _girlAddress) public onlyOwner {
    girlOps = GirlOps(_girlAddress);
  }

  function setGenesFactory(address _genesFactoryAddress) public onlyOwner {
    genesFactory = GenesFactory(_genesFactoryAddress);
  }

  function setGirlByRarity(uint[] _tokenIds, uint _rarity) public onlyOwner {
      for(uint i=0; i<_tokenIds.length; i++) {
        if(_rarity == 0) {
          NCards.push(_tokenIds[i]);
        } else if(_rarity == 1) {
          RCards.push(_tokenIds[i]);
        } else if(_rarity == 2) {
          SRCards.push(_tokenIds[i]);
        } else if(_rarity == 3) {
          SSRCards.push(_tokenIds[i]);
        } else {
          revert();
        }
      }
  }

  function canOpen() public view returns (bool) {
    if(NCards.length > 0 && RCards.length >0 && SRCards.length >0 && SSRCards.length >0) {
      return true;
    }else{
      return false;
    }
  }

}