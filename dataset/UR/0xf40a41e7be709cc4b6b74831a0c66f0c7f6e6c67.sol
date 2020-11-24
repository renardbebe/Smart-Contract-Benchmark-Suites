 

pragma solidity 0.4.26;

 

contract DigitalDollarRetainer {

 
string public terms = "|| Establishing a retainer and acknowledging the mutual consideration and agreement hereby, Client, indentified as ethereum address '0x[[Client]]', commits a digital payment transactional script capped at '$[[Payment Cap in Dollars]]' for the benefit of Provider, identified as ethereum address '0x[[Provider]]', in exchange for the prompt satisfaction of the following deliverables, '[[Deliverable]]', to Client by Provider upon scripted payments set at the rate of '$[[Deliverable Rate]]' per deliverable, with such retainer relationship not to exceed '[[Retainer Duration in Days]]' days and to be governed by the choice of [[Choice of Law and Arbitration Forum]] law and 'either/or' arbitration rules in [[Choice of Law and Arbitration Forum]]. ||";

 
uint256 private decimalFactor = 1000000000000000000;  
address public daiToken = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;  
address public usdcToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;  

 
address public client;  
address public provider;  
string public deliverable;  
string public governingLawandForum;  
uint256 public retainerDurationinDays;  
uint256 public deliverableRate;  
uint256 public paid;  
uint256 public payCap;  

event Paid(uint256 amount, address indexed);  

constructor(address _client, address _provider, string _deliverable, string _governingLawandForum, uint256 _retainerDurationinDays, uint256 _deliverableRate, uint256 _payCap) public {
client = _client;
provider = _provider;
deliverable = _deliverable;
governingLawandForum = _governingLawandForum;
retainerDurationinDays = _retainerDurationinDays;
deliverableRate = _deliverableRate;
payCap = _payCap;
}

function payDAI() public {  
require(msg.sender == client);
require(paid <= payCap, "payDAI: payCap exceeded");
require(paid + deliverableRate <= payCap, "payDAI: payCap exceeded");
uint256 weiAmount = deliverableRate * decimalFactor;
ERC20 dai = ERC20(daiToken);
dai.transferFrom(msg.sender, provider, weiAmount);
emit Paid(weiAmount, msg.sender);
paid = paid + deliverableRate;
}

function payUSDC() public {  
require(msg.sender == client);
require(paid <= payCap, "payUSDC: payCap exceeded");
require(paid + deliverableRate <= payCap, "payUSDC: payCap exceeded");
uint256 weiAmount = deliverableRate * decimalFactor;
ERC20 usdc = ERC20(usdcToken);
usdc.transferFrom(msg.sender, provider, weiAmount);
emit Paid(weiAmount, msg.sender);
paid = paid + deliverableRate;
}
}

 

 
contract ERC20 {
uint256 public totalSupply;

function balanceOf(address who) public view returns (uint256);
function transfer(address to, uint256 value) public returns (bool);
function allowance(address owner, address spender) public view returns (uint256);
function transferFrom(address from, address to, uint256 value) public returns (bool);
function approve(address spender, uint256 value) public returns (bool);

event Approval(address indexed owner, address indexed spender, uint256 value);
event Transfer(address indexed from, address indexed to, uint256 value);
}

 

contract DigitalDollarRetainerFactory {

 
mapping (address => bool) public validContracts;
address[] public contracts;

 
function getContractCount()
public
view
returns(uint contractCount)
{
return contracts.length;
}

 
function getDeployedContracts() public view returns (address[])
{
return contracts;
}

 
function newDigitalDollarRetainer(address _client, address _provider, string _deliverable, string _governingLawandForum, uint256 _retainerDurationinDays, uint256 _deliverableRate, uint256 _payCap)
public
returns(address)
{
DigitalDollarRetainer c = new DigitalDollarRetainer(_client, _provider, _deliverable, _governingLawandForum, _retainerDurationinDays, _deliverableRate, _payCap);
validContracts[c] = true;
contracts.push(c);
return c;
}
}