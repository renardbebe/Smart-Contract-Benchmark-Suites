 

pragma solidity 0.4.23;

contract ERC223Interface {
    function transfer(address _to, uint _value, bytes _data) external;
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes indexed _data);
}

  

contract ERC223ReceivingContract {
 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract ERC20Interface {

     
     
     
     
    function transfer(address _to, uint _value) external returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);

     
     
     
     
    function approve(address _spender, uint _value) external returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) external constant returns (uint remaining);

     
    function totalSupply() external constant returns (uint supply);

     
     
    function balanceOf(address _owner) external constant returns (uint balance);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal pure {
        require(assertion);
    }
}

contract ERC20Token is ERC20Interface {
    using SafeMath for uint;

    uint public totalSupply;

    mapping (address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowed;

    function transfer(address _to, uint _value) external returns (bool success) {
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function totalSupply() external constant returns (uint) {
        return totalSupply;
    }

    function balanceOf(address _owner) external constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}


contract ERC223Token is ERC20Token, ERC223Interface {
    using SafeMath for uint;

     
    function transfer(address _to, uint _value, bytes _data) external {
         
         
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
    }
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
 
 
 
 
 
 
 
 
 
contract PayBlokToken is ERC223Token, Ownable {
    using SafeMath for uint;

    string public symbol;
    string public name;
    address public contractOwner;
    uint8 public decimals;

     
     
     
    constructor() public {
        symbol = "PBLK";
        name = "PayBlok";
        decimals = 18;
        totalSupply = 250000000000000000000000000;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public onlyOwner {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);

        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}