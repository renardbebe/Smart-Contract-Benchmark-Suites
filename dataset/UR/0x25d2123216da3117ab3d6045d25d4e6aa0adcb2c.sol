 

pragma solidity ^0.4.16;
contract IcoData{
 
 
 
 
address Mars = 0x1947f347B6ECf1C3D7e1A58E3CDB2A15639D48Be;
address Mercury = 0x00795263bdca13104309Db70c11E8404f81576BE;
address Europa = 0x00e4E3eac5b520BCa1030709a5f6f3dC8B9e1C37;
address Jupiter = 0x2C76F260707672e240DC639e5C9C62efAfB59867;
address Neptune = 0xEB04E1545a488A5018d2b5844F564135211d3696;

 
function GetContractAddr() public constant returns (address){
return this;
}	
address ContractAddr = GetContractAddr();

struct State{
bool PrivateSale;
bool PreSale;
bool MainSale; 
bool End;
}

struct Market{
uint256 EtherPrice;    
uint256 TocPrice;    
uint256 Commission;    
} 

struct Admin{
bool Authorised; 
uint256 Level;
}

 
mapping (address => State) public state;
 
mapping (address => Market) public market;
 
mapping (address => Admin) public admin;

 
function AuthAdmin(address _admin, bool _authority, uint256 _level) external 
returns(bool) {
if((msg.sender != Mars) && (msg.sender != Mercury) && (msg.sender != Europa)
&& (msg.sender != Jupiter) && (msg.sender != Neptune)) revert();  
admin[_admin].Authorised = _authority; 
admin[_admin].Level = _level;
return true;
} 

 
function GeneralUpdate(uint256 _etherprice, uint256 _tocprice, uint256 _commission) 
external returns(bool){
     
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
 
market[ContractAddr].EtherPrice = _etherprice; 
market[ContractAddr].TocPrice = _tocprice;
market[ContractAddr].Commission = _commission;
return true;
}

 
function EtherPriceUpdate(uint256 _etherprice)external returns(bool){
     
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
 
market[ContractAddr].EtherPrice = _etherprice; 
return true;
}

 
function UpdateState(uint256 _state) external returns(bool){
     
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
 
if(_state == 1){
state[ContractAddr].PrivateSale = true; 
state[ContractAddr].PreSale = false;
state[ContractAddr].MainSale = false;
state[ContractAddr].End = false;
}
 
if(_state == 2){
state[ContractAddr].PrivateSale = false; 
state[ContractAddr].PreSale = true;
state[ContractAddr].MainSale = false;
state[ContractAddr].End = false;
}
 
if(_state == 3){
state[ContractAddr].PrivateSale = false; 
state[ContractAddr].PreSale = false;
state[ContractAddr].MainSale = true;
state[ContractAddr].End = false;
}
 
if(_state == 4){
state[ContractAddr].PrivateSale = false; 
state[ContractAddr].PreSale = false;
state[ContractAddr].MainSale = false;
state[ContractAddr].End = true;
}
return true;
}

 

 
function GetPrivateSale() public view returns (bool){
return state[ContractAddr].PrivateSale;
}
 
function GetPreSale() public view returns (bool){
return state[ContractAddr].PreSale;
}
 
function GetMainSale() public view returns (bool){
return state[ContractAddr].MainSale;
}
 
function GetEnd() public view returns (bool){
return state[ContractAddr].End;
}
 
function GetEtherPrice() public view returns (uint256){
return market[ContractAddr].EtherPrice;
}
 
function GetTocPrice() public view returns (uint256){
return market[ContractAddr].TocPrice;
}
 
function GetCommission() public view returns (uint256){
return market[ContractAddr].Commission;
}

} 



