 

pragma solidity ^0.4.24;


 

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract Superuser is Ownable, RBAC {
  string public constant ROLE_SUPERUSER = "superuser";

  constructor () public {
    addRole(msg.sender, ROLE_SUPERUSER);
  }

   
  modifier onlySuperuser() {
    checkRole(msg.sender, ROLE_SUPERUSER);
    _;
  }

  modifier onlyOwnerOrSuperuser() {
    require(msg.sender == owner || isSuperuser(msg.sender));
    _;
  }

   
  function isSuperuser(address _addr)
    public
    view
    returns (bool)
  {
    return hasRole(_addr, ROLE_SUPERUSER);
  }

   
  function transferSuperuser(address _newSuperuser) public onlySuperuser {
    require(_newSuperuser != address(0));
    removeRole(msg.sender, ROLE_SUPERUSER);
    addRole(_newSuperuser, ROLE_SUPERUSER);
  }

   
  function transferOwnership(address _newOwner) public onlyOwnerOrSuperuser {
    _transferOwnership(_newOwner);
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
library SafeMath {
   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function mul(uint256 a, uint256 b) 
      internal 
      pure 
      returns (uint256 c) 
  {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b, "SafeMath mul failed");
    return c;
  }

   
  function sub(uint256 a, uint256 b)
      internal
      pure
      returns (uint256) 
  {
    require(b <= a, "SafeMath sub failed");
    return a - b;
  }

   
  function add(uint256 a, uint256 b)
      internal
      pure
      returns (uint256 c) 
  {
    c = a + b;
    require(c >= a, "SafeMath add failed");
    return c;
  }
  
   
  function sqrt(uint256 x)
      internal
      pure
      returns (uint256 y) 
  {
    uint256 z = ((add(x,1)) / 2);
    y = x;
    while (z < y) 
    {
      y = z;
      z = ((add((x / z),z)) / 2);
    }
  }
  
   
  function sq(uint256 x)
      internal
      pure
      returns (uint256)
  {
    return (mul(x,x));
  }
  
   
  function pwr(uint256 x, uint256 y)
      internal 
      pure 
      returns (uint256)
  {
    if (x==0)
        return (0);
    else if (y==0)
        return (1);
    else 
    {
      uint256 z = x;
      for (uint256 i=1; i < y; i++)
        z = mul(z,x);
      return (z);
    }
  }
}

 

 

interface INFTsCrowdsale {

  function getAuction(uint256 tokenId) external view
  returns (
    bytes32,
    address,
    uint256,
    uint256,
    uint256,
    uint256
  );

  function isOnAuction(uint256 tokenId) external view returns (bool);

  function isOnPreAuction(uint256 tokenId) external view returns (bool);

  function newAuction(uint128 price, uint256 tokenId, uint256 startAt, uint256 endAt) external;

  function batchNewAuctions(uint128[] prices, uint256[] tokenIds, uint256[] startAts, uint256[] endAts) external;

  function payByEth (uint256 tokenId) external payable; 

  function payByErc20 (uint256 tokenId) external;

  function cancelAuction (uint256 tokenId) external;

  function batchCancelAuctions (uint256[] tokenIds) external;
  
   

  event NewAuction (
    bytes32 id,
    address indexed seller,
    uint256 price,
    uint256 startAt,
    uint256 endAt,
    uint256 indexed tokenId
  );

  event PayByEth (
    bytes32 id,
    address indexed seller,
    address indexed buyer,
    uint256 price,
    uint256 endAt,
    uint256 indexed tokenId
  );

  event PayByErc20 (
    bytes32 id,
    address indexed seller,
    address indexed buyer, 
    uint256 price,
    uint256 endAt,
    uint256 indexed tokenId
  );

  event CancelAuction (
    bytes32 id,
    address indexed seller,
    uint256 indexed tokenId
  );

}

 

contract NFTsCrowdsaleBase is Superuser, INFTsCrowdsale {

  using SafeMath for uint256;

  ERC20 public erc20Contract;
  ERC721 public erc721Contract;
   
  uint public eth2erc20;
   
  struct Auction {
    bytes32 id;  
    address seller;  
    uint256 price;  
    uint256 startAt;  
    uint256 endAt;  
    uint256 tokenId;  
  }

  mapping (uint256 => Auction) tokenIdToAuction;
  
  constructor(address _erc721Address,address _erc20Address, uint _eth2erc20) public {
    erc721Contract = ERC721(_erc721Address);
    erc20Contract = ERC20(_erc20Address);
    eth2erc20 = _eth2erc20;
  }

  function getAuction(uint256 _tokenId) external view
  returns (
    bytes32,
    address,
    uint256,
    uint256,
    uint256,
    uint256
  ){
    Auction storage auction = tokenIdToAuction[_tokenId];
    return (auction.id, auction.seller, auction.price, auction.startAt, auction.endAt, auction.tokenId);
  }

  function isOnAuction(uint256 _tokenId) external view returns (bool) {
    Auction storage _auction = tokenIdToAuction[_tokenId];
    uint256 time = block.timestamp;
    return (time < _auction.endAt && time > _auction.startAt);
  }

  function isOnPreAuction(uint256 _tokenId) external view returns (bool) {
    Auction storage _auction = tokenIdToAuction[_tokenId];
    return (block.timestamp < _auction.startAt);
  }

  function _isTokenOwner(address _seller, uint256 _tokenId) internal view returns (bool){
    return (erc721Contract.ownerOf(_tokenId) == _seller);
  }

  function _isOnAuction(uint256 _tokenId) internal view returns (bool) {
    Auction storage _auction = tokenIdToAuction[_tokenId];
    uint256 time = block.timestamp;
    return (time < _auction.endAt && time > _auction.startAt);
  }
  function _escrow(address _owner, uint256 _tokenId) internal {
    erc721Contract.transferFrom(_owner, this, _tokenId);
  }

  function _cancelEscrow(address _owner, uint256 _tokenId) internal {
    erc721Contract.transferFrom(this, _owner, _tokenId);
  }

  function _transfer(address _receiver, uint256 _tokenId) internal {
    erc721Contract.safeTransferFrom(this, _receiver, _tokenId);
  }

  function _newAuction(uint256 _price, uint256 _tokenId, uint256 _startAt, uint256 _endAt) internal {
    require(_price == uint256(_price));
    address _seller = msg.sender;

    require(_isTokenOwner(_seller, _tokenId));
    _escrow(_seller, _tokenId);

    bytes32 auctionId = keccak256(
      abi.encodePacked(block.timestamp, _seller, _tokenId, _price)
    );
    
    Auction memory _order = Auction(
      auctionId,
      _seller,
      uint128(_price),
      _startAt,
      _endAt,
      _tokenId
    );

    tokenIdToAuction[_tokenId] = _order;
    emit NewAuction(auctionId, _seller, _price, _startAt, _endAt, _tokenId);
  }

  function _cancelAuction(uint256 _tokenId) internal {
    Auction storage _auction = tokenIdToAuction[_tokenId];
    require(_auction.seller == msg.sender || msg.sender == owner);
    emit CancelAuction(_auction.id, _auction.seller, _tokenId);
    _cancelEscrow(_auction.seller, _tokenId);
    delete tokenIdToAuction[_tokenId];
  }

  function _payByEth(uint256 _tokenId) internal {
    uint256 _ethAmount = msg.value;
    Auction storage _auction = tokenIdToAuction[_tokenId];
    uint256 price = _auction.price;
    require(_isOnAuction(_auction.tokenId));
    require(_ethAmount >= price);

    uint256 payExcess = _ethAmount.sub(price);

    if (price > 0) {
      _auction.seller.transfer(price);
    }
    address buyer = msg.sender;
    buyer.transfer(payExcess);
    _transfer(buyer, _tokenId);
    emit PayByEth(_auction.id, _auction.seller, msg.sender, _auction.price, _auction.endAt, _auction.tokenId);
    delete tokenIdToAuction[_tokenId];
  }

  function _payByErc20(uint256 _tokenId) internal {

    Auction storage _auction = tokenIdToAuction[_tokenId];
    uint256 price = uint256(_auction.price);
    uint256 computedErc20Price = price.mul(eth2erc20);
    uint256 balance = erc20Contract.balanceOf(msg.sender);
    require(balance >= computedErc20Price);
    require(_isOnAuction(_auction.tokenId));

    if (price > 0) {
      erc20Contract.transferFrom(msg.sender, _auction.seller, computedErc20Price);
    }
    _transfer(msg.sender, _tokenId);
    emit PayByErc20(_auction.id, _auction.seller, msg.sender, _auction.price, _auction.endAt, _auction.tokenId);
    delete tokenIdToAuction[_tokenId];
  }
  
}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  event Pause2();
  event Unpause2();

  bool public paused = false;
  bool public paused2 = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenNotPaused2() {
    require(!paused2);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

  modifier whenPaused2() {
    require(paused2);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  function pause2() public onlyOwner whenNotPaused2 {
    paused2 = true;
    emit Pause2();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }

  function unpause2() public onlyOwner whenPaused2 {
    paused2 = false;
    emit Unpause2();
  }
}

 

contract NFTsCrowdsale is NFTsCrowdsaleBase, Pausable {

  constructor(address erc721Address, address erc20Address, uint eth2erc20) public 
  NFTsCrowdsaleBase(erc721Address, erc20Address, eth2erc20){}

   
  function newAuction(uint128 price, uint256 tokenId, uint256 startAt, uint256 endAt) whenNotPaused external {
    uint256 _startAt = startAt;
    if (msg.sender != owner) {
      _startAt = block.timestamp;
    }
    _newAuction(price, tokenId, _startAt, endAt);
  }

   
  function batchNewAuctions(uint128[] prices, uint256[] tokenIds, uint256[] startAts, uint256[] endAts) whenNotPaused external {
    uint256 i = 0;
    while (i < tokenIds.length) {
      _newAuction(prices[i], tokenIds[i], startAts[i], endAts[i]);
      i += 1;
    }
  }

   
  function payByEth (uint256 tokenId) whenNotPaused external payable {
    _payByEth(tokenId); 
  }

   
  function payByErc20 (uint256 tokenId) whenNotPaused2 external {
    _payByErc20(tokenId);
  }

   
  function cancelAuction (uint256 tokenId) external {
    _cancelAuction(tokenId);
  }

   
  function batchCancelAuctions (uint256[] tokenIds) external {
    uint256 i = 0;
    while (i < tokenIds.length) {
      _cancelAuction(tokenIds[i]);
      i += 1;
    }
  }
}