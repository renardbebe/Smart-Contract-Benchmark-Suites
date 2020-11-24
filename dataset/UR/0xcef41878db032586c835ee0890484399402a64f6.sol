 

pragma solidity ^0.4.24;

 

 
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

 

 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

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

   
  mapping(uint256 => string) internal tokenURIs;

   
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

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
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

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
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

     
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

     
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

contract MarketInerface {
    function buyBlocks(address, uint16[]) external returns (uint) {}
    function sellBlocks(address, uint, uint16[]) external returns (uint) {}
    function isMarket() public view returns (bool) {}
    function isOnSale(uint16) public view returns (bool) {}
    function areaPrice(uint16[]) public view returns (uint) {}
    function importOldMEBlock(uint8, uint8) external returns (uint, address) {}
}

contract RentalsInterface {
    function rentOutBlocks(address, uint, uint16[]) external returns (uint) {}
    function rentBlocks(address, uint, uint16[]) external returns (uint) {}
    function blocksRentPrice(uint, uint16[]) external view returns (uint) {}
    function isRentals() public view returns (bool) {}
    function isRented(uint16) public view returns (bool) {}
    function renterOf(uint16) public view returns (address) {}
}

contract AdsInterface {
    function advertiseOnBlocks(address, uint16[], string, string, string) external returns (uint) {}
    function canAdvertiseOnBlocks(address, uint16[]) public view returns (bool) {}
    function isAds() public view returns (bool) {}
}

 
 
contract MEHAccessControl is Pausable {

     
    bool public isMEH = true;

     
    MarketInerface public market;
    RentalsInterface public rentals;
    AdsInterface public ads;

     
    event LogModuleUpgrade(address newAddress, string moduleName);
    
 
    
     
    modifier onlyMarket() {
        require(msg.sender == address(market));
        _;
    }

     
     
    modifier onlyBalanceOperators() {
        require(msg.sender == address(market) || msg.sender == address(rentals));
        _;
    }

 
     
     
     
    function adminSetMarket(address _address) external onlyOwner {
        MarketInerface candidateContract = MarketInerface(_address);
        require(candidateContract.isMarket());
        market = candidateContract;
        emit LogModuleUpgrade(_address, "Market");
    }

     
    function adminSetRentals(address _address) external onlyOwner {
        RentalsInterface candidateContract = RentalsInterface(_address);
        require(candidateContract.isRentals());
        rentals = candidateContract;
        emit LogModuleUpgrade(_address, "Rentals");
    }

     
    function adminSetAds(address _address) external onlyOwner {
        AdsInterface candidateContract = AdsInterface(_address);
        require(candidateContract.isAds());
        ads = candidateContract;
        emit LogModuleUpgrade(_address, "Ads");
    }
}

 

 



 
 
