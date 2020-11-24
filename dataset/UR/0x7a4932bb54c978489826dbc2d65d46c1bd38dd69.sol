 

 

 
contract SafeMath {
  function safeMul(uint a, uint b) internal constant returns (uint) {
    uint c = a * b;

    assert(a == 0 || c / a == b);

    return c;
  }

  function safeDiv(uint a, uint b) internal constant returns (uint) {    
    uint c = a / b;

    return c;
  }

  function safeSub(uint a, uint b) internal constant returns (uint) {
    require(b <= a);

    return a - b;
  }

  function safeAdd(uint a, uint b) internal constant returns (uint) {
    uint c = a + b;

    assert(c>=a && c>=b);

    return c;
  }
}

contract MintInterface {
  function mint(address recipient, uint amount) returns (bool success);
}

 
contract PriceModel {
  function getPrice(uint block) constant returns (uint);
}

contract EtherReceiverInterface {
  function receiveEther() public payable;
}

 
contract CrowdsaleTokens is SafeMath {

  address public tokenContract;  
  address public priceModel;  
  address public vaultAddress;  

   
  uint public crowdsaleStarts;  
  uint public crowdsaleEnds;  

   
  uint public totalCollected;  

   
  uint public tokensIssued;  
  uint public tokenCap;  

  modifier crowdsalePeriod() {
    require(block.number >= crowdsaleStarts && block.number < crowdsaleEnds);

    _;
  }

  function CrowdsaleTokens(
    address _tokenContract,
    address _priceModel,
    address _vaultAddress,
    uint _crowdsaleStarts,
    uint _crowdsaleEnds,
    uint _tokenCap
  ) {
    tokenContract = _tokenContract;
    priceModel = _priceModel;
    vaultAddress = _vaultAddress;
    crowdsaleStarts = _crowdsaleStarts;
    crowdsaleEnds = _crowdsaleEnds;
    tokenCap = _tokenCap;
  }

   
  function() payable {
    buy();
  }

   
   
  function buy() public payable crowdsalePeriod {
     
    uint price = calculatePrice(block.number);

     
    processPurchase(price);
  }

   
   
  function processPurchase(uint price) private {
     
    uint numTokens = safeDiv(safeMul(msg.value, price), 1 ether);

     
    assert(numTokens <= remaining() && remaining() > 0);

     
    totalCollected = safeAdd(totalCollected, msg.value);
    tokensIssued = safeAdd(tokensIssued, numTokens);

     
    EtherReceiverInterface(vaultAddress).receiveEther.value(msg.value)();

     
    if (!MintInterface(tokenContract).mint(msg.sender, numTokens))
      revert();
  }

   
  function calculatePrice(uint block) public constant returns (uint) {
    return PriceModel(priceModel).getPrice(block);
  }

   
  function remaining() public constant returns (uint) {

    return safeSub(tokenCap, tokensIssued);
  }
}