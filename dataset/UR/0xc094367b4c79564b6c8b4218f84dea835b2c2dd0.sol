 

pragma solidity ^0.4.24;
 

contract TempleInterface {
  function purchaseFor(address _referredBy, address _customerAddress) public payable returns (uint256);
}

contract TikiMadness {

   

   
  modifier onlyOwner() {
    require(msg.sender == contractOwner);
    _;
  }

   
  modifier notContract() {
    require(tx.origin == msg.sender);
    _;
  }

   
  modifier notPaused() {
    require(now > startTime);
    _;
  }

   
  modifier easyOnGas() {
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


   

  uint256 private increaseRatePercent =  132;
  uint256 private godTikiPercent =  2;  
  uint256 private devFeePercent =  5;
  uint256 private bagHolderFundPercent =  5;
  uint256 private exchangeTokenPercent =  10;
  uint256 private previousOwnerPercent =  110;
  uint256 private priceFallDuration =  1 hours;

   

   
  mapping (uint256 => address) public tikiIndexToOwner;

   
  mapping (address => uint256) private ownershipTokenCount;

   
  address public contractOwner;
  
   
  uint256 public startTime = 1543692600;  

   
  uint256 public currentDevFee = 0;

   
  address public templeOfEthaddress = 0x0e21902d93573c18fd0acbadac4a5464e9732f54;  

   
  TempleInterface public templeContract;

   

  struct TikiMask {
    string name;
    uint256 basePrice;  
    uint256 highPrice;
    uint256 fallDuration;
    uint256 saleTime;  
    uint256 bagHolderFund;
  }

  TikiMask [6] public tikiMasks;

  constructor () public {

    contractOwner = msg.sender;
    templeContract = TempleInterface(templeOfEthaddress);

    TikiMask memory _Huracan = TikiMask({
            name: "Huracan",
            basePrice: 0.015 ether,
            highPrice: 0.015 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    tikiMasks[0] =  _Huracan;

    TikiMask memory _Itzamna = TikiMask({
            name: "Itzamna",
            basePrice: 0.018 ether,
            highPrice: 0.018 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    tikiMasks[1] =  _Itzamna;

    TikiMask memory _Mitnal = TikiMask({
            name: "Mitnal",
            basePrice: 0.020 ether,
            highPrice: 0.020 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    tikiMasks[2] =  _Mitnal;

    TikiMask memory _Tepeu = TikiMask({
            name: "Tepeu",
            basePrice: 0.025 ether,
            highPrice: 0.025 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    tikiMasks[3] =  _Tepeu;

    TikiMask memory _Usukan = TikiMask({
            name: "Usukan",
            basePrice: 0.030 ether,
            highPrice: 0.030 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    tikiMasks[4] =  _Usukan;

    TikiMask memory _Voltan = TikiMask({
            name: "Voltan",
            basePrice: 0.035 ether,
            highPrice: 0.035 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    tikiMasks[5] =  _Voltan;

    _transfer(0x0, contractOwner, 0);
    _transfer(0x0, contractOwner, 1);
    _transfer(0x0, contractOwner, 2);
    _transfer(0x0, contractOwner, 3);
    _transfer(0x0, contractOwner, 4);
    _transfer(0x0, contractOwner, 5);


  }


   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
   
  function getTiki(uint256 _tokenId) public view returns (
    string tikiName,
    uint256 currentPrice,
    uint256 basePrice,
    address currentOwner,
    uint256 bagHolderFund,
    bool isBagFundAvailable
  ) {
    TikiMask storage tiki = tikiMasks[_tokenId];
    tikiName = tiki.name;
    currentPrice = priceOf(_tokenId);
    basePrice = tiki.basePrice;
    currentOwner = tikiIndexToOwner[_tokenId];
    bagHolderFund = tiki.bagHolderFund;
    isBagFundAvailable = now > (tiki.saleTime + priceFallDuration);
  }


   
   
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = tikiIndexToOwner[_tokenId];
    require(owner != address(0));
  }

   
  function purchase(uint256 _tokenId , address _referredBy) public payable notContract notPaused easyOnGas  {

    address oldOwner = tikiIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 currentPrice = priceOf(_tokenId);

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= currentPrice);

    uint256 previousOwnerGets = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),previousOwnerPercent);
    uint256 exchangeTokensAmount = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),exchangeTokenPercent);
    uint256 devFeeAmount = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),devFeePercent);
    uint256 bagHolderFundAmount = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),bagHolderFundPercent);
    uint256 godTikiGets = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),godTikiPercent);

    if (msg.value>currentPrice){
      bagHolderFundAmount = bagHolderFundAmount + (msg.value-currentPrice);  
    }
    currentDevFee = currentDevFee + devFeeAmount;

     
    templeContract.purchaseFor.value(exchangeTokensAmount)(_referredBy, msg.sender);
 
     
    ownerOf(godTiki()).transfer(godTikiGets);

     
    _transfer(oldOwner, newOwner, _tokenId);

     
    tikiMasks[_tokenId].highPrice = SafeMath.mul(SafeMath.div(currentPrice,100),increaseRatePercent);
    tikiMasks[_tokenId].saleTime = now;
    tikiMasks[_tokenId].bagHolderFund = tikiMasks[_tokenId].bagHolderFund + bagHolderFundAmount;
    tikiMasks[_tokenId].basePrice = max(tikiMasks[_tokenId].basePrice,SafeMath.div(tikiMasks[_tokenId].bagHolderFund,8));   

     
    if (oldOwner != address(this)) {
      if (oldOwner.send(previousOwnerGets)){}
    }

    emit onTokenSold(_tokenId, currentPrice, oldOwner, newOwner, tikiMasks[_tokenId].name);

  }

   
  function godTiki() public view returns (uint256 tokenId) {
    uint256 lowestPrice = priceOf(0);
    uint256 lowestId = 0;
    for(uint x=1;x<6;x++){
      if(priceOf(x)<lowestPrice){
        lowestId=x;
      }
    }
    return lowestId;
  }

   
  function priceOf(uint256 _tokenId) public view returns (uint256 price) {

    TikiMask storage tiki = tikiMasks[_tokenId];
    uint256 secondsPassed  = now - tiki.saleTime;

    if (secondsPassed >= tiki.fallDuration || tiki.highPrice==tiki.basePrice) {
            return tiki.basePrice;
    }

    uint256 totalPriceChange = tiki.highPrice - tiki.basePrice;
    uint256 currentPriceChange = totalPriceChange * secondsPassed /tiki.fallDuration;
    uint256 currentPrice = tiki.highPrice - currentPriceChange;

    return currentPrice;
  }

   
  function collectBagHolderFund(uint256 _tokenId) public notPaused {
      require(msg.sender == tikiIndexToOwner[_tokenId]);
      uint256 bagHolderFund;
      bool isBagFundAvailable = false;
       (
        ,
        ,
        ,
        ,
        bagHolderFund,
        isBagFundAvailable
        ) = getTiki(_tokenId);
        require(isBagFundAvailable && bagHolderFund > 0);
        uint256 amount = bagHolderFund;
        tikiMasks[_tokenId].bagHolderFund = 0;
        tikiMasks[_tokenId].basePrice = 0.015 ether;
        msg.sender.transfer(amount);
  }

  function paused() public view returns (bool){
    return (now < startTime);
  }

   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == tikiIndexToOwner[_tokenId];
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {

     
    uint length;
    assembly { length := extcodesize(_to) }
    require (length == 0);

    ownershipTokenCount[_to]++;
     
    tikiIndexToOwner[_tokenId] = _to;

    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
    }
  }

   
  function collectDevFees() public onlyOwner {
      if (currentDevFee < address(this).balance){
         uint256 amount = currentDevFee;
         currentDevFee = 0;
         contractOwner.transfer(amount);
      }
  }


     
    function max(uint a, uint b) private pure returns (uint) {
           return a > b ? a : b;
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