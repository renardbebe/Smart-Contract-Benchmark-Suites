 

pragma solidity ^0.4.10;

 

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
        OwnershipTransferred(owner, newOwner);
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



 
      
contract SpaceXToken is ERC20Interface, Owned, Pausable {
    using SafeMath for uint;


    uint8 public decimals;
    
    uint256 public totalRaised;            
    uint256 public startTimestamp;         
    uint256 public endTimeStamp;           
    uint256 public basePrice =  15000000000000000;               
    uint256 public step1 =      80000000000000;
    uint256 public step2 =      60000000000000;
    uint256 public step3 =      40000000000000;
    uint256 public tokensSold;
    uint256 currentPrice;
    uint256 public totalPrice;
    uint256 public _totalSupply;         
    
    string public version = '1.0';       
    string public symbol;           
    string public  name;
    
    
    address public fundsWallet;              

    mapping(address => uint) balances;     
    mapping(address => mapping(address => uint)) allowed;  

     

    function SpaceXToken() public {
        tokensSold = 0;
        startTimestamp = 1527080400;
        endTimeStamp = 1529672400;
        fundsWallet = owner;
        name = "SpaceXToken";                                      
        decimals = 0;                                                
        symbol = "SCX";                        
        _totalSupply = 4000 * 10**uint(decimals);        
        balances[owner] = _totalSupply;                
        tokensSold = 0;
        currentPrice = basePrice;
        totalPrice = 0;
        Transfer(msg.sender, owner, _totalSupply);


    }


     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
    
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

     
    
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

     
    
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }

     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
     
    function TokenSale(uint256 numberOfTokens) public whenNotPaused payable {  
        
         
        
        require(now >= startTimestamp , "Sale has not started yet.");
        require(now <= endTimeStamp, "Sale has ended.");
        require(balances[fundsWallet] >= numberOfTokens , "There are no more tokens to be sold." );
        require(numberOfTokens >= 1 , "You must buy 1 or more tokens.");
        require(numberOfTokens <= 10 , "You must buy at most 10 tokens in a single purchase.");
        require(tokensSold.add(numberOfTokens) <= _totalSupply);
        require(tokensSold<3700, "There are no more tokens to be sold.");
        
         
        
        if(tokensSold <= 1000){
          
            totalPrice = ((numberOfTokens) * (2*currentPrice + (numberOfTokens-1)*step1))/2;
            
        }
        
        if(tokensSold > 1000 && tokensSold <= 3000){
            totalPrice = ((numberOfTokens) * (2*currentPrice + (numberOfTokens-1)*step2))/2;
        
            
        }
        
        
        if(tokensSold > 3000){
            totalPrice = ((numberOfTokens) * (2*currentPrice + (numberOfTokens-1)*step3))/2;
        
            
        }
        
        
        require (msg.value >= totalPrice);   

        balances[fundsWallet] = balances[fundsWallet] - numberOfTokens;
        balances[msg.sender] = balances[msg.sender] + numberOfTokens;

        tokensSold = tokensSold + numberOfTokens;
        
        if(tokensSold <= 1000){
          
            currentPrice = basePrice + step1 * tokensSold;
            
        }
        
        if(tokensSold > 1000 && tokensSold <= 3000){
            currentPrice = basePrice + (step1 * 1000) + (step2 * (tokensSold-1000));
        
            
        }
        
        if(tokensSold > 3000){
            
            currentPrice = basePrice + (step1 * 1000) + (step2 * 2000) + (step3 * (tokensSold-3000));
          
        }
        totalRaised = totalRaised + totalPrice;
        
        msg.sender.transfer(msg.value - totalPrice);             
        Transfer(fundsWallet, msg.sender, numberOfTokens);  

    }
    
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    
    
    function viewCurrentPrice() view returns (uint) {
        if(tokensSold <= 1000){
          
            return basePrice + step1 * tokensSold;
            
        }
        
        if(tokensSold > 1000 && tokensSold <= 3000){
            return basePrice + (step1 * 1000) + (step2 * (tokensSold-1000));
        
            
        }
        
        if(tokensSold > 3000){
            
            return basePrice + (step1 * 1000) + (step2 * 2000) + (step3 * (tokensSold-3000));
          
        }
    }

    
    
    
    function viewTokensSold() view returns (uint) {
        return tokensSold;
    }

     
    
    function viewTokensRemaining() view returns (uint) {
        return _totalSupply - tokensSold;
    }
    
     
     
    function withdrawBalance(uint256 amount) onlyOwner returns(bool) {
        require(amount <= address(this).balance);
        owner.transfer(amount);
        return true;

    }
    
     
     
    function getBalanceContract() constant returns(uint){
        return address(this).balance;
    }
}