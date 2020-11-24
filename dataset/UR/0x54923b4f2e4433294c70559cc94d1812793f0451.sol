 

pragma solidity ^0.4.24;

contract Token {

    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract Future1Exchange
 {
    address public archon; 
    
    mapping (address => mapping(address => uint256)) public _token;
    
    constructor() public
    {
         archon = msg.sender;                                                            
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

    
     
     
     
    function tokenTransfer(address token, uint256 tokens)public payable                          
    {

        _token[msg.sender][token] = safeAdd(_token[msg.sender][token], tokens);
        Token(token).transferFrom(msg.sender,address(this), tokens);

    }
    
     
     
     
     
    function tokenWithdraw(address token, address to, uint256 tokens)public payable      
    {
        if(archon==msg.sender)
        {                                                                                                        
            if(Token(token).balanceOf(address(this))>=tokens) 
            {
                _token[msg.sender][token] = safeSub(_token[msg.sender][token] , tokens) ;   
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
    
     
     
     
    function withdrawETH(address  to, uint256 value) public payable returns (bool)        
    {
        
        if(archon==msg.sender)
        {                                                                                           
                 to.transfer(value);
                 return true;
    
         }
    }
}