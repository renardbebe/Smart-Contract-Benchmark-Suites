 

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
      require(c / a == b);

      return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
       
      require(b > 0);
      uint256 c = a / b;
       

      return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b <= a);
      uint256 c = a - b;

      return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a);

      return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b != 0);
      return a % b;
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



 
contract AirDropLight is OwnableWithAdmin {
  using SafeMath for uint256;

  event AirDropFailed(address recipient, uint256 amount);
  
   
  uint256 public grandTotalClaimed = 0;

   
  ERC20 public token;

   
  uint256  maxDirect = 1500 * (10**uint256(18));

   
  mapping(address => bool) public recipients;

   
  address[] public addresses;
   
  constructor(ERC20 _token) public {
     
    require(_token != address(0));

    token = _token;

  }

  
   
  function () public {
     
  }


   
  function transferManyDirect (address[] _recipients, uint256 _tokenAmount) onlyOwnerOrAdmin  public{
    for (uint256 i = 0; i < _recipients.length; i++) {
      
      if(!recipients[_recipients[i]] && _tokenAmount < maxDirect){        
        transferDirect(_recipients[i],_tokenAmount);
      }else{
        emit AirDropFailed(_recipients[i], _tokenAmount);
      }
      
    }    
  }

        
   
  function transferDirect(address _recipient,uint256 _tokenAmount) public{

     
    require(token.balanceOf(this)>=_tokenAmount);
    
     
    require(_tokenAmount < maxDirect );

     
     
    require(!recipients[_recipient]); 
    recipients[_recipient] = true;
  
     
    require(token.transfer(_recipient, _tokenAmount));

     
    grandTotalClaimed = grandTotalClaimed.add(_tokenAmount);


     
     
     
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



 
contract BNXAirDropLight is AirDropLight {
  constructor(   
    ERC20 _token
  ) public AirDropLight(_token) {

     

  }
}