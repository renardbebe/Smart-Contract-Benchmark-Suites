 

pragma solidity ^0.4.19;

 
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


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () public {
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

 
 
 
 

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract LCXCoin is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint256 public decimals;
    uint256 public _totalSupply;
    uint256 public burnt;
    address public charityFund = 0x1F53b1E1E9771A38eDA9d144eF4877341e47CF51;
    address public bountyFund = 0xfF311F52ddCC4E9Ba94d2559975efE3eb1Ea3bc6;
    address public tradingFund = 0xf609127b10DaB6e53B7c489899B265c46Cee1E9d;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    mapping (address => bool) public frozenAccount;
    
    
    event FrozenFunds(address target, bool frozen);  
    event Burn(address indexed burner, uint256 value);
    event Burnfrom(address indexed _from, uint256 value);
  
     
    constructor () public {
        symbol = "LCX";
        name = "London Crypto Exchange";
        decimals = 18;
        _totalSupply = 113000000 * 10 ** uint(decimals);     
        balances[charityFund] = safeAdd(balances[charityFund], 13000000 * (10 ** decimals));  
        emit Transfer(address(0), charityFund, 13000000 * (10 ** decimals));      
        balances[bountyFund] = safeAdd(balances[bountyFund], 25000000 * (10 ** decimals));  
        emit Transfer(address(0), bountyFund, 25000000 * (10 ** decimals));      
        balances[tradingFund] = safeAdd(balances[tradingFund], 75000000 * (10 ** decimals));  
        emit Transfer(address(0), tradingFund, 75000000 * (10 ** decimals));      
    }

     
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               			 
        require (balances[_from] >= _value);               			     
        require (balances[_to] + _value > balances[_to]); 			     
        require(!frozenAccount[_from]);                     			 
        require(!frozenAccount[_to]);                       			 
        uint previousBalances = balances[_from] + balances[_to];		 
        balances[_from] = safeSub(balances[_from],_value);    			 
        balances[_to] = safeAdd(balances[_to],_value);        			 
        emit Transfer(_from, _to, _value);									 
        assert(balances[_from] + balances[_to] == previousBalances); 
    }
    
   
     

    function transfer(address to, uint tokens) public returns (bool success) {
        _transfer(msg.sender, to, tokens);
        return true;
    }

     
  
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        
        require(tokens <= allowed[from][msg.sender]); 
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens); 
        _transfer(from, to, tokens);
        return true;
    }
    
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
         
         
         
         
        require((tokens == 0) || (allowed[msg.sender][spender] == 0));
        
        allowed[msg.sender][spender] = tokens;  
        emit Approval(msg.sender, spender, tokens);  
        return true;
    }

     

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
         
         
        
        require(approve(spender, tokens));  
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
    function () public payable {
        revert();
    }

     

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = safeSub(balances[burner],_value);
        _totalSupply = safeSub(_totalSupply,_value);
        burnt = safeAdd(burnt,_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
  
    function burnFrom(address _from, uint256 _value) public onlyOwner returns  (bool success) {
        require (balances[_from] >= _value);            
        require (msg.sender == owner);   
        _totalSupply = safeSub(_totalSupply,_value);
        burnt = safeAdd(burnt,_value);
        balances[_from] = safeSub(balances[_from],_value);                      
        emit Burnfrom(_from, _value);
        return true;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}