 

 




 
contract ERC20Interface 
{
          
      function balanceOf(address tokenOwner) public constant returns (uint256 balance);
      function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
      function transfer(address to, uint256 tokens) public returns (bool success);
          
      function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
          
          
} 




 
 
 
contract LoveLock
{
address public owner;                     

uint    public lastrecordindex;           
uint    public lovelock_price;            
uint    public lovelock_price_LOV;        

address public last_buyer;                
bytes32 public last_hash;                 

address TokenContractAddress;             
ERC20Interface TokenContract;             
address public thisAddress;               

uint    public debug_last_approved;


 
 
 
struct DataRecord
{
string name1;
string name2;
string lovemessage;
uint   locktype;
uint   timestamp;
}  

mapping(bytes32 => DataRecord) public DataRecordStructs;

 
 
 
struct DataRecordIndex
{
bytes32 index_hash;
}  

mapping(uint256 => DataRecordIndex) public DataRecordIndexStructs;



 
 
 
function LoveLock () public
{
 

lovelock_price           = 10000000000000000;

lovelock_price_LOV       = 1000000000000000000*5000;  
                           
owner                    = msg.sender;

 
TokenContractAddress     = 0x26B1FBE292502da2C8fCdcCF9426304d0900b703;  
TokenContract            = ERC20Interface(TokenContractAddress); 

thisAddress              = address(this);

lastrecordindex          = 0;
}  
 



 
 
 
function withdraw_to_owner() public returns (bool)
{
if (msg.sender != owner) return (false);

 
uint256 balance = TokenContract.balanceOf(this);
TokenContract.transfer(owner, balance); 

 
owner.transfer( this.balance );

return(true);
}  



 
 
 
function number_to_hash( uint param ) public constant returns (bytes32)
{
bytes32 ret = keccak256(param);
return(ret);
}  





 
 
 
event LovelockPayment
(
address indexed _from,
bytes32 hashindex,
uint _value2
);
    
    
 
 
 
function buy_lovelock( bytes32 index_hash, string name1, string name2, string lovemessage, uint locktype ) public payable returns (uint)
{
last_buyer = msg.sender;


 
if (DataRecordStructs[index_hash].timestamp > 1000)
   {
   return 0;
   }
   

 
if ( msg.value >= lovelock_price )
   {
   
    
     
    lastrecordindex = lastrecordindex + 1;  
       
    last_hash = index_hash;
        
     
    DataRecordStructs[last_hash].name1       = name1;
    DataRecordStructs[last_hash].name2       = name2;
    DataRecordStructs[last_hash].lovemessage = lovemessage;
    DataRecordStructs[last_hash].locktype    = locktype;
    DataRecordStructs[last_hash].timestamp   = now;
   
    DataRecordIndexStructs[lastrecordindex].index_hash = last_hash;
   
     
    LovelockPayment(msg.sender, last_hash, lastrecordindex);  
    
   
   return(1);
   } else
     {
     revert();
     }

 
return(0);
}  




 
 
 
function buy_lovelock_withLOV( bytes32 index_hash, string name1, string name2, string lovemessage, uint locktype ) public returns (uint)
{
last_buyer = msg.sender;
uint256      amount_token = 0; 


 
if (DataRecordStructs[index_hash].timestamp > 1000)
   {
   return 0;
   }

    
 
amount_token = TokenContract.allowance( msg.sender, thisAddress );
debug_last_approved = amount_token;
   

if (amount_token >= lovelock_price_LOV)
   {

    
   bool success = TokenContract.transferFrom(msg.sender, thisAddress, amount_token);
          
   if (success == true)
      {   

       
       
      lastrecordindex = lastrecordindex + 1;  
            
      last_hash = index_hash;
        
       
      DataRecordStructs[last_hash].name1       = name1;
      DataRecordStructs[last_hash].name2       = name2;
      DataRecordStructs[last_hash].lovemessage = lovemessage;
      DataRecordStructs[last_hash].locktype    = locktype;
      DataRecordStructs[last_hash].timestamp   = now;

      DataRecordIndexStructs[lastrecordindex].index_hash = last_hash;
   
       
      LovelockPayment(msg.sender, last_hash, lastrecordindex);  
       
       
      }  
      else 
         {
          
         }
       
      
     
   return(1); 
   } else
     {
      
      
     }

return(0);
}  




 
 
 
function transfer_owner( address new_owner ) public returns (uint)
{
if (msg.sender != owner) return(0);
require(new_owner != 0);

owner = new_owner;
return(1);
}  





}  