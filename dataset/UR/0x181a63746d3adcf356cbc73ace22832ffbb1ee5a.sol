 

pragma solidity ^0.4.16;



   
   

   
   





 
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


contract ERC20 {
  uint256 public constant totalSupply=100000000000000;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract Alaricoin is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

     
  string public constant name= "Alaricoin";
  string public constant symbol= "ALCO";
  string public constant image="https://alaricoin.org/wp-content/alco.png";
  string public constant x="MzksMjkyMjAyLzE2LDI1OTE3Mw==";
  uint8 public constant decimals = 8;

  function Alaricoin() {

       
      balances[0x5932cbb7Cc02cf0D811a33dAa8d818f0441b8457]=100000 * 10 ** 8;
      
       
      balances[0x45d9927B6938b193B9E733F021DeCdaE8b582Ac4]=7000 * 10 ** 8;
      balances[0x7195794b15747dD589747C6200194be6B56c1BF3]=6000 * 10 ** 8;
      balances[0x59bdeAf328FBF3aeD6f6c3c874a32D6a46a1ACcf]=6000 * 10 ** 8;
      balances[0x85afD9d575dB33F5C16E10c0eAd2519f4215ed95]=6000 * 10 ** 8;
      balances[0x2E429e4Ddd2D494fA2708e6611429DE589303510]=5000 * 10 ** 8;
      balances[0x17074c2480882Ad1AD53614Ab3907789108d919E]=5000 * 10 ** 8;
      balances[0x4c6e580B8366180D3D2Ed6E338eDBB50d10edF82]=3000 * 10 ** 8;
      balances[0x839Ab10cE6Efbaa4F38d25c913Af6C438CD2b1B9]=3000 * 10 ** 8;
      balances[0x4C3C0053B9947d3005E31eAd0042Ab3a7C6e3Ef3]=3000 * 10 ** 8;
      balances[0xACf858ec7301024C37C2bAaCabF1cdD691AF99e1]=3000 * 10 ** 8;
      balances[0xb37FA525222180654DAe96ca1Ad15ECeB3595cF7]=3000 * 10 ** 8;


       
      balances[0x09Ad487Ba5Be982d64097faf19583Ad8DeaA016e]=85000 * 10 ** 8;
      balances[0xBFc59C104bD16E84d016eFA4B34Ea47ee216C982]=85000 * 10 ** 8;
      balances[0x6e542BA667A8feD6e6d1e2cd741F7a8a156b07D3]=85000 * 10 ** 8;
      balances[0x5E1A8Ab18BC7D28da9e13491585DF8b0160F99cC]=85000 * 10 ** 8;
      balances[0x793064E86b4b274BdbEF672e8EaAeB87517FfDeC]=85000 * 10 ** 8;
      balances[0x1Fd7772Fb2Bf826fAc26566efE2624aAd664C8e9]=85000 * 10 ** 8;
      balances[0x57f7D077ff04cA5A6e65948c938657D0Ed57603A]=85000 * 10 ** 8;
      balances[0xA5C54614198063eD9807BB4802d70108402CeDa1]=85000 * 10 ** 8;
      balances[0x7bbFF0b5F17d1eC947070AE104eecD56396bb4D4]=85000 * 10 ** 8;
      balances[0x690bB68fFF6938Da706A240320Fba0933C5864B5]=85000 * 10 ** 8;
    
  }


   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

     
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}