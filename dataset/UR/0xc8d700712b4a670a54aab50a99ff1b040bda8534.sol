 

 

pragma solidity ^0.4.25;

 

contract TokenPesaDAOToken  {

    string public constant name = "TokenPesa DAO Token";
	string public constant symbol = "TDAT";
	uint8 public constant decimals = 18;
	
 
  mapping(address => uint) _balances;
  mapping(address => mapping( address => uint )) _approvals;
  
 
  uint public cap_tdat;
  
 
  uint public currentSupply;
  
 
  address public minter;
  
 
modifier onlyMinter {
    
      if (msg.sender != minter) revert();
      _;
  }
  
 
modifier capReached(uint amount) {
    
    if((currentSupply + amount) > cap_tdat) revert();
    _;
}

  event Transfer(address indexed from, address indexed to, uint value );
  event Approval(address indexed owner, address indexed spender, uint value );
  event TokenMint(address newTokenHolder, uint amountOfTokens);
  event MinterTransfered(address prevMinter, address nextMinter);
 
 
 
 
 constructor(uint cap_token) public  {
     
    cap_tdat = cap_token;
    minter = msg.sender;
    
  }

 
function totalSupply() public constant returns (uint supply) {
    return currentSupply;
  }

 
function balanceOf(address who) public constant returns (uint value) {
    return _balances[who];
  }

 
function allowance(address _owner, address spender) public constant returns (uint _allowance) {
    return _approvals[_owner][spender];
  }

   
function safeToAdd(uint a, uint b) internal pure returns (bool) {
    return (a + b >= a && a + b >= b);
  }

 
function transfer(address to, uint value) public returns (bool ok) {

    if(_balances[msg.sender] < value) revert();
    
    if(!safeToAdd(_balances[to], value)) revert();
    
    _balances[msg.sender] -= value;
    _balances[to] += value;
    
    emit Transfer(msg.sender, to, value);
    return true;
  }

 
function transferFrom(address from, address to, uint value) public returns (bool ok) {
     
    if(_balances[from] < value) revert();

     
    if(_approvals[from][msg.sender] < value) revert();
    
    if(!safeToAdd(_balances[to], value)) revert();
    
     
    _approvals[from][msg.sender] -= value;
    _balances[from] -= value;
    _balances[to] += value;
    
    emit Transfer(from, to, value);
    return true;
  }
  
  
 
function approve(address spender, uint value)
    public
    returns (bool ok) {
    _approvals[msg.sender][spender] = value;
    
    emit Approval(msg.sender, spender, value);
    return true;
  }

 
 
 
function mint(address recipient, uint amount) onlyMinter capReached(amount)  public returns (bool ok)
  {
    if(!safeToAdd(_balances[recipient], amount)) revert();
    if(!safeToAdd(currentSupply, amount)) revert();
    
   _balances[recipient] += amount;  
   currentSupply += amount;
    
    emit TokenMint(recipient, amount);
    return true;
  }
  
 
function transferMintership(address newMinter) public onlyMinter returns (bool ok)
  {
    minter = newMinter;
    
    emit MinterTransfered(minter, newMinter);
     return true;
  }
  
}