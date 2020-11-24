 

pragma solidity ^0.4.19;
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0){
        return 0;
    }
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 
contract Ownable {

  address public owner;

  address public newOwner;

  address public techSupport;

  address public newTechSupport;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyTechSupport() {
    require(msg.sender == techSupport);
    _;
  }

  function Ownable() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }

  function transferTechSupport (address _newSupport) public{
    require (msg.sender == owner || msg.sender == techSupport);
    newTechSupport = _newSupport;
  }

  function acceptSupport() public{
    if(msg.sender == newTechSupport){
      techSupport = newTechSupport;
    }
  }
}

 
contract VGCToken {
  function setCrowdsaleContract (address _address) public {}
  function burnTokens(address _address) public{}
  function getCrowdsaleBalance() public view returns(uint) {}
  function getRefBalSended () public view returns(bool){}
  function sendCrowdsaleBalance (address _address, uint _value) public {}
  function finishIco() public{}
}

 
contract Crowdsale is Ownable{

  using SafeMath for uint;
   
  function pow(uint256 a, uint256 b) internal pure returns (uint256){
   return (a**b);
  }

  uint decimals = 2;
   
  VGCToken public token;

  struct Ico{
    uint bonus;
    uint balance;
  }
   
  function Crowdsale(address _tokenAddress, address _addressOwner) public{
    token = VGCToken(_tokenAddress);
    owner = _addressOwner;
    structurePreIco.push(Ico(55555555555,1000000*pow(10,decimals)));  
    structurePreIco.push(Ico(58823529411,1000000*pow(10,decimals)));  
    structurePreIco.push(Ico(62500000000,1000000*pow(10,decimals)));  
    structurePreIco.push(Ico(66666666666,1000000*pow(10,decimals)));  
    structurePreIco.push(Ico(71428571428,1000000*pow(10,decimals)));  
    structurePreIco.push(Ico(76923076923,1000000*pow(10,decimals)));  


    structureIco.push(Ico(83333333333,10000000*pow(10,decimals)));  
    structureIco.push(Ico(90909090909,10000000*pow(10,decimals)));  
    structureIco.push(Ico(100000000000,10000000*pow(10,decimals)));  

    techSupport = msg.sender;
    token.setCrowdsaleContract(this);
  }
   
  Ico[] public structurePreIco;
  Ico[] public structureIco;
     
  uint public tokenPrice = 2000000000000000 / pow(10,decimals);
  uint minDeposit = 100000000000000000;  

     
  uint public preIcoStart = 1516320000;  
  uint public preIcoFinish = 1521590400;  

     
  uint public icoStart = 1521590401;  
  uint public icoFinish = 1529625600;  
  uint icoMinCap = 300000*pow(10,decimals);

   
  function isPreIco(uint _time) constant public returns (bool){
    if((preIcoStart <= _time) && (_time <= preIcoFinish)){
      return true;
    }
    return false;
  }

   
  function isIco(uint _time) constant public returns (bool){
    if((icoStart <= _time) && (_time <= icoFinish)){
      return true;
    }
    return false;
  }

   
  uint public preIcoTokensSold = 0;
  uint public iCoTokensSold = 0;
  uint public tokensSold = 0;
  uint public ethCollected = 0;

   
  mapping (address => uint) public investorBalances;

   
  function  buyIfPreIcoDiscount (uint _value) internal returns(uint,uint) {
    uint buffer = 0;
    uint bufferEth = 0;
    uint bufferValue = _value;
    uint res = 0;

    for (uint i = 0; i<structurePreIco.length; i++){
      res = _value/(tokenPrice*structurePreIco[i].bonus/100000000000);

       
      if(res >= (uint)(5000).mul(pow(10,decimals))){
        res = res.add(res/10);
      }
      if (res<=structurePreIco[i].balance){
         
        structurePreIco[i].balance = structurePreIco[i].balance.sub(res);
        buffer = res.add(buffer);
        return (buffer,0);
      }else {
        buffer = buffer.add(structurePreIco[i].balance);
         
        bufferEth += structurePreIco[i].balance*tokenPrice*structurePreIco[i].bonus/100000000000;
        _value = _value.sub(structurePreIco[i].balance*tokenPrice*structurePreIco[i].bonus/100000000000);
        structurePreIco[i].balance = 0;
        }
      }
    return  (buffer,bufferValue.sub(bufferEth));
  }

   
  function  buyIfIcoDiscount (uint _value) internal returns(uint,uint) {
    uint buffer = 0;
    uint bufferEth = 0;
    uint bufferValue = _value;
    uint res = 0;

    for (uint i = 0; i<structureIco.length; i++){
      res = _value/(tokenPrice*structureIco[i].bonus/100000000000);

       
      if(res >= (uint)(5000).mul(pow(10,decimals))){
        res = res.add(res/10);
      }
        if (res<=structureIco[i].balance){
          bufferEth = bufferEth+_value;
          structureIco[i].balance = structureIco[i].balance.sub(res);
          buffer = res.add(buffer);
          return (buffer,0);
        }else {
          buffer = buffer.add(structureIco[i].balance);
          bufferEth += structureIco[i].balance*tokenPrice*structureIco[i].bonus/100000000000;
          _value = _value.sub(structureIco[i].balance*tokenPrice*structureIco[i].bonus/100000000000);
          structureIco[i].balance = 0;
      }
    }
    return  (buffer,bufferValue.sub(bufferEth));
  }

   
  function() public payable{
    require(msg.value >= minDeposit);
    require(isIco(now) || isPreIco(now));
    require(buy(msg.sender,msg.value,now,false));  
  }

  bool public preIcoEnded = false;
   
  function buy(address _address, uint _value, uint _time, bool dashboard) internal returns (bool){
    uint tokensForSend;
    uint etherForSend;
    if (isPreIco(_time)){
      (tokensForSend,etherForSend) = buyIfPreIcoDiscount(_value);
      assert (tokensForSend >= 50*pow(10,decimals));
      preIcoTokensSold += tokensForSend;
      if (etherForSend!=0 && !dashboard){
        _address.transfer(etherForSend);
      }
      owner.transfer(this.balance);
    }
    if (isIco(_time)){
      if(!preIcoEnded){
        for (uint i = 0; i<structurePreIco.length; i++){
          structureIco[structureIco.length-1].balance = structureIco[structureIco.length-1].balance.add(structurePreIco[i].balance);
          structurePreIco[i].balance = 0;
        }
       preIcoEnded = true;
      }
      (tokensForSend,etherForSend) = buyIfIcoDiscount(_value);
      assert (tokensForSend >= 50*pow(10,decimals));
      iCoTokensSold += tokensForSend;

      if (etherForSend!=0 && !dashboard){
        _address.transfer(etherForSend);
      }
      investorBalances[_address] += _value.sub(etherForSend);

      if (isIcoTrue()){
        owner.transfer(this.balance);
      }
    }

    tokensSold += tokensForSend;

    token.sendCrowdsaleBalance(_address,tokensForSend);

    ethCollected = ethCollected.add(_value.sub(etherForSend));

    return true;
  }

   
  function finishIco() public {
    require (now > icoFinish + 3 days);
    require (token.getRefBalSended());
    for (uint i = 0; i<structureIco.length; i++){
      structureIco[i].balance = 0;
    }
    for (i = 0; i<structurePreIco.length; i++){
      structurePreIco[i].balance = 0;
    }
    token.finishIco();
  }

   
  function isIcoTrue() public constant returns (bool){
    if (tokensSold >= icoMinCap){
      return true;
    }
    return false;
  }

   
  function refund() public{
    require (!isIcoTrue());
    require (icoFinish + 3 days <= now);

    token.burnTokens(msg.sender);
    msg.sender.transfer(investorBalances[msg.sender]);
    investorBalances[msg.sender] = 0;
  }


   
  function sendEtherManually(address _address, uint _value) public onlyTechSupport{
    require(buy(_address,_value,now,true));
  }

   
  function tokensCount(uint _value) public view onlyTechSupport returns(uint res) {
    if (isPreIco(now)){
      (res,) = buyIfPreIcoDiscount(_value);
    }
    if (isIco(now)){
      (res,) = buyIfIcoDiscount(_value);
    }
    return res;
  }

  function getEtherBalanceOnCrowdsale() public view returns(uint) {
    return this.balance;
  }
}