 

pragma solidity ^0.4.23;


 
contract ERC721 {
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  function implementsERC721() public pure returns (bool);
  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) external view returns (address owner);
  function approve(address _to, uint256 _tokenId) external;
  function transfer(address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
}


 
interface CurioAuction {
  function isCurioAuction() external returns (bool);
  function withdrawBalance() external;
  function setAuctionPriceLimit(uint256 _newAuctionPriceLimit) external;
  function createAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  )
    external;
}


 
contract Curio is ERC721 {
  event Create(
    address indexed owner,
    uint256 indexed tokenId,
    string name
  );
  event ContractUpgrade(address newContract);

  struct Token {
    string name;
  }

   
  string public constant NAME = "Curio";
  string public constant SYMBOL = "CUR";

   
  Token[] tokens;

   
  mapping (uint256 => address) public tokenIndexToOwner;

   
  mapping (address => uint256) ownershipTokenCount;

   
  mapping (uint256 => address) public tokenIndexToApproved;

  address public ownerAddress;
  address public adminAddress;

  bool public paused = false;

   
  address public newContractAddress;

   
  CurioAuction public auction;

   
  uint256 public constant TOTAL_SUPPLY_LIMIT = 900;

   
  uint256 public releaseCreatedCount;

   
  modifier onlyOwner() {
    require(msg.sender == ownerAddress);
    _;
  }

   
  modifier onlyAdmin() {
    require(msg.sender == adminAddress);
    _;
  }

   
  modifier onlyOwnerOrAdmin() {
    require(
      msg.sender == adminAddress ||
      msg.sender == ownerAddress
    );
    _;
  }

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  constructor() public {
     
    paused = true;

     
    ownerAddress = msg.sender;
    adminAddress = msg.sender;
  }


   
   
   


   
  function implementsERC721() public pure returns (bool) {
    return true;
  }

   
  function() external payable {
    require(msg.sender == address(auction));
  }

   
  function withdrawBalance() external onlyOwner {
    ownerAddress.transfer(address(this).balance);
  }

   
  function totalSupply() public view returns (uint) {
    return tokens.length;
  }

   
  function balanceOf(address _owner) public view returns (uint256 count) {
    return ownershipTokenCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) external view returns (address owner) {
    owner = tokenIndexToOwner[_tokenId];

    require(owner != address(0));
  }

   
  function getToken(uint256 _id) external view returns (string name) {
    Token storage token = tokens[_id];

    name = token.name;
  }

   
  function setOwner(address _newOwner) onlyOwner external {
    require(_newOwner != address(0));

    ownerAddress = _newOwner;
  }

   
  function setAdmin(address _newAdmin) onlyOwner external {
    require(_newAdmin != address(0));

    adminAddress = _newAdmin;
  }

   
  function setAuctionPriceLimit(uint256 _newAuctionPriceLimit) onlyOwnerOrAdmin external {
    auction.setAuctionPriceLimit(_newAuctionPriceLimit);
  }

   
  function setNewAddress(address _newContract) onlyOwner whenPaused external {
    newContractAddress = _newContract;

    emit ContractUpgrade(_newContract);
  }

   
  function pause() onlyOwnerOrAdmin whenNotPaused external {
    paused = true;
  }

   
  function unpause() onlyOwner whenPaused public {
    require(auction != address(0));
    require(newContractAddress == address(0));

    paused = false;
  }

   
  function transfer(
    address _to,
    uint256 _tokenId
  )
    whenNotPaused
    external
  {
     
    require(_to != address(0));

     
     
     
    require(_to != address(this));

     
     
     
    require(_to != address(auction));

     
    require(_owns(msg.sender, _tokenId));

     
    _transfer(msg.sender, _to, _tokenId);
  }

   
  function approve(
    address _to,
    uint256 _tokenId
  )
    whenNotPaused
    external
  {
     
    require(_owns(msg.sender, _tokenId));

     
    _approve(_tokenId, _to);

     
    emit Approval(msg.sender, _to, _tokenId);
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    whenNotPaused
    external
  {
     
    require(_to != address(0));

     
     
     
    require(_to != address(this));

     
    require(_approvedFor(msg.sender, _tokenId));
    require(_owns(_from, _tokenId));

     
    _transfer(_from, _to, _tokenId);
  }

   
  function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
       
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalTokens = totalSupply();
      uint256 resultIndex = 0;

      uint256 tokenId;

      for (tokenId = 0; tokenId <= totalTokens; tokenId++) {
        if (tokenIndexToOwner[tokenId] == _owner) {
          result[resultIndex] = tokenId;
          resultIndex++;
        }
      }

      return result;
    }
  }

   
  function setAuctionAddress(address _address) onlyOwner external {
    CurioAuction candidateContract = CurioAuction(_address);

    require(candidateContract.isCurioAuction());

     
    auction = candidateContract;
  }

   
  function createAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration
  )
    whenNotPaused
    external
  {
     
     
    require(_owns(msg.sender, _tokenId));

     
    _approve(_tokenId, auction);

     
    auction.createAuction(
      _tokenId,
      _startingPrice,
      _endingPrice,
      _duration,
      msg.sender
    );
  }

   
  function withdrawAuctionBalance() onlyOwnerOrAdmin external {
    auction.withdrawBalance();
  }

   
  function createReleaseTokenAuction(
    string _name,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration
  )
    onlyAdmin
    external
  {
     
    require(releaseCreatedCount < TOTAL_SUPPLY_LIMIT);

     
    uint256 tokenId = _createToken(_name, address(this));

     
    _approve(tokenId, auction);

     
    auction.createAuction(
      tokenId,
      _startingPrice,
      _endingPrice,
      _duration,
      address(this)
    );

    releaseCreatedCount++;
  }

   
  function createFreeToken(
    string _name,
    address _to
  )
    onlyAdmin
    external
  {
    require(_to != address(0));
    require(_to != address(this));
    require(_to != address(auction));

     
    require(releaseCreatedCount < TOTAL_SUPPLY_LIMIT);

     
    _createToken(_name, _to);

    releaseCreatedCount++;
  }


   
   
   


   
  function _createToken(
    string _name,
    address _owner
  )
    internal
    returns (uint)
  {
    Token memory _token = Token({
      name: _name
    });

    uint256 newTokenId = tokens.push(_token) - 1;

     
    require(newTokenId == uint256(uint32(newTokenId)));

    emit Create(_owner, newTokenId, _name);

     
    _transfer(0, _owner, newTokenId);

    return newTokenId;
  }

   
  function _owns(
    address _claimant,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    return tokenIndexToOwner[_tokenId] == _claimant;
  }

   
  function _approvedFor(
    address _claimant,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    return tokenIndexToApproved[_tokenId] == _claimant;
  }

   
  function _approve(
    uint256 _tokenId,
    address _approved
  )
    internal
  {
    tokenIndexToApproved[_tokenId] = _approved;
  }

   
  function _transfer(
    address _from,
    address _to,
    uint256 _tokenId
  )
    internal
  {
    ownershipTokenCount[_to]++;

     
    tokenIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;

       
      delete tokenIndexToApproved[_tokenId];
    }

    emit Transfer(_from, _to, _tokenId);
  }
}