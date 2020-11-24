 

pragma solidity 0.4.22;

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
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event FrozenFunds(address target, uint tokens);
    event Buy(address indexed sender, uint eth, uint token);
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

     
    function acceptOwnership() public onlyOwner {
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

contract VXR is ERC20Interface, Pausable {
    using SafeMath for uint;
    string public symbol;
    string public  name;
    uint8 public decimals;

    uint public _totalSupply;
    mapping(address => uint) public balances;
    mapping(address => uint) public lockInfo;
    mapping(address => mapping(address => uint)) internal allowed;
    mapping (address => bool) public admins;
    
    modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    function setAdmin(address _admin, bool isAdmin) public onlyOwner {
        admins[_admin] = isAdmin;
    }

    constructor() public{
        symbol = 'VXR';
        name = 'Versara Trade';
        decimals = 18;
        _totalSupply = 1000000000*10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                     
        require(_value != 0);                                    
        require(balances[_from] >= _value);                      
        require(balances[_from] - _value >= lockInfo[_from]);    
        balances[_from] = balances[_from].sub(_value);           
        balances[_to] = balances[_to].add(_value);               
        emit Transfer(_from, _to, _value);
    }

    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
         _transfer(msg.sender, to, tokens);
         return true;
    }

    function approve(address _spender, uint tokens) public whenNotPaused returns (bool success) {
        allowed[msg.sender][_spender] = tokens;
        emit Approval(msg.sender, _spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
        require(allowed[from][msg.sender] >= tokens);
        _transfer(from, to, tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public whenNotPaused view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
     
    function lockOf(address tokenOwner) public view returns (uint lockedToken) {
        return lockInfo[tokenOwner];
    }

     
    function lock(address target, uint lockedToken) public whenNotPaused onlyAdmin {
        lockInfo[target] = lockedToken;
        emit FrozenFunds(target, lockedToken);
    }

     
    function batchLock(address[] accounts, uint lockedToken) public whenNotPaused onlyAdmin {
      for (uint i = 0; i < accounts.length; i++) {
           lock(accounts[i], lockedToken);
        }
    }

     
    function batchLockArray(address[] accounts, uint[] lockedToken) public whenNotPaused onlyAdmin {
      for (uint i = 0; i < accounts.length; i++) {
           lock(accounts[i], lockedToken[i]);
        }
    }

     
    function batchAirdropWithLock(address[] receivers, uint tokens, bool freeze) public whenNotPaused onlyAdmin {
      for (uint i = 0; i < receivers.length; i++) {
           sendTokensWithLock(receivers[i], tokens, freeze);
        }
    }

     
    function batchVipWithLock(address[] receivers, uint[] tokens, bool freeze) public whenNotPaused onlyAdmin {
      for (uint i = 0; i < receivers.length; i++) {
           sendTokensWithLock(receivers[i], tokens[i], freeze);
        }
    }

     
    function sendTokensWithLock (address receiver, uint tokens, bool freeze) public whenNotPaused onlyAdmin {
        _transfer(msg.sender, receiver, tokens);
        if(freeze) {
            uint lockedAmount = lockInfo[receiver] + tokens;
            lock(receiver, lockedAmount);
        }
    }

     
    function sendInitialTokens (address user) public onlyOwner {
        _transfer(msg.sender, user, balanceOf(owner));
    }
}