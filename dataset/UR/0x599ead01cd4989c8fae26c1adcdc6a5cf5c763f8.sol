 

pragma solidity ^0.4.19;



 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract ERC20Interface {
          
      function balanceOf(address tokenOwner) public constant returns (uint256 balance);
          
      function transfer(address to, uint256 tokens) public returns (bool success);
          
          
          
          
 } 


 
 
 
contract Tokensale
{
using SafeMath for uint256;

address public owner;                   
address public thisAddress;             
string  public lastaction;              
uint256 public constant RATE = 1000;  
uint256 public raisedAmount     = 0;    
uint256 public available_tokens = 0;    

uint256 public lasttokencount;          
bool    public last_transfer_state;     



 
 
 
function Tokensale () public
{
owner       = msg.sender;
thisAddress = address(this);
}  


 
 



 
 
 
function () payable public
{
address tokenAddress = 0x80248B05a810F685B12C78e51984f808293e57D3;
ERC20Interface loveContract = ERC20Interface(tokenAddress);  


 
 
 
if ( msg.value >= 1250000000000000 )
   {
    
   uint256 weiAmount = msg.value;
   uint256 tokens = weiAmount.mul(RATE);
    
    
   available_tokens = loveContract.balanceOf(thisAddress);    
    
   
   if (available_tokens >= tokens)
      {      
      
      	  lasttokencount = tokens;   
      	  raisedAmount   = raisedAmount.add(msg.value);
   
           
          last_transfer_state = loveContract.transfer(msg.sender,  tokens);
          
          
      }  
      else
          {
          revert();
          }
   
   
   
   }  
   else
       {
       revert();
       }





}  
 



 
 
 
function owner_withdraw () public
{
if (msg.sender != owner) return;

owner.transfer( this.balance );
lastaction = "Withdraw";  
}  



 
 
 
function kill () public
{
if (msg.sender != owner) return;


 
address tokenAddress = 0x80248B05a810F685B12C78e51984f808293e57D3;
ERC20Interface loveContract = ERC20Interface(tokenAddress);  

uint256 balance = loveContract.balanceOf(this);
assert(balance > 0);
loveContract.transfer(owner, balance);


owner.transfer( this.balance );
selfdestruct(owner);
}  


}  