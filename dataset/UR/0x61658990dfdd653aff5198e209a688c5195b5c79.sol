 

pragma solidity ^0.4.24;
 
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


contract CryptoTrader {
 using SafeMath for uint256;
 mapping(address => uint256) balances;  
 mapping (address => mapping (address => uint256)) internal allowed;
 mapping (address => uint256) public ETHBalance;  

 uint256 public totalSupply;  
 address public contract_owner_address;

 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed buyer, uint256 value);
 event Burn(address indexed burner, uint256 value);

 string public constant name = "Digital Humanity Token";
 string public constant symbol = "DHT";
 uint8 public decimals = 0;
 uint public start_sale = 1537952400;  
 uint public presalePeriod = 61;  
 address public affiliateAddress ;

 uint public maxAmountPresale_USD = 40000000;  
 uint public soldAmount_USD = 0;  


  
 constructor (
     uint256 initialSupply,
     address _affiliateAddress
 ) public {
     totalSupply = initialSupply;
     affiliateAddress = _affiliateAddress;
     contract_owner_address = msg.sender;
     balances[contract_owner_address] = getPercent(totalSupply,75);  
     balances[affiliateAddress] = getPercent(totalSupply,25);  
 }

  
 function approve(address _buyer, uint256 _value) public returns (bool) {
     allowed[msg.sender][_buyer] = _value;
     emit Approval(msg.sender, _buyer, _value);
     return true;
 }

  
 function allowance(address _owner, address _buyer) public view returns (uint256) {
     return allowed[_owner][_buyer];
 }

  
 function balanceOf(address _owner) public view returns (uint256 balance) {
     return balances[_owner];
 }

  
 function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
     require(_to != address(0));
     require(_value <= balances[_from]);
     require(_value <= allowed[_from][msg.sender]);

     balances[_from] = balances[_from].sub(_value);
     balances[_to] = balances[_to].add(_value);
     allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
     emit Transfer(_from, _to, _value);
     return true;
 }

  
 
 function transfer(address _to, uint256 _value) public returns (bool) {
     require(_to != address(0));
     require(_value <= balances[msg.sender]);

      
     balances[msg.sender] = balances[msg.sender].sub(_value);
     balances[_to] = balances[_to].add(_value);
     emit Transfer(msg.sender, _to, _value);
     return true;
 }

  
 
 function transferSale(address _to, uint256 _value, uint256 _eth_price, uint256 _usd_amount) public  returns (bool success) {
     transfer(_to, _value);
     ETHBalance[_to] = ETHBalance[_to].add(_eth_price);
     soldAmount_USD += _usd_amount;
     return true;
 }

  
 
 function burn(uint256 _value) public {
     require(_value <= balances[msg.sender]);
     address burner = msg.sender;
     balances[burner] = balances[burner].sub(_value);
     totalSupply = totalSupply.sub(_value);
     emit Burn(burner, _value);
 }

  
 
 function refund(address _to) public payable returns(bool){
     require(address(this).balance > 0);
     uint256 _value = balances[_to];
     uint256 ether_value = ETHBalance[_to];
     require(now > start_sale + presalePeriod * 1 days && soldAmount_USD < maxAmountPresale_USD);
     require(_value > 0);
     require(ether_value > 0);
     balances[_to] = balances[_to].sub(_value);
     balances[contract_owner_address] = balances[contract_owner_address].add(_value);
     ETHBalance[_to] = 0;
     approve(_to, ether_value);
     address(_to).transfer(ether_value);
     return true;
 }

  
 
 function depositContrac(uint256 _value) public payable returns(bool){
     approve(address(this), _value);
     return  address(this).send(_value);
 }

 function getPercent(uint _value, uint _percent) internal pure returns(uint quotient){
     uint _quotient = _value.mul(_percent).div(100);
     return ( _quotient);
 }
}