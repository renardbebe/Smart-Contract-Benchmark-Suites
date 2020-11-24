 

pragma solidity ^0.4.18;

 
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

contract Token {
   
  function totalSupply() public constant returns (uint256 supply);

   
   
  function balanceOf(address _owner) public constant returns (uint256 balance);

   
   
   
   
  function transfer(address _to, uint256 _value) public returns (bool success);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

   
   
   
   
  function approve(address _spender, uint256 _value) public returns (bool success);

   
   
   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

 
contract Ownable {
    
  address public owner;

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}
contract Gateway is Ownable{
    using SafeMath for uint;
    address public feeAccount1 = 0xec2c6cf5f919e538975e6c58dfa315b803223ce2;  
    address public feeAccount2 = 0xec2c6cf5f919e538975e6c58dfa315b803223ce2;  
    
    struct BuyInfo {
      address buyerAddress; 
      address sellerAddress;
      uint value;
      address currency;
    }
    
    mapping(address => mapping(uint => BuyInfo)) public payment;
   
    mapping(address => uint) public balances;
    uint balanceFee;
    uint public feePercent;
    uint public maxFee;
    constructor() public{
       feePercent = 1500000;  
       maxFee = 3000000;  
    }
    
    
    function getBuyerAddressPayment(address _sellerAddress, uint _orderId) public constant returns(address){
      return  payment[_sellerAddress][_orderId].buyerAddress;
    }    
    function getSellerAddressPayment(address _sellerAddress, uint _orderId) public constant returns(address){
      return  payment[_sellerAddress][_orderId].sellerAddress;
    }    
    
    function getValuePayment(address _sellerAddress, uint _orderId) public constant returns(uint){
      return  payment[_sellerAddress][_orderId].value;
    }    
    
    function getCurrencyPayment(address _sellerAddress, uint _orderId) public constant returns(address){
      return  payment[_sellerAddress][_orderId].currency;
    }
    
    
    function setFeeAccount1(address _feeAccount1) onlyOwner public{
      feeAccount1 = _feeAccount1;  
    }
    function setFeeAccount2(address _feeAccount2) onlyOwner public{
      feeAccount2 = _feeAccount2;  
    }
    function setFeePercent(uint _feePercent) onlyOwner public{
      require(_feePercent <= maxFee);
      feePercent = _feePercent;  
    }    
    function payToken(address _tokenAddress, address _sellerAddress, uint _orderId,  uint _value) public returns (bool success){
      require(_tokenAddress != address(0));
      require(_sellerAddress != address(0)); 
      require(_value > 0);
      Token token = Token(_tokenAddress);
      require(token.allowance(msg.sender, this) >= _value);
      token.transferFrom(msg.sender, _sellerAddress, _value);
      payment[_sellerAddress][_orderId] = BuyInfo(msg.sender, _sellerAddress, _value, _tokenAddress);
      success = true;
    }
    function payEth(address _sellerAddress, uint _orderId, uint _value) public returns  (bool success){
      require(_sellerAddress != address(0)); 
      require(_value > 0);
      require(balances[msg.sender] >= _value);
      uint fee = _value.mul(feePercent).div(100000000);
      balances[msg.sender] = balances[msg.sender].sub(_value);
      _sellerAddress.transfer(_value.sub(fee));
      balanceFee = balanceFee.add(fee);
      payment[_sellerAddress][_orderId] = BuyInfo(msg.sender, _sellerAddress, _value, 0x0000000000000000000000000000000000000001);    
      success = true;
    }
    function transferFee() onlyOwner public{
      uint valfee1 = balanceFee.div(2);
      feeAccount1.transfer(valfee1);
      balanceFee = balanceFee.sub(valfee1);
      feeAccount2.transfer(balanceFee);
      balanceFee = 0;
    }
    function balanceOfToken(address _tokenAddress, address _Address) public constant returns (uint) {
      Token token = Token(_tokenAddress);
      return token.balanceOf(_Address);
    }
    function balanceOfEthFee() public constant returns (uint) {
      return balanceFee;
    }
    function refund() public{
      require(balances[msg.sender] > 0);
      uint value = balances[msg.sender];
      balances[msg.sender] = 0;
      msg.sender.transfer(value);
    }
    function getBalanceEth() public constant returns(uint){
      return balances[msg.sender];    
    }
    function() external payable {
      balances[msg.sender] = balances[msg.sender].add(msg.value);    
  }
}