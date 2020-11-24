 

pragma solidity ^0.4.24;

contract PerformanceBond {
 

 
address Mars = 0x1947f347B6ECf1C3D7e1A58E3CDB2A15639D48Be;
address Mercury = 0x00795263bdca13104309Db70c11E8404f81576BE;
address Europa = 0x00e4E3eac5b520BCa1030709a5f6f3dC8B9e1C37;
address Jupiter = 0x2C76F260707672e240DC639e5C9C62efAfB59867;
address Neptune = 0xEB04E1545a488A5018d2b5844F564135211d3696;

 
function GetContractAddr() public constant returns (address){
return this;
}	
address ContractAddr = GetContractAddr();

 
uint256 PercentConverter = 10000;

 
struct Bond{
uint256 BondNum;
}

struct Specification{
uint256 WriterDeposit;
uint256 BeneficiaryStake;
uint256 BeneficiaryDeposit;
uint256 ExtensionLimit;
uint256 CreationBlock;
uint256 ExpirationBlock;
address BondWriter;
address BondBeneficiary;
bool StopExtension;
bool Activated;
bool Dispute;
uint256 CtrFee;
uint256 ArbFee;
}

struct Agreement{
address Arbiter;
bool Writer;    
bool Beneficiary;    
}

struct Settlement{
uint256 Writer;    
uint256 Beneficiary;
bool WriterSettled;
bool BeneficiarySettled;
bool Judgement;
}

struct User{
uint256 TransactionNum;
}

struct Log{
uint256 BondNum;
}

struct Admin{
bool Authorised; 
uint256 Level;
}

struct Arbiter{
bool Registered; 
}

struct Configuration{
uint256 ArbiterFee;
uint256 ContractFee;
uint256 StakePercent;
address Banker;
}

struct TR{
uint256 n0;    
uint256 n1;
uint256 n2;
uint256 n3;
uint256 n4;
uint256 n5;
uint256 n6;
uint256 n7;
uint256 n8;
uint256 n9;
}

struct Identifier {
uint256 c0;    
uint256 c1;
uint256 c2;
uint256 c3;
uint256 c4;
uint256 c5;
uint256 c6;
uint256 c7;
}

 
TR tr;
Identifier id;

 
mapping (address => Bond) public bond;
mapping (uint256 => Specification) public spec;
mapping (uint256 => Agreement) public agree;
mapping (address => User) public user;
mapping (uint256 => Settlement) public settle;
mapping (address => mapping (uint256 => Log)) public tracker;
mapping (address => Configuration) public config;
mapping (address => Admin) public admin;
mapping (address => Arbiter) public arbiter;

 
function AuthAdmin(address _admin, bool _authority, uint256 _level) external 
returns(bool) {
if((msg.sender != Mars) && (msg.sender != Mercury) && (msg.sender != Europa)
&& (msg.sender != Jupiter) && (msg.sender != Neptune)) revert();  
admin[_admin].Authorised = _authority; 
admin[_admin].Level = _level;
return true;
} 

 
function SetUp(uint256 _afee,uint256 _cfee,uint256 _spercent,address _banker) 
external returns(bool){
       
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
 
config[ContractAddr].ArbiterFee = _afee;
config[ContractAddr].ContractFee = _cfee;
config[ContractAddr].StakePercent = _spercent;
config[ContractAddr].Banker = _banker;
return true;
}

 
function Register(address arbiter_, bool authority_) external 
returns(bool) {
       
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
 
arbiter[arbiter_].Registered = authority_; 
return true;
}

 
function Percent(uint256 _value, uint256 _percent) internal returns(uint256){
tr.n1 = mul(_value,_percent);
tr.n2 = div(tr.n1,PercentConverter);
return tr.n2;
} 

 
function WriteBond(uint256 _expire, address _bene, address _arbi) payable external returns (bool){
     
if(msg.value <= 0) revert();
require(arbiter[_arbi].Registered == true);
 
bond[ContractAddr].BondNum += 1;
tr.n3 = bond[ContractAddr].BondNum; 
 
spec[tr.n3].WriterDeposit = msg.value;
tr.n4 = Percent(msg.value,config[ContractAddr].StakePercent);
spec[tr.n3].BeneficiaryStake = tr.n4;
spec[tr.n3].ExtensionLimit = _expire;
spec[tr.n3].CreationBlock = block.number;
tr.n5 = add(block.number,_expire);
spec[tr.n3].ExpirationBlock = tr.n5;
spec[tr.n3].BondWriter = msg.sender;
spec[tr.n3].BondBeneficiary = _bene;
 
user[msg.sender].TransactionNum += 1;
tr.n6 = user[msg.sender].TransactionNum;
tracker[msg.sender][tr.n6].BondNum = tr.n3;
 
user[_bene].TransactionNum += 1;
tr.n7 = user[_bene].TransactionNum;
tracker[_bene][tr.n7].BondNum = tr.n3;
 
agree[tr.n3].Arbiter = _arbi;
agree[tr.n3].Writer = true;
 
tr.n0 = Percent(msg.value,config[ContractAddr].ContractFee);
id.c0 = Percent(msg.value,config[ContractAddr].ArbiterFee);
 
spec[tr.n3].CtrFee = tr.n0;
spec[tr.n3].ArbFee = id.c0;
return true;
}    

 
function ChangeExtension(uint256 _bondnum, bool _change) external returns(bool){
      
require(spec[_bondnum].BondWriter == msg.sender);
 
spec[_bondnum].StopExtension = _change;
return true;
} 

 
function BeneficiaryStake(uint256 _bondnum) payable external returns(bool){
 
if(msg.value <= 0) revert();
require(spec[_bondnum].BondBeneficiary == msg.sender);
require(spec[_bondnum].ExpirationBlock >= block.number);
require(spec[_bondnum].Activated == false);
require(settle[_bondnum].WriterSettled == false);
require(msg.value >= spec[_bondnum].BeneficiaryStake);
 
spec[_bondnum].Activated = true;
spec[_bondnum].BeneficiaryDeposit = msg.value;
return true;
} 

 
function Appoint(uint256 _bondnum, address _arbi) external returns(bool){
 
require(arbiter[_arbi].Registered == true); 
if((agree[_bondnum].Writer ==true) && (agree[_bondnum].Beneficiary == true)) revert();
      
if(spec[_bondnum].BondBeneficiary == msg.sender){
agree[_bondnum].Arbiter = _arbi;
agree[_bondnum].Beneficiary = true;
agree[_bondnum].Writer = false;
}
      
if(spec[_bondnum].BondWriter == msg.sender){
agree[_bondnum].Arbiter = _arbi;
agree[_bondnum].Writer = true;
agree[_bondnum].Beneficiary = false;
}
return true;
} 

 
function Dispute(uint256 _bondnum) external returns(bool){
      
require(spec[_bondnum].Activated == true);
require(settle[_bondnum].WriterSettled == false);    
require(settle[_bondnum].BeneficiarySettled == false);      
      
if(spec[_bondnum].BondBeneficiary == msg.sender){
spec[_bondnum].Dispute = true;
}
      
if(spec[_bondnum].BondWriter == msg.sender){
spec[_bondnum].Dispute = true;
}
return true;
} 

 
function Approve(uint256 _bondnum) external returns(bool){
      
if(spec[_bondnum].BondBeneficiary == msg.sender){
agree[_bondnum].Beneficiary = true;
}
      
if(spec[_bondnum].BondWriter == msg.sender){
agree[_bondnum].Writer = true;
}
return true;
} 

 
function Judgement(uint256 _bondnum, uint256 writer_, uint256 bene_) external returns(bool){
  
require(spec[_bondnum].Dispute == true);
require(agree[_bondnum].Arbiter == msg.sender);
require(agree[_bondnum].Writer == true);
require(agree[_bondnum].Beneficiary == true);
require(settle[_bondnum].Judgement == false);
 
settle[_bondnum].Judgement = true;
 
tr.n8 = add(spec[_bondnum].WriterDeposit,spec[_bondnum].BeneficiaryDeposit);
tr.n9 = add(writer_,bene_);
assert(tr.n9 <= tr.n8);
 
settle[_bondnum].Writer = writer_;
settle[_bondnum].Beneficiary = bene_;
return true;
} 

 
function Extend(uint256 _bondnum, uint256 _blocks) external returns(bool){
   
require(spec[_bondnum].StopExtension == false);
require(spec[_bondnum].BondBeneficiary == msg.sender);
require(spec[_bondnum].ExpirationBlock >= block.number);
require(_blocks <= spec[_bondnum].ExtensionLimit);
 
spec[_bondnum].ExpirationBlock = add(block.number,_blocks);
return true;
} 

 
function SettleBond(uint256 _bondnum) external returns(bool){
      
id.c1 = spec[_bondnum].CtrFee;
id.c2 = spec[_bondnum].ArbFee;
id.c3 = add(id.c1,id.c2);

 
if((spec[_bondnum].BondWriter == msg.sender) && (spec[_bondnum].Activated == false)){
  
require(settle[_bondnum].WriterSettled == false);
 
settle[_bondnum].WriterSettled = true;
 
msg.sender.transfer(spec[_bondnum].WriterDeposit);
assert(settle[_bondnum].WriterSettled == true);
}

 
if((block.number > spec[_bondnum].ExpirationBlock) && (spec[_bondnum].Dispute == false)
&& (spec[_bondnum].BondWriter == msg.sender) && (spec[_bondnum].Activated == true)){
  
require(settle[_bondnum].WriterSettled == false);
 
settle[_bondnum].WriterSettled = true;
 
id.c4 = sub(spec[_bondnum].WriterDeposit,id.c3);
config[ContractAddr].Banker.transfer(id.c1);
agree[_bondnum].Arbiter.transfer(id.c2);
msg.sender.transfer(id.c4);
assert(settle[_bondnum].WriterSettled == true);
} 

 
if((settle[_bondnum].Judgement == true) && (spec[_bondnum].Dispute == true)
&& (spec[_bondnum].BondWriter == msg.sender)){
  
require(settle[_bondnum].WriterSettled == false);
 
settle[_bondnum].WriterSettled = true;
 
if(settle[_bondnum].Writer > id.c3){
id.c5 = sub(settle[_bondnum].Writer,id.c3);
config[ContractAddr].Banker.transfer(id.c1);
agree[_bondnum].Arbiter.transfer(id.c2);
msg.sender.transfer(id.c5);
} 
assert(settle[_bondnum].WriterSettled == true);
}

 
if((settle[_bondnum].Judgement == true) && (spec[_bondnum].Dispute == true)
&& (spec[_bondnum].BondBeneficiary == msg.sender)){
  
require(settle[_bondnum].BeneficiarySettled == false);
 
settle[_bondnum].BeneficiarySettled = true;
 
if(settle[_bondnum].Beneficiary > id.c3){
id.c6 = sub(settle[_bondnum].Beneficiary,id.c3);
config[ContractAddr].Banker.transfer(id.c1);
agree[_bondnum].Arbiter.transfer(id.c2);
msg.sender.transfer(id.c6);
} 
assert(settle[_bondnum].BeneficiarySettled == true);
}

 
if((block.number > spec[_bondnum].ExpirationBlock) && (spec[_bondnum].Dispute == false)
&& (spec[_bondnum].BondBeneficiary == msg.sender) && (spec[_bondnum].Activated == true)){
  
require(settle[_bondnum].BeneficiarySettled == false);
 
settle[_bondnum].BeneficiarySettled = true;
 
id.c7 = sub(spec[_bondnum].BeneficiaryDeposit,id.c3);
config[ContractAddr].Banker.transfer(id.c1);
agree[_bondnum].Arbiter.transfer(id.c2);
msg.sender.transfer(id.c7);
assert(settle[_bondnum].BeneficiarySettled == true);
} 

return true;
}  

 
function () payable external{
revert();  
}

 
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
  
function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }  
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
} 