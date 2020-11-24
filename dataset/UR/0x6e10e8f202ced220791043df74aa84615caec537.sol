 

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


contract KittyToken is AccessAdmin, ERC721 {
  using SafeMath for SafeMath;
   
  event CreateGift(uint tokenId,uint32 cardId, address _owner, uint256 _price);
   
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  struct Kitty {
    uint32 kittyId;
  }

  Kitty[] public kitties;  
  function KittyToken() public {
    kitties.length += 1;
    setAdminContract(msg.sender,true);
    setActionContract(msg.sender,true);
  }

   
   
  mapping (uint256 => address) public TokenIdToOwner;
   
  mapping (uint256 => uint256) kittyIdToOwnerIndex;  
   
  mapping (address => uint256[]) ownerTokittyArray;
   
  mapping (uint256 => uint256) TokenIdToPrice;
   
  mapping (uint32 => uint256) tokenCountOfkitty;
   
  mapping (uint256 => uint32) IndexTokitty;
   
  mapping (uint256 => address) kittyTokenIdToApprovals;
   
  mapping (address => mapping (address => bool)) operatorToApprovals;
  mapping(uint256 => bool) tokenToSell;
  

   
   
  uint256 destroyKittyCount;
  uint256 onAuction;
   
   
  modifier isValidToken(uint256 _tokenId) {
    require(_tokenId >= 1 && _tokenId <= kitties.length);
    require(TokenIdToOwner[_tokenId] != address(0)); 
    _;
  }
  modifier canTransfer(uint256 _tokenId) {
    require(msg.sender == TokenIdToOwner[_tokenId]);
    _;
  }
   
  function CreateKittyToken(address _owner,uint256 _price, uint32 _cardId) public onlyAccess {
    _createKittyToken(_owner,_price,_cardId);
  }

     
  function _createKittyToken(address _owner, uint256 _price, uint32 _kittyId) 
  internal {
    uint256 newTokenId = kitties.length;
    Kitty memory _kitty = Kitty({
      kittyId: _kittyId
    });
    kitties.push(_kitty);
     
    CreateGift(newTokenId, _kittyId, _owner, _price);
    TokenIdToPrice[newTokenId] = _price;
    IndexTokitty[newTokenId] = _kittyId;
    tokenCountOfkitty[_kittyId] = SafeMath.add(tokenCountOfkitty[_kittyId],1);
     
     
    _transfer(address(0), _owner, newTokenId);
  } 
   
  function setTokenPriceByOwner(uint256 _tokenId, uint256 _price) external {
    require(TokenIdToOwner[_tokenId] == msg.sender);
    TokenIdToPrice[_tokenId] = _price;
  }

     
  function setTokenPrice(uint256 _tokenId, uint256 _price) external onlyAccess {
    TokenIdToPrice[_tokenId] = _price;
  }

   
   
  function getKittyInfo(uint256 _tokenId) external view returns (
    uint32 kittyId,  
    uint256 price,
    address owner,
    bool selled
  ) {
    Kitty storage kitty = kitties[_tokenId];
    kittyId = kitty.kittyId;
    price = TokenIdToPrice[_tokenId];
    owner = TokenIdToOwner[_tokenId];
    selled = tokenToSell[_tokenId];
  }
   
   
   
   
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    if (_from != address(0)) {
      uint256 indexFrom = kittyIdToOwnerIndex[_tokenId];   
      uint256[] storage cpArray = ownerTokittyArray[_from];
      require(cpArray[indexFrom] == _tokenId);

       
      if (indexFrom != cpArray.length - 1) {
        uint256 lastTokenId = cpArray[cpArray.length - 1];
        cpArray[indexFrom] = lastTokenId; 
        kittyIdToOwnerIndex[lastTokenId] = indexFrom;
      }
      cpArray.length -= 1; 
    
      if (kittyTokenIdToApprovals[_tokenId] != address(0)) {
        delete kittyTokenIdToApprovals[_tokenId];
      }      
    }

     
    TokenIdToOwner[_tokenId] = _to;
    ownerTokittyArray[_to].push(_tokenId);
    kittyIdToOwnerIndex[_tokenId] = ownerTokittyArray[_to].length - 1;
        
    Transfer(_from != address(0) ? _from : this, _to, _tokenId);
  }

   
  function getAuctions() external view returns (uint256[]) {
    uint256 totalgifts = kitties.length - destroyKittyCount - 1;

    uint256[] memory result = new uint256[](onAuction);
    uint256 tokenId = 1;
    for (uint i=0;i< totalgifts;i++) {
      if (tokenToSell[tokenId] == true) {
        result[i] = tokenId;
        tokenId ++;
      }
    }
    return result;
  }
   

  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0));
    return ownerTokittyArray[_owner].length;
  }

  function ownerOf(uint256 _tokenId) external view returns (address) {
    return TokenIdToOwner[_tokenId];
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
    address owner = TokenIdToOwner[_tokenId];
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
    address owner = TokenIdToOwner[_tokenId];
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

    require(_tokenId >= 1 && _tokenId <= kitties.length);
    address owner = TokenIdToOwner[_tokenId];
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
    address owner = TokenIdToOwner[_tokenId];
    require(owner != address(0));
    require(msg.sender == owner || operatorToApprovals[owner][msg.sender]);

    kittyTokenIdToApprovals[_tokenId] = _approved;
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
    return kittyTokenIdToApprovals[_tokenId];
  }
  
   
   
   
   
  function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
    return operatorToApprovals[_owner][_operator];
  }
   
  function name() public pure returns(string) {
    return "Pirate Kitty Token";
  }
   
  function symbol() public pure returns(string) {
    return "KCT";
  }
   
   
   
   
   

   
   
   
  function totalSupply() external view returns (uint256) {
    return kitties.length - destroyKittyCount -1;
  }
   
   
   
   
   
  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index<(kitties.length - destroyKittyCount));
     
    return _index;
  }
   
   
   
   
   
   
   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
    require(_index < ownerTokittyArray[_owner].length);
    if (_owner != address(0)) {
      uint256 tokenId = ownerTokittyArray[_owner][_index];
      return tokenId;
    }
  }

   
   
   
   
   
  function tokensOfOwner(address _owner) external view returns (uint256[],uint32[]) {
    uint256 len = ownerTokittyArray[_owner].length;
    uint256[] memory tokens = new uint256[](len);
    uint32[] memory kittyss = new uint32[](len);
    uint256 icount;
    if (_owner != address(0)) {
      for (uint256 i=0;i<len;i++) {
        tokens[i] = ownerTokittyArray[_owner][icount];
        kittyss[i] = IndexTokitty[ownerTokittyArray[_owner][icount]];
        icount++;
      }
    }
    return (tokens,kittyss);
  }

   
   
   
   
   
  function tokensOfkitty(uint32 _kittyId) public view returns(uint256[] kittyTokens) {
    uint256 tokenCount = tokenCountOfkitty[_kittyId];
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalkitties = kitties.length - destroyKittyCount - 1;
      uint256 resultIndex = 0;

      uint256 tokenId;
      for (tokenId = 0; tokenId <= totalkitties; tokenId++) {
        if (IndexTokitty[tokenId] == _kittyId) {
          result[resultIndex] = tokenId;
          resultIndex++;
        }
      }
      return result;
    }
  } 
}