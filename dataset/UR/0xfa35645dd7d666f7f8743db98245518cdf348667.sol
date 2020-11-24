 

pragma solidity ^0.4.24;
 

contract TempleInterface {
  function purchaseFor(address _referredBy, address _customerAddress) public payable returns (uint256);
}

contract TribalWarfare {

   

   
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

    event onRoundEnded(
         uint256 indexed roundNumber,
         uint256 indexed tokenId,
         address owner,
         uint256 winnings
      );

   

  uint256 private increaseRatePercent =  135;
  uint256 private devFeePercent =  5;
  uint256 private currentPotPercent =  5;
  uint256 private nextPotPercent =  5;
  uint256 private exchangeTokenPercent =  10;
  uint256 private previousOwnerPercent =  110;
  uint256 private initialRoundDuration =  12 minutes;

   

   
  mapping (uint256 => address) public tokenIndexToOwner;

   
  mapping (address => uint256) private ownershipTokenCount;

   
  address public contractOwner;

   
  uint256 public currentDevFee = 0;

   
  address public templeOfEthaddress = 0x0e21902d93573c18fd0acbadac4a5464e9732f54;  

   
  TempleInterface public templeContract;

   
  bool public paused = false;

  uint256 public currentPot =  0;
  uint256 public nextPot =  0;
  uint256 public roundNumber =  0;
  uint256 public roundEndingTime =  0;
  uint256 public lastFlip =  0;  

   

  struct TribalMask {
    string name;
    uint256 basePrice;
    uint256 currentPrice;
    uint256 timePowerMinutes;
  }

  TribalMask [6] public tribalMasks;

  constructor () public {

    contractOwner = msg.sender;
    templeContract = TempleInterface(templeOfEthaddress);
    paused=true;

    TribalMask memory _Yucatec = TribalMask({
            name: "Yucatec",
            basePrice: 0.018 ether,
            currentPrice: 0.018 ether,
            timePowerMinutes: 12 minutes
            });

    tribalMasks[0] =  _Yucatec;

    TribalMask memory _Chiapas = TribalMask({
            name: "Chiapas",
            basePrice: 0.020 ether,
            currentPrice: 0.020 ether,
            timePowerMinutes: 10 minutes
            });

    tribalMasks[1] =  _Chiapas;

    TribalMask memory _Kekchi = TribalMask({
            name: "Kekchi",
            basePrice: 0.022 ether,
            currentPrice: 0.022 ether,
            timePowerMinutes: 8 minutes
            });

    tribalMasks[2] =  _Kekchi;

    TribalMask memory _Chontal = TribalMask({
            name: "Chontal",
            basePrice: 0.024 ether,
            currentPrice: 0.024 ether,
            timePowerMinutes: 6 minutes
            });

    tribalMasks[3] =  _Chontal;

    TribalMask memory _Akatek = TribalMask({
            name: "Akatek",
            basePrice: 0.028 ether,
            currentPrice: 0.028 ether,
            timePowerMinutes: 4 minutes
            });

    tribalMasks[4] =  _Akatek;

    TribalMask memory _Itza = TribalMask({
            name: "Itza",
            basePrice: 0.030 ether,
            currentPrice: 0.030 ether,
            timePowerMinutes: 2 minutes
            });

    tribalMasks[5] =  _Itza;

    _transfer(0x0, contractOwner, 0);
    _transfer(0x0, contractOwner, 1);
    _transfer(0x0, contractOwner, 2);
    _transfer(0x0, contractOwner, 3);
    _transfer(0x0, contractOwner, 4);
    _transfer(0x0, contractOwner, 5);

  }

   
   
  function getTribalMask(uint256 _tokenId) public view returns (
    string maskName,
    uint256 basePrice,
    uint256 currentPrice,
    address currentOwner
  ) {
    TribalMask storage mask = tribalMasks[_tokenId];
    maskName = mask.name;
    basePrice = mask.basePrice;
    currentPrice = priceOf(_tokenId);
    currentOwner = tokenIndexToOwner[_tokenId];
  }

   
   
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = tokenIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function () public payable {
       
      currentPot = currentPot + SafeMath.div(msg.value,2);
      nextPot = nextPot + SafeMath.div(msg.value,2);
  }

 function start() public payable onlyOwner {
   roundNumber = 1;
   roundEndingTime = now + initialRoundDuration;
   currentPot = currentPot + SafeMath.div(msg.value,2);
   nextPot = nextPot + SafeMath.div(msg.value,2);
   paused = false;
 }

 function isRoundEnd() public view returns (bool){
     return (now>roundEndingTime);
 }

 function newRound() internal {
    
    
    tokenIndexToOwner[lastFlip].transfer(currentPot);
    
   emit onRoundEnded(roundNumber, lastFlip, tokenIndexToOwner[lastFlip], currentPot);

    
   tribalMasks[0].currentPrice=tribalMasks[0].basePrice;
   tribalMasks[1].currentPrice=tribalMasks[1].basePrice;
   tribalMasks[2].currentPrice=tribalMasks[2].basePrice;
   tribalMasks[3].currentPrice=tribalMasks[3].basePrice;
   tribalMasks[4].currentPrice=tribalMasks[4].basePrice;
   tribalMasks[5].currentPrice=tribalMasks[5].basePrice;
   roundNumber++;
   roundEndingTime = now + initialRoundDuration;
   currentPot = nextPot;
   nextPot = 0;
 }

   
  function purchase(uint256 _tokenId , address _referredBy) public payable notContract notPaused easyOnGas  {

     
    if (now >= roundEndingTime){
        newRound();
    }

    uint256 currentPrice = tribalMasks[_tokenId].currentPrice;
     
    require(msg.value >= currentPrice);

    address oldOwner = tokenIndexToOwner[_tokenId];
    address newOwner = msg.sender;

      
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

    uint256 previousOwnerGets = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),previousOwnerPercent);
    uint256 exchangeTokensAmount = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),exchangeTokenPercent);
    uint256 devFeeAmount = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),devFeePercent);
    currentPot = currentPot + SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),currentPotPercent);
    nextPot = nextPot + SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),nextPotPercent);

     
    if (msg.value > currentPrice){
      if (now < roundEndingTime){
        nextPot = nextPot + (msg.value - currentPrice);
      }else{
         
        msg.sender.transfer(msg.value - currentPrice);
      }
    }

    currentDevFee = currentDevFee + devFeeAmount;

    templeContract.purchaseFor.value(exchangeTokensAmount)(_referredBy, msg.sender);

     
    _transfer(oldOwner, newOwner, _tokenId);

     
    tribalMasks[_tokenId].currentPrice = SafeMath.mul(SafeMath.div(currentPrice,100),increaseRatePercent);
     
    roundEndingTime = roundEndingTime + tribalMasks[_tokenId].timePowerMinutes;

    lastFlip = _tokenId;
     
    if (oldOwner != address(this)) {
      if (oldOwner.send(previousOwnerGets)){}
    }

    emit onTokenSold(_tokenId, currentPrice, oldOwner, newOwner, tribalMasks[_tokenId].name);

  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
      if(isRoundEnd()){
        return  tribalMasks[_tokenId].basePrice;
      }
    return tribalMasks[_tokenId].currentPrice;
  }

   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == tokenIndexToOwner[_tokenId];
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {

     
    uint length;
    assembly { length := extcodesize(_to) }
    require (length == 0);

    ownershipTokenCount[_to]++;
     
    tokenIndexToOwner[_tokenId] = _to;

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