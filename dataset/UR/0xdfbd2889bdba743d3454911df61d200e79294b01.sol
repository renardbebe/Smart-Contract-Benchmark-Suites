 

pragma solidity ^0.4.21;

 

contract ERC20Interface {
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool ok);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool ok);
    function approve(address _spender, uint256 _value) public returns (bool ok);
    function allowance(address _owner, address _spender) public constant returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 
library SafeMath {
    function multiply(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function divide(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

 

contract StandardToken is ERC20Interface {
    using SafeMath for uint256;

     
    mapping(address => uint) balances;
     
    mapping (address => mapping (address => uint)) allowed;

     
    modifier onlyPayloadSize(uint256 size) {
        require(msg.data.length == size + 4);
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool ok) {
        require(_to != address(0));
        require(_value > 0);
        uint256 holderBalance = balances[msg.sender];
        require(_value <= holderBalance);

        balances[msg.sender] = holderBalance.subtract(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool ok) {
        require(_to != address(0));
        uint256 allowToTrans = allowed[_from][msg.sender];
        uint256 balanceFrom = balances[_from];
        require(_value <= balanceFrom);
        require(_value <= allowToTrans);

        balances[_from] = balanceFrom.subtract(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowToTrans.subtract(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool ok) {
         
         
         
         
         
         
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) onlyPayloadSize(2 * 32) public returns (bool ok) {
        uint256 oldValue = allowed[msg.sender][_spender];
        allowed[msg.sender][_spender] = oldValue.add(_addedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) onlyPayloadSize(2 * 32) public returns (bool ok) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.subtract(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

}

 

contract BurnableToken is StandardToken {
     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _holder, uint256 _value) internal {
        require(_value <= balances[_holder]);

        balances[_holder] = balances[_holder].subtract(_value);
        totalSupply = totalSupply.subtract(_value);

        emit Burn(_holder, _value);
        emit Transfer(_holder, address(0), _value);
    }

    event Burn(address indexed _burner, uint256 _value);
}

 

 
contract Ownable {
    address public owner;
    address public newOwner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);

        owner = newOwner;
        newOwner = address(0);

        emit OwnershipTransferred(owner, newOwner);
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);
}

 

contract ERC223Interface is ERC20Interface {
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool ok);

    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes indexed _data);
}

 

contract ERC223ReceivingContract {
     
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

 

contract Standard223Token is ERC223Interface, StandardToken {
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool ok) {
        if (!super.transfer(_to, _value)) {
            revert();
        }
        if (isContract(_to)) {
            contractFallback(msg.sender, _to, _value, _data);
        }

        emit Transfer(msg.sender, _to, _value, _data);

        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool ok) {
        return transfer(_to, _value, new bytes(0));
    }

    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool ok) {
        if (!super.transferFrom(_from, _to, _value)) {
            revert();
        }
        if (isContract(_to)) {
            contractFallback(_from, _to, _value, _data);
        }

        emit Transfer(_from, _to, _value, _data);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool ok) {
        return transferFrom(_from, _to, _value, new bytes(0));
    }

    function contractFallback(address _origin, address _to, uint256 _value, bytes _data) private {
        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(_origin, _value, _data);
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }

        return (length > 0);
    }
}

 

 
 
 
contract ICOToken is BurnableToken, Ownable, Standard223Token {
    string public name;
    string public symbol;
    uint8 public decimals;

     
     
     
    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        balances[owner] = totalSupply;

        emit Mint(owner, totalSupply);
        emit Transfer(address(0), owner, totalSupply);
        emit MintFinished();
    }

    function () public payable {
        revert();
    }

    event Mint(address indexed _to, uint256 _amount);
    event MintFinished();
}