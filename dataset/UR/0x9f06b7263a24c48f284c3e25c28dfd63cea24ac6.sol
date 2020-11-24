 

pragma solidity ^0.4.18;
library SafeMath {
    
   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  function percent(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = (a * b)/100;
    uint256 k = a * b;
    assert(a == 0 || k / a == b);
    return c;
  }
  
}

contract Ownable {
address public owner;
function Ownable() public {    owner = msg.sender;  }

event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

modifier onlyOwner() {    require(msg.sender == owner);    _;  }

function transferOwnership(address newOwner) public onlyOwner {
require(newOwner != address(0));
OwnershipTransferred(owner, newOwner);
owner = newOwner;
  }

}

contract ERC20Basic {
  uint256 public totalSupply=1000000;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
 
}
contract BasicToken is ERC20Basic, Ownable {
    using SafeMath for uint256;
    mapping (address => uint) public Account_balances;
    mapping (address => uint) public Account_frozen;
    mapping (address => uint) public Account_timePayout; 
    
    event FrozenAccount_event(address target, uint frozen);


  function transfer(address _toaddress, uint256 _value) public returns (bool) {
    require(Account_frozen[msg.sender]==0 );
    require(Account_frozen[_toaddress]==0 );
    Account_timePayout[_toaddress]=Account_timePayout[msg.sender];
    Account_balances[msg.sender] = Account_balances[msg.sender].sub(_value);
    Account_balances[_toaddress] = Account_balances[_toaddress].add(_value);
    Transfer(msg.sender, _toaddress, _value);
    return true;
  }
 
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return Account_balances[_owner];
     }
  
 function BasicToken()    public {   
     Account_balances[msg.sender] =   totalSupply;    
          }
 }
contract AESconstants is BasicToken {
    string public constant name = "Adept Ethereum Stocks";
    string public constant symbol = "AES";
    string public constant tagline = "AES - when resoluteness is rewarded!";
    uint32 public constant decimals = 0;
}
contract Freeze_contract is AESconstants {
   
function Freeze(address _address, uint _uint)   private {
Account_frozen[_address] = _uint;
FrozenAccount_event(_address, _uint);
}    
    
 
 
 
 

 
function user_on_freeze() public  {     require(Account_frozen[msg.sender]==0);  Freeze(msg.sender,2);   }
function user_off_freeze() public {    require(Account_frozen[msg.sender]==2);   Freeze(msg.sender,0);   }
 


function pay_Bounty(address _address, uint _sum_pay )  onlyOwner public {
transfer(_address, _sum_pay); 
Freeze(_address, 1);
} 

function offFreeze_Bounty(address _address) onlyOwner public { Freeze(_address, 0); }     
   
}


contract AES_token_contract is Freeze_contract {
using SafeMath for uint;

uint public next_payout=now + 90 days;
uint public payout = 0;  

 
function Take_payout() public {
 
require(Account_timePayout[msg.sender] < now);
 
if(next_payout<now){
payout=this.balance; 
next_payout=now + 90 days;
}   

msg.sender.transfer(payout.mul(Account_balances[msg.sender]).div(totalSupply));
Account_timePayout[msg.sender]=next_payout;
      }

function() external payable {} 
   
 }
