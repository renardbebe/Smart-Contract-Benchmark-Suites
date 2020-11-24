 

pragma solidity ^0.4.13;

 

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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract UTNP is BasicToken, BurnableToken, ERC20, Ownable {

    string public constant name = "UTN-P: Universa Token";
    string public constant symbol = "UTNP";
    uint8 public constant decimals = 18;
    string public constant version = "1.0";

    uint256 constant INITIAL_SUPPLY_UTN = 4997891952;

     
    mapping(address => bool) public isBurner;

     
    function UTNP() public {
        totalSupply = INITIAL_SUPPLY_UTN * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;

        isBurner[msg.sender] = true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        return false;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        return false;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return 0;
    }

     
    function grantBurner(address _burner, bool _value) public onlyOwner {
        isBurner[_burner] = _value;
    }

     
    modifier onlyBurner() {
        require(isBurner[msg.sender]);
        _;
    }

     
    function burn(uint256 _value) public onlyBurner {
        super.burn(_value);
    }
}