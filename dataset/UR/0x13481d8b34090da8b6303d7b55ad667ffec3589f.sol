 

pragma solidity ^0.4.25;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

  function toUINT112(uint256 a) internal pure returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal pure returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal pure returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping(address => uint256) restricts;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    require(restricts[msg.sender] <= now);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract F1ZZToken is BasicToken {

  string public constant name = "F1ZZToken";
  string public constant symbol = "FZZ";
  uint8 public constant decimals = 18;


  uint256 public constant INITIAL_SUPPLY = 35000000000 * (10 ** uint256(decimals));
  
  constructor() public {
    totalSupply = INITIAL_SUPPLY;

    balances[0xB5CaD809c5c4A6825249a0b7d6260D3A8144c254] = 875000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0xB5CaD809c5c4A6825249a0b7d6260D3A8144c254, 875000000 * (10 ** uint256(decimals)));

    balances[0x4Ac2410C1Ed6651F44A361EcCc8D8Fd9554F24A3] = 1750000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0x4Ac2410C1Ed6651F44A361EcCc8D8Fd9554F24A3, 1750000000 * (10 ** uint256(decimals)));

    balances[0xa79F051Beb3b9700b3417570D37FC20D540abef8] = 875000000  * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0xa79F051Beb3b9700b3417570D37FC20D540abef8, 875000000 * (10 ** uint256(decimals)));


    balances[0x2b0301De52848E0886521e58250CF887383201f4] = 250000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0x2b0301De52848E0886521e58250CF887383201f4, 250000000 * (10 ** uint256(decimals)));


    balances[0x86453BCA8d8a0a5Ba88ab3700d5CD4545039d5C6] = 875000000  * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0x86453BCA8d8a0a5Ba88ab3700d5CD4545039d5C6, 875000000 * (10 ** uint256(decimals)));


    balances[0x709292Fc5d5a31d9E679bbbd19DE652a8AcB6D29] = 1500000000  * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0x709292Fc5d5a31d9E679bbbd19DE652a8AcB6D29, 1500000000 * (10 ** uint256(decimals)));

    balances[0x4D8c85780e913B551cbA382e191D09456F5A2cb2] = 7000000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0x4D8c85780e913B551cbA382e191D09456F5A2cb2, 7000000000 * (10 ** uint256(decimals)));

    balances[0x035Fef4499d61abcEfEd458B5a9621586349F94e] = 1750000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0x035Fef4499d61abcEfEd458B5a9621586349F94e, 1750000000 * (10 ** uint256(decimals)));

    balances[0x2b5D5A25E88187Ee03174f267395198EDC8fCD3A] = 5250000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0x2b5D5A25E88187Ee03174f267395198EDC8fCD3A, 5250000000 * (10 ** uint256(decimals)));


    balances[0xfA08d0db631dc6c50a51a198e9EE0A7839BBa873] = 3500000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0xfA08d0db631dc6c50a51a198e9EE0A7839BBa873, 3500000000 * (10 ** uint256(decimals)));


    balances[0x6EB8376F0B044Cad3168E189362B9d3484aEd295] = 2625000000 * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0x6EB8376F0B044Cad3168E189362B9d3484aEd295, 2625000000 * (10 ** uint256(decimals)));

    balances[0xba44f101579401d6F80C4C5b04c65fB5447FBDc8] = 5250000000  * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0xba44f101579401d6F80C4C5b04c65fB5447FBDc8, 5250000000 * (10 ** uint256(decimals)));

    balances[0x54A153f12B8701e7A4ee7622747E4efc7f04533c] = 3500000000  * (10 ** uint256(decimals));
    emit Transfer(msg.sender, 0x54A153f12B8701e7A4ee7622747E4efc7f04533c, 3500000000 * (10 ** uint256(decimals)));

     

    restricts[0x2b0301De52848E0886521e58250CF887383201f4] = now + 104 days;

    restricts[0x86453BCA8d8a0a5Ba88ab3700d5CD4545039d5C6] = now + 134 days;
    restricts[0x709292Fc5d5a31d9E679bbbd19DE652a8AcB6D29] = now + 134 days;
    restricts[0x4D8c85780e913B551cbA382e191D09456F5A2cb2] = now + 134 days;
    restricts[0x035Fef4499d61abcEfEd458B5a9621586349F94e] = now + 134 days;
    restricts[0x2b5D5A25E88187Ee03174f267395198EDC8fCD3A] = now + 134 days;
    restricts[0xfA08d0db631dc6c50a51a198e9EE0A7839BBa873] = now + 134 days;
    restricts[0x6EB8376F0B044Cad3168E189362B9d3484aEd295] = now + 134 days;
    restricts[0xba44f101579401d6F80C4C5b04c65fB5447FBDc8] = now + 134 days;
    restricts[0x54A153f12B8701e7A4ee7622747E4efc7f04533c] = now + 134 days;
  }

}