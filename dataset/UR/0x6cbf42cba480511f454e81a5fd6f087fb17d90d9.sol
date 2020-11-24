 

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

 		
 
event BroadcastTransfer(address indexed from, address indexed to, uint256 value);
 
event BroadcastApproval(address indexed _owner, address indexed _spender, uint _value);

 
function TOC() public {
name = "TOC";
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
 
emit BroadcastTransfer(_from, _to, _value); 
}

 
function transfer(address _to, uint256 _value) external returns (bool){
_transfer(msg.sender, _to, _value);
return true;
}

 
function approve(address _spender, uint256 _value) public returns (bool success){
     
allowed[msg.sender][_spender] = _value;
 
emit BroadcastApproval(msg.sender, _spender, _value); 
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

} 


pragma solidity ^0.4.16;
contract BlockPoints{
 
 
 
 
address Mars = 0x1947f347B6ECf1C3D7e1A58E3CDB2A15639D48Be;
address Mercury = 0x00795263bdca13104309Db70c11E8404f81576BE;
address Europa = 0x00e4E3eac5b520BCa1030709a5f6f3dC8B9e1C37;
address Jupiter = 0x2C76F260707672e240DC639e5C9C62efAfB59867;
address Neptune = 0xEB04E1545a488A5018d2b5844F564135211d3696;

 
function GetContractAddr() public constant returns (address){
return this;
}	
address ContractAddr = GetContractAddr();

 
string public Name;
string public Symbol;
uint8 public Decimals;
uint256 public TotalSupply;

struct Global{
bool Suspend;
uint256 Rate;
}

struct DApps{
bool AuthoriseMint;
bool AuthoriseBurn;
bool AuthoriseRate;
}
 
struct Admin{
bool Authorised; 
uint256 Level;
}

struct Coloured{
uint256 Amount;
uint256 Rate;
}

struct AddressBook{
address TOCAddr;
}

struct Process{
uint256 n1;
uint256 n2;
uint256 n3;
uint256 n4;
uint256 n5;
}

 
Process pr;

 
mapping (address => Global) public global;
 
mapping (address => uint256) public balances;
 
mapping (address => DApps) public dapps;
 
mapping(address => mapping(address => Coloured)) public coloured;
 
mapping (address => Admin) public admin;
 
mapping (address => AddressBook) public addressbook;


 
function BlockPoints() public {
Name = 'BlockPoints';
Symbol = 'BKP';
Decimals = 0;
TotalSupply = 1;
balances[msg.sender] = TotalSupply; 
}

 
event BrodMint(address indexed from, address indexed enduser, uint256 amount);
 
event BrodBurn(address indexed from, address indexed enduser, uint256 amount);

 
function receiveApproval(address _from, uint256 _value, 
address _token, bytes _extraData) external returns(bool){ 
TOC
TOCCall = TOC(_token);
TOCCall.transferFrom(_from,this,_value);
return true;
}

 
function AuthAdmin (address _admin, bool _authority, uint256 _level) external 
returns(bool){
if((msg.sender != Mars) && (msg.sender != Mercury) && (msg.sender != Europa) &&
(msg.sender != Jupiter) && (msg.sender != Neptune)) revert();      
admin[_admin].Authorised = _authority;
admin[_admin].Level = _level;
return true;
}

 
function AuthAddr(address _tocaddr) external returns(bool){
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 3 ) revert();
addressbook[ContractAddr].TOCAddr = _tocaddr;
return true;
}

 
function AuthDapps (address _dapp, bool _mint, bool _burn, bool _rate) external 
returns(bool){
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5) revert();
dapps[_dapp].AuthoriseMint = _mint;
dapps[_dapp].AuthoriseBurn = _burn;
dapps[_dapp].AuthoriseRate = _rate;
return true;
}

 
function AuthSuspend (bool _suspend) external returns(bool){
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 3) revert();
global[ContractAddr].Suspend = _suspend;
return true;
}

 
function SetRate (uint256 _globalrate) external returns(bool){
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5) revert();
global[ContractAddr].Rate = _globalrate;
return true;
}

 
function SpecialRate (address _user, address _dapp, uint256 _amount, uint256 _rate) 
external returns(bool){
     
if(dapps[msg.sender].AuthoriseRate == false) revert(); 
if(dapps[_dapp].AuthoriseRate == false) revert(); 
coloured[_user][_dapp].Amount += _amount;
coloured[_user][_dapp].Rate = _rate;
return true;
}


 
function Reward(address r_to, uint256 r_amount) external returns (bool){
     
if(dapps[msg.sender].AuthoriseMint == false) revert(); 
 
balances[r_to] += r_amount;
 
TotalSupply += r_amount;
 
emit BrodMint(msg.sender,r_to,r_amount);     
return true;
}

 
function ConvertBkp(uint256 b_amount) external returns (bool){
 
require(global[ContractAddr].Suspend == false);
require(b_amount > 0);
require(global[ContractAddr].Rate > 0);
 
pr.n1 = sub(balances[msg.sender],b_amount);
 
require(balances[msg.sender] >= b_amount); 
 
balances[msg.sender] -= b_amount;
TotalSupply -= b_amount;
 
pr.n2 = mul(b_amount,global[ContractAddr].Rate);
 
TOC
TOCCall = TOC(addressbook[ContractAddr].TOCAddr);
 
assert(pr.n1 == balances[msg.sender]);
 
TOCCall.transfer(msg.sender,pr.n2);
return true;
}

 
function ConvertColouredBkp(address _dapp) external returns (bool){
 
require(global[ContractAddr].Suspend == false);
require(coloured[msg.sender][_dapp].Rate > 0);
 
uint256 b_amount = coloured[msg.sender][_dapp].Amount;
require(b_amount > 0);
 
require(balances[msg.sender] >= b_amount); 
 
pr.n3 = sub(coloured[msg.sender][_dapp].Amount,b_amount);
pr.n4 = sub(balances[msg.sender],b_amount);
 
coloured[msg.sender][_dapp].Amount -= b_amount;
balances[msg.sender] -= b_amount;
TotalSupply -= b_amount;
 
pr.n5 = mul(b_amount,coloured[msg.sender][_dapp].Rate);
 
TOC
TOCCall = TOC(addressbook[ContractAddr].TOCAddr);
 
assert(pr.n3 == coloured[msg.sender][_dapp].Amount);
assert(pr.n4 == balances[msg.sender]);
 
TOCCall.transfer(msg.sender,pr.n5);
return true;
}

 
function Burn(address b_to, uint256 b_amount) external returns (bool){
     
if(dapps[msg.sender].AuthoriseBurn == false) revert();    
 
require(balances[b_to] >= b_amount); 
 
balances[b_to] -= b_amount;
 
TotalSupply -= b_amount;
 
emit BrodBurn(msg.sender, b_to,b_amount); 
return true;
}

 
function mul(uint256 a, uint256 b) public pure returns (uint256) {
uint256 c = a * b;
assert(a == 0 || c / a == b);
return c;
  }
function sub(uint256 a, uint256 b) public pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }  
  
} 