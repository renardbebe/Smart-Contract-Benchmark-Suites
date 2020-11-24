 

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
contract BurnContract {

    address public owner;
    ERC20 Paytoken;
     
    modifier onlyAdmin() {
        require (msg.sender == owner);
        _;
    }

    function setPayanyToken(address _PayToken) onlyAdmin public {
        Paytoken = ERC20(_PayToken);
    }
    
    
    function getTokenBalanceOf(address h0dler) constant public returns(uint balance){
        return Paytoken.balanceOf(h0dler);
    }
    
    function swapToEth(address _to) payable public  returns(bool){
        _to.transfer(msg.value);
    }
    
}