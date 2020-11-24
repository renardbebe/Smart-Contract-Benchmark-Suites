 

pragma solidity ^0.4.24;

 

library ItemUtils {

    uint256 internal constant UID_SHIFT = 2 ** 0;  
    uint256 internal constant RARITY_SHIFT = 2 ** 32;  
    uint256 internal constant CLASS_SHIFT = 2 ** 36;   
    uint256 internal constant TYPE_SHIFT = 2 ** 46;   
    uint256 internal constant TIER_SHIFT = 2 ** 56;  
    uint256 internal constant NAME_SHIFT = 2 ** 63;  
    uint256 internal constant REGION_SHIFT = 2 ** 70;  
    uint256 internal constant BASE_SHIFT = 2 ** 78;

    function createItem(uint256 _class, uint256 _type, uint256 _rarity, uint256 _tier, uint256 _name, uint256 _region) internal pure returns (uint256 dna) {
        dna = setClass(dna, _class);
        dna = setType(dna, _type);
        dna = setRarity(dna, _rarity);
        dna = setTier(dna, _tier);
        dna = setName(dna, _name);
        dna = setRegion(dna, _region);
    }

    function setUID(uint256 _dna, uint256 _value) internal pure returns (uint256) {
        require(_value < RARITY_SHIFT / UID_SHIFT);
        return setValue(_dna, _value, UID_SHIFT);
    }

    function setRarity(uint256 _dna, uint256 _value) internal pure returns (uint256) {
        require(_value < CLASS_SHIFT / RARITY_SHIFT);
        return setValue(_dna, _value, RARITY_SHIFT);
    }

    function setClass(uint256 _dna, uint256 _value) internal pure returns (uint256) {
        require(_value < TYPE_SHIFT / CLASS_SHIFT);
        return setValue(_dna, _value, CLASS_SHIFT);
    }

    function setType(uint256 _dna, uint256 _value) internal pure returns (uint256) {
        require(_value < TIER_SHIFT / TYPE_SHIFT);
        return setValue(_dna, _value, TYPE_SHIFT);
    }

    function setTier(uint256 _dna, uint256 _value) internal pure returns (uint256) {
        require(_value < NAME_SHIFT / TIER_SHIFT);
        return setValue(_dna, _value, TIER_SHIFT);
    }

    function setName(uint256 _dna, uint256 _value) internal pure returns (uint256) {
        require(_value < REGION_SHIFT / NAME_SHIFT);
        return setValue(_dna, _value, NAME_SHIFT);
    }

    function setRegion(uint256 _dna, uint256 _value) internal pure returns (uint256) {
        require(_value < BASE_SHIFT / REGION_SHIFT);
        return setValue(_dna, _value, REGION_SHIFT);
    }

    function getUID(uint256 _dna) internal pure returns (uint256) {
        return (_dna % RARITY_SHIFT) / UID_SHIFT;
    }

    function getRarity(uint256 _dna) internal pure returns (uint256) {
        return (_dna % CLASS_SHIFT) / RARITY_SHIFT;
    }

    function getClass(uint256 _dna) internal pure returns (uint256) {
        return (_dna % TYPE_SHIFT) / CLASS_SHIFT;
    }

    function getType(uint256 _dna) internal pure returns (uint256) {
        return (_dna % TIER_SHIFT) / TYPE_SHIFT;
    }

    function getTier(uint256 _dna) internal pure returns (uint256) {
        return (_dna % NAME_SHIFT) / TIER_SHIFT;
    }

    function getName(uint256 _dna) internal pure returns (uint256) {
        return (_dna % REGION_SHIFT) / NAME_SHIFT;
    }

    function getRegion(uint256 _dna) internal pure returns (uint256) {
        return (_dna % BASE_SHIFT) / REGION_SHIFT;
    }

    function setValue(uint256 dna, uint256 value, uint256 shift) internal pure returns (uint256) {
        return dna + (value * shift);
    }
}

 

