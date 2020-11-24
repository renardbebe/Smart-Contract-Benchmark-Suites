 

pragma solidity ^0.4.25;

contract SNPToken {

  address admin;
  address admin2=0xa4e81224fC73a9E095809e34f5324aa18fA2a412;

  address saleContractICO=address(0);
  string public name="skynavpro [SNP]";
  string public symbol="SNP";
  uint256 public totalSupply;
  uint endOfICO = 1555323000;  

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
  );

  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping(address => uint256)) public allowance;

  constructor (uint256 _initialSupply) public {
    admin=msg.sender;
    balanceOf[msg.sender]=_initialSupply;
    totalSupply = _initialSupply;
    saleContractICO=address(0);
  }

  function transfer(address _to, uint256 _value) public returns(bool success){
    require(balanceOf[msg.sender]>=_value, "The balance of the sender is not high enough.");

    require((msg.sender == admin) || (msg.sender==admin2) || isTransferAllowedForEverybody()==true, "Tokens can not be traded until the ICO is over.");

    balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);
    balanceOf[_to]=SafeMath.add(balanceOf[_to], _value);

    emit Transfer(msg.sender, _to, _value);

    return true;
  }

  function approve(address _spender, uint256 _value) public returns(bool success) {

    allowance[msg.sender][_spender]=_value;

    emit Approval(msg.sender, _spender, _value);

    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns(bool success){

    require((msg.sender == admin) || (msg.sender==admin2) || isTransferAllowedForEverybody()==true, "Tokens can not be traded until the ICO is over.");

    require(balanceOf[_from]>=_value, "The balance of the sender is not high enough.");
    require(allowance[_from][msg.sender]>=_value, "The allowance is not big enough.");

    allowance[_from][msg.sender]=SafeMath.sub(allowance[_from][msg.sender],_value);
    balanceOf[_from]=SafeMath.sub(balanceOf[_from], _value);
    balanceOf[_to]=SafeMath.add(balanceOf[_to],_value);

    emit Transfer(_from, _to, _value);

    return true;
  }

  function isTransferAllowedForEverybody() private view returns (bool isAllowed) {

    bool isICORunning;

    if (now<endOfICO) {  
      isICORunning=true;
    }
    else {
      isICORunning=false;
    }

    if (msg.sender==saleContractICO) {
      return true;
    }
    else {
      if (isICORunning==true) {
        return false;
      }
      else {
        return true;
      }
    }
  }

  function burnSaleContractTokens(uint256 _value) public {

    require((msg.sender == admin) || (msg.sender==admin2), "Only admins can run this function.");
    require(_value <= balanceOf[saleContractICO], "You can not burn more tokens than the available amount.");

    balanceOf[saleContractICO] = SafeMath.sub(balanceOf[saleContractICO],_value);
    totalSupply = SafeMath.sub(totalSupply, _value);
    emit Transfer(saleContractICO, address(0), _value);
  }

  function setSaleContractICOAddress(address _newSaleContractICO) public {
    require((msg.sender == admin) || (msg.sender==admin2));
    saleContractICO = _newSaleContractICO;
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
}