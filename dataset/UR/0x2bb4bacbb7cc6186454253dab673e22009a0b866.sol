 

 
 
 
 
 

 
 
 
 
 


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 



 


 
 
 
 
 
 
 
 
 
 
 
 
 





 
 
pragma solidity ^0.4.25;
contract Token {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenExchange{

    uint256 public minETHExchange = 10000000000000000; 
    uint256 public TokenCountPer = 200000000000000000000; 
    address public tokenAddress = address(0x5d47D55b33e067F8BfA9f1955c776B5AddD8fF17); 
    address public fromAddress = address(0xfA25eC30ba33742D8d5E9657F7d04AeF8AF91F40); 
    address public owner = address(0x8cddc253CA7f0bf51BeF998851b3F8E41053B784); 
    Token _token = Token(tokenAddress); 

    function() public payable {
        require(msg.value >= minETHExchange); 
        uint256 count = 0;
        count = msg.value / minETHExchange; 

        uint256 remianETH = msg.value - (count * minETHExchange); 
        uint256 tokenCount = count * TokenCountPer; 

        if(remianETH > 0){ 
            tx.origin.transfer(remianETH);
        }
        require(_token.transferFrom(fromAddress,tx.origin,tokenCount)); 
        owner.transfer(address(this).balance);
    }
}