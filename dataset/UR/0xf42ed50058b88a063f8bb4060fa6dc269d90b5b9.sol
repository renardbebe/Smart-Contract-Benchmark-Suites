 

pragma solidity 0.4.24;

 
interface ERC721Receiver {
   
   

   
  function onERC721Received(
    address _operator,
    address _from,
    uint _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
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

contract MyCryptoChampCore{
    struct Champ {
        uint id;
        uint attackPower;
        uint defencePower;
        uint cooldownTime; 
        uint readyTime;
        uint winCount;
        uint lossCount;
        uint position; 
        uint price; 
        uint withdrawCooldown; 
        uint eq_sword; 
        uint eq_shield; 
        uint eq_helmet; 
        bool forSale; 
    }
    
    struct AddressInfo {
        uint withdrawal;
        uint champsCount;
        uint itemsCount;
        string name;
    }

    struct Item {
        uint id;
        uint8 itemType; 
        uint8 itemRarity; 
        uint attackPower;
        uint defencePower;
        uint cooldownReduction;
        uint price;
        uint onChampId; 
        bool onChamp; 
        bool forSale;
    }
    
    Champ[] public champs;
    Item[] public items;
    mapping (uint => uint) public leaderboard;
    mapping (address => AddressInfo) public addressInfo;
    mapping (bool => mapping(address => mapping (address => bool))) public tokenOperatorApprovals;
    mapping (bool => mapping(uint => address)) public tokenApprovals;
    mapping (bool => mapping(uint => address)) public tokenToOwner;
    mapping (uint => string) public champToName;
    mapping (bool => uint) public tokensForSaleCount;
    uint public pendingWithdrawal = 0;

    function addWithdrawal(address _address, uint _amount) public;
    function clearTokenApproval(address _from, uint _tokenId, bool _isTokenChamp) public;
    function setChampsName(uint _champId, string _name) public;
    function setLeaderboard(uint _x, uint _value) public;
    function setTokenApproval(uint _id, address _to, bool _isTokenChamp) public;
    function setTokenOperatorApprovals(address _from, address _to, bool _approved, bool _isTokenChamp) public;
    function setTokenToOwner(uint _id, address _owner, bool _isTokenChamp) public;
    function setTokensForSaleCount(uint _value, bool _isTokenChamp) public;
    function transferToken(address _from, address _to, uint _id, bool _isTokenChamp) public;
    function newChamp(uint _attackPower,uint _defencePower,uint _cooldownTime,uint _winCount,uint _lossCount,uint _position,uint _price,uint _eq_sword, uint _eq_shield, uint _eq_helmet, bool _forSale,address _owner) public returns (uint);
    function newItem(uint8 _itemType,uint8 _itemRarity,uint _attackPower,uint _defencePower,uint _cooldownReduction,uint _price,uint _onChampId,bool _onChamp,bool _forSale,address _owner) public returns (uint);
    function updateAddressInfo(address _address, uint _withdrawal, bool _updatePendingWithdrawal, uint _champsCount, bool _updateChampsCount, uint _itemsCount, bool _updateItemsCount, string _name, bool _updateName) public;
    function updateChamp(uint _champId, uint _attackPower,uint _defencePower,uint _cooldownTime,uint _readyTime,uint _winCount,uint _lossCount,uint _position,uint _price,uint _withdrawCooldown,uint _eq_sword, uint _eq_shield, uint _eq_helmet, bool _forSale) public;
    function updateItem(uint _id,uint8 _itemType,uint8 _itemRarity,uint _attackPower,uint _defencePower,uint _cooldownReduction,uint _price,uint _onChampId,bool _onChamp,bool _forSale) public;

    function getChampStats(uint256 _champId) public view returns(uint256,uint256,uint256);
    function getChampsByOwner(address _owner) external view returns(uint256[]);
    function getTokensForSale(bool _isTokenChamp) view external returns(uint256[]);
    function getItemsByOwner(address _owner) external view returns(uint256[]);
    function getTokenCount(bool _isTokenChamp) external view returns(uint);
    function getTokenURIs(uint _tokenId, bool _isTokenChamp) public view returns(string);
    function onlyApprovedOrOwnerOfToken(uint _id, address _msgsender, bool _isTokenChamp) external view returns(bool);
    
}

 
contract Ownable {
  address internal contractOwner;

  constructor () internal {
    if(contractOwner == address(0)){
      contractOwner = msg.sender;
    }
  }

   
  modifier onlyOwner() {
    require(msg.sender == contractOwner);
    _;
  }
  

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    contractOwner = newOwner;
  }

}

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}


