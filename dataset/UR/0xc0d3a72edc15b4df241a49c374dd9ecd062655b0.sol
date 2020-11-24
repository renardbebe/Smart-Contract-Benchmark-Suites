 

pragma solidity ^0.4.18;
 
 
interface CaptainTokenInterface {
  function CreateCaptainToken(address _owner,uint256 _price, uint32 _captainId, uint32 _color,uint32 _atk, uint32 _defense,uint32 _level,uint256 _exp) public;
}

interface CaptainGameConfigInterface {
  function getCardInfo(uint32 cardId) external constant returns (uint32,uint32,uint32, uint32,uint32,uint256,uint256);
  function getSellable(uint32 _captainId) external returns (bool);
}
contract CaptainSell {

  address devAddress;
  function CaptainSell() public {
    devAddress = msg.sender;
  }

  CaptainTokenInterface public captains;
  CaptainGameConfigInterface public config; 
   
  event BuyToken(uint256 tokenId, uint256 oldPrice, address prevOwner, address winner);
  
   
  mapping(uint32 => uint256) captainToCount; 
   
   
   
  function() external payable {
  }

  modifier onlyOwner() {
    require(msg.sender == devAddress);
    _;
  }

   
  function setGameConfigContract(address _address) external onlyOwner {
    config = CaptainGameConfigInterface(_address);
  }

   
  function setCaptainTokenContract(address _address) external onlyOwner {
    captains = CaptainTokenInterface(_address);
  }


  function prepurchase(uint32 _captainId) external payable {
    uint32 color;
    uint32 atk;
    uint32 defense;
    uint256 price;
    uint256 captainCount;
    uint256 SellCount = captainToCount[_captainId];
    (color,atk,,,defense,price,captainCount) = config.getCardInfo(_captainId);
    require(config.getSellable(_captainId) == true);
    SellCount += 1;
    require(SellCount<=captainCount);

     
    require(msg.sender != address(0));
    
     
    require(msg.value >= price);
    captains.CreateCaptainToken(msg.sender,price,_captainId,color,atk, defense,1,0);
    captainToCount[_captainId] = SellCount;

     
    devAddress.transfer(msg.value);
     
    BuyToken(_captainId, price,address(this),msg.sender);
  }

  function getCaptainCount(uint32 _captainId) external constant returns (uint256) {
    return captainToCount[_captainId];
  }

   
  function withdraw() external onlyOwner {
    require(this.balance>0);
    msg.sender.transfer(this.balance);
  }

}