library StringUtils {

    function concat(string _base, string _value) internal pure returns (string) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i++];
        }

        return string(_newValue);
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0) {
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

}

 

 
contract Ownable {
    address emitter;
    address administrator;

     
    function setEmitter(address _emitter) internal {
        require(_emitter != address(0));
        require(emitter == address(0));
        emitter = _emitter;
    }

     
    function setAdministrator(address _administrator) internal {
        require(_administrator != address(0));
        require(administrator == address(0));
        administrator = _administrator;
    }

     
    modifier onlyEmitter() {
        require(msg.sender == emitter);
        _;
    }

     
    modifier onlyAdministrator() {
        require(msg.sender == administrator);
        _;
    }

     
    function transferOwnership(address _emitter, address _administrator) public onlyAdministrator {
        require(_emitter != _administrator);
        require(_emitter != emitter);
        require(_emitter != address(0));
        require(_administrator != address(0));
        emitter = _emitter;
        administrator = _administrator;
    }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract GameCoin is StandardToken {
    string public constant name = "GameCoin";

    string public constant symbol = "GC";

    uint8 public constant decimals = 0;

    bool public isGameCoin = true;

     
    constructor(address[] owners) public {
        for (uint256 i = 0; i < owners.length; i++) {
            _mint(owners[i], 2 * 10 ** 6);
        }
    }

     
    function _mint(address _account, uint256 _amount) internal {
        require(_account != 0);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }
}

 

contract PresaleGacha {

    uint32 internal constant CLASS_NONE = 0;
    uint32 internal constant CLASS_CHARACTER = 1;
    uint32 internal constant CLASS_CHEST = 2;
    uint32 internal constant CLASS_MELEE = 3;
    uint32 internal constant CLASS_RANGED = 4;
    uint32 internal constant CLASS_ARMOR = 5;
    uint32 internal constant CLASS_HELMET = 6;
    uint32 internal constant CLASS_LEGS = 7;
    uint32 internal constant CLASS_GLOVES = 8;
    uint32 internal constant CLASS_BOOTS = 9;
    uint32 internal constant CLASS_NECKLACE = 10;
    uint32 internal constant CLASS_MODS = 11;
    uint32 internal constant CLASS_TROPHY = 12;

    uint32 internal constant TYPE_CHEST_NONE = 0;
    uint32 internal constant TYPE_CHEST_APPRENTICE = 1;
    uint32 internal constant TYPE_CHEST_WARRIOR = 2;
    uint32 internal constant TYPE_CHEST_GLADIATOR = 3;
    uint32 internal constant TYPE_CHEST_WARLORD = 4;
    uint32 internal constant TYPE_CHEST_TOKEN_PACK = 5;
    uint32 internal constant TYPE_CHEST_INVESTOR_PACK = 6;

    uint32 internal constant TYPE_RANGED_PRESALE_RIFLE = 1;
    uint32 internal constant TYPE_ARMOR_PRESALE_ARMOR = 1;
    uint32 internal constant TYPE_LEGS_PRESALE_LEGS = 1;
    uint32 internal constant TYPE_BOOTS_PRESALE_BOOTS = 1;
    uint32 internal constant TYPE_GLOVES_PRESALE_GLOVES = 1;
    uint32 internal constant TYPE_HELMET_PRESALE_HELMET = 1;
    uint32 internal constant TYPE_NECKLACE_PRESALE_NECKLACE = 1;
    uint32 internal constant TYPE_MODES_PRESALE_MODES = 1;

    uint32 internal constant NAME_NONE = 0;
    uint32 internal constant NAME_COSMIC = 1;
    uint32 internal constant NAME_FUSION = 2;
    uint32 internal constant NAME_CRIMSON = 3;
    uint32 internal constant NAME_SHINING = 4;
    uint32 internal constant NAME_ANCIENT = 5;

    uint32 internal constant RARITY_NONE = 0;
    uint32 internal constant RARITY_COMMON = 1;
    uint32 internal constant RARITY_RARE = 2;
    uint32 internal constant RARITY_EPIC = 3;
    uint32 internal constant RARITY_LEGENDARY = 4;
    uint32 internal constant RARITY_UNIQUE = 5;

    struct ChestItem {
        uint32 _class;
        uint32 _type;
        uint32 _rarity;
        uint32 _tier;
        uint32 _name;
    }

    mapping(uint256 => ChestItem) chestItems;

    mapping(uint32 => uint32) apprenticeChestProbability;
    mapping(uint32 => uint32) warriorChestProbability;
    mapping(uint32 => uint32) gladiatorChestProbability;
    mapping(uint32 => uint32) warlordChestProbability;

    constructor () public {
        chestItems[0] = ChestItem(CLASS_RANGED, TYPE_RANGED_PRESALE_RIFLE, RARITY_NONE, 0, NAME_NONE);
        chestItems[1] = ChestItem(CLASS_ARMOR, TYPE_ARMOR_PRESALE_ARMOR, RARITY_NONE, 0, NAME_NONE);
        chestItems[2] = ChestItem(CLASS_LEGS, TYPE_LEGS_PRESALE_LEGS, RARITY_NONE, 0, NAME_NONE);
        chestItems[3] = ChestItem(CLASS_BOOTS, TYPE_BOOTS_PRESALE_BOOTS, RARITY_NONE, 0, NAME_NONE);
        chestItems[4] = ChestItem(CLASS_GLOVES, TYPE_GLOVES_PRESALE_GLOVES, RARITY_NONE, 0, NAME_NONE);
        chestItems[5] = ChestItem(CLASS_HELMET, TYPE_HELMET_PRESALE_HELMET, RARITY_NONE, 0, NAME_NONE);
        chestItems[6] = ChestItem(CLASS_NECKLACE, TYPE_NECKLACE_PRESALE_NECKLACE, RARITY_NONE, 0, NAME_NONE);
        chestItems[7] = ChestItem(CLASS_MODS, TYPE_MODES_PRESALE_MODES, RARITY_NONE, 0, NAME_NONE);

        apprenticeChestProbability[0] = 60;
        apprenticeChestProbability[1] = 29;
        apprenticeChestProbability[2] = 5;
        apprenticeChestProbability[3] = 3;
        apprenticeChestProbability[4] = 2;
        apprenticeChestProbability[5] = 1;

        warriorChestProbability[0] = 10;
        warriorChestProbability[1] = 20;
        warriorChestProbability[2] = 15;
        warriorChestProbability[3] = 25;
        warriorChestProbability[4] = 25;
        warriorChestProbability[5] = 5;

        gladiatorChestProbability[0] = 15;
        gladiatorChestProbability[1] = 15;
        gladiatorChestProbability[2] = 20;
        gladiatorChestProbability[3] = 20;
        gladiatorChestProbability[4] = 18;
        gladiatorChestProbability[5] = 12;

        warlordChestProbability[0] = 10;
        warlordChestProbability[1] = 30;
        warlordChestProbability[2] = 60;
    }

    function getTier(uint32 _type, uint256 _id) internal pure returns (uint32){
        if (_type == TYPE_CHEST_APPRENTICE) {
            return (_id == 0 || _id == 3) ? 3 : (_id == 1 || _id == 4) ? 4 : 5;
        } else if (_type == TYPE_CHEST_WARRIOR) {
            return (_id == 0 || _id == 3 || _id == 5) ? 4 : (_id == 1 || _id == 4) ? 5 : 3;
        } else if (_type == TYPE_CHEST_GLADIATOR) {
            return (_id == 0 || _id == 3 || _id == 5) ? 5 : (_id == 2 || _id == 4) ? 5 : 3;
        } else if (_type == TYPE_CHEST_WARLORD) {
            return (_id == 1) ? 4 : 5;
        } else {
            require(false);
        }
    }

    function getRarity(uint32 _type, uint256 _id) internal pure returns (uint32) {
        if (_type == TYPE_CHEST_APPRENTICE) {
            return _id < 3 ? RARITY_RARE : RARITY_EPIC;
        } else if (_type == TYPE_CHEST_WARRIOR) {
            return _id < 2 ? RARITY_RARE : (_id > 1 && _id < 5) ? RARITY_EPIC : RARITY_LEGENDARY;
        } else if (_type == TYPE_CHEST_GLADIATOR) {
            return _id == 0 ? RARITY_RARE : (_id > 0 && _id < 4) ? RARITY_EPIC : RARITY_LEGENDARY;
        } else if (_type == TYPE_CHEST_WARLORD) {
            return (_id == 0) ? RARITY_EPIC : RARITY_LEGENDARY;
        } else {
            require(false);
        }
    }

    function isApprenticeChest(uint256 _identifier) internal pure returns (bool) {
        return ItemUtils.getType(_identifier) == TYPE_CHEST_APPRENTICE;
    }

    function isWarriorChest(uint256 _identifier) internal pure returns (bool) {
        return ItemUtils.getType(_identifier) == TYPE_CHEST_WARRIOR;
    }

    function isGladiatorChest(uint256 _identifier) internal pure returns (bool) {
        return ItemUtils.getType(_identifier) == TYPE_CHEST_GLADIATOR;
    }

    function isWarlordChest(uint256 _identifier) internal pure returns (bool) {
        return ItemUtils.getType(_identifier) == TYPE_CHEST_WARLORD;
    }

    function getApprenticeDistributedRandom(uint256 rnd) internal view returns (uint256) {
        uint256 tempDist = 0;
        for (uint8 i = 0; i < 6; i++) {
            tempDist += apprenticeChestProbability[i];
            if (rnd <= tempDist) {
                return i;
            }
        }
        return 0;
    }

    function getWarriorDistributedRandom(uint256 rnd) internal view returns (uint256) {
        uint256 tempDist = 0;
        for (uint8 i = 0; i < 6; i++) {
            tempDist += warriorChestProbability[i];
            if (rnd <= tempDist) {
                return i;
            }
        }
        return 0;
    }

    function getGladiatorDistributedRandom(uint256 rnd) internal view returns (uint256) {
        uint256 tempDist = 0;
        for (uint8 i = 0; i < 6; i++) {
            tempDist += gladiatorChestProbability[i];
            if (rnd <= tempDist) {
                return i;
            }
        }
        return 0;
    }

    function getWarlordDistributedRandom(uint256 rnd) internal view returns (uint256) {
        uint256 tempDist = 0;
        for (uint8 i = 0; i < 3; i++) {
            tempDist += warlordChestProbability[i];
            if (rnd <= tempDist) {
                return i;
            }
        }
        return 0;
    }
}

 

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 

 
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

 

 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 

 
contract ERC721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

 

 
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

 

 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

 

 
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
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

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
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
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
     
     
     
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
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
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
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
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 

 
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

   
  string internal name_;

   
  string internal symbol_;

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return name_;
  }

   
  function symbol() external view returns (string) {
    return symbol_;
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }


   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

     
     
    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
     
    ownedTokens[_from].length--;

     
     
     

    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

 

