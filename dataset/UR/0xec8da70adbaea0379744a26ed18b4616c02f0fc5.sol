 

pragma solidity ^0.4.23;

contract ERC223 {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);

    function name() public constant returns (string _name);
    function symbol() public constant returns (string _symbol);
    function decimals() public constant returns (uint8 _decimals);
    function totalSupply() public constant returns (uint256 _supply);

    function transfer(address to, uint value) public returns (bool _success);
    function transfer(address to, uint value, bytes data) public returns (bool _success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
    event Burn(address indexed _burner, uint256 _value);
}

 
 
contract PeekePrivateTokenCoupon is ERC223 {
    using SafeMath for uint;

    mapping(address => uint) balances;

    string public name    = "Peeke Private Coupon";
    string public symbol  = "PPC-PKE";
    uint8 public decimals = 18;
    uint256 public totalSupply = 155000000 * (10**18);

    constructor(PeekePrivateTokenCoupon) public {
        balances[msg.sender] = totalSupply;
    }

     
    function name() constant public returns (string _name) {
        return name;
    }

     
    function symbol() constant public returns (string _symbol) {
        return symbol;
    }

     
    function decimals() constant public returns (uint8 _decimals) {
        return decimals;
    }

     
    function totalSupply() constant public returns (uint256 _totalSupply) {
        return totalSupply;
    }

     
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

     
     
    function transfer(address _to, uint _value) public returns (bool success) {
         
         
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

     
    function isContract(address _addr) private constant returns (bool is_contract) {
      uint length;
      assembly {
             
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        emit Transfer(msg.sender, _to, _value);
        emit ERC223Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        ContractReceiver reciever = ContractReceiver(_to);
        reciever.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        emit ERC223Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function burn() public {
        uint256 tokens = balances[msg.sender];
        balances[msg.sender] = 0;
        totalSupply = totalSupply.sub(tokens);
        emit Burn(msg.sender, tokens);
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }
}


contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}


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