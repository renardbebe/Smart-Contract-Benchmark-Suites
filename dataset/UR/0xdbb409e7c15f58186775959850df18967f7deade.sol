 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 
 
 


 
 
 

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

 
 
 
contract BECCToken is ERC20, Owned {
    using SafeMath for uint;
    
    event Pause();
    event Unpause();
    event ReleasedTokens(uint tokens);
    event AllocateTokens(address to, uint tokens);
    
    bool public paused = false;

    string public symbol;
    string public name;
    uint8 public decimals;
    
    uint private _totalSupply;               
    uint private _initialRelease;            
    uint private _locked;                    
    uint private _released = 0;              
    uint private _allocated = 0;
    uint private _startTime = 1534233600 + 180 days;     

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
        symbol = "BECC";
        name = "Beechain Exchange Cross-chain Coin";
        decimals = 18;
        _totalSupply = 500000000 * 10**uint(decimals);
        _initialRelease = _totalSupply * 7 / 10;
        _locked = _totalSupply * 3 / 10;
        balances[owner] = _initialRelease;
        emit Transfer(address(0), owner, _initialRelease);
    }

     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        require(address(0) != to && tokens <= balances[msg.sender] && 0 <= tokens);
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
        require(address(0) != to && tokens <= balances[from] && tokens <= allowed[from][msg.sender] && 0 <= tokens);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
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

     
     
     
    function transferERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
    
     
     
     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
     
     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
    
     
     
     
    function freeBalance() public view returns (uint tokens) {
        return _released.sub(_allocated);
    }

     
     
     
    function releasedBalance() public view returns (uint tokens) {
        return _released;
    }

     
     
     
    function allocatedBalance() public view returns (uint tokens) {
        return _allocated;
    }
    
     
     
     
    function calculateReleased() public onlyOwner returns (uint tokens) {
        require(now > _startTime);
        uint _monthDiff = (now.sub(_startTime)).div(30 days);

        if (_monthDiff >= 10 ) {
            _released = _locked;
        } else {
            _released = _monthDiff.mul(_locked.div(10));
        }
        emit ReleasedTokens(_released);
        return _released;
    }

     
     
     
    function allocateTokens(address to, uint tokens) public onlyOwner returns (bool success){
        require(address(0) != to && 0 <= tokens && tokens <= _released.sub(_allocated));
        balances[to] = balances[to].add(tokens);
        _allocated = _allocated.add(tokens);
        emit AllocateTokens(to, tokens);
        return true;
    }
}