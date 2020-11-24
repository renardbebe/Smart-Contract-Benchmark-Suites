 

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

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
}
contract GGG {
 

using SafeMath for uint256;

mapping (address => bool) private admins;
string public name;
string public symbol;
uint8 public decimals = 18;
uint256 public remainRewards;
address public distributeA;
 
uint256 public totalSupply;

address contractCreator;
 
mapping (address => uint256) public balanceOf;
mapping (address => mapping (address => uint256)) public allowance;

 
event Transfer(address indexed from, address indexed to, uint256 value);

 
event Burn(address indexed from, uint256 value);

 
function GGG() public {
totalSupply = 100000000000 * 10 ** uint256(decimals);   
balanceOf[msg.sender] = totalSupply.div(4);                 
remainRewards = totalSupply - balanceOf[msg.sender];
name = "Goyougame";                                    
symbol = "GGG";                                

contractCreator = msg.sender;
admins[contractCreator] = true;
}

 
modifier onlyContractCreator() {
require (msg.sender == contractCreator);
_;
}
modifier onlyAdmins() {
require(admins[msg.sender]);
_;
}

 

 
function setOwner (address _owner) onlyContractCreator() public {
contractCreator = _owner;
}

function addAdmin (address _admin) onlyContractCreator() public {
admins[_admin] = true;
}

function removeAdmin (address _admin) onlyContractCreator() public {
delete admins[_admin];
}

function getDsitribute(address _who, uint _amount) public onlyAdmins{

remainRewards = remainRewards - _amount;
balanceOf[_who] =  balanceOf[_who] + _amount;
Transfer(distributeA, _who, _amount * 10 ** uint256(decimals));


}

function getDsitributeMulti(address[] _who, uint[] _amount) public onlyAdmins{
require(_who.length == _amount.length);
for(uint i=0; i <= _who.length; i++){
remainRewards = remainRewards - _amount[i];
balanceOf[_who[i]] =  balanceOf[_who[i]] + _amount[i];
Transfer(distributeA, _who[i], _amount[i] * 10 ** uint256(decimals));

}
}
 
function _transfer(address _from, address _to, uint _value) internal {
 
require(_to != 0x0);
 
require(balanceOf[_from] >= _value);
 
require(balanceOf[_to] + _value > balanceOf[_to]);
 
uint previousBalances = balanceOf[_from] + balanceOf[_to];
 
balanceOf[_from] -= _value;
 
balanceOf[_to] += _value;
Transfer(_from, _to, _value);
 
assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
}

 
function transfer(address _to, uint256 _value) public {
_transfer(msg.sender, _to, _value);
}

function setaddress(address _dis) public onlyAdmins{
distributeA = _dis;

}
 
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
require(_value <= allowance[_from][msg.sender]);      
allowance[_from][msg.sender] -= _value;
_transfer(_from, _to, _value);
return true;
}

 
function approve(address _spender, uint256 _value) public
returns (bool success) {
allowance[msg.sender][_spender] = _value;
return true;
}

 
function approveAndCall(address _spender, uint256 _value, bytes _extraData)
public
returns (bool success) {
tokenRecipient spender = tokenRecipient(_spender);
if (approve(_spender, _value)) {
spender.receiveApproval(msg.sender, _value, this, _extraData);
return true;
}
}

 
function burn(uint256 _value) public returns (bool success) {
require(balanceOf[msg.sender] >= _value);    
balanceOf[msg.sender] -= _value;             
totalSupply -= _value;                       
Burn(msg.sender, _value);
return true;
}

 
function burnFrom(address _from, uint256 _value) public returns (bool success) {
require(balanceOf[_from] >= _value);                 
require(_value <= allowance[_from][msg.sender]);     
balanceOf[_from] -= _value;                          
allowance[_from][msg.sender] -= _value;              
totalSupply -= _value;                               
Burn(_from, _value);
return true;
}
}