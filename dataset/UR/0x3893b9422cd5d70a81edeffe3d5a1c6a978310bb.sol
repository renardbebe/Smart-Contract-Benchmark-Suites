 

pragma solidity ^0.4.18;

 
library SafeMath {

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

 
contract Owned {
    address public owner;

    event OwnershipTransfered(address indexed owner);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
        OwnershipTransfered(owner);
    }
}

 
contract ERC20Token {

    using SafeMath for uint256;

    string public constant name = "Mithril Token";
    string public constant symbol = "MITH";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, uint256 value, address indexed to, bytes extraData);

    function ERC20Token() public {
    }

     
    function _transfer(address from, address to, uint256 value) internal {
         
        require(balanceOf[from] >= value);

         
        require(balanceOf[to] + value > balanceOf[to]);

         
        uint256 previousBalances = balanceOf[from].add(balanceOf[to]);

        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);

        Transfer(from, to, value);

         
        assert(balanceOf[from].add(balanceOf[to]) == previousBalances);
    }

     
    function transfer(address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value, bytes extraData) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        Approval(msg.sender, value, spender, extraData);
        return true;
    }
}

 
contract MithrilToken is Owned, ERC20Token {

     
    address public vault;
    address public wallet;

    function MithrilToken() public {
    }

    function init(uint256 _supply, address _vault, address _wallet) public onlyOwner {
        require(vault == 0x0);
        require(_vault != 0x0);

        totalSupply = _supply;
        vault = _vault;
        wallet = _wallet;
        balanceOf[vault] = totalSupply;
    }

    function () payable public {
        wallet.transfer(msg.value);
    }
}