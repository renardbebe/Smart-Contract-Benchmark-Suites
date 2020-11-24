 

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



 
contract AirDrop is OwnableWithAdmin {
  using SafeMath for uint256;

  uint256 private constant DECIMALFACTOR = 10**uint256(18);


  event FundsBooked(address backer, uint256 amount, bool isContribution);
  event LogTokenClaimed(address indexed _recipient, uint256 _amountClaimed, uint256 _totalAllocated, uint256 _grandTotalClaimed);
  event LogNewAllocation(address indexed _recipient, uint256 _totalAllocated);
  event LogRemoveAllocation(address indexed _recipient, uint256 _tokenAmountRemoved);
  event LogOwnerSetAllocation(address indexed _recipient, uint256 _totalAllocated);
  event LogTest();
   

   
  uint256 public grandTotalClaimed = 0;

   
  ERC20 public token;

   
  uint256 public tokensTotal = 0;

   
  uint256 public hardCap = 0;
  


   
  mapping (address => uint256) public allocationsTotal;

   
  mapping (address => uint256) public totalClaimed;


   
  mapping(address => bool) public buyers;

   
  mapping(address => bool) public buyersReceived;

   
  address[] public addresses;
  
 
  constructor(ERC20 _token) public {
     
    require(_token != address(0));

    token = _token;
  }

  
   
  function () public {
     
  }

   
  function setManyAllocations (address[] _recipients, uint256 _tokenAmount) onlyOwnerOrAdmin  public{
    for (uint256 i = 0; i < _recipients.length; i++) {
      setAllocation(_recipients[i],_tokenAmount);
    }    
  }


   
  function setAllocation (address _recipient, uint256 _tokenAmount) onlyOwnerOrAdmin  public{
      require(_tokenAmount > 0);      
      require(_recipient != address(0)); 

       
      require(_validateHardCap(_tokenAmount));

       
      _setAllocation(_recipient, _tokenAmount);    

       
      tokensTotal = tokensTotal.add(_tokenAmount);  

       
      emit LogOwnerSetAllocation(_recipient, _tokenAmount);
  }

   
  function removeAllocation (address _recipient) onlyOwner  public{         
      require(_recipient != address(0)); 
      require(totalClaimed[_recipient] == 0);  


       
      uint256 _tokenAmountRemoved = allocationsTotal[_recipient];

       
      tokensTotal = tokensTotal.sub(_tokenAmountRemoved);

       
      allocationsTotal[_recipient] = 0;
       
       
      buyers[_recipient] = false;

      emit LogRemoveAllocation(_recipient, _tokenAmountRemoved);
  }


  
  function _setAllocation (address _buyer, uint256 _tokenAmount) internal{

      if(!buyers[_buyer]){
         
        buyers[_buyer] = true;

         
        buyersReceived[_buyer] = false;

         
        addresses.push(_buyer);

         
        allocationsTotal[_buyer] = 0;


      }  

       
      allocationsTotal[_buyer]  = allocationsTotal[_buyer].add(_tokenAmount); 


       
      emit LogNewAllocation(_buyer, _tokenAmount);

  }


   
  function checkAvailableTokens (address _recipient) public view returns (uint256) {
     
    require(buyers[_recipient]); 

    return allocationsTotal[_recipient];
  }

   
  function distributeManyTokens(address[] _recipients) onlyOwnerOrAdmin public {
    for (uint256 i = 0; i < _recipients.length; i++) {
      distributeTokens( _recipients[i]);
    }
  }

   
  function withdrawTokens() public {
    distributeTokens(msg.sender);
  }

   
  function distributeTokens(address _recipient) public {
    
     
    require(buyers[_recipient]);

     
     
    buyersReceived[_recipient] = true;

    uint256 _availableTokens = allocationsTotal[_recipient];
     

     
    require(token.balanceOf(this)>=_availableTokens);

     
    require(token.transfer(_recipient, _availableTokens));

     
    totalClaimed[_recipient] = totalClaimed[_recipient].add(_availableTokens);

     
    grandTotalClaimed = grandTotalClaimed.add(_availableTokens);


     
    allocationsTotal[_recipient] = 0;


    emit LogTokenClaimed(_recipient, _availableTokens, allocationsTotal[_recipient], grandTotalClaimed);

    

  }



  function _validateHardCap(uint256 _tokenAmount) internal view returns (bool) {
      return tokensTotal.add(_tokenAmount) <= hardCap;
  }


  function getListOfAddresses() public onlyOwnerOrAdmin view returns (address[]) {    
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



 
contract BYTMAirDrop is AirDrop {
  constructor(   
    ERC20 _token
  ) public AirDrop(_token) {

     
    hardCap = 40000000 * (10**uint256(18)); 

  }
}