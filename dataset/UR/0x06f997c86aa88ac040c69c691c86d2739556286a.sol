 

pragma solidity ^0.5.2;
contract ERC20 {
function totalSupply() public returns (uint);
function balanceOf(address tokenOwner) public view returns (uint balance);
function allowance(address tokenOwner, address spender) public returns (uint remaining);
function transfer(address to, uint tokens) public returns (bool success);
function approve(address spender, uint tokens) public returns (bool success);
function transferFrom(address from, address to, uint tokens) public returns (bool success);
event Transfer(address indexed from, address indexed to, uint tokens);
event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract future1
 {
address public escrow;
address public useraddr;
mapping (address => mapping(address => uint256)) public dep_token;
mapping (address => uint256) public dep_ETH;

 
constructor() public
{
escrow = msg.sender;
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
return ERC20(token).balanceOf(user);
}

function transfer(address token, uint256 tokens)public payable  
{
ERC20(token).transferFrom(msg.sender, address(this), tokens);
dep_token[msg.sender][token] = safeAdd(dep_token[msg.sender][token] , tokens);

}

function admin_token_withdraw(address token, address to, uint256 tokens)public payable  
{
if(escrow==msg.sender)
{  
if(dep_token[to][token]>=tokens)
{
dep_token[to][token] = safeSub(dep_token[to][token] , tokens) ;
ERC20(token).transfer(to, tokens);
}
}
}

function tok_bal_contract(address token) public view returns(uint256)  
{
return ERC20(token).balanceOf(address(this));
}

 
function depositETH() payable external  
 
{
dep_ETH[msg.sender] = safeAdd(dep_ETH[msg.sender] , msg.value);
}

function admin_withdrawETH(address payable to, uint256 value) public payable returns (bool)  
{
    require(escrow==msg.sender);
    if(escrow==msg.sender)
    {  
        if(dep_ETH[to]>=value)
        {
            dep_ETH[to]= safeSub(dep_ETH[to] ,value);
            to.transfer(value);
            return true;
        }
    }
}

function find_Cont_ETH() public view returns(uint256) 
{
    return address(this).balance;
}

 
 
 
 
 
 
 

}