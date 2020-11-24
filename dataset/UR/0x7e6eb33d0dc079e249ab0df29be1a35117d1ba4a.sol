 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 


 
 
 
 
contract ERC20 {
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
    function receiveApproval(address from, uint tokens, address token, bytes data) public;
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

 
 
 
contract AIC20Token is ERC20, Owned {
    using SafeMath for uint;
    
    event Pause();
    event Unpause();

    bool public paused = false;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint private _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

     
     
     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
     
     
    modifier whenPaused() {
        require(paused);
        _;
    }
  
     
     
     
    constructor() public {
        symbol = "AIC20";
        name = "Agricultural industrial chain 20";
        decimals = 8;
        _totalSupply = 1000000000 * 10**uint(decimals);
        balances[owner] =  _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        require(address(0) != to && tokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
    function approve(address spender, uint tokens) public whenNotPaused returns (bool success) {
        require(address(0) != spender && 0 <= tokens);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
        require(address(0) != to && tokens <= balances[msg.sender] && tokens <= allowed[from][msg.sender]);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
    function batchTransfer(address[] toAddresses, uint tokens) public onlyOwner whenNotPaused returns (bool success) {
		uint len = toAddresses.length;
		require(0 < len);
		uint amount = tokens.mul(len);
		require(amount <= balances[msg.sender]);
        for (uint i = 0; i < len; i++) {
            address _to = toAddresses[i];
            require(address(0) != _to);
            balances[_to] = balances[_to].add(tokens);
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            emit Transfer(msg.sender, _to, tokens);
        }
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
    function () public payable {
        revert();
    }

     
     
     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
     
     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

 
 
 

library SafeMath {
    
  function mul(uint _a, uint _b) internal pure returns (uint c) {
    if (_a == 0) {
      return 0;
    }
    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  function div(uint _a, uint _b) internal pure returns (uint) {
    return _a / _b;
  }

  function sub(uint _a, uint _b) internal pure returns (uint) {
    assert(_b <= _a);
    return _a - _b;
  }

  function add(uint _a, uint _b) internal pure returns (uint c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}