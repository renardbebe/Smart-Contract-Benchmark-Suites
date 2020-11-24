 

pragma solidity ^0.5.10;

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "Add error");
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "Sub error");
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "Mul error");
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "Div error");
        c = a / b;
    }
}

 
 
 
 
contract ERC20 {
    function totalSupply() external returns (uint);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
 
 
contract Airdropper is Owned {
    using SafeMath for uint;

    ERC20 public token;

     
    constructor(address tokenAddress) public {
        token = ERC20(tokenAddress);
    }
    
      
    function airdrop(address[] memory dests, uint[] memory values) public onlyOwner {
         
         
        require(dests.length == values.length);

        for (uint256 i = 0; i < dests.length; i++) {
            token.transfer(dests[i], values[i]);
        }
    }

     
    function returnTokens() public onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
    }

     
    function destroy() public onlyOwner {
        selfdestruct(msg.sender);
    }
}