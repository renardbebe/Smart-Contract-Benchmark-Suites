 

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

 
function TOC() public {
name = "Token Changer";
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

pragma solidity ^0.4.22;

contract AirdropDIST {
 

 
address Mars = 0x1947f347B6ECf1C3D7e1A58E3CDB2A15639D48Be;
address Mercury = 0x00795263bdca13104309Db70c11E8404f81576BE;
address Europa = 0x00e4E3eac5b520BCa1030709a5f6f3dC8B9e1C37;
address Jupiter = 0x2C76F260707672e240DC639e5C9C62efAfB59867;
address Neptune = 0xEB04E1545a488A5018d2b5844F564135211d3696;

 
function GetContractAddr() public constant returns (address){
return this;
}	
address ContractAddr = GetContractAddr();


 
struct Accounting{
bool Received;    
}

struct Admin{
bool Authorised; 
uint256 Level;
}

struct Config{
uint256 TocAmount;	
address TocAddr;
}

 
mapping (address => Accounting) public account;
mapping (address => Config) public config;
mapping (address => Admin) public admin;

 
function AuthAdmin(address _admin, bool _authority, uint256 _level) external 
returns(bool) {
if((msg.sender != Mars) && (msg.sender != Mercury) && (msg.sender != Europa)
&& (msg.sender != Jupiter) && (msg.sender != Neptune)) revert();  
admin[_admin].Authorised = _authority; 
admin[_admin].Level = _level;
return true;
} 

 
function SetUp(uint256 _amount, address _tocaddr) external returns(bool){
       
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
 
config[ContractAddr].TocAmount = _amount;
config[ContractAddr].TocAddr = _tocaddr;
return true;
}

 
function receiveApproval(address _from, uint256 _value, 
address _token, bytes _extraData) external returns(bool){ 
TOC
TOCCall = TOC(_token);
TOCCall.transferFrom(_from,this,_value);
return true;
}

 
function Withdraw(uint256 _amount) external returns(bool){
       
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
 
TOC
TOCCall = TOC(config[ContractAddr].TocAddr);
TOCCall.transfer(msg.sender, _amount);
return true;
}

 
function Get() external returns(bool){
       
if(account[msg.sender].Received == true) revert();
 
account[msg.sender].Received = true;
 
TOC
TOCCall = TOC(config[ContractAddr].TocAddr);
TOCCall.transfer(msg.sender, config[ContractAddr].TocAmount);
       
assert(account[msg.sender].Received == true);
return true;
}

 
function () payable external{
revert();  
}

} 