contract ERC721 is Ownable, SupportsInterfaceWithLookup {

  using AddressUtils for address;

  string private _ERC721name = "Champ";
  string private _ERC721symbol = "MXC";
  bool private tokenIsChamp = true;
  address private controllerAddress;
  MyCryptoChampCore core;

  function setCore(address newCoreAddress) public onlyOwner {
    core = MyCryptoChampCore(newCoreAddress);
  }

  function setController(address _address) external onlyOwner {
    controllerAddress = _address;
  }

  function emitTransfer(address _from, address _to, uint _tokenId) external {
    require(msg.sender == controllerAddress);
    emit Transfer(_from, _to, _tokenId);
  }

   
  event Transfer(address indexed _from, address indexed _to, uint indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
   

    
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;
  
  bytes4 constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }


   
  modifier onlyOwnerOf(uint _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier canTransfer(uint _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
}

   
  function balanceOf(address _owner) public view returns (uint) {
    require(_owner != address(0));
    uint balance;
    if(tokenIsChamp){
      (,balance,,) = core.addressInfo(_owner);
    }else{
      (,,balance,) = core.addressInfo(_owner);
    }
    return balance;
}

   
function ownerOf(uint _tokenId) public view returns (address) {
    address owner = core.tokenToOwner(tokenIsChamp,_tokenId);
    require(owner != address(0));
    return owner;
}


 
function exists(uint _tokenId) public view returns (bool) {
    address owner = core.tokenToOwner(tokenIsChamp,_tokenId);
    return owner != address(0);
}

 
function approve(address _to, uint _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    core.setTokenApproval(_tokenId, _to,tokenIsChamp);
    emit Approval(owner, _to, _tokenId);
 }

 
  function getApproved(uint _tokenId) public view returns (address) {
    return core.tokenApprovals(tokenIsChamp,_tokenId);
  }

 
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    core.setTokenOperatorApprovals(msg.sender,_to,_approved,tokenIsChamp);
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
    return core.tokenOperatorApprovals(tokenIsChamp, _owner,_operator);
}

 
function isApprovedOrOwner(
    address _spender,
    uint _tokenId
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

 
function transferFrom(
    address _from,
    address _to,
    uint _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    require(_from != address(0));
    require(_to != address(0));

    core.clearTokenApproval(_from, _tokenId, tokenIsChamp);
    core.transferToken(_from, _to, _tokenId, tokenIsChamp);

    emit Transfer(_from, _to, _tokenId);
}

 
function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId
  )
    public
    canTransfer(_tokenId)
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
}

   
function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
}

 
function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint _tokenId,
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

   
   
   
   
   
   
  function totalSupply() external view returns (uint){
    return core.getTokenCount(tokenIsChamp);
  }

   
   
   
   
   
  function tokenByIndex(uint _index) external view returns (uint){
    uint tokenIndexesLength = this.totalSupply();
    require(_index < tokenIndexesLength);
    return _index;
  }

  
   
   
   
   
   
   
   
  function tokenOfOwnerByIndex(address _owner, uint _index) external view returns (uint){
      require(_index >= balanceOf(_owner));
      require(_owner!=address(0));
      
      uint[] memory tokens;
      uint tokenId;
      
      if(tokenIsChamp){
          tokens = core.getChampsByOwner(_owner);
      }else{
          tokens = core.getItemsByOwner(_owner);
      }
      
      for(uint i = 0; i < tokens.length; i++){
          if(i + 1 == _index){
              tokenId = tokens[i];
              break;
          }
      }
      
      return tokenId;
  }
  
  
   
   
   
   
  function name() external view returns (string _name){
    return _ERC721name;
  }

   
  function symbol() external view returns (string _symbol){
    return _ERC721symbol;
  }

   
   
   
   
  function tokenURI(uint _tokenId) external view returns (string){
    require(exists(_tokenId));
    return core.getTokenURIs(_tokenId,tokenIsChamp);
  }

}