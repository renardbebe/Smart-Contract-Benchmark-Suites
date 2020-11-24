 

pragma solidity ^0.4.24;

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

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


 
 
 
 
contract BBT is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    modifier onlyWhitelist() {
        require(blacklist[msg.sender] == false);
        _;
    }

    modifier canDistr() {
        require(!distributionFinished);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

     
     
     
    uint256 public _airdropAmount;
    uint256 public _airdropTotal;
    uint256 public _airdropSupply;
    uint256 public _totalRemaining;

    mapping(address => bool) initialized;
    bool public distributionFinished = false;
    mapping (address => bool) public blacklist;

    event Distr(address indexed to, uint256 amount);
    event DistrFinished();

     
     
     
    constructor() public {
        symbol = "BBT";
        name = "BiBox";
        decimals = 18;
        _totalSupply = 1000000000 * 10 ** uint256(decimals);
        _airdropAmount = 35000 * 10 ** uint256(decimals);
        _airdropSupply =  300000000 * 10 ** uint256(decimals);
        _totalRemaining = _airdropSupply;
        balances[owner] = _totalSupply.sub(_airdropSupply);

        emit Transfer(address(0), owner, _totalSupply);
    }


     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) onlyPayloadSize(2 * 32) public returns (bool success) {
        require(to != address(0));
        require(tokens <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;

    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);
        require(to != address(0));

        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from, to, tokens);
        return true;

    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

     
     
     
    function getBalance(address _address) internal returns (uint256) {
        if (_airdropTotal < _airdropSupply && !initialized[_address]) {
            return balances[_address] + _airdropAmount;
        } else {
            return balances[_address];
        }
    }

     
     
     
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {

        _airdropTotal = _airdropTotal.add(_amount);
        _totalRemaining = _totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        if (_airdropTotal >= _airdropSupply) {
            distributionFinished = true;
        }
    }

    function () external payable {
        getTokens();
    }


    function getTokens() payable canDistr onlyWhitelist public {

        if (_airdropAmount > _totalRemaining) {
            _airdropAmount = _totalRemaining;
        }

        require(_totalRemaining <= _totalRemaining);

        distr(msg.sender, _airdropAmount);

        if (_airdropAmount > 0) {
            blacklist[msg.sender] = true;
        }

        if (_airdropTotal >= _airdropSupply) {
            distributionFinished = true;
        }

        _airdropAmount = _airdropAmount.div(100000).mul(99999);

        uint256 etherBalance = this.balance;
        if (etherBalance > 0) {
            owner.transfer(etherBalance);
        }
    }
}