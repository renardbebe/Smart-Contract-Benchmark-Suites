 

pragma solidity ^0.4.18;  

contract ShrimpFarmer{
    function buyEggs() public payable;
}
contract AdPotato{
    address ceoAddress;
    ShrimpFarmer fundsTarget;
    Advertisement[] ads;
    uint256 NUM_ADS=10;
    uint256 BASE_PRICE=0.005 ether;
    uint256 PERCENT_TAXED=30;
     
    event BoughtAd(address sender, uint256 amount);
     
    modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress
    );
    _;
    }
     
    function AdPotato() public{
        ceoAddress=msg.sender;
        initialize(0x58AFF91f5b48245Bd83deeB2C7d31875f68b3f0D);
    }
     
    struct Advertisement{
        string text;
        string url;
        address owner;
        uint256 startingLevel;
        uint256 startingTime;
        uint256 halfLife;
    }
     
    function initialize(address fund) public onlyCLevel{
        fundsTarget=ShrimpFarmer(fund);
        for(uint i=0;i<NUM_ADS;i++){
            ads.push(Advertisement({text:"Your Text Here",url:"",owner:ceoAddress,startingLevel:0,startingTime:now,halfLife:12 hours}));
        }
    }
    function buyAd(uint256 index,string text,string url) public payable{
        require(ads.length>index);
        require(msg.sender==tx.origin);
        Advertisement storage toBuy=ads[index];
        uint256 currentLevel=getCurrentLevel(toBuy.startingLevel,toBuy.startingTime,toBuy.halfLife);
        uint256 currentPrice=getCurrentPrice(currentLevel);
        require(msg.value>=currentPrice);
        uint256 purchaseExcess = SafeMath.sub(msg.value, currentPrice);
        toBuy.text=text;
        toBuy.url=url;
        toBuy.startingLevel=currentLevel+1;
        toBuy.startingTime=now;
        fundsTarget.buyEggs.value(SafeMath.div(SafeMath.mul(currentPrice,PERCENT_TAXED),100))(); 
        toBuy.owner.transfer(SafeMath.div(SafeMath.mul(currentPrice,100-PERCENT_TAXED),100)); 
        toBuy.owner=msg.sender; 
        msg.sender.transfer(purchaseExcess);
        emit BoughtAd(msg.sender,purchaseExcess);
    }
    function getAdText(uint256 index)public view returns(string){
        return ads[index].text;
    }
    function getAdUrl(uint256 index)public view returns(string){
        return ads[index].url;
    }
    function getAdOwner(uint256 index) public view returns(address){
        return ads[index].owner;
    }
    function getAdPrice(uint256 index) public view returns(uint256){
        Advertisement ad=ads[index];
        return getCurrentPrice(getCurrentLevel(ad.startingLevel,ad.startingTime,ad.halfLife));
    }
    function getCurrentPrice(uint256 currentLevel) public view returns(uint256){
        return BASE_PRICE*2**currentLevel;  
    }
    function getCurrentLevel(uint256 startingLevel,uint256 startingTime,uint256 halfLife)public view returns(uint256){
        uint256 timePassed=SafeMath.sub(now,startingTime);
        uint256 levelsPassed=SafeMath.div(timePassed,halfLife);
        if(startingLevel<levelsPassed){
            return 0;
        }
        return SafeMath.sub(startingLevel,levelsPassed);
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