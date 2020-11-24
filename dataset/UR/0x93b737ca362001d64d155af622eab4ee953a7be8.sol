 

pragma solidity ^0.4.24;

 
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
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

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransfered(owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
        emit OwnershipTransfered(owner);
    }
}

 
contract ERC20Token {
    using SafeMath for uint256;

    string public constant name = "Ansforce Network Token";
    string public constant symbol = "ANT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 0;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, uint256 value, address indexed to, bytes extraData);

    constructor() public {
    }

     
    function _transfer(address from, address to, uint256 value) internal {
         
        require(balanceOf[from] >= value);

         
        require(balanceOf[to] + value > balanceOf[to]);

         
        uint256 previousBalances = balanceOf[from].add(balanceOf[to]);

        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);

        emit Transfer(from, to, value);

         
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
        emit Approval(msg.sender, value, spender, extraData);
        return true;
    }
}


contract AnsforceNetworkToken is Owned, ERC20Token {
    constructor() public {
    }
    
    function init(uint256 _supply, address _vault) public onlyOwner {
        require(totalSupply == 0);
        require(_supply > 0);
        require(_vault != address(0));
        totalSupply = _supply;
        balanceOf[_vault] = totalSupply;
    }
    
    
    bool public stopped = false;
    
    modifier isRunning {
        require (!stopped);
        _;
    }
    
    function transfer(address to, uint256 value) isRunning public {
        ERC20Token.transfer(to, value);
    }
    
    function stop() public onlyOwner {
        stopped = true;
    }

    function start() public onlyOwner {
        stopped = false;
    }
    
    
    mapping (address => uint256) public freezeOf;
    
     
    event Freeze(address indexed target, uint256 value);

     
    event Unfreeze(address indexed target, uint256 value);
    
    function freeze(address target, uint256 _value) public onlyOwner returns (bool success) {
        require( _value > 0 );
        balanceOf[target] = SafeMath.sub(balanceOf[target], _value);
        freezeOf[target] = SafeMath.add(freezeOf[target], _value);
        emit Freeze(target, _value);
        return true;
    }

    function unfreeze(address target, uint256 _value) public onlyOwner returns (bool success) {
        require( _value > 0 );
        freezeOf[target] = SafeMath.sub(freezeOf[target], _value);
        balanceOf[target] = SafeMath.add(balanceOf[target], _value);
        emit Unfreeze(target, _value);
        return true;
    }
}