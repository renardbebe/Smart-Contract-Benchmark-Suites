 

pragma solidity ^0.4.24;

contract Token {

    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract Future1Exchange
 {
     
    address public adminaddr; 
    
     
    
    mapping (address => mapping(address => uint256)) public dep_token;
    
    mapping (address => uint256) public dep_ETH;

     
    constructor() public
    {
         adminaddr = msg.sender;                                                            
    }
    
    
    function safeAdd(uint crtbal, uint depbal) public pure returns (uint) 
    {
        uint totalbal = crtbal + depbal;
        return totalbal;
    }
    
    function safeSub(uint crtbal, uint depbal) public pure returns (uint) 
    {
        uint totalbal = crtbal - depbal;
        return totalbal;
    }
    
     
     
     
    function balanceOf(address token,address user) public view returns(uint256)            
    {
        return Token(token).balanceOf(user);
    }

    
     
     
     
    function token_transfer(address token, uint256 tokens)public payable                          
    {
        
        if(Token(token).approve(address(this),tokens))
        {
            dep_token[msg.sender][token] = safeAdd(dep_token[msg.sender][token], tokens);
            Token(token).transferFrom(msg.sender,address(this), tokens);
        }
    }
    
    
     
     
     
     
    function admin_token_withdraw(address token, address to, uint256 tokens)public payable      
    {
        if(adminaddr==msg.sender)
        {                                                                                                        
            if(dep_token[msg.sender][token]>=tokens) 
            {
                dep_token[msg.sender][token] = safeSub(dep_token[msg.sender][token] , tokens) ;   
                Token(token).transfer(to, tokens);
            }
        }
    }
    
     
     
    function contract_bal(address token) public view returns(uint256)                       
    {
        return Token(token).balanceOf(address(this));
    }
    
     
    function depositETH() payable external                                                      
    { 
        
    }
    
    
     
     
     
    function admin_withdrawETH(address  to, uint256 value) public payable returns (bool)        
    {
        
        if(adminaddr==msg.sender)
        {                                                                                           
                 to.transfer(value);
                 return true;
    
         }
    }
}