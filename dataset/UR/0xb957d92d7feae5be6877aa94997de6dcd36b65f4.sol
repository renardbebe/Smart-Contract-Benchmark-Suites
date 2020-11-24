 

pragma solidity ^0.4.19;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 

 
contract ERC20Basic {uint256 public totalSupply; function balanceOf(address who) public constant returns (uint256); function transfer(address to, uint256 value) public returns (bool); event Transfer(address indexed from, address indexed to, uint256 value);}
  
  
 
library SafeMath {function mul(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a * b; assert(a == 0 || c / a == b); return c;}
 
 
function div(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a / b; return c;}
function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a); return a - b;}
function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b; assert(c >= a); return c;}}
  
 
contract BasicToken is ERC20Basic {using SafeMath for uint256; mapping(address => uint256) balances;
function transfer(address _to, uint256 _value) public returns (bool) {balances[msg.sender] = balances[msg.sender].sub(_value); balances[_to] = balances[_to].add(_value); Transfer(msg.sender, _to, _value); return true;}
  
 
function balanceOf(address _owner) public constant returns (uint256 balance) {return balances[_owner];}}
  
 
function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {var _allowance = allowed[_from][msg.sender];
 
 
balances[_to] = balances[_to].add(_value); balances[_from] = balances[_from].sub(_value); allowed[_from][msg.sender] = _allowance.sub(_value); Transfer(_from, _to, _value); return true;}
 
function approve(address _spender, uint256 _value) public returns (bool) {
 
 
 
 
require((_value == 0) || (allowed[msg.sender][_spender] == 0)); allowed[msg.sender][_spender] = _value; Approval(msg.sender, _spender, _value); return true;}
 
function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {return allowed[_owner][_spender];}}
  
 
contract Ownable {address public owner;
 
function Ownable() public {owner = msg.sender;} modifier onlyOwner() {require(msg.sender == owner);_;}
 
function transferOwnership(address newOwner) public onlyOwner {require(newOwner != address(0)); owner = newOwner;}}
 
contract H2G2 is StandardToken, Ownable {
    string public constant name = "The Hitchhiker's Guide to the Galaxy";
        string public constant symbol = "H2G2";
            string public version = 'V1.0.42.000.000.The.Primary.Phase';
            uint public constant decimals = 18;
        uint256 public initialSupply;
    uint256 public unitsOneEthCanBuy;            
uint256 public totalEthInWei;                    
                                                 
                                                 
address public fundsWallet;                      
    function H2G2 () public {
        totalSupply = 42000000 * 10 ** decimals;
            balances[msg.sender] = totalSupply;
                initialSupply = totalSupply;
            Transfer(0, this, totalSupply);
        Transfer(this, msg.sender, totalSupply);
    unitsOneEthCanBuy = 1000;                    
fundsWallet = msg.sender;                        
                                                 
}function() public payable{totalEthInWei = totalEthInWei + msg.value; uint256 amount = msg.value * unitsOneEthCanBuy; require(balances[fundsWallet] >= amount); balances[fundsWallet] = balances[fundsWallet] - amount; balances[msg.sender] = balances[msg.sender] + amount;
Transfer(fundsWallet, msg.sender, amount);       
 
fundsWallet.transfer(msg.value);}
 
function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {allowed[msg.sender][_spender] = _value; Approval(msg.sender, _spender, _value);
 
if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { return; } return true;}}
 
 
 