contract Hype is Ownable {
using SafeMath for uint;  
address public investors;
function Hype(address _addres)  onlyOwner public {investors=_addres;    }
    mapping (uint => address) public level;    
    uint private price=5000000000000000;       
    uint public step_level=0;
    uint public step_pay=0;
    uint private constant percent_hype=10;
    uint private constant percent_investors=3;
    uint private bonus=price.percent(100+percent_hype);
    
function() external payable {
require(msg.value > 4999999999999999);
uint amt_deposit=msg.value.div(price);  
investors.transfer(msg.value.percent(percent_investors));        

 for (  uint i= 0; i < amt_deposit; i++) { 
        if (level[step_pay].send(bonus)==true){
          step_pay++;
                                              }
     level[step_level]=msg.sender;
     step_level++;
                                              }
                                              }

   
}
contract BigHype is Ownable {
using SafeMath for uint;  
address public investors;
function BigHype(address _addres)  onlyOwner public {investors=_addres;      }

struct info {
        address i_address;
        uint i_balance;
            }

    mapping (uint => info) public level;    
    uint public step_level=0;
    uint public step_pay=0;
    uint private constant percent_hype=10;
    uint private constant percent_investors=3;
 
function() external payable {
require(msg.value > 4999999999999999); 
investors.transfer(msg.value.percent(percent_investors));       
uint bonus=(level[step_pay].i_balance).percent(100+percent_hype);  
 if (step_level>0 && level[step_pay].i_address.send(bonus)==true){
          step_pay++;
                                                                 }
     level[step_level].i_address=msg.sender;
     level[step_level].i_balance=msg.value;
     step_level++;
}

}


contract Crowdsale is Ownable {
  
address private	multisig = msg.sender; 
bool private share_team_AES=false;


using SafeMath for uint;

AES_token_contract   public AEStoken  = new AES_token_contract(); 
Hype     public hype    = new Hype(AEStoken);
BigHype  public bighype = new BigHype(AEStoken);

uint public Time_Start_Crowdsale= 1518210000;  

 
function Take_share_team_AES() onlyOwner public {
require(share_team_AES == false);
AEStoken.transfer(multisig,500000); 
share_team_AES=true;
}

 
function For_admin() onlyOwner public {
AEStoken.transferOwnership(multisig); 
hype.transferOwnership(multisig); 
bighype.transferOwnership(multisig); 
}


function getTokensSale() public  view returns(uint){  return AEStoken.balanceOf(this);  }
function getBalance_in_token() public view returns(uint){  return AEStoken.balanceOf(msg.sender); }
 
modifier isSaleTime() {  require(Time_Start_Crowdsale<now);  _;  } 
 
  
  
  
  

 
   function createTokens() isSaleTime private  {
      
        uint Tokens_on_Sale = AEStoken.balanceOf(this);      
        uint CenaTokena=1000000000000000;  
        
        uint Discount=0;
        
       
            if(Tokens_on_Sale>400000)   {Discount+=20;}    
       else if(Tokens_on_Sale>300000)   {Discount+=15; }    
       else if(Tokens_on_Sale>200000)   {Discount+=10; }    
       else if(Tokens_on_Sale>100000)   {Discount+=5; } 
       
        
            if(msg.value> 1000000000000000000 && Tokens_on_Sale>2500 )  {Discount+=20; }    
       else if(msg.value>  900000000000000000 && Tokens_on_Sale>1500 )  {Discount+=15;  }    
       else if(msg.value>  600000000000000000 && Tokens_on_Sale>500  )  {Discount+=10;  }    
       else if(msg.value>  300000000000000000 && Tokens_on_Sale>250  )  {Discount+=5;  }    
       
        
     uint256   Time_Discount=now-Time_Start_Crowdsale;
             if(Time_Discount < 3 days)   {Discount+=20; }
        else if(Time_Discount < 5 days)   {Discount+=15; }       
        else if(Time_Discount < 10 days)  {Discount+=10; }
        else if(Time_Discount < 20 days)  {Discount+=5;  } 
         
     CenaTokena=CenaTokena.percent(100-Discount);  
     uint256 Tokens=msg.value.div(CenaTokena);  
       
        if (Tokens_on_Sale>=Tokens)   {         
            multisig.transfer(msg.value);
          }
     else {
        multisig.transfer(msg.value.mul(Tokens_on_Sale.div(Tokens)));    
        msg.sender.transfer(msg.value.mul(Tokens-Tokens_on_Sale).div(Tokens));   
        Tokens=Tokens_on_Sale;
        }
        
       AEStoken.transfer(msg.sender, Tokens);
        
        }
       
 
    function() external payable {
     
      if (AEStoken.balanceOf(this)>0)  { createTokens(); }
      else { AEStoken.transfer(msg.value); } 
        
    }
    
}