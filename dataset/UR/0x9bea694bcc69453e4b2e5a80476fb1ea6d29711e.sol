 

pragma solidity ^0.4.19;

 
 
 
 
 
 
 
 


 
 
 
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


 
 
 
 
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0x0));
        emit OwnershipTransferred(owner,_newOwner);
        owner = _newOwner;
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


 
 
 
 
contract BetcoinICO is ERC20Interface, Owned {
    
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public RATE;
    bool public isStopped = false;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event LogRateChanged(uint256 rate);
    
    modifier onlyWhenRunning {
        require(!isStopped);
        _;
    }
    
    
     
     
     
    function BetcoinICO() public {
        symbol = "BETC";
        name = "Betcoin";
        decimals = 18;
        _totalSupply = 125500000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        RATE = 5000;  
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    
     
     
     
    function() public payable {
        buyTokens();
    }
    
    
     
     
     
    function buyTokens() onlyWhenRunning public payable {
         
        require(msg.value > 0);
        
        uint tokens = msg.value.mul(RATE);
        
         
        require(balances[owner] >= tokens);
        
         
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        emit Transfer(owner, msg.sender, tokens);
        
         
        owner.transfer(msg.value);
    }
    
    
     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        if(balances[msg.sender] >= tokens && tokens > 0 && to!=address(0)) {
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(msg.sender, to, tokens);
            return true;
        } else { return false; }
    }


     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        if(tokens > 0 && spender != address(0)) {
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            return true;
        } else { return false; }
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        if (balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens > 0) {
            balances[from] = balances[from].sub(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(from, to, tokens);
            return true;
        } else { return false; }
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    
     
     
     
     
     
     
     
     
     
     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    
     
     
     
     
     
     
     
     
     
     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    
     
     
     
    function stopICO() onlyOwner public {
        isStopped = true;
    }
    
    
     
     
     
    function resumeICO() onlyOwner public {
        isStopped = false;
    }
    
    
     
     
     
    function changeRate(uint256 rate) onlyOwner public {
        require(rate > 0);
        
        RATE = rate;
        emit LogRateChanged(rate);
    }

}