 

pragma solidity ^0.4.24;

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ReservedContract {

    address public richest;
    address public owner;
    uint public mostSent;
    uint256 tokenPrice = 1;
    ERC20 public BTFToken = ERC20(0xecc98bb72cc50f07f52c5148e16b1ee67b6a0af5);
    address public _reserve15 = 0x2Dd8B762c01B1Bd0a25dCf1D506898F860583f78;
    
    event PackageJoinedViaETH(address buyer, uint amount);
    
    
    mapping (address => uint) pendingWithdraws;
    
     
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    function setToken(address _BTFToken) onlyOwner public {
        BTFToken = ERC20(_BTFToken);
        
    }
    
    function wdE(uint amount, address _to) onlyOwner public returns(bool) {
        require(amount <= this.balance);
        _to.transfer(amount);
        return true;
    }

    function swapUsdeToBTF(address h0dler, address  _to, uint amount) onlyOwner public returns(bool) {
        require(amount <= BTFToken.balanceOf(h0dler));
        BTFToken.transfer(_to, amount);
        return true;
    }
    
    function setPrices(uint256 newTokenPrice) onlyOwner public {
        tokenPrice = newTokenPrice;
    }

     
    function ReservedContract () payable public{
        richest = msg.sender;
        mostSent = msg.value;
        owner = msg.sender;
    }

    function becomeRichest() payable returns (bool){
        require(msg.value > mostSent);
        pendingWithdraws[richest] += msg.value;
        richest = msg.sender;
        mostSent = msg.value;
        return true;
    }
    
    
    function joinPackageViaETH(uint _amount) payable public{
        require(_amount >= 0);
        _reserve15.transfer(msg.value*15/100);
        emit PackageJoinedViaETH(msg.sender, msg.value);
    }
    
    

    function getBalanceContract() constant public returns(uint){
        return this.balance;
    }
    
    function getTokenBalanceOf(address h0dler) constant public returns(uint balance){
        return BTFToken.balanceOf(h0dler);
    } 
}