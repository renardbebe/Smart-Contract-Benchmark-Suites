 

 

pragma solidity ^0.4.26;


 
contract Owned {
    
     
    constructor() public { owner = msg.sender; }
    address owner;

     
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
}

 

interface ERC20Interface {
    function totalSupply() external constant returns (uint);
    function balanceOf(address tokenOwner) external constant returns (uint balance);
    function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 

contract JOBTokenMultiDrop is Owned{

     
    function withdrawTokens(address tokenContractAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenContractAddress).transfer(msg.sender, tokens);
    }
    
    function multiDropSameQty(address tokenContractAddress, uint tokens, address[] userAddresses) public onlyOwner
    {
        for (uint i=0; i<userAddresses.length; i++) {
            ERC20Interface(tokenContractAddress).transfer(userAddresses[i], tokens);
        }
    }
    
    function multiDropSameQty(address tokenContractAddress, uint[] tokens, address[] userAddresses) public onlyOwner
    {
        for (uint i=0; i<userAddresses.length; i++) {
            ERC20Interface(tokenContractAddress).transfer(userAddresses[i], tokens[i]);
        }
    }

}