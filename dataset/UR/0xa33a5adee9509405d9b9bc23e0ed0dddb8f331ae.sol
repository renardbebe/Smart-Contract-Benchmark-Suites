 

pragma solidity ^0.4.18;
 
 
 
 
 
contract ERC721   {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _approved, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
     function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 
interface ERC721TokenReceiver {
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

 
 
 
interface ERC721Metadata   {
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string);
}

 
 
 
interface ERC721Enumerable   {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
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


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() external onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() external onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function mul32(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function div32(uint32 a, uint32 b) internal pure returns (uint32) {
     
    uint32 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function sub32(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function add32(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract AccessAdmin is Pausable {

   
  mapping (address => bool) adminContracts;

   
  mapping (address => bool) actionContracts;

  function setAdminContract(address _addr, bool _useful) public onlyOwner {
    require(_addr != address(0));
    adminContracts[_addr] = _useful;
  }

  modifier onlyAdmin {
    require(adminContracts[msg.sender]); 
    _;
  }

  function setActionContract(address _actionAddr, bool _useful) public onlyAdmin {
    actionContracts[_actionAddr] = _useful;
  }

  modifier onlyAccess() {
    require(actionContracts[msg.sender]);
    _;
  }
}

interface CaptainGameConfigInterface {
  function getLevelConfig(uint32 cardId, uint32 level) external view returns (uint32 atk,uint32 defense,uint32 atk_min,uint32 atk_max);
}
contract CaptainToken is AccessAdmin, ERC721 {
  using SafeMath for SafeMath;
   
  event CreateCaptain(uint tokenId,uint32 captainId, address _owner, uint256 _price);
   
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event LevelUP(address indexed _owner,uint32 oldLevel, uint32 newLevel);

  struct Captain {
    uint32 captainId;  
    uint32 color;  
    uint32 atk; 
    uint32 defense;
    uint32 level;
    uint256 exp;
  }
  CaptainGameConfigInterface public config;

  Captain[] public captains;  
  function CaptainToken() public {
    captains.length += 1;
    setAdminContract(msg.sender,true);
    setActionContract(msg.sender,true);
  }
   
  function setGameConfigContract(address _address) external onlyOwner {
    config = CaptainGameConfigInterface(_address);
  }

   
   
  mapping (uint256 => address) public captainTokenIdToOwner;
   
  mapping (uint256 => uint256) captainIdToOwnerIndex;  
   
  mapping (address => uint256[]) ownerToCaptainArray;
   
  mapping (uint256 => uint256) captainTokenIdToPrice;
   
  mapping (uint32 => uint256) tokenCountOfCaptain;
   
  mapping (uint256 => uint32) IndexToCaptain;
   
  mapping (uint256 => address) captainTokenIdToApprovals;
   
  mapping (address => mapping (address => bool)) operatorToApprovals;
  mapping(uint256 => bool) tokenToSell;
  

   
   
  uint256 destroyCaptainCount;
  
   
   
  modifier isValidToken(uint256 _tokenId) {
    require(_tokenId >= 1 && _tokenId <= captains.length);
    require(captainTokenIdToOwner[_tokenId] != address(0)); 
    _;
  }
  modifier canTransfer(uint256 _tokenId) {
    require(msg.sender == captainTokenIdToOwner[_tokenId] || msg.sender == captainTokenIdToApprovals[_tokenId]);
    _;
  }
   
  function CreateCaptainToken(address _owner,uint256 _price, uint32 _captainId, uint32 _color,uint32 _atk,uint32 _defense,uint32 _level,uint256 _exp) public onlyAccess {
    _createCaptainToken(_owner,_price,_captainId,_color,_atk,_defense,_level,_exp);
  }

   
  function _createCaptainToken(address _owner, uint256 _price, uint32 _captainId, uint32 _color, uint32 _atk, uint32 _defense,uint32 _level,uint256 _exp) 
  internal {
    uint256 newTokenId = captains.length;
    Captain memory _captain = Captain({
      captainId: _captainId,
      color: _color,
      atk: _atk,
      defense: _defense,
      level: _level,
      exp: _exp 
    });
    captains.push(_captain);
     
    CreateCaptain(newTokenId, _captainId, _owner, _price);
    captainTokenIdToPrice[newTokenId] = _price;
    IndexToCaptain[newTokenId] = _captainId;
    tokenCountOfCaptain[_captainId] = SafeMath.add(tokenCountOfCaptain[_captainId],1);
     
     
    _transfer(address(0), _owner, newTokenId);
  } 
   
  function setTokenPrice(uint256 _tokenId, uint256 _price) external onlyAccess {
    captainTokenIdToPrice[_tokenId] = _price;
  }

   
  function setTokenPriceByOwner(uint256 _tokenId, uint256 _price) external {
    require(captainTokenIdToOwner[_tokenId] == msg.sender);
    captainTokenIdToPrice[_tokenId] = _price;
  }

   
  function setSelled(uint256 _tokenId, bool fsell) external onlyAccess {
    tokenToSell[_tokenId] = fsell;
  }

  function getSelled(uint256 _tokenId) external view returns (bool) {
    return tokenToSell[_tokenId];
  }

   
   
   
   
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    if (_from != address(0)) {
      uint256 indexFrom = captainIdToOwnerIndex[_tokenId];   
      uint256[] storage cpArray = ownerToCaptainArray[_from];
      require(cpArray[indexFrom] == _tokenId);

       
      if (indexFrom != cpArray.length - 1) {
        uint256 lastTokenId = cpArray[cpArray.length - 1];
        cpArray[indexFrom] = lastTokenId; 
        captainIdToOwnerIndex[lastTokenId] = indexFrom;
      }
      cpArray.length -= 1; 
    
      if (captainTokenIdToApprovals[_tokenId] != address(0)) {
        delete captainTokenIdToApprovals[_tokenId];
      }      
    }

     
    captainTokenIdToOwner[_tokenId] = _to;
    ownerToCaptainArray[_to].push(_tokenId);
    captainIdToOwnerIndex[_tokenId] = ownerToCaptainArray[_to].length - 1;
        
    Transfer(_from != address(0) ? _from : this, _to, _tokenId);
  }


   
   
  function getCaptainInfo(uint256 _tokenId) external view returns (
    uint32 captainId,  
    uint32 color, 
    uint32 atk,
    uint32 defense,
    uint32 level,
    uint256 exp, 
    uint256 price,
    address owner,
    bool selled
  ) {
    Captain storage captain = captains[_tokenId];
    captainId = captain.captainId;
    color = captain.color;
    atk = captain.atk;
    defense = captain.defense;
    level = captain.level;
    exp = captain.exp;
    price = captainTokenIdToPrice[_tokenId];
    owner = captainTokenIdToOwner[_tokenId];
    selled = tokenToSell[_tokenId];
  }

   
  function LevelUp(uint256 _tokenId,uint32 _level) external payable {
    require(msg.sender == captainTokenIdToOwner[_tokenId]);
    Captain storage captain = captains[_tokenId];
    uint32 captainId = captain.captainId;
    uint32 level = captain.level;
    uint256 cur_exp = SafeMath.mul(SafeMath.mul(level,SafeMath.sub(level,1)),25);  
    uint256 req_exp = SafeMath.mul(SafeMath.mul(_level,SafeMath.sub(_level,1)),25);
    require(captain.exp>=SafeMath.sub(req_exp,cur_exp));
    uint256 exp = SafeMath.sub(captain.exp,SafeMath.sub(req_exp,cur_exp));
    if (SafeMath.add32(level,_level)>=99) {
      captains[_tokenId].level = 99;
    } else {
      captains[_tokenId].level = _level;
    }

    (captains[_tokenId].atk,captains[_tokenId].defense,,) = config.getLevelConfig(captainId,captains[_tokenId].level);
    captains[_tokenId].exp = exp;
     
    LevelUP(msg.sender,level,captain.level);
  }

   

  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0));
    return ownerToCaptainArray[_owner].length;
  }

  function ownerOf(uint256 _tokenId) external view returns (address) {
    return captainTokenIdToOwner[_tokenId];
  }
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable {
    _safeTransferFrom(_from, _to, _tokenId, data);
  }
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
    internal
    isValidToken(_tokenId) 
    canTransfer(_tokenId)
    {
    address owner = captainTokenIdToOwner[_tokenId];
    require(owner != address(0) && owner == _from);
    require(_to != address(0));
        
    _transfer(_from, _to, _tokenId);

     
     
    bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, data);
     
    require(retval == 0xf0b9e5ba);
  }
    
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        whenNotPaused
        isValidToken(_tokenId)
        canTransfer(_tokenId)
        payable
    {
    address owner = captainTokenIdToOwner[_tokenId];
    require(owner != address(0));
    require(owner == _from);
    require(_to != address(0));
        
    _transfer(_from, _to, _tokenId);
  }

   
  function safeTransferByContract(address _from,address _to, uint256 _tokenId) 
  external
  whenNotPaused
  {
    require(actionContracts[msg.sender]);

    require(_tokenId >= 1 && _tokenId <= captains.length);
    address owner = captainTokenIdToOwner[_tokenId];
    require(owner != address(0));
    require(_to != address(0));
    require(owner != _to);
    require(_from == owner);

    _transfer(owner, _to, _tokenId);
  }

   
   
   
  function approve(address _approved, uint256 _tokenId)
    external
    whenNotPaused 
    payable
  {
    address owner = captainTokenIdToOwner[_tokenId];
    require(owner != address(0));
    require(msg.sender == owner || operatorToApprovals[owner][msg.sender]);

    captainTokenIdToApprovals[_tokenId] = _approved;
    Approval(owner, _approved, _tokenId);
  }

   
   
   
  function setApprovalForAll(address _operator, bool _approved) 
    external 
    whenNotPaused
  {
    operatorToApprovals[msg.sender][_operator] = _approved;
    ApprovalForAll(msg.sender, _operator, _approved);
  }

   
   
   
  function getApproved(uint256 _tokenId) external view isValidToken(_tokenId) returns (address) {
    return captainTokenIdToApprovals[_tokenId];
  }
  
   
   
   
   
  function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
    return operatorToApprovals[_owner][_operator];
  }
   
  function name() public pure returns(string) {
    return "Pirate Conquest Token";
  }
   
  function symbol() public pure returns(string) {
    return "PCT";
  }
   
   
   
   
   

   
   
   
  function totalSupply() external view returns (uint256) {
    return captains.length - destroyCaptainCount -1;
  }
   
   
   
   
   
  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index<(captains.length - destroyCaptainCount));
     
    return _index;
  }
   
   
   
   
   
   
   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
    require(_index < ownerToCaptainArray[_owner].length);
    if (_owner != address(0)) {
      uint256 tokenId = ownerToCaptainArray[_owner][_index];
      return tokenId;
    }
  }

   
   
   
   
   
  function tokensOfOwner(address _owner) external view returns (uint256[],uint32[]) {
    uint256 len = ownerToCaptainArray[_owner].length;
    uint256[] memory tokens = new uint256[](len);
    uint32[] memory captainss = new uint32[](len);
    uint256 icount;
    if (_owner != address(0)) {
      for (uint256 i=0;i<len;i++) {
        tokens[i] = ownerToCaptainArray[_owner][icount];
        captainss[i] = IndexToCaptain[ownerToCaptainArray[_owner][icount]];
        icount++;
      }
    }
    return (tokens,captainss);
  }

   
   
   
   
   
  function tokensOfCaptain(uint32 _captainId) public view returns(uint256[] captainTokens) {
    uint256 tokenCount = tokenCountOfCaptain[_captainId];
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalcaptains = captains.length - destroyCaptainCount - 1;
      uint256 resultIndex = 0;

      uint256 tokenId;
      for (tokenId = 0; tokenId <= totalcaptains; tokenId++) {
        if (IndexToCaptain[tokenId] == _captainId) {
          result[resultIndex] = tokenId;
          resultIndex++;
        }
      }
      return result;
    }
  } 
}