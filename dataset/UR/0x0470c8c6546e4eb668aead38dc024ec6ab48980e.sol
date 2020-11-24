 

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


contract PokemonPow is ERC721 {

  address cryptoVideoGames = 0xdEc14D8f4DA25108Fd0d32Bf2DeCD9538564D069; 
  address cryptoVideoGameItems = 0xD2606C9bC5EFE092A8925e7d6Ae2F63a84c5FDEa;

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "CryptoKotakuPokemonPow";  
  string public constant SYMBOL = "PokemonPow";  

  uint256 private startingPrice = 0.005 ether;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.5 ether;

   

   
   
  mapping (uint256 => address) public powIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public powIndexToApproved;

   
  mapping (uint256 => uint256) private powIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

   
  struct Pow {
    string name;
    uint gameId;
    uint gameItemId1;
    uint gameItemId2;
  }

  Pow[] private pows;

   
   
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

   
  function PokemonPow() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    powIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createPromoPow(address _owner, string _name, uint256 _price, uint _gameId, uint _gameItemId1, uint _gameItemId2) public onlyCOO {

    address powOwner = _owner;
    if (powOwner == address(0)) {
      powOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createPow(_name, powOwner, _price, _gameId, _gameItemId1, _gameItemId2);
  }

   
  function createContractPow(string _name, uint _gameId, uint _gameItemId1, uint _gameItemId2) public onlyCOO {
    _createPow(_name, address(this), startingPrice, _gameId, _gameItemId1, _gameItemId2);
  }

   
   
  function getPow(uint256 _tokenId) public view returns (
    uint256 Id,
    string powName,
    uint256 sellingPrice,
    address owner,
    uint gameId,
    uint gameItemId1,
    uint gameItemId2
  ) {
    Pow storage pow = pows[_tokenId];
    Id = _tokenId;
    powName = pow.name;
    sellingPrice = powIndexToPrice[_tokenId];
    owner = powIndexToOwner[_tokenId];
    gameId = pow.gameId;
    gameItemId1 = pow.gameItemId1;
    gameItemId2 = pow.gameItemId2;
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
    owner = powIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = powIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = powIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 gameOwnerPayment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 5), 100));
    uint256 gameItemOwnerPayment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 5), 100));
    uint256 payment =  sellingPrice - gameOwnerPayment - gameOwnerPayment - gameItemOwnerPayment - gameItemOwnerPayment;
    uint256 purchaseExcess = SafeMath.sub(msg.value,sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      powIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 100);
    } else if (sellingPrice < secondStepLimit) {
       
      powIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 180), 100);
    } else {
       
      powIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 100);
    }

    _transfer(oldOwner, newOwner, _tokenId);
    TokenSold(_tokenId, sellingPrice, powIndexToPrice[_tokenId], oldOwner, newOwner, pows[_tokenId].name);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }
    
    msg.sender.transfer(purchaseExcess);
    _transferDivs(gameOwnerPayment, gameItemOwnerPayment, _tokenId);
    
  }

   
  function _transferDivs(uint256 _gameOwnerPayment, uint256 _gameItemOwnerPayment, uint256 _tokenId) private {
    CryptoVideoGames gamesContract = CryptoVideoGames(cryptoVideoGames);
    CryptoVideoGameItem gameItemContract = CryptoVideoGameItem(cryptoVideoGameItems);
    address gameOwner = gamesContract.getVideoGameOwner(pows[_tokenId].gameId);
    address gameItem1Owner = gameItemContract.getVideoGameItemOwner(pows[_tokenId].gameItemId1);
    address gameItem2Owner = gameItemContract.getVideoGameItemOwner(pows[_tokenId].gameItemId2);
    gameOwner.transfer(_gameOwnerPayment);
    gameItem1Owner.transfer(_gameItemOwnerPayment);
    gameItem2Owner.transfer(_gameItemOwnerPayment);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return powIndexToPrice[_tokenId];
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
    address oldOwner = powIndexToOwner[_tokenId];

     
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
      uint256 totalPows = totalSupply();
      uint256 resultIndex = 0;

      uint256 powId;
      for (powId = 0; powId <= totalPows; powId++) {
        if (powIndexToOwner[powId] == _owner) {
          result[resultIndex] = powId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return pows.length;
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
    return powIndexToApproved[_tokenId] == _to;
  }

   
  function _createPow(string _name, address _owner, uint256 _price, uint _gameId, uint _gameItemId1, uint _gameItemId2) private {
    Pow memory _pow = Pow({
      name: _name,
      gameId: _gameId,
      gameItemId1: _gameItemId1,
      gameItemId2: _gameItemId2
    });
    uint256 newPowId = pows.push(_pow) - 1;

     
     
    require(newPowId == uint256(uint32(newPowId)));

    Birth(newPowId, _name, _owner);

    powIndexToPrice[newPowId] = _price;

     
     
    _transfer(address(0), _owner, newPowId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == powIndexToOwner[_tokenId];
  }

   
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

   
  function modifyPowPrice(uint _powId, uint256 _newPrice) public {
      require(_newPrice > 0);
      require(powIndexToOwner[_powId] == msg.sender);
      powIndexToPrice[_powId] = _newPrice;
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to]++;
     
    powIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete powIndexToApproved[_tokenId];
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


contract CryptoVideoGameItem {
  function getVideoGameItemOwner(uint _videoGameItemId) public view returns(address) {
    }
}