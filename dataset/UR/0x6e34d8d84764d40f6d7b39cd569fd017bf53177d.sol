 

pragma solidity 0.4.19;

contract Owned {
    address public owner;
    address public candidate;

    function Owned() internal {
        owner = msg.sender;
    }
    
     
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

     
    function changeOwner(address _owner) onlyOwner public {
        candidate = _owner;
    }

     
    function acceptOwner() public {
        require(candidate != address(0));
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }
}

 
library SafeMath {
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint balance);
    function allowance(address owner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value) public returns (bool success);
    function approve(address spender, uint value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Skraps is ERC20, Owned {
    using SafeMath for uint;

    string public name = "Skraps";
    string public symbol = "SKRP";
    uint8 public decimals = 18;
    uint public totalSupply;

    uint private endOfFreeze = 1518912000;  

    mapping (address => uint) private balances;
    mapping (address => mapping (address => uint)) private allowed;

    function balanceOf(address _who) public constant returns (uint) {
        return balances[_who];
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function Skraps() public {
        totalSupply = 110000000 * 1 ether;
        balances[msg.sender] = totalSupply;
        Transfer(0, msg.sender, totalSupply);
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        require(now >= endOfFreeze || msg.sender == owner);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        require(now >= endOfFreeze || msg.sender == owner);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        require(_spender != address(0));
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function withdrawTokens(uint _value) public onlyOwner {
        require(balances[this] > 0 && balances[this] >= _value);
        balances[this] = balances[this].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        Transfer(this, msg.sender, _value);
    }
}