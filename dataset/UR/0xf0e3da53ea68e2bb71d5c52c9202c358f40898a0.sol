 

pragma solidity ^0.4.20;

 
 
 
 
 

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


 
 
 
 
 

contract GameEventInterface {
    event BuyTickets(address game, address to, uint amount);
    event Winner(address game, address to, uint prize, uint random_number, uint buyer_who_won);
    event Jackpot(address game, address to, uint jackpot);
}

 
 
 
 
 

contract AwardsTokensInterface {
    function awardToken(address toAddress, uint amount) public;
    function receiveFromGame() public payable;
    function addGame(address gameAddress, uint amount) public;
}


 
 
 
 
 

contract ICO is ERC20Interface {
    using SafeMath for uint;
    
     
                                                                                     
    string public constant symbol = "FXT";                                           
    string public constant name = "Fortunity Owners Token";                          
    uint8 public constant decimals = 18;                                             
    uint256 _totalSupply = (1000000 * 10**uint(decimals));  
    mapping(address => uint256) balances;                                            
    mapping(address => mapping (address => uint256)) allowed;                        
                                                                                     
     
    address public owner;                                                            
    address public affiliate;  
                                                                                     
     
    uint public payoutRound;                                                         
    bool public payoutOpen;                                                          
    uint public payoutProfit;                                                        
    uint public lastPayoutTime;                                                      
    mapping(address => uint) payoutPaidoutRound;                                     
                                                                                     
     
    

  
     
                                                                                     
    function ICO() public {                                                          
        owner               = msg.sender;                                            
        balances[owner]     = _totalSupply;                                          
        Transfer(address(0), msg.sender, _totalSupply);                              
        affiliate           = msg.sender;                                            
        payoutRound        = 0;                                                      
        payoutOpen         = false;                                                  
        payoutProfit       = 0;                                                      
        lastPayoutTime     = 0;                                                      
    }                                                                                
                                                                                     
     
    modifier onlyAdmin () {                                                          
        require((msg.sender == owner) || (msg.sender == affiliate));                 
        _;                                                                           
    }                                                                                
                                                                                     
     
    
    
     
    event EthReceived(address inAddress, uint amount);                               
                                                                                     
    function() public payable {                                                      
        msg.sender.transfer(msg.value);                                              
    }                                                                                
                                                                                     
    function receiveFromGame() public payable {                                      
        EthReceived(msg.sender, msg.value);                                          
    }                                                                                
                                                                                     
     
                                                                                    
                                                                                    
                                                                                    
     
                                                                                     
    event PayoutStatus(bool status);                                                 
                                                                                     
     
    function openPayout() public onlyAdmin {                                         
        require(!payoutOpen);                                                        
        payoutRound += 1;                                                            
        payoutOpen = true;                                                           
        payoutProfit = address(this).balance;                                        
        lastPayoutTime = now;                                                        
        PayoutStatus(payoutOpen);                                                    
    }                                                                                
                                                                                     
     
    function closePayout() public onlyAdmin {                                        
        require(lastPayoutTime < (now.add(7 days)));                                 
        payoutOpen = false;                                                          
        PayoutStatus(payoutOpen);                                                    
    }                                                                                
                                                                                     
     
    function requestDividendPayout() public {                                        
        require(payoutOpen);                                                         
        require(payoutPaidoutRound[msg.sender] != payoutRound);                      
        payoutPaidoutRound[msg.sender] = payoutRound;                                
        msg.sender.transfer((payoutProfit.mul(balances[msg.sender])).div(_totalSupply));
    }                                                                                
                                                                                     
                                                                                     
     



     
                                                                                     
    function changeAffiliate(address newAffiliate) public onlyAdmin {                
        require(newAffiliate != address(0));                                         
        affiliate = newAffiliate;                                                    
    }                                                                                
                                                                                     
    function takeAll() public onlyAdmin {                                            
        msg.sender.transfer(address(this).balance);                                  
    }                                                                                
     
    
    
    
     
                                                                                     
    function totalSupply() public constant returns (uint) {                          
        return _totalSupply;                                                         
    }                                                                                
                                                                                     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {  
        return balances[tokenOwner];                                                 
    }                                                                                
                                                                                     
    function transfer(address to, uint tokens) public returns (bool success) {       
        require(!payoutOpen);                                                        
        require(to != address(0));                                                   
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
        require(!payoutOpen);                                                        
        require(to != address(0));                                                   
        balances[from] = balances[from].sub(tokens);                                 
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);           
        balances[to] = balances[to].add(tokens);                                     
        Transfer(from, to, tokens);                                                  
        return true;                                                                 
    }                                                                                
                                                                                     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];                                         
    }                                                                                
                                                                                     
     
}