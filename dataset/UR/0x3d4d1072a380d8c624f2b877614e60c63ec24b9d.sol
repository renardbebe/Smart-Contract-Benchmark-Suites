 

pragma solidity ^0.5.0;

 

 
 
 
 
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 

contract BVATokenHolder {
    ERC20Interface erc20Contract;
    address payable owner;
    string public name;


    modifier isOwner() {
        require(msg.sender == owner, "must be contract owner");
        _;
    }


     
     
     
    constructor(ERC20Interface ctr, string memory _name) public {
        erc20Contract = ctr;
        owner         = msg.sender;
        name          = _name;
    }


     
     
     
    function transferTokens(address to, uint amount) external isOwner {
        erc20Contract.transfer(to, amount);
    }


     
     
     
    function withdrawEther(uint _amount) external isOwner {
        owner.transfer(_amount);
    }


     
     
     
    function () external payable {
    }
}