contract MehERC721 is ERC721Token("MillionEtherHomePage","MEH"), MEHAccessControl {

     
     
     
    function isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    )
        internal
        view
        returns (bool)
    {   
        bool onSale = market.isOnSale(uint16(_tokenId));

        address owner = ownerOf(_tokenId);
        bool spenderIsApprovedOrOwner =
            _spender == owner ||
            getApproved(_tokenId) == _spender ||
            isApprovedForAll(owner, _spender);

        return (
            (onSale && _spender == address(market)) ||
            (!(onSale) && spenderIsApprovedOrOwner)
        );
    }

     
     
     
    function _mintCrowdsaleBlock(address _to, uint16 _blockId) external onlyMarket whenNotPaused {
        if (totalSupply() <= 9999) {
        _mint(_to, uint256(_blockId));
        }
    }

     
    function approve(address _to, uint256 _tokenId) public whenNotPaused {
        super.approve(_to, _tokenId);
    }
 
     
    function setApprovalForAll(address _to, bool _approved) public whenNotPaused {
        super.setApprovalForAll(_to, _approved);
    }    

     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        super.transferFrom(_from, _to, _tokenId);
    }
}

 

 



 
contract Accounting is MEHAccessControl {
    using SafeMath for uint256;

     
    mapping(address => uint256) public balances;

     
    event LogContractBalance(address payerOrPayee, int balanceChange);

 
    
     
    function withdraw() external whenNotPaused {
        address payee = msg.sender;
        uint256 payment = balances[payee];

        require(payment != 0);
        assert(address(this).balance >= payment);

        balances[payee] = 0;

         
        payee.transfer(payment);
        emit LogContractBalance(payee, int256(-payment));
    }

     
     
     
    function operatorTransferFunds(
        address _payer, 
        address _recipient, 
        uint _amount) 
    external 
    onlyBalanceOperators
    whenNotPaused
    {
        require(balances[_payer] >= _amount);
        _deductFrom(_payer, _amount);
        _depositTo(_recipient, _amount);
    }

     
    function depositFunds() internal whenNotPaused {
        _depositTo(msg.sender, msg.value);
        emit LogContractBalance(msg.sender, int256(msg.value));
    }

     
    function _depositTo(address _recipient, uint _amount) internal {
        balances[_recipient] = balances[_recipient].add(_amount);
    }

     
    function _deductFrom(address _payer, uint _amount) internal {
        balances[_payer] = balances[_payer].sub(_amount);
    }

 

     
     
     
     
     
     
    function adminRescueFunds() external onlyOwner whenPaused {
        address payee = owner;
        uint256 payment = address(this).balance;
        payee.transfer(payment);
    }

     
    function canPay(uint _needed) internal view returns (bool) {
        return (msg.value.add(balances[msg.sender]) >= _needed);
    }
}

 

 

 

 
 
 
contract MEH is MehERC721, Accounting {

     
    event LogBuys(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        address newLandlord
    );

     
    event LogSells(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        uint sellPrice
    );

     
    event LogRentsOut(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        uint rentPricePerPeriodWei
    );

     
    event LogRents(
        uint ID,
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        uint numberOfPeriods,
        uint rentedFrom
    );

     
    event LogAds(uint ID, 
        uint8 fromX,
        uint8 fromY,
        uint8 toX,
        uint8 toY,
        string imageSourceUrl,
        string adUrl,
        string adText,
        address indexed advertiser);

 
    
     
     
     
     
    function buyArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) 
        external
        whenNotPaused
        payable
    {   
         
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        require(canPay(areaPrice(fromX, fromY, toX, toY)));
        depositFunds();

         
         
        uint id = market.buyBlocks(msg.sender, blocksList(fromX, fromY, toX, toY));
        emit LogBuys(id, fromX, fromY, toX, toY, msg.sender);
    }

     
     
    function sellArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint priceForEachBlockWei)
        external 
        whenNotPaused
    {   
         
        require(isLegalCoordinates(fromX, fromY, toX, toY));

         
         
        uint id = market.sellBlocks(
            msg.sender, 
            priceForEachBlockWei, 
            blocksList(fromX, fromY, toX, toY)
        );
        emit LogSells(id, fromX, fromY, toX, toY, priceForEachBlockWei);
    }

     
    function areaPrice(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY) 
        public 
        view 
        returns (uint) 
    {   
         
        require(isLegalCoordinates(fromX, fromY, toX, toY));

         
        return market.areaPrice(blocksList(fromX, fromY, toX, toY));
    }

 
        
     
     
     
    function rentOutArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint rentPricePerPeriodWei)
        external
        whenNotPaused
    {   
         
        require(isLegalCoordinates(fromX, fromY, toX, toY));

         
         
        uint id = rentals.rentOutBlocks(
            msg.sender, 
            rentPricePerPeriodWei, 
            blocksList(fromX, fromY, toX, toY)
        );
        emit LogRentsOut(id, fromX, fromY, toX, toY, rentPricePerPeriodWei);
    }
    
     
     
     
    function rentArea(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint numberOfPeriods)
        external
        payable
        whenNotPaused
    {   
         
         
        require(isLegalCoordinates(fromX, fromY, toX, toY));
        require(canPay(areaRentPrice(fromX, fromY, toX, toY, numberOfPeriods)));
        depositFunds();

         
         
        uint id = rentals.rentBlocks(
            msg.sender, 
            numberOfPeriods, 
            blocksList(fromX, fromY, toX, toY)
        );
        emit LogRents(id, fromX, fromY, toX, toY, numberOfPeriods, 0);
    }

     
     
    function areaRentPrice(uint8 fromX, uint8 fromY, uint8 toX, uint8 toY, uint numberOfPeriods)
        public 
        view 
        returns (uint) 
    {   
         
        require(isLegalCoordinates(fromX, fromY, toX, toY));

         
        return rentals.blocksRentPrice (numberOfPeriods, blocksList(fromX, fromY, toX, toY));
    }

 
    
     
     
     
     
    function placeAds( 
        uint8 fromX, 
        uint8 fromY, 
        uint8 toX, 
        uint8 toY, 
        string imageSource, 
        string link, 
        string text
    ) 
        external
        whenNotPaused
    {   
         
        require(isLegalCoordinates(fromX, fromY, toX, toY));

         
         
        uint AdsId = ads.advertiseOnBlocks(
            msg.sender, 
            blocksList(fromX, fromY, toX, toY), 
            imageSource, 
            link, 
            text
        );
        emit LogAds(AdsId, fromX, fromY, toX, toY, imageSource, link, text, msg.sender);
    }

     
     
    function canAdvertise(
        address advertiser,
        uint8 fromX, 
        uint8 fromY, 
        uint8 toX, 
        uint8 toY
    ) 
        external
        view
        returns (bool)
    {   
         
        require(isLegalCoordinates(fromX, fromY, toX, toY));

         
        return ads.canAdvertiseOnBlocks(advertiser, blocksList(fromX, fromY, toX, toY));
    }

 

     
    function adminImportOldMEBlock(uint8 x, uint8 y) external onlyOwner {
        (uint id, address newLandlord) = market.importOldMEBlock(x, y);
        emit LogBuys(id, x, y, x, y, newLandlord);
    }

 
    
     
    function getBlockOwner(uint8 x, uint8 y) external view returns (address) {
        return ownerOf(blockID(x, y));
    }

 
    
     
    function blockID(uint8 x, uint8 y) public pure returns (uint16) {
        return (uint16(y) - 1) * 100 + uint16(x);
    }

     
    function countBlocks(
        uint8 fromX, 
        uint8 fromY, 
        uint8 toX, 
        uint8 toY
    ) 
        internal 
        pure 
        returns (uint16)
    {
        return (toX - fromX + 1) * (toY - fromY + 1);
    }

     
    function blocksList(
        uint8 fromX, 
        uint8 fromY, 
        uint8 toX, 
        uint8 toY
    ) 
        internal 
        pure 
        returns (uint16[] memory r) 
    {
        uint i = 0;
        r = new uint16[](countBlocks(fromX, fromY, toX, toY));
        for (uint8 ix=fromX; ix<=toX; ix++) {
            for (uint8 iy=fromY; iy<=toY; iy++) {
                r[i] = blockID(ix, iy);
                i++;
            }
        }
    }
    
     
     
     
     
    function isLegalCoordinates(
        uint8 _fromX, 
        uint8 _fromY, 
        uint8 _toX, 
        uint8 _toY
    )    
        private 
        pure 
        returns (bool) 
    {
        return ((_fromX >= 1) && (_fromY >=1)  && (_toX <= 100) && (_toY <= 100) 
            && (_fromX <= _toX) && (_fromY <= _toY));
    }
}