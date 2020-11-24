 

 
pragma solidity ^0.4.21;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
pragma solidity ^0.4.21;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
pragma solidity ^0.4.21;






 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
pragma solidity ^0.4.21;




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
pragma solidity ^0.4.21;





 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
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

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
 
pragma solidity ^0.4.21;





contract ARTIDToken is StandardToken {
    using SafeMath for uint256;
    
    string public constant name = "ARTIDToken";
    string public constant symbol = "ARTID";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 120e6 * 1e18;
    uint256 public constant Wallet_Initial_Supply = 12e6 * 1e18;
    address public constant Wallet1 =address(0x5593105770Cd53802c067734d7e321E22E08C9a4);
     
    address public constant Wallet2 =address(0x7003D8df7b38f4c758975fD4800574Fecc0DA7cd);
     
    address public constant Wallet3 =address(0xDfdAA3B74fcc65b9E90d5922a74F8140A2b67d0f);
     
    address public constant Wallet4 =address(0x0141f8d84F25739e426fd19783A1eC3A1f5a35e0);
     
    address public constant Wallet5 =address(0x8863F676474C65E9B85dc2B7fEe16188503AE790);
     
    address public constant Wallet6 =address(0xAbF2e86c69648E9ed6CD284f4f82dF3f9df7a3DD);
     
    address public constant Wallet7 =address(0x66348c99019D6c21fe7c4f954Fd5A5Cb0b41aa2c);
     
    address public constant Wallet8 =address(0x3257b7eBB5e52c67cdd0C1112b28db362b7463cD);
     
    address public constant Wallet9 =address(0x0c26122396a4Bd59d855f19b69dADBa3B19BA4D7);
     
    address public constant Wallet10=address(0x5b38E7b2C9aC03fA53E96220DCd299E3B47e1624);

     
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[Wallet1] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet1, Wallet_Initial_Supply);
        balances[Wallet2] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet2, Wallet_Initial_Supply);
        balances[Wallet3] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet3, Wallet_Initial_Supply);
        balances[Wallet4] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet4, Wallet_Initial_Supply);
        balances[Wallet5] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet5, Wallet_Initial_Supply);
        balances[Wallet6] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet6, Wallet_Initial_Supply);
        balances[Wallet7] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet7, Wallet_Initial_Supply);
        balances[Wallet8] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet8, Wallet_Initial_Supply);
        balances[Wallet9] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet9, Wallet_Initial_Supply);
        balances[Wallet10] = Wallet_Initial_Supply;
        emit Transfer(0x0, Wallet10, Wallet_Initial_Supply);

    }

}