 

pragma solidity ^0.4.15;

library SafeMathLib {

  function times(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function minus(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }

  function divide(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

}

 
contract Owned {
    address public owner;

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function Owned() public { owner = msg.sender;}

     
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
        NewOwner(msg.sender, _newOwner);
    }

    event NewOwner(address indexed oldOwner, address indexed newOwner);
}

  
contract DadaPresaleFundCollector is Owned {

  using SafeMathLib for uint;

  address public presaleAddressAmountHolder = 0xF636c93F98588b7F1624C8EC4087702E5BE876b6;

   
  mapping(address => uint) public balances;

   
  uint constant maximumIndividualCap = 500 ether;
   
  uint constant etherCap = 3000 ether;

   
  bool public moving;

   
  bool public isExecutionAllowed;

   
  bool public isRefundAllowed;
  
   
   
  bool public isCapReached;

  bool public isFinalized;

  mapping (address => bool) public whitelist;

  event Invested(address investor, uint value);
  event Refunded(address investor, uint value);
  event WhitelistUpdated(address whitelistedAddress, bool isWhitelisted);
  event EmptiedToWallet(address wallet);

   
  function DadaPresaleFundCollector() public {

  }

   
  function updateWhitelist(address whitelistedAddress, bool isWhitelisted) public onlyOwner {
    whitelist[whitelistedAddress] = isWhitelisted;
    WhitelistUpdated(whitelistedAddress, isWhitelisted);
  }

   
  function invest() public payable {
     
    require(isExecutionAllowed);
     
    require(!isCapReached);
     
     
    uint currentBalance = this.balance;
    require(currentBalance <= etherCap);

     
    require(!moving);
    address investor = msg.sender;
     
    require(whitelist[investor]);
    
     
    require((balances[investor].plus(msg.value)) <= maximumIndividualCap);

    require(msg.value <= maximumIndividualCap);
    balances[investor] = balances[investor].plus(msg.value);
     
    if (currentBalance == etherCap){
      isCapReached = true;
    }
    Invested(investor, msg.value);
  }

   
  function refund() public {
    require(isRefundAllowed);
    address investor = msg.sender;
    require(this.balance > 0);
    require(balances[investor] > 0);
     
    moving = true;
    uint amount = balances[investor];
    balances[investor] = 0;
    investor.transfer(amount);
    Refunded(investor, amount);
  }

   
  function emptyToWallet() public onlyOwner {
    require(!isFinalized);
    isFinalized = true;
    moving = true;
    presaleAddressAmountHolder.transfer(this.balance);
    EmptiedToWallet(presaleAddressAmountHolder); 
  }  

  function flipExecutionSwitchTo(bool state) public onlyOwner{
    isExecutionAllowed = state;
  }

  function flipCapSwitchTo(bool state) public onlyOwner{
    isCapReached = state;
  }

  function flipRefundSwitchTo(bool state) public onlyOwner{
    isRefundAllowed = state;
  }

  function flipFinalizedSwitchTo(bool state) public onlyOwner{
    isFinalized = state;
  }

  function flipMovingSwitchTo(bool state) public onlyOwner{
    moving = state;
  }  

   
  function() public payable {
    revert();
  }
}