 

pragma solidity 0.4.21;


 
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


 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract FlogmallAirdropper is Ownable {
    using SafeMath for uint;

    ERC20 public token;
    uint public multiplier;

     
    function FlogmallAirdropper(address tokenAddress, uint decimals) public {
        require(decimals <= 77);   

        token = ERC20(tokenAddress);
        multiplier = 10**decimals;
    }

     
    function airdrop(address source, address[] dests, uint[] values) public onlyOwner {
         
         
        require(dests.length == values.length);

        for (uint256 i = 0; i < dests.length; i++) {
            require(token.transferFrom(source, dests[i], values[i].mul(multiplier)));
        }
    }

     
    function returnTokens() public onlyOwner {
        token.transfer(owner, token.balanceOf(this));
    }

     
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}