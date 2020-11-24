 

pragma solidity ^0.4.24;


 
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract OwnableWithAdmin {
  address public owner;
  address public adminOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  constructor() public {
    owner = msg.sender;
    adminOwner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier onlyAdmin() {
    require(msg.sender == adminOwner);
    _;
  }

   
  modifier onlyOwnerOrAdmin() {
    require(msg.sender == adminOwner || msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function transferAdminOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(adminOwner, newOwner);
    adminOwner = newOwner;
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

  function uint2str(uint i) internal pure returns (string){
      if (i == 0) return "0";
      uint j = i;
      uint length;
      while (j != 0){
          length++;
          j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint k = length - 1;
      while (i != 0){
          bstr[k--] = byte(48 + i % 10);
          i /= 10;
      }
      return string(bstr);
  }
 
  
}


 
contract LockedPrivatesale is OwnableWithAdmin {
  using SafeMath for uint256;

  uint256 private constant DECIMALFACTOR = 10**uint256(18);


  event FundsBooked(address backer, uint256 amount, bool isContribution);
  event LogTokenClaimed(address indexed _recipient, uint256 _amountClaimed, uint256 _totalAllocated, uint256 _grandTotalClaimed);
  event LogNewAllocation(address indexed _recipient, uint256 _totalAllocated);
  event LogRemoveAllocation(address indexed _recipient, uint256 _tokenAmountRemoved);
  event LogOwnerAllocation(address indexed _recipient, uint256 _totalAllocated);
   

   
  uint256 public grandTotalClaimed = 0;

   
  ERC20 public token;

   
  uint256 public tokensTotal = 0;

   
  uint256 public hardCap = 0;
  

   
  uint256 public step1;
  uint256 public step2;
  uint256 public step3;

   
  mapping (address => uint256) public allocationsTotal;

   
  mapping (address => uint256) public totalClaimed;

   
  mapping (address => uint256) public allocations1;

   
  mapping (address => uint256) public allocations2;

   
  mapping (address => uint256) public allocations3;

   
  mapping(address => bool) public buyers;

   
  mapping(address => bool) public buyersReceived;

   
  address[] public addresses;
  
 
  constructor(uint256 _step1, uint256 _step2, uint256 _step3, ERC20 _token) public {
     
    require(_token != address(0));

    require(_step1 >= now);
    require(_step2 >= _step1);
    require(_step3 >= _step2);

    step1       = _step1;
    step2       = _step2;
    step3       = _step3;

    token = _token;
  }

  
   
  function () public {
     
  }



   
  function setAllocation (address _recipient, uint256 _tokenAmount) onlyOwnerOrAdmin  public{
      require(_tokenAmount > 0);      
      require(_recipient != address(0)); 

       
      require(_validateHardCap(_tokenAmount));

       
      _setAllocation(_recipient, _tokenAmount);    

       
      tokensTotal = tokensTotal.add(_tokenAmount);  

       
      emit LogOwnerAllocation(_recipient, _tokenAmount);
  }

   
  function removeAllocation (address _recipient) onlyOwner  public{         
      require(_recipient != address(0)); 
      require(totalClaimed[_recipient] == 0);  


       
      uint256 _tokenAmountRemoved = allocationsTotal[_recipient];

       
      tokensTotal = tokensTotal.sub(_tokenAmountRemoved);

       
      allocations1[_recipient]      = 0; 
      allocations2[_recipient]      = 0; 
      allocations3[_recipient]      = 0;
      allocationsTotal[_recipient]  = 0;  
      
       
      buyers[_recipient] = false;

      emit LogRemoveAllocation(_recipient, _tokenAmountRemoved);
  }


  
  function _setAllocation (address _buyer, uint256 _tokenAmount) internal{

      if(!buyers[_buyer]){
         
        buyers[_buyer] = true;

         
        addresses.push(_buyer);

         
        allocationsTotal[_buyer] = 0;

      }  

       
      allocationsTotal[_buyer]  = allocationsTotal[_buyer].add(_tokenAmount); 

       
      uint256 splitAmount = allocationsTotal[_buyer].div(3);
      uint256 diff        = allocationsTotal[_buyer].sub(splitAmount+splitAmount+splitAmount);


       
      allocations1[_buyer]   = splitAmount;             
      allocations2[_buyer]   = splitAmount;             
      allocations3[_buyer]   = splitAmount.add(diff);   


       
      emit LogNewAllocation(_buyer, _tokenAmount);

  }


   
  function checkAvailableTokens (address _recipient) public view returns (uint256) {
     
    require(buyers[_recipient]);

    uint256 _availableTokens = 0;

    if(now >= step1){
      _availableTokens = _availableTokens.add(allocations1[_recipient]);
    }
    if(now >= step2){
      _availableTokens = _availableTokens.add(allocations2[_recipient]);
    }
    if(now >= step3){
      _availableTokens = _availableTokens.add(allocations3[_recipient]);
    }

    return _availableTokens;
  }

   
  function distributeManyTokens(address[] _recipients) onlyOwnerOrAdmin public {
    for (uint256 i = 0; i < _recipients.length; i++) {

       
       
      if(buyers[_recipients[i]] && !buyersReceived[_recipients[i]]){
        distributeTokens( _recipients[i]);
      }
    }
  }


   
  function distributeAllTokens() onlyOwner public {
    for (uint256 i = 0; i < addresses.length; i++) {

       
       
      if(buyers[addresses[i]] && !buyersReceived[addresses[i]]){
        distributeTokens( addresses[i]);
      }
            
    }
  }

   
  function withdrawTokens() public {
    distributeTokens(msg.sender);
  }

   
  function distributeTokens(address _recipient) public {
     
    require(now >= step1);
     
    require(buyers[_recipient]);

     
    bool _lastWithdraw = false;

    uint256 _availableTokens = 0;
    
    if(now >= step1  && now >= step2  && now >= step3 ){      

      _availableTokens = _availableTokens.add(allocations3[_recipient]); 
      _availableTokens = _availableTokens.add(allocations2[_recipient]);
      _availableTokens = _availableTokens.add(allocations1[_recipient]);

       
      allocations3[_recipient] = 0;
      allocations2[_recipient] = 0;
      allocations1[_recipient] = 0;

       
      _lastWithdraw = true;


    } else if(now >= step1  && now >= step2 ){
      
      _availableTokens = _availableTokens.add(allocations2[_recipient]);
      _availableTokens = _availableTokens.add(allocations1[_recipient]); 

       
      allocations2[_recipient] = 0;
      allocations1[_recipient] = 0;


    }else if(now >= step1){

      _availableTokens = allocations1[_recipient];

       
      allocations1[_recipient] = 0; 


    }

    require(_availableTokens>0);    

     
    require(token.balanceOf(this)>=_availableTokens);

     
    require(token.transfer(_recipient, _availableTokens));

     
    totalClaimed[_recipient] = totalClaimed[_recipient].add(_availableTokens);

     
    grandTotalClaimed = grandTotalClaimed.add(_availableTokens);

    emit LogTokenClaimed(_recipient, _availableTokens, allocationsTotal[_recipient], grandTotalClaimed);

     
     
    if(_lastWithdraw){
      buyersReceived[_recipient] = true;
    }

  }



  function _validateHardCap(uint256 _tokenAmount) internal view returns (bool) {
      return tokensTotal.add(_tokenAmount) <= hardCap;
  }


  function getListOfAddresses() public view returns (address[]) {    
    return addresses;
  }


   
  function returnTokens() public onlyOwner {
    uint256 balance = token.balanceOf(this);
    require(token.transfer(owner, balance));
  }

   
  function refundTokens(address _recipient, ERC20 _token) public onlyOwner {
    uint256 balance = _token.balanceOf(this);
    require(_token.transfer(_recipient, balance));
  }


}


 
contract EDPrivateSale is LockedPrivatesale {
  constructor(
    uint256 _step1, 
    uint256 _step2, 
    uint256 _step3,    
    ERC20 _token
  ) public LockedPrivatesale(_step1, _step2, _step3, _token) {

     
    hardCap = 50000000 * (10**uint256(18)); 

  }
}