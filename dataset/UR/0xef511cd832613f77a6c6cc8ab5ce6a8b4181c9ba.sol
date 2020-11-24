 

pragma solidity ^0.4.13;

 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract ICOBuyer {

   
  address public developer = 0xF23B127Ff5a6a8b60CC4cbF937e5683315894DDA;
   
  address public sale = 0x0;
   
  ERC20 public token;
  
   
  function set_addresses(address _sale, address _token) {
     
    require(msg.sender == developer);
     
     
    sale = _sale;
    token = ERC20(_token);
  }
  
  
   

  
  function withdrawToken(address _token){
      require(msg.sender == developer);
      require(token.transfer(developer, ERC20(_token).balanceOf(address(this))));
  }
  
  function withdrawETH(){
      require(msg.sender == developer);
      developer.transfer(this.balance);
  }
  
   
  function buy(){
    require(sale != 0x0);
    require(sale.call.value(this.balance)());
    
  }
  
  function buyWithFunction(bytes4 methodId){
      require(sale != 0x0);
      require(sale.call.value(this.balance)(methodId));
  }
  
  function buyWithAddress(address _ICO){
      require(msg.sender == developer);
      require(_ICO != 0x0);
      require(_ICO.call.value(this.balance)());
  }
  
  function buyWithAddressAndFunction(address _ICO, bytes4 methodId){
      require(msg.sender == developer);
      require(_ICO != 0x0);
      require(_ICO.call.value(this.balance)(methodId));
  }
  
   
  function () payable {
    
  }
}