pragma solidity ^0.4.16;
contract IcoDapp{
 
 
 
 
address Mars = 0x1947f347B6ECf1C3D7e1A58E3CDB2A15639D48Be;
address Mercury = 0x00795263bdca13104309Db70c11E8404f81576BE;
address Europa = 0x00e4E3eac5b520BCa1030709a5f6f3dC8B9e1C37;
address Jupiter = 0x2C76F260707672e240DC639e5C9C62efAfB59867;
address Neptune = 0xEB04E1545a488A5018d2b5844F564135211d3696;

 
uint256 Converter = 10000;

 
function GetContractAddr() public constant returns (address){
return this;
}	
address ContractAddr = GetContractAddr();

struct Buyer{
bool Withdrawn;    
uint256 TocBalance;
uint256 WithdrawalBlock;
uint256 Num;
}

struct Transaction{
uint256 Amount;
uint256 EtherPrice;
uint256 TocPrice;
uint256 Block;
}    

struct AddressBook{
address TOCAddr;
address DataAddr;
address Banker;
}

struct Admin{
bool Authorised; 
uint256 Level;
}

struct OrderBooks{
uint256 PrivateSupply;
uint256 PreSupply;
uint256 MainSupply;
}

struct Promoters{
bool Registered;    
uint256 TotalCommission; 
}

struct PromoAdmin{
uint256 CurrentNum;
uint256 Max;    
}


 
mapping (address => Buyer) public buyer;
 
mapping(address => mapping(uint256 => Transaction)) public transaction;
 
mapping (address => OrderBooks) public orderbooks;
 
mapping (address => Promoters) public promoters;
 
mapping (address => AddressBook) public addressbook;
 
mapping (address => PromoAdmin) public promoadmin;
 
mapping (address => Admin) public admin;

struct TA{
uint256 n1;
uint256 n2;
uint256 n3;
uint256 n4;
uint256 n5;
uint256 n6;
uint256 n7;
uint256 n8;
uint256 n9;
uint256 n10;
uint256 n11;
}

struct LA{
bool l1;
bool l2;
bool l3;
}

 
TA ta;
LA la;

 
function AuthAdmin(address _admin, bool _authority, uint256 _level) external 
returns(bool) {
if((msg.sender != Mars) && (msg.sender != Mercury) && (msg.sender != Europa)
&& (msg.sender != Jupiter) && (msg.sender != Neptune)) revert();  
admin[_admin].Authorised = _authority; 
admin[_admin].Level = _level;
return true;
} 

 
function AuthAddr(address _tocaddr, address _dataddr, address _banker) 
external returns(bool){
       
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
 
addressbook[ContractAddr].TOCAddr = _tocaddr;
addressbook[ContractAddr].DataAddr = _dataddr;
addressbook[ContractAddr].Banker = _banker;
return true;
}

 
function ConfigPromoter(uint256 _max) external returns (bool){
     
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();    
     
promoadmin[ContractAddr].Max = _max; 
return true;
}

 
function AddPromoter(address _addpromoter) external returns (bool){
     
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert(); 
     
promoters[_addpromoter].Registered = true;
promoters[_addpromoter].TotalCommission = 0;
promoadmin[ContractAddr].CurrentNum += 1;
return true;
}

 
function Register(address _referrer) external returns (bool){
  
if(promoters[_referrer].Registered == false) revert();
if(promoters[msg.sender].Registered == true) revert();
if(promoadmin[ContractAddr].CurrentNum >= promoadmin[ContractAddr].Max) revert();
     
promoters[msg.sender].Registered = true;
promoters[msg.sender].TotalCommission = 0; 
promoadmin[ContractAddr].CurrentNum += 1;
return true;
}

 
function IncPrivateSupply(uint256 _privatesupply) external returns (bool){
     
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();    
     
orderbooks[ContractAddr].PrivateSupply += _privatesupply; 
return true;
}

 
function IncPreSupply(uint256 _presupply) external returns (bool){
     
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();    
     
orderbooks[ContractAddr].PreSupply += _presupply;
return true;
}

 
function IncMainSupply(uint256 _mainsupply) external returns (bool){
     
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();    
     
orderbooks[ContractAddr].MainSupply += _mainsupply;
return true;
}

 
function RefCommission(uint256 _amount, uint256 _com) internal returns (uint256){
ta.n1 = mul(_amount, _com);
ta.n2 = div(ta.n1,Converter);
return ta.n2;
}

 
function CalcToc(uint256 _etherprice, uint256 _tocprice, uint256 _deposit) 
internal returns (uint256){    
ta.n3 = mul(_etherprice, _deposit);
ta.n4 = div(ta.n3,_tocprice);
return ta.n4;
}

 
function PrivateSaleBuy(address _referrer) payable external returns (bool){
     
if(promoters[_referrer].Registered == false) revert();
if(msg.value <= 0) revert();
 
IcoData
DataCall = IcoData(addressbook[ContractAddr].DataAddr);
 
la.l1 = DataCall.GetEnd();
la.l2 = DataCall.GetPrivateSale();
ta.n5 = DataCall.GetEtherPrice();    
ta.n6 = DataCall.GetTocPrice();    
ta.n7 = DataCall.GetCommission();    
     
if(la.l1 == true) revert();
if(la.l2 == false) revert();
 
ta.n8 = CalcToc(ta.n5, ta.n6, msg.value);
if(ta.n8 > orderbooks[ContractAddr].PrivateSupply) revert();
 
ta.n9 = RefCommission(msg.value, ta.n7);
 
ta.n10 = sub(msg.value, ta.n9);
 
addressbook[ContractAddr].Banker.transfer(ta.n10);
_referrer.transfer(ta.n9);
 
orderbooks[ContractAddr].PrivateSupply -= ta.n8;
buyer[msg.sender].TocBalance += ta.n8;
buyer[msg.sender].Num += 1;
ta.n11 = buyer[msg.sender].Num; 
transaction[msg.sender][ta.n11].Amount = ta.n8;
transaction[msg.sender][ta.n11].EtherPrice = ta.n5;
transaction[msg.sender][ta.n11].TocPrice = ta.n6;
transaction[msg.sender][ta.n11].Block = block.number;
promoters[_referrer].TotalCommission += ta.n9;
return true;
}    

 
function PreSaleBuy(address _referrer) payable external returns (bool){
     
if(promoters[_referrer].Registered == false) revert();
if(msg.value <= 0) revert();
 
IcoData
DataCall = IcoData(addressbook[ContractAddr].DataAddr);
 
la.l1 = DataCall.GetEnd();
la.l2 = DataCall.GetPreSale();
ta.n5 = DataCall.GetEtherPrice();    
ta.n6 = DataCall.GetTocPrice();    
ta.n7 = DataCall.GetCommission();    
     
if(la.l1 == true) revert();
if(la.l2 == false) revert();
 
ta.n8 = CalcToc(ta.n5, ta.n6, msg.value);
if(ta.n8 > orderbooks[ContractAddr].PreSupply) revert();
 
ta.n9 = RefCommission(msg.value, ta.n7);
 
ta.n10 = sub(msg.value, ta.n9);
 
addressbook[ContractAddr].Banker.transfer(ta.n10);
_referrer.transfer(ta.n9);
 
orderbooks[ContractAddr].PreSupply -= ta.n8;
buyer[msg.sender].TocBalance += ta.n8;
buyer[msg.sender].Num += 1;
ta.n11 = buyer[msg.sender].Num; 
transaction[msg.sender][ta.n11].Amount = ta.n8;
transaction[msg.sender][ta.n11].EtherPrice = ta.n5;
transaction[msg.sender][ta.n11].TocPrice = ta.n6;
transaction[msg.sender][ta.n11].Block = block.number;
promoters[_referrer].TotalCommission += ta.n9;
return true;
}    


 
function MainSaleBuy() payable external returns (bool){
     
if(msg.value <= 0) revert();
 
IcoData
DataCall = IcoData(addressbook[ContractAddr].DataAddr);
 
la.l1 = DataCall.GetEnd();
la.l2 = DataCall.GetMainSale();
ta.n5 = DataCall.GetEtherPrice();    
ta.n6 = DataCall.GetTocPrice();    
ta.n7 = DataCall.GetCommission();    
     
if(la.l1 == true) revert();
if(la.l2 == false) revert();
 
ta.n8 = CalcToc(ta.n5, ta.n6, msg.value);
if(ta.n8 > orderbooks[ContractAddr].MainSupply) revert();
 
addressbook[ContractAddr].Banker.transfer(msg.value);
 
orderbooks[ContractAddr].MainSupply -= ta.n8;
buyer[msg.sender].TocBalance += ta.n8;
buyer[msg.sender].Num += 1;
ta.n9 = buyer[msg.sender].Num; 
transaction[msg.sender][ta.n9].Amount = ta.n8;
transaction[msg.sender][ta.n11].EtherPrice = ta.n5;
transaction[msg.sender][ta.n11].TocPrice = ta.n6;
transaction[msg.sender][ta.n9].Block = block.number;
return true;
}    

 
function Withdraw() external returns (bool){
 
IcoData
DataCall = IcoData(addressbook[ContractAddr].DataAddr);
 
la.l3 = DataCall.GetEnd();
  
if(la.l3 == false) revert();
if(buyer[msg.sender].TocBalance <= 0) revert();
if(buyer[msg.sender].Withdrawn == true) revert();
 
buyer[msg.sender].Withdrawn = true;
buyer[msg.sender].WithdrawalBlock = block.number;
 
TOC
TOCCall = TOC(addressbook[ContractAddr].TOCAddr);
 
assert(buyer[msg.sender].Withdrawn == true);
 
TOCCall.transfer(msg.sender,buyer[msg.sender].TocBalance);
 
assert(buyer[msg.sender].Withdrawn == true);
return true;
}  

 
function receiveApproval(address _from, uint256 _value, 
address _token, bytes _extraData) external returns(bool){ 
TOC
TOCCall = TOC(_token);
TOCCall.transferFrom(_from,this,_value);
return true;
}

 
function () payable external{
revert();  
}

 
function mul(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
function div(uint256 a, uint256 b) public pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }  
function sub(uint256 a, uint256 b) public pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
function add(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
} 


pragma solidity ^0.4.16;

 
interface tokenRecipient { 
function receiveApproval(address _from, uint256 _value, 
address _token, bytes _extraData) external; 
}

contract TOC {
 

 
string public name;
string public symbol;
uint8 public decimals;
uint256 public totalSupply;

 
mapping (address => uint256) public balances;
 
mapping(address => mapping (address => uint256)) public allowed;

 		
 
event Transfer(address indexed from, address indexed to, uint256 value);
 
event Approval(address indexed _owner, address indexed _spender, uint _value);

 
constructor() public {
name = "TokenChanger";
symbol = "TOC";
decimals = 18;
 
totalSupply = 10**27;
balances[msg.sender] = totalSupply; 
}

 
function _transfer(address _from, address _to, uint _value) internal {    
     
if(_to == 0x0) revert();
 
if(balances[_from] < _value) revert(); 
 
if(balances[_to] + _value < balances[_to]) revert();
 
uint PreviousBalances = balances[_from] + balances[_to];
 
balances[_from] -= _value;
 
balances[_to] += _value; 
 
assert(balances[_from] + balances[_to] == PreviousBalances);
 
emit Transfer(_from, _to, _value); 
}

 
function transfer(address _to, uint256 _value) external returns (bool){
_transfer(msg.sender, _to, _value);
return true;
}

 
function approve(address _spender, uint256 _value) public returns (bool success){
     
allowed[msg.sender][_spender] = _value;
 
emit Approval(msg.sender, _spender, _value); 
return true;                                        
}

 
function transferFrom(address _from, address _to, uint256 _value) 
external returns (bool success) {
 
require(_value <= allowed[_from][msg.sender]); 
 
allowed[_from][msg.sender] -= _value;
 
_transfer(_from, _to, _value);
return true;
}

 
function approveAndCall(address _spender, uint256 _value, 
 bytes _extraData) external returns (bool success) {
tokenRecipient 
spender = tokenRecipient(_spender);
if(approve(_spender, _value)) {
spender.receiveApproval(msg.sender, _value, this, _extraData);
}
return true;
}

 
function () payable external{
revert();  
}
} 