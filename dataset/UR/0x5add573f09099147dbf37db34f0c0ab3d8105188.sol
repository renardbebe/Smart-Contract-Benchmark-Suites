 

pragma solidity ^0.4.18;
 
 
 
 
 
 
 
 
 
 
 


 
 
 
library SafeMath {
function add(uint a, uint b) internal pure returns (uint c) {
c = a + b;
require(c >= a);
}
function sub(uint a, uint b) internal pure returns (uint c) {
require(b <= a);
c = a - b;
}
function mul(uint a, uint b) internal pure returns (uint c) {
c = a * b;
require(a == 0 || c / a == b);
}
function div(uint a, uint b) internal pure returns (uint c) {
require(b > 0);
c = a / b;
}
}


 
 
 
 
contract ERC20Interface {
function totalSupply() public constant returns (uint);
function balanceOf(address tokenOwner) public constant returns (uint balance);
function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
function transfer(address to, uint tokens) public returns (bool success);
function approve(address spender, uint tokens) public returns (bool success);
function transferFrom(address from, address to, uint tokens) public returns (bool success);

event Transfer(address indexed from, address indexed to, uint tokens);
event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
contract ApproveAndCallFallBack {
function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

 
 
 
contract Owned {
address public owner;
address public newOwner;

event OwnershipTransferred(address indexed _from, address indexed _to);

function Owned() public {
owner = msg.sender;
}

modifier onlyOwner {
require(msg.sender == owner);
_;
}

function transferOwnership(address _newOwner) public onlyOwner {
newOwner = _newOwner;
}

function acceptOwnership() public {
require(msg.sender == newOwner);
OwnershipTransferred(owner, newOwner);
owner = newOwner;
newOwner = address(0);
}
}


 
 
 
 
contract InGRedientToken  is ERC20Interface, Owned {
using SafeMath for uint;

string public symbol;
string public  name;
uint8 public decimals;
uint public _totalSupply;

mapping(address => uint) balances;
mapping(address => mapping(address => uint)) allowed;


 
 
 
function InGRedientToken() public {
symbol = "IGR";
name = "InGRedientToken";
decimals = 3;  
_totalSupply = 1000000000000000000000 * 10**uint(decimals);
balances[owner] = _totalSupply;
Transfer(address(0), owner, _totalSupply);
}


 
 
 
function totalSupply() public constant returns (uint) {
return _totalSupply  - balances[address(0)];
}


 
 
 
function balanceOf(address tokenOwner) public constant returns (uint balance) {
return balances[tokenOwner];
}

 
 
 
 
 
 
 
 
function approve(address spender, uint tokens) public returns (bool success) {
allowed[msg.sender][spender] = tokens;
Approval(msg.sender, spender, tokens);
return true;
}

 
 
 
 
 
function transfer(address to, uint tokens) public returns (bool success) {
balances[msg.sender] = balances[msg.sender].sub(tokens);
balances[to] = balances[to].add(tokens);
Transfer(msg.sender, to, tokens);
return true;
}

 
 
 
 
 
 
 
 
 
function transferFrom(address from, address to, uint tokens) public returns (bool success) {
balances[from] = balances[from].sub(tokens);
allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
balances[to] = balances[to].add(tokens);
Transfer(from, to, tokens);
return true;
}


 
 
 
 
function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
return allowed[tokenOwner][spender];
}


 
 
 
 
 
function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
allowed[msg.sender][spender] = tokens;
Approval(msg.sender, spender, tokens);
ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
return true;
}

 
 
 
function () public payable {
revert();
}


 
 
 
function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
return ERC20Interface(tokenAddress).transfer(owner, tokens);
}



 
 
 

event  FarmerRequestedCertificate(address owner, address certAuth, uint tokens);
 
 
 
function farmerRequestCertificate(address _certAuth, uint _tokens, string _product,string _IngValueProperty, string _localGPSProduction, string  _dateProduction ) public returns (bool success) {
 
allowed[owner][_certAuth] = _tokens;
Approval(owner, _certAuth, _tokens);
FarmerRequestedCertificate(owner, _certAuth, _tokens);
return true;
}

 
 
 
 
function certAuthIssuesCerticate(address owner, address farmer, uint tokens, string _url,string product,string IngValueProperty, string localGPSProduction, uint dateProduction ) public returns (bool success) {
balances[owner] = balances[owner].sub(tokens);
 
allowed[owner][msg.sender] = 0;
balances[farmer] = balances[farmer].add(tokens);
Transfer(owner, farmer, tokens);
return true;
}

 
 
 
function sellsIngrWithoutDepletion(address to, uint tokens,string _url) public returns (bool success) {
string memory url=_url;  
balances[msg.sender] = balances[msg.sender].sub(tokens);
balances[to] = balances[to].add(tokens);
Transfer(msg.sender, to, tokens);
return true;
}

 
 
 
 
 
function sellsIntermediateGoodWithDepletion(address to, uint tokens,string _url,uint out2inIngredientPercentage ) public returns (bool success) {
string memory url=_url;  
require (out2inIngredientPercentage <= 100);  
balances[msg.sender] = balances[msg.sender].sub((tokens*(100-out2inIngredientPercentage))/100); 
transfer(to, tokens*out2inIngredientPercentage/100);
return true;
}

 
 
 
 
 
function genAddressFromGTIN13date(string _GTIN13,string _YYMMDD) constant returns(address c){
bytes32 a= keccak256(_GTIN13,_YYMMDD);
address b = address(a);
return b;
}

 
 
 
 
 
 
function transferAndWriteUrl(address to, uint tokens, string _url) public returns (bool success) {
balances[msg.sender] = balances[msg.sender].sub(tokens);
balances[to] = balances[to].add(tokens);
Transfer(msg.sender, to, tokens);
return true;
}

 
 
 
 
 
function comminglerSellsProductSKUWithProRataIngred(address _to, uint _numSKUsSold,string _url,uint _qttyIGRinLLSKU, string _GTIN13, string _YYMMDD ) public returns (bool success) {
string memory url=_url;  
address c= genAddressFromGTIN13date( _GTIN13, _YYMMDD);
require (_qttyIGRinLLSKU >0);  
 
transferAndWriteUrl(c, _qttyIGRinLLSKU, _url);
 
transferAndWriteUrl(_to, (_numSKUsSold-1)*_qttyIGRinLLSKU,_url); 
return true;
}


}