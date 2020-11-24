 

 



 
 
 
contract LoveLock
{
address public owner;                     

uint    public lastrecordindex;           
uint    public lovelock_price;            

address public last_buyer;                
bytes32 public last_hash;                 


 
 
 
struct DataRecord
{
string name1;
string name2;
string lovemessage;
uint   locktype;
}  

mapping(bytes32 => DataRecord) public DataRecordStructs;





 
 
 
function LoveLock () public
{
 

 
 
lovelock_price             = 1100000000000000;
owner                    = msg.sender;
lastrecordindex          = 0;
}  
 



 
 
 
function withdraw_to_reward_contract() public constant returns (bool)
{
address reward_contract = 0xF711233A0Bec76689FEA4870cc6f4224334DB9c3;
reward_contract.transfer( this.balance );
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
    
    
 
 
 
function buy_lovelock( string name1, string name2, string lovemessage, uint locktype ) public payable returns (uint)
{
last_buyer = msg.sender;

 
if ( msg.value >= lovelock_price )
   {
    
   lastrecordindex = lastrecordindex + 1;  
       
    
   last_hash = keccak256(lastrecordindex);  
        
    
   DataRecordStructs[last_hash].name1       = name1;
   DataRecordStructs[last_hash].name2       = name2;
   DataRecordStructs[last_hash].lovemessage = lovemessage;
   DataRecordStructs[last_hash].locktype    = locktype;
   
    
   LovelockPayment(msg.sender, last_hash, lastrecordindex);  
   
   return(1);
   } else
     {
     revert();
     }

 
return(0);
} 







 
 
 
function kill () public
{
if (msg.sender != owner) return;

 
owner.transfer( this.balance );
selfdestruct(owner);
}  



}  