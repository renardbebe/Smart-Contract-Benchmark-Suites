 

pragma solidity ^0.4.13;

 
library Math {

     
    function Mul(uint a, uint b) constant internal returns (uint) {
      uint c = a * b;
       
      assert(a == 0 || c / a == b);
      return c;
    }

     
    function Div(uint a, uint b) constant internal returns (uint) {
       
      assert(b > 0);
      uint c = a / b;
      assert(a == b * c + a % b);
      return c;
    }

     
    function Sub(uint a, uint b) constant internal returns (uint) {
       
      assert(b <= a);
      return a - b;
    }

     
    function Add(uint a, uint b) constant internal returns (uint) {
      uint c = a + b;
       
      assert(c>=a && c>=b);
      return c;
    }
}

 
contract ERC20Basic {
  
   
  uint public totalSupply;

   
  function balanceOf(address who) constant public returns (uint);

   
  function transfer(address _to, uint _value) public returns(bool ok);

   
  event Transfer(address indexed _from, address indexed _to, uint _value);
}

 
contract ERC20 is ERC20Basic {

   
  function allowance(address owner, address spender) public constant returns (uint);

   
  function transferFrom(address _from, address _to, uint _value) public returns(bool ok);

   
  function approve(address _spender, uint _value) public returns(bool ok);

   
  event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract Ownable {

   
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }
  
   
  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) 
        owner = newOwner;
  }

}

 
contract Pausable is Ownable {

   
  bool public stopped;

   
  event StateChanged(bool changed);

   
  modifier stopInEmergency {
    require(!stopped);
    _;
  }

   
  modifier onlyInEmergency {
    require(stopped);
    _;
  }

   
  function emergencyStop() external onlyOwner  {
    stopped = true;
     
    StateChanged(true);
  }

   
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
     
    StateChanged(true);
  }

}

 
contract EXH is ERC20, Ownable {

  using Math for uint;

   
   
  string public name;

   
  string public symbol;

   
  uint8 public decimals;    

   
  string public version = 'v1.0'; 

   
  uint public totalSupply;

   
  bool public locked;

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

   
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4);
     _;
  }
  
   
  modifier onlyUnlocked() {
    require(!locked || msg.sender == owner);
    _;
  }

   
  function EXH() public {

     
    locked = true;

     
    totalSupply = 0;

     
    name = 'EXH Token';

     
    symbol = 'EXH';
 
    decimals = 18;
  }
 
   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public onlyUnlocked returns (bool){

     
    if (_value > 0 && !(_to == address(0))) {
       
      balances[msg.sender] = balances[msg.sender].Sub(_value);
       
      balances[_to] = balances[_to].Add(_value);
       
      Transfer(msg.sender, _to, _value);
      return true;
    }
    else{
      return false;
    }
  }

   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) public onlyUnlocked returns (bool) {

     
    if (_value > 0 && (_to != address(0) && _from != address(0))) {
       
      var _allowance = allowed[_from][msg.sender];
       
      balances[_to] = balances[_to].Add( _value);
       
      balances[_from] = balances[_from].Sub( _value);
       
      allowed[_from][msg.sender] = _allowance.Sub( _value);
       
      Transfer(_from, _to, _value);
      return true;
    }else{
      return false;
    }
  }

   
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }
  
   
  function approve(address _spender, uint _value) public returns (bool) {
    require(_spender != address(0));
    allowed[msg.sender][_spender] = _value;
     
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
  
}

 
contract Crowdsale is EXH, Pausable {

  using Math for uint;
  
   

   
  uint public startBlock;   

   
  uint public endBlock;  

   
  uint public maxCap;   

   
  uint public maxCapPreSale;   

   
  uint public ETHReceived;    

   
  uint public PRICE;   

   
  uint public crowdsaleStatus; 

   
  uint public crowdSaleType; 

   
  uint public totalSupplyPreSale; 

   
  uint public durationPreSale;

   
  uint valueOneEther = 1e18;

   
  uint public durationCrowdSale;

   
  uint public countTotalInvestors;

   
  uint public countInvestorsRefunded;
  
   
  uint public refundStatus;

  
  uint public maxCapMintTransfer ;

   
  uint public totalSupplyMintTransfer;

   
  uint public totalSupplyCrowdsale;

   
  uint256 public countTotalInvestorsInCrowdsale;

  uint256 public countInvestorsRefundedInCrowdsale;

   
  struct Investor {
     
    uint weiReceivedCrowdsaleType0;
     
    uint weiReceivedCrowdsaleType1;
     
    uint exhSentCrowdsaleType0;
     
    uint exhSentCrowdsaleType1;
     
    uint investorID;
  }

   
  mapping(address => Investor) public investors;
   
  mapping (uint => address) public investorList;

  
   
  event ReceivedETH(address addr, uint value);

   
  event MintAndTransferEXH(address addr, uint value, bytes32 comment);

   
  function Crowdsale() public {

     
    startBlock = 0;   
     
    endBlock = 0;    
     
    maxCap = 31750000e18;
     
    maxCapPreSale = 500000e18;
     
    maxCapMintTransfer = 1250000e18;
     
    PRICE = 10; 
     
    crowdsaleStatus = 0;    
     
    crowdSaleType = 0;
     
    durationPreSale = 8 days + 1 hours;
     
    durationCrowdSale = 28 days;
     
    countTotalInvestors = 0;
     
    countInvestorsRefunded = 0;
     
    refundStatus = 0;

    countTotalInvestorsInCrowdsale = 0;
    countInvestorsRefundedInCrowdsale = 0;
    
  }

   
  modifier respectTimeFrame() {
    assert(!((now < startBlock) || (now > endBlock )));
    _;
  }

   
  function start() public onlyOwner {
     
    assert(startBlock == 0);
    startBlock = now;            
     
    endBlock = now.Add(durationCrowdSale.Add(durationPreSale));
     
    crowdsaleStatus = 1;
     
    StateChanged(true);  
  }

   
  function startSale() public onlyOwner
  {
    if(now > startBlock.Add(durationPreSale) && now <= endBlock){
        crowdsaleStatus = 1;
        crowdSaleType = 1;
        if(crowdSaleType != 1)
        {
          totalSupplyCrowdsale = totalSupplyPreSale;
        }
         
        StateChanged(true); 
    }
    else
      revert();
  }

   
  function updateDuration(uint time) public onlyOwner
  {
      require(time != 0);
      assert(startBlock != 0);
      assert(crowdSaleType == 1 && crowdsaleStatus != 2);
      durationCrowdSale = durationCrowdSale.Add(time);
      endBlock = endBlock.Add(time);
       
      StateChanged(true);
  }

   
  function setPrice(uint price) public onlyOwner
  {
      require( price != 0);
      PRICE = price;
       
      StateChanged(true);
  }
  
   
  function unlock() public onlyOwner
  {
    locked = false;
     
    StateChanged(true);
  }
  
   
  function () public payable {
   
    createTokens(msg.sender);
  }

   
  function createTokens(address beneficiary) internal stopInEmergency  respectTimeFrame {
     
    assert(crowdsaleStatus == 1); 
     
    require(msg.value >= 1 ether/getPrice());   
     
    require(msg.value != 0);
     
    uint exhToSend = msg.value.Mul(getPrice());

     
    Investor storage investorStruct = investors[beneficiary];

     
    if(crowdSaleType == 0){
      require(exhToSend.Add(totalSupplyPreSale) <= maxCapPreSale);
      totalSupplyPreSale = totalSupplyPreSale.Add(exhToSend);
      if((maxCapPreSale.Sub(totalSupplyPreSale) < valueOneEther)||(now > (startBlock.Add(7 days + 1 hours)))){
        crowdsaleStatus = 2;
      }        
      investorStruct.weiReceivedCrowdsaleType0 = investorStruct.weiReceivedCrowdsaleType0.Add(msg.value);
      investorStruct.exhSentCrowdsaleType0 = investorStruct.exhSentCrowdsaleType0.Add(exhToSend);
    }

     
    else if (crowdSaleType == 1){
      if (exhToSend.Add(totalSupply) > maxCap ) {
        revert();
      }
      totalSupplyCrowdsale = totalSupplyCrowdsale.Add(exhToSend);
      if(maxCap.Sub(totalSupplyCrowdsale) < valueOneEther)
      {
        crowdsaleStatus = 2;
      }
      if(investorStruct.investorID == 0 || investorStruct.weiReceivedCrowdsaleType1 == 0){
        countTotalInvestorsInCrowdsale++;
      }
      investorStruct.weiReceivedCrowdsaleType1 = investorStruct.weiReceivedCrowdsaleType1.Add(msg.value);
      investorStruct.exhSentCrowdsaleType1 = investorStruct.exhSentCrowdsaleType1.Add(exhToSend);
    }

     
    if(investorStruct.investorID == 0){
        countTotalInvestors++;
        investorStruct.investorID = countTotalInvestors;
        investorList[countTotalInvestors] = beneficiary;
    }

     
    totalSupply = totalSupply.Add(exhToSend);
     
    ETHReceived = ETHReceived.Add(msg.value);  
     
    balances[beneficiary] = balances[beneficiary].Add(exhToSend);
     
    ReceivedETH(beneficiary,ETHReceived); 
     
    GetEXHFundAccount().transfer(msg.value);
     
    StateChanged(true);
  }

   
  function MintAndTransferToken(address beneficiary,uint exhToCredit,bytes32 comment) external onlyOwner {
     
    assert(startBlock != 0);
     
    assert(totalSupplyMintTransfer <= maxCapMintTransfer);
     
    require(totalSupplyMintTransfer.Add(exhToCredit) <= maxCapMintTransfer);
     
    balances[beneficiary] = balances[beneficiary].Add(exhToCredit);
     
    totalSupply = totalSupply.Add(exhToCredit);
     
    totalSupplyMintTransfer = totalSupplyMintTransfer.Add(exhToCredit);
     
    MintAndTransferEXH(beneficiary, exhToCredit,comment);
     
    StateChanged(true);  
  }

   
  function getPrice() public constant returns (uint result) {
      if (crowdSaleType == 0) {
            return (PRICE.Mul(100)).Div(70);
      }
      if (crowdSaleType == 1) {
          uint crowdsalePriceBracket = 1 weeks;
          uint startCrowdsale = startBlock.Add(durationPreSale);
            if (now > startCrowdsale && now <= startCrowdsale.Add(crowdsalePriceBracket)) {
                return ((PRICE.Mul(100)).Div(80));
            }else if (now > startCrowdsale.Add(crowdsalePriceBracket) && now <= (startCrowdsale.Add(crowdsalePriceBracket.Mul(2)))) {
                return (PRICE.Mul(100)).Div(85);
            }else if (now > (startCrowdsale.Add(crowdsalePriceBracket.Mul(2))) && now <= (startCrowdsale.Add(crowdsalePriceBracket.Mul(3)))) {
                return (PRICE.Mul(100)).Div(90);
            }else if (now > (startCrowdsale.Add(crowdsalePriceBracket.Mul(3))) && now <= (startCrowdsale.Add(crowdsalePriceBracket.Mul(4)))) {
                return (PRICE.Mul(100)).Div(95);
            }
      }
      return PRICE;
  }

  function GetEXHFundAccount() internal returns (address) {
    uint remainder = block.number%10;
    if(remainder==0){
      return 0xda141e704601f8C8E343C5cA246355c812238D91;
    } else if(remainder==1){
      return 0x2381963906C434dD4639489Bec9A2bB55D83cC14;
    } else if(remainder==2){
      return 0x537C7119452A7814ABD1C4ED71F6eCD25225C0F6;
    } else if(remainder==3){
      return 0x1F04880fFdFff05d36307f69EAAc8645B98449E2;
    } else if(remainder==4){
      return 0xd72B82b69FEe29d81f5e2DA66aB91014aDaE0AA0;
    } else if(remainder==5){
      return 0xf63bef6B67064053191dc4bC6F1D06592C07925f;
    } else if(remainder==6){
      return 0x7381F9C5d35E895e80aDeC1e1A3541860F876600;
    } else if(remainder==7){
      return 0x370301AE4659D2975be9F976011c787EC59e0645;
    } else if(remainder==8){
      return 0x2C041b6A7fF277966cB0b4cb966aaB8Fc1178ac5;
    }else {
      return 0x8A401290A39Dc8D046e42BABaf5a818e29ae4fda;
    }
  }

   
  function finalize() public onlyOwner {
     
    assert(crowdsaleStatus==1 && crowdSaleType==1);
     
      assert(!((totalSupplyCrowdsale < maxCap && now < endBlock) && (maxCap.Sub(totalSupplyCrowdsale) >= valueOneEther)));  
       
      
       
      if (totalSupply < 5300000e18)
        refundStatus = 2;
      else
        refundStatus = 1;
      
     
    crowdsaleStatus = 2;
     
    StateChanged(true);
  }

   
  function refund() public onlyOwner {
      assert(refundStatus == 2);
      uint batchSize = countInvestorsRefunded.Add(50) < countTotalInvestors ? countInvestorsRefunded.Add(50): countTotalInvestors;
      for(uint i=countInvestorsRefunded.Add(1); i <= batchSize; i++){
          address investorAddress = investorList[i];
          Investor storage investorStruct = investors[investorAddress];
           
          if(investorStruct.exhSentCrowdsaleType1 > 0 && investorStruct.exhSentCrowdsaleType1 <= balances[investorAddress]){
               
              investorAddress.transfer(investorStruct.weiReceivedCrowdsaleType1);
               
              ETHReceived = ETHReceived.Sub(investorStruct.weiReceivedCrowdsaleType1);
               
              totalSupply = totalSupply.Sub(investorStruct.exhSentCrowdsaleType1);
               
              balances[investorAddress] = balances[investorAddress].Sub(investorStruct.exhSentCrowdsaleType1);
               
              investorStruct.weiReceivedCrowdsaleType1 = 0;
              investorStruct.exhSentCrowdsaleType1 = 0;
              countInvestorsRefundedInCrowdsale = countInvestorsRefundedInCrowdsale.Add(1);
          }
      }
       
      countInvestorsRefunded = batchSize;
      StateChanged(true);
  }

   
  function drain() public onlyOwner {
    GetEXHFundAccount().transfer(this.balance);
  }

   
  function fundContractForRefund() payable{
     
  }

}