 

pragma solidity ^0.4.25;
 

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Is not owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

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

contract WhiteList is Ownable {

    mapping(address => address) whiteList;

    constructor() public {
        whiteList[msg.sender] = msg.sender;
    }

    function add(address who) public onlyOwner() {
        require(who != address(0), "Invalid address");
        whiteList[who] = who;
    }

    function remove(address who) public onlyOwner() {
        require(who != address(0), "Invalid address");
        delete whiteList[who];
    }

    function isWhiteListed(address who) public view returns (bool) {
        return whiteList[who] != address(0);
    }
}

 
 
 

contract Sh8pe is Ownable, WhiteList {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    constructor () public {

        name = "Angel Token";
        symbol = "Angels";
        decimals = 18;
        totalSupply = 100000000;

        balances[msg.sender] = totalSupply;
        emit Transfer(this, msg.sender, totalSupply);
    }

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }

     
    function transfer(address from, address to, uint256 value) public returns (bool) {
        require(isWhiteListed(msg.sender) == true, "Not white listed");
        require(balances[from] >= value, "Insufficient balance");  

        balances[from] = balances[from].sub(value);  
        balances[to] = balances[to].add(value);  

        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}