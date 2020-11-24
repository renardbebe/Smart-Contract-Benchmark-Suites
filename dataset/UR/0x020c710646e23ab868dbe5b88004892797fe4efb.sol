 

pragma solidity ^0.4.24;

 
 
 
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


 
 
 
contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
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


 
 
 
 
 
 
 


 
 
 
contract Golfcoin is Pausable, SafeMath, ERC20 {
	string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;



    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) internal allowed;

    event Burned(address indexed burner, uint256 value);
    event Mint(address indexed to, uint256 amount);


     
     
     
    constructor() public {
        symbol = "GOLF";
        name = "Golfcoin";
        decimals = 18;
        _totalSupply = 100000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        require(to != address(this));  

         
        if (balances[msg.sender] >= tokens
            && tokens > 0) {

                 
                balances[msg.sender] = safeSub(balances[msg.sender], tokens);
                balances[to] = safeAdd(balances[to], tokens);

                 
                emit Transfer(msg.sender, to, tokens);
                return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function approve(address spender, uint tokens) public whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
        require(to != address(this));

         
        if (allowed[from][msg.sender] >= tokens
            && balances[from] >= tokens
            && tokens > 0) {

             
            balances[from] = safeSub(balances[from], tokens);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);

             
            emit Transfer(from, to, tokens);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
    function burn(uint256 _value) public onlyOwner {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = safeSub(balances[burner], _value);
        _totalSupply = safeSub(_totalSupply, _value);
        emit Burned(burner, _value);
    }


     
     
     
    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
    	_totalSupply = safeAdd(_totalSupply, _amount);
    	balances[_to] = safeAdd(balances[_to], _amount);
    	
    	emit Mint(_to, _amount);
    	emit Transfer(address(0), _to, _amount);
    	
    	return true;
    }


     
     
     
    function () public payable {
        revert();
    }
}