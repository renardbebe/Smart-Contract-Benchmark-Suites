 

pragma solidity ^0.4.24;

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address Owner) public constant returns (uint256 balance);
    function allowance(address Owner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed Owner, address indexed spender, uint256 value);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 value, address token, bytes data) public;
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Vioscoin is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() public {
        symbol = "VIS";
        name = "Vioscoin";
        decimals = 18;
        _totalSupply = 5000000000000000000000000;
        balances[0x67e9911D9275389dB0599BE60b1Be5C8850Df7b1] = _totalSupply;
        emit Transfer(address(0), 0x67e9911D9275389dB0599BE60b1Be5C8850Df7b1, _totalSupply);
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address _Owner) public constant returns (uint256 balance) {
        return balances[_Owner];
    }

    function transfer(address to, uint256 _value) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[to] = safeAdd(balances[to], _value);
        emit Transfer(msg.sender, to, _value);
        return true;
    }

    function approve(address spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][spender] = _value;
        emit Approval(msg.sender, spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256  _value) public returns (bool success) {
        balances[_from] = safeSub(balances[_from],  _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        balances[_to] = safeAdd(balances[_to],  _value);
        emit Transfer(_from, _to,  _value);
        return true;
    }

    
    function allowance(address Owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[Owner][_spender];
    }

    function approveAndCall(address _spender, uint256 _value, bytes data) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _value, this, data);
        return true;
    }

    function () public payable {
        revert();
    }

    function transferAnyERC20Token(address Address, uint256 _value) public onlyOwner returns (bool success) {
        return ERC20Interface(Address).transfer(owner, _value);
    }
}