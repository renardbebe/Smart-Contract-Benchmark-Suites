 

pragma solidity ^0.4.11;

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract ERC20Basic {

  uint256 public totalSupply;

  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}




 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  uint256 public tokenCapped = 0;   


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
 
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    require(totalSupply.add(_amount) <= tokenCapped);
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


 
contract AvalonToken is MintableToken {
  string public constant name = "Avalon";
  string public constant symbol = "AVA";
  uint public constant decimals = 4;
 
  function AvalonToken() {
     tokenCapped = 100000000000;  

      

      
     mint(0x993ca291697eb994e17a1f0dbe9053d57b8aec8e,87000000000);

      
     mint(0x94325b00aeebdac34373ee7e15f899d51a17af42,650000000);
     mint(0x6720919702089684870d4afd0f5175c77f82c051,650000000);
     mint(0x77c3ff7ee29896943fd99d0339a67bae5762234c,650000000);
     mint(0x66585aafe1dcf5c4a382f55551a8efbb93b023b3,650000000);
     mint(0x13adbcbaf8da7f85fc3c7fd2e4e08bc6afcb59f3,650000000);
     mint(0x2f7444f6bdbc5ff4adc310e08ed8e2d288cbf81f,650000000);
     mint(0xb88f5ae2d3afcc057359a678d745fb6e7d9d4567,650000000);
     mint(0x21df7143f56e71c2c49c7ecc585fa88d70bd3d11,650000000);
     mint(0xb4e3603b879f152766e8f58829dae173a048f6da,650000000);
     mint(0xf58184d03575d5f8be93839adca9e0ed5280d4a8,650000000);
     mint(0x313d17995920f4d1349c1c6aaeacc6b5002cc4c2,650000000);
     mint(0xdbf062603dd285ec3e4b4fab97ecde7238bd3ee4,650000000);
     mint(0x6047c67e3c7bcbb8e909f4d8ae03631ec9b94dab,650000000);
     mint(0x0871ea40312df5e72bb6bde14973deddab17cf15,650000000);
     mint(0xc321024cfb029bcde6d6a541553e1b262e95f834,650000000);
     mint(0x1247e829e74ad09b0bb1a95830efacebfa7f472b,650000000);
     mint(0x04ff81425d96f12eaae5f320e2bd4e0c5d2d575a,650000000);
     mint(0xbc1425541f61958954cfd31843bd9f6c15319c66,650000000);
     mint(0xd890ab57fbd2724ae28a02108c29c191590e1045,650000000);
     mint(0xf741f6a1d992cd8cc9cbec871c7dc4ed4d683376,650000000);

     finishMinting();  
  } 
}