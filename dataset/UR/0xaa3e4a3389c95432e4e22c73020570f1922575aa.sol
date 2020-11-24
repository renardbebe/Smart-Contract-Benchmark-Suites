 

pragma solidity ^0.4.24;

 
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

contract apexGoldInterface {
  function isStarted() public view returns (bool);
  function buyFor(address _referredBy, address _customerAddress) public payable returns (uint256);
}

contract APGSolids is ERC721 {

   

   
  modifier onlyOwner() {
    require(msg.sender == contractOwner);
    _;
  }

   
  modifier notContract() {
    require(tx.origin == msg.sender);
    _;
  }

   
  modifier notPaused() {
    require(paused == false);
    _;
  }

   
  modifier notGasbag() {
    require(tx.gasprice < 99999999999);
    _;
  }

   
  
   

  event onTokenSold(
       uint256 indexed tokenId,
       uint256 price,
       address prevOwner,
       address newOwner,
       string name
    );


   

  string public constant NAME = "APG Solids";
  string public constant SYMBOL = "APGS";

  uint256 private increaseRatePercent =  135;
  uint256 private devFeePercent =  5;
  uint256 private bagHolderFundPercent =  5;
  uint256 private exchangeTokenPercent =  10;
  uint256 private previousOwnerPercent =  110;
  uint256 private priceFallDuration =  4 hours;

   

   
  mapping (uint256 => address) public solidIndexToOwner;

   
  mapping (address => uint256) private ownershipTokenCount;

   
  mapping (uint256 => address) public solidIndexToApproved;

   
  address public contractOwner;

   
  uint256 public currentDevFee = 0;

   
  address public apexGoldaddress;

   
  bool public paused;

   

  struct Solid {
    string name;
    uint256 basePrice;
    uint256 highPrice;
    uint256 fallDuration;
    uint256 saleTime;  
    uint256 bagHolderFund;
  }

  Solid [6] public solids;

  constructor () public {

    contractOwner = msg.sender;
    paused=true;

    Solid memory _Tetrahedron = Solid({
            name: "Tetrahedron",
            basePrice: 0.014 ether,
            highPrice: 0.014 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    solids[1] =  _Tetrahedron;

    Solid memory _Cube = Solid({
            name: "Cube",
            basePrice: 0.016 ether,
            highPrice: 0.016 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    solids[2] =  _Cube;

    Solid memory _Octahedron = Solid({
            name: "Octahedron",
            basePrice: 0.018 ether,
            highPrice: 0.018 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    solids[3] =  _Octahedron;

    Solid memory _Dodecahedron = Solid({
            name: "Dodecahedron",
            basePrice: 0.02 ether,
            highPrice: 0.02 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    solids[4] =  _Dodecahedron;

    Solid memory _Icosahedron = Solid({
            name: "Icosahedron",
            basePrice: 0.03 ether,
            highPrice: 0.03 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    solids[5] =  _Icosahedron;

    _transfer(0x0, contractOwner, 1);
    _transfer(0x0, contractOwner, 2);
    _transfer(0x0, contractOwner, 3);
    _transfer(0x0, contractOwner, 4);
    _transfer(0x0, contractOwner, 5);

  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    solidIndexToApproved[_tokenId] = _to;

    emit Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
   
  function getSolid(uint256 _tokenId) public view returns (
    string solidName,
    uint256 price,
    address currentOwner,
    uint256 bagHolderFund,
    bool isBagFundAvailable
  ) {
    Solid storage solid = solids[_tokenId];
    solidName = solid.name;
    price = priceOf(_tokenId);
    currentOwner = solidIndexToOwner[_tokenId];
    bagHolderFund = solid.bagHolderFund;
    isBagFundAvailable = now > (solid.saleTime + priceFallDuration);
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
    owner = solidIndexToOwner[_tokenId];
    require(owner != address(0));
  }

   
  function purchase(uint256 _tokenId , address _referredBy) public payable notContract notPaused notGasbag   {

    address oldOwner = solidIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 currentPrice = priceOf(_tokenId);

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= currentPrice);

    uint256 previousOwnerGets = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),previousOwnerPercent);
    uint256 exchangeTokensAmount = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),exchangeTokenPercent);
    uint256 devFeeAmount = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),devFeePercent);
    uint256 bagHolderFundAmount = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),bagHolderFundPercent);

    currentDevFee = currentDevFee + devFeeAmount;

    if (exchangeContract.isStarted()) {
        exchangeContract.buyFor.value(exchangeTokensAmount)(_referredBy, msg.sender);
    }else{
         
        msg.sender.transfer(exchangeTokensAmount);
    }

     
    _transfer(oldOwner, newOwner, _tokenId);

     
    solids[_tokenId].highPrice = SafeMath.mul(SafeMath.div(currentPrice,100),increaseRatePercent);
    solids[_tokenId].saleTime = now;
    solids[_tokenId].bagHolderFund+=bagHolderFundAmount;

     
    if (oldOwner != address(this)) {
      if (oldOwner.send(previousOwnerGets)){}
    }

    emit onTokenSold(_tokenId, currentPrice, oldOwner, newOwner, solids[_tokenId].name);

  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {

    Solid storage solid = solids[_tokenId];
    uint256 secondsPassed  = now - solid.saleTime;

    if (secondsPassed >= solid.fallDuration || solid.highPrice==solid.basePrice) {
            return solid.basePrice;
    }

    uint256 totalPriceChange = solid.highPrice - solid.basePrice;
    uint256 currentPriceChange = totalPriceChange * secondsPassed /solid.fallDuration;
    uint256 currentPrice = solid.highPrice - currentPriceChange;

    return currentPrice;
  }

  function collectBagHolderFund(uint256 _tokenId) public notPaused {
      require(msg.sender == solidIndexToOwner[_tokenId]);
      uint256 bagHolderFund;
      bool isBagFundAvailable = false;
       (
        ,
        ,
        ,
        bagHolderFund,
        isBagFundAvailable
        ) = getSolid(_tokenId);
        require(isBagFundAvailable && bagHolderFund > 0);
        uint256 amount = bagHolderFund;
        solids[_tokenId].bagHolderFund = 0;
        msg.sender.transfer(amount);
  }


   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

   
   
   
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = solidIndexToOwner[_tokenId];

     
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
      uint256 totalTokens = totalSupply();
      uint256 resultIndex = 0;

      uint256 tokenId;
      for (tokenId = 0; tokenId <= totalTokens; tokenId++) {
        if (solidIndexToOwner[tokenId] == _owner) {
          result[resultIndex] = tokenId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return 5;
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
    return solidIndexToApproved[_tokenId] == _to;
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == solidIndexToOwner[_tokenId];
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {

     
    uint length;
    assembly { length := extcodesize(_to) }
    require (length == 0);

    ownershipTokenCount[_to]++;
     
    solidIndexToOwner[_tokenId] = _to;

    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete solidIndexToApproved[_tokenId];
    }

     
    emit Transfer(_from, _to, _tokenId);
  }

   
  function collectDevFees() public onlyOwner {
      if (currentDevFee < address(this).balance){
         uint256 amount = currentDevFee;
         currentDevFee = 0;
         contractOwner.transfer(amount);
      }
  }

   
   apexGoldInterface public exchangeContract;

  function setExchangeAddresss(address _address) public onlyOwner {
    exchangeContract = apexGoldInterface(_address);
    apexGoldaddress = _address;
   }

    
   function setPaused(bool _paused) public onlyOwner {
     paused = _paused;
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