contract GlitchGoonsItem is PresaleGacha, ERC721Token, Ownable {
    string public constant name = "GlitchGoons";

    string public constant symbol = "GG";

    uint256 internal id;
    string internal tokenUriPref = "https://static.glitch-goons.com/metadata/gg/";

    struct PresalePack {
        uint32 available;
        uint32 gameCoin;
        uint256 price;
    }

    PresalePack tokenPack;
    PresalePack investorPack;
    PresalePack apprenticeChest;
    PresalePack warriorChest;
    PresalePack gladiatorChest;
    PresalePack warlordChest;

    uint256 private closingTime;
    uint256 private openingTime;

    GameCoin gameCoinContract;

    constructor (address _emitter, address _administrator, address _gameCoin, uint256 _openingTime, uint256 _closingTime)
    ERC721Token(name, symbol)
    public {
        setEmitter(_emitter);
        setAdministrator(_administrator);

        GameCoin gameCoinCandidate = GameCoin(_gameCoin);
        require(gameCoinCandidate.isGameCoin());
        gameCoinContract = gameCoinCandidate;

        tokenPack = PresalePack(50, 4000, 10 ether);
        investorPack = PresalePack(1, 10 ** 6, 500 ether);

        apprenticeChest = PresalePack(550, 207, .5 ether);
        warriorChest = PresalePack(200, 717, 1.75 ether);
        gladiatorChest = PresalePack(80, 1405, 3.5 ether);
        warlordChest = PresalePack(35, 3890, 10 ether);

        closingTime = _closingTime;
        openingTime = _openingTime;
    }

    function addItemToInternal(address _to, uint256 _class, uint256 _type, uint256 _rarity, uint256 _tier, uint256 _name, uint256 _region) internal {
        uint256 identity = ItemUtils.createItem(_class, _type, _rarity, _tier, _name, _region);
        identity = ItemUtils.setUID(identity, ++id);
        _mint(_to, identity);
    }

    function addItemTo(address _to, uint256 _class, uint256 _type, uint256 _rarity, uint256 _tier, uint256 _name, uint256 _region) external onlyEmitter {
        addItemToInternal(_to, _class, _type, _rarity, _tier, _name, _region);
    }

    function buyTokenPack(uint256 _region) external onlyWhileOpen canBuyPack(tokenPack) payable {
        addItemToInternal(msg.sender, CLASS_CHEST, TYPE_CHEST_TOKEN_PACK, RARITY_NONE, 0, NAME_NONE, _region);
        tokenPack.available--;
        administrator.transfer(msg.value);
    }

    function buyInvestorPack(uint256 _region) external onlyWhileOpen canBuyPack(investorPack) payable {
        addItemToInternal(msg.sender, CLASS_CHEST, TYPE_CHEST_INVESTOR_PACK, RARITY_NONE, 0, NAME_NONE, _region);
        investorPack.available--;
        administrator.transfer(msg.value);
    }

    function buyApprenticeChest(uint256 _region) external onlyWhileOpen canBuyPack(apprenticeChest) payable {
        addItemToInternal(msg.sender, CLASS_CHEST, TYPE_CHEST_APPRENTICE, RARITY_NONE, 0, NAME_NONE, _region);
        apprenticeChest.available--;
        administrator.transfer(msg.value);
    }

    function buyWarriorChest(uint256 _region) external onlyWhileOpen canBuyPack(warriorChest) payable {
        addItemToInternal(msg.sender, CLASS_CHEST, TYPE_CHEST_WARRIOR, RARITY_NONE, 0, NAME_NONE, _region);
        warriorChest.available--;
        administrator.transfer(msg.value);
    }

    function buyGladiatorChest(uint256 _region) external onlyWhileOpen canBuyPack(gladiatorChest) payable {
        addItemToInternal(msg.sender, CLASS_CHEST, TYPE_CHEST_GLADIATOR, RARITY_NONE, 0, NAME_NONE, _region);
        gladiatorChest.available--;
        administrator.transfer(msg.value);
    }

    function buyWarlordChest(uint256 _region) external onlyWhileOpen canBuyPack(warlordChest) payable {
        addItemToInternal(msg.sender, CLASS_CHEST, TYPE_CHEST_WARLORD, RARITY_NONE, 0, NAME_NONE, _region);
        warlordChest.available--;
        administrator.transfer(msg.value);
    }

    function openChest(uint256 _identifier) external onlyChestOwner(_identifier) {
        uint256 _type = ItemUtils.getType(_identifier);

        if (_type == TYPE_CHEST_TOKEN_PACK) {
            transferTokens(tokenPack);
        } else if (_type == TYPE_CHEST_INVESTOR_PACK) {
            transferTokens(investorPack);
        } else {
            uint256 blockNum = block.number;

            for (uint i = 0; i < 5; i++) {
                uint256 hash = uint256(keccak256(abi.encodePacked(_identifier, blockNum, i, block.coinbase, block.timestamp, block.difficulty)));
                blockNum--;
                uint256 rnd = hash % 101;
                uint32 _tier;
                uint32 _rarity;
                uint256 _id;

                if (isApprenticeChest(_identifier)) {
                    _id = getApprenticeDistributedRandom(rnd);
                    _rarity = getRarity(TYPE_CHEST_APPRENTICE, _id);
                    _tier = getTier(TYPE_CHEST_APPRENTICE, _id);
                } else if (isWarriorChest(_identifier)) {
                    _id = getWarriorDistributedRandom(rnd);
                    _rarity = getRarity(TYPE_CHEST_WARRIOR, _id);
                    _tier = getTier(TYPE_CHEST_WARRIOR, _id);
                } else if (isGladiatorChest(_identifier)) {
                    _id = getGladiatorDistributedRandom(rnd);
                    _rarity = getRarity(TYPE_CHEST_GLADIATOR, _id);
                    _tier = getTier(TYPE_CHEST_GLADIATOR, _id);
                } else if (isWarlordChest(_identifier)) {
                    _id = getWarlordDistributedRandom(rnd);
                    _rarity = getRarity(TYPE_CHEST_WARLORD, _id);
                    _tier = getTier(TYPE_CHEST_WARLORD, _id);
                } else {
                    require(false);
                }

                ChestItem storage chestItem = chestItems[hash % 8];
                uint256 _region = ItemUtils.getRegion(_identifier);
                uint256 _name = 1 + hash % 5;
                if (i == 0) {
                    if (isWarriorChest(_identifier)) {
                        addItemToInternal(msg.sender, chestItem._class, chestItem._type, RARITY_RARE, 3, _name, _region);
                    } else if (isGladiatorChest(_identifier)) {
                        addItemToInternal(msg.sender, chestItem._class, chestItem._type, RARITY_RARE, 5, _name, _region);
                    } else if (isWarlordChest(_identifier)) {
                        addItemToInternal(msg.sender, chestItem._class, chestItem._type, RARITY_LEGENDARY, 5, _name, _region);
                    } else {
                        addItemToInternal(msg.sender, chestItem._class, chestItem._type, _rarity, _tier, _name, _region);
                    }
                } else {
                    addItemToInternal(msg.sender, chestItem._class, chestItem._type, _rarity, _tier, _name, _region);
                }
            }
        }

        _burn(msg.sender, _identifier);
    }

    function getTokenPacksAvailable() view public returns (uint256) {
        return tokenPack.available;
    }

    function getTokenPackPrice() view public returns (uint256) {
        return tokenPack.price;
    }

    function getInvestorPacksAvailable() view public returns (uint256) {
        return investorPack.available;
    }

    function getInvestorPackPrice() view public returns (uint256) {
        return investorPack.price;
    }

    function getApprenticeChestAvailable() view public returns (uint256) {
        return apprenticeChest.available;
    }

    function getApprenticeChestPrice() view public returns (uint256) {
        return apprenticeChest.price;
    }

    function getWarriorChestAvailable() view public returns (uint256) {
        return warriorChest.available;
    }

    function getWarriorChestPrice() view public returns (uint256) {
        return warriorChest.price;
    }

    function getGladiatorChestAvailable() view public returns (uint256) {
        return gladiatorChest.available;
    }

    function getGladiatorChestPrice() view public returns (uint256) {
        return gladiatorChest.price;
    }

    function getWarlordChestAvailable() view public returns (uint256) {
        return warlordChest.available;
    }

    function getWarlordChestPrice() view public returns (uint256) {
        return warlordChest.price;
    }

     
    modifier onlyWhileOpen {
        require(isOpen());
        _;
    }

    modifier canBuyPack(PresalePack pack) {
        require(msg.value == pack.price);
        require(pack.available > 0);
        _;
    }

    modifier onlyChestOwner(uint256 _identity) {
        require(ownerOf(_identity) == msg.sender);
        require(ItemUtils.getClass(_identity) == CLASS_CHEST);
        _;
    }

     
    function isOpen() public view returns (bool) {
        return block.timestamp >= openingTime && block.timestamp <= closingTime;
    }

    function getClosingTime() public view returns (uint256) {
        return closingTime;
    }

    function getOpeningTime() public view returns (uint256) {
        return openingTime;
    }

    function transferTokens(PresalePack pack) internal {
        require(gameCoinContract.balanceOf(address(this)) >= pack.gameCoin);
        gameCoinContract.transfer(msg.sender, pack.gameCoin);
    }

    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return string(abi.encodePacked(tokenUriPref, StringUtils.uint2str(ItemUtils.getUID(_tokenId)), ".json"));
    }

    function setTokenUriPref(string _uri) public onlyAdministrator {
        tokenUriPref = _uri;
    }
}