 

pragma solidity ^0.4.18;  



 
 
contract ERC721 {
   
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   
   
   
   
   
}


contract GameItemNew is ERC721 {

  address cryptoVideoGames = 0xdec14d8f4da25108fd0d32bf2decd9538564d069; 

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "CryptoKotakuGameItemNew";  
  string public constant SYMBOL = "GameItemNew";  

  uint256 private startingPrice = 0.005 ether;

   

   
   
  mapping (uint256 => address) public gameItemIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public gameItemIndexToApproved;

   
  mapping (uint256 => uint256) private gameItemIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

   
  struct GameItem {
    string name;
    uint gameId;
  }

  GameItem[] private gameItems;

   
   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

   
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

   
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress
    );
    _;
  }

   
  function GameItemNew() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    gameItemIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createPromoGameItem(address _owner, string _name, uint256 _price, uint _gameId) public onlyCOO {

    address gameItemOwner = _owner;
    if (gameItemOwner == address(0)) {
      gameItemOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createGameItem(_name, gameItemOwner, _price, _gameId);
  }

   
  function createContractGameItem(string _name, uint _gameId) public onlyCOO {
    _createGameItem(_name, address(this), startingPrice, _gameId);
  }

   
   
  function getGameItem(uint256 _tokenId) public view returns (
    uint256 Id,
    string gameItemName,
    uint256 sellingPrice,
    address owner,
    uint gameId
  ) {
    GameItem storage gameItem = gameItems[_tokenId];
    Id = _tokenId;
    gameItemName = gameItem.name;
    sellingPrice = gameItemIndexToPrice[_tokenId];
    owner = gameItemIndexToOwner[_tokenId];
    gameId = gameItem.gameId;
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

   
  function name() public pure returns (string) {
    return NAME;
  }

   
   
   
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = gameItemIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = gameItemIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = gameItemIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 gameOwnerPayment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 10), 100));
    uint256 devFees = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 6), 100));
    uint256 payment =  sellingPrice - devFees - gameOwnerPayment;
    uint256 purchaseExcess = SafeMath.sub(msg.value,sellingPrice);

   
    gameItemIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 100);
    
    _transfer(oldOwner, newOwner, _tokenId);
    TokenSold(_tokenId, sellingPrice, gameItemIndexToPrice[_tokenId], oldOwner, newOwner, gameItems[_tokenId].name);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
    }
    
    msg.sender.transfer(purchaseExcess);
    _transferDivs(gameOwnerPayment, _tokenId, devFees);
    
  }

   
  function _transferDivs(uint256 _gameOwnerPayment, uint256 _tokenId,uint256 _devFees) private {
    CryptoVideoGames gamesContract = CryptoVideoGames(cryptoVideoGames);
    address gameOwner = gamesContract.getVideoGameOwner(gameItems[_tokenId].gameId);
    gameOwner.transfer(_gameOwnerPayment);
    ceoAddress.transfer(_devFees);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return gameItemIndexToPrice[_tokenId];
  }

   
   
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

   
   
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));

    cooAddress = _newCOO;
  }

   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

   
   
   
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = gameItemIndexToOwner[_tokenId];

     
    require(_addressNotNull(newOwner));

     
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

   
   
   
   
   
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalGameItems = totalSupply();
      uint256 resultIndex = 0;

      uint256 gameItemId;
      for (gameItemId = 0; gameItemId <= totalGameItems; gameItemId++) {
        if (gameItemIndexToOwner[gameItemId] == _owner) {
          result[resultIndex] = gameItemId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return gameItems.length;
  }

   
   
   
   
  function transfer(
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

   
   
   
   
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }

   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return gameItemIndexToApproved[_tokenId] == _to;
  }

   
  function _createGameItem(string _name, address _owner, uint256 _price, uint _gameId) private {
    GameItem memory _gameItem = GameItem({
      name: _name,
      gameId: _gameId
    });
    uint256 newGameItemId = gameItems.push(_gameItem) - 1;

     
     
    require(newGameItemId == uint256(uint32(newGameItemId)));

    Birth(newGameItemId, _name, _owner);

    gameItemIndexToPrice[newGameItemId] = _price;

     
     
    _transfer(address(0), _owner, newGameItemId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == gameItemIndexToOwner[_tokenId];
  }

   
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

   
  function modifyGameItemPrice(uint _gameItemId, uint256 _newPrice) public {
      require(_newPrice > 0);
      require(gameItemIndexToOwner[_gameItemId] == msg.sender);
      gameItemIndexToPrice[_gameItemId] = _newPrice;
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to]++;
     
    gameItemIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete gameItemIndexToApproved[_tokenId];
    }

     
    Transfer(_from, _to, _tokenId);
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


contract CryptoVideoGames {
     
    function getVideoGameOwner(uint _videoGameId) public view returns(address) {
    }
    
}