 

pragma solidity ^0.4.18;


 
 
 
library SafeMath {

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

   
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
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

    function Owned() public {
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

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

 
 
 
 
contract PonyToken is ERC20Interface, Pausable {
    using SafeMath for uint;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public _currentSupply;
    mapping(address => bool) _protect;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event Burn(address indexed burner, uint256 value);
    
    
      
    function PonyToken() public {
        symbol = "Pony";
        name = "Platform of Open Nodes Integrated";
        decimals = 18;
        _totalSupply = 1000000000 * 10**uint256(decimals);
        emit Transfer(address(0), owner, _totalSupply);
    }

     
    modifier whenNotInProtect(){
        require(_protect[msg.sender] == false);
        _;
    }

     
    function accountProtect(address _account) public onlyOwner{
        require(_account != 0);
        _protect[_account] = true;
    }

     
    function accountUnProtect(address _account) public onlyOwner{
        require(_account != 0);
        _protect[_account] = false;
    }

     
    function burn(uint256 _value) public whenNotInProtect{
        _burn(msg.sender, _value);
    }

     
    function _burn(address _account, uint256 _amount) internal {
        require(_account != 0);
        require(_amount <= balances[_account]);
        require(_totalSupply > _amount);
        _totalSupply = _totalSupply.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
        emit Burn(_account, _amount);
    }

     
    function burnFrom(address _from, uint256 _value) public {
        _burnFrom(_from, _value);
    }


     
    function _burnFrom(address _account, uint256 _amount) internal {
        require(_amount <= allowed[_account][msg.sender]);

        allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
        _burn(_account, _amount);
    }


     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

     
     
     
    function currentSupply() public constant returns (uint) {
        return _currentSupply;
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public whenNotPaused whenNotInProtect returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public whenNotPaused whenNotInProtect returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
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


     
    function increaseSupply (uint256 _value, address _to) onlyOwner whenNotPaused external {
        require(_value + _currentSupply < _totalSupply);
        _currentSupply = _currentSupply.add(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(address(0x0), _to, _value);
    }

     
    function batchTransfer(address[] _receivers, uint256 _value) public whenNotPaused whenNotInProtect returns (uint256) {
        uint cnt = _receivers.length;
        uint256 amount = uint256(cnt) .mul(_value);
        
        require(cnt > 0 && cnt <= 20);
        require(_value > 0 && balances[msg.sender] >= amount);
        require(amount >= _value);

        balances[msg.sender] = balances[msg.sender].sub(amount);

        for (uint i = 0; i < cnt; i++) {
            balances[_receivers[i]] = balances[_receivers[i]].add(_value);
        }
        emit Transfer(msg.sender, address(0), amount);    
        return amount;
    }
    
}


contract TokenTimelock {
    ERC20Interface public token;
     
    address public beneficiary;

     
    uint256 public releaseTime;

    constructor(ERC20Interface _token, address _beneficiary, uint256 _releaseTime) public
    {
         
        require(_releaseTime > block.timestamp);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

     
    function release() public {
         
        require(block.timestamp >= releaseTime);

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0);

        token.transfer(beneficiary, amount);
    }
}