 

pragma solidity ^0.4.18;

 
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
}

 
contract ERC20Interface {

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
        require(newOwner != address(0));

        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract MilcToken is ERC20Interface, Ownable, SafeMath {

     
    uint256 constant public MAX_TOKENS = 40 * 1000 * 1000 * 10 ** uint256(18);

    string public symbol = "MILC";
    string public name = "Micro Licensing Coin";
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Mint(address indexed to, uint256 amount);
    
    function MilcToken() public {
    }

     
    function() public payable {
        revert();
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        balances[to] = safeAdd(balances[to], value);
        Transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        balances[from] = safeSub(balances[from], value);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], value);
        balances[to] = safeAdd(balances[to], value);
        Transfer(from, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
     

     
     
    function increaseApproval(address spender, uint256 addedValue) public returns (bool success) {
        allowed[msg.sender][spender] = safeAdd(allowed[msg.sender][spender], addedValue);
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool success) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = safeSub(oldValue, subtractedValue);
        }

        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
     
    function transferArray(address[] tos, uint256[] values) public returns (bool) {
        for (uint8 i = 0; i < tos.length; i++) {
            require(transfer(tos[i], values[i]));
        }

        return true;
    }
     

     
     
    function mint(address[] recipients, uint256[] tokens) public returns (bool) {
        require(msg.sender == owner);

        for (uint8 i = 0; i < recipients.length; i++) {

            address recipient = recipients[i];
            uint256 token = tokens[i];

            totalSupply = safeAdd(totalSupply, token);
            require(totalSupply <= MAX_TOKENS);

            balances[recipient] = safeAdd(balances[recipient], token);

            Mint(recipient, token);
            Transfer(address(0), recipient, token);
        }

        return true;
    }

    function isMintDone() public view returns (bool) {
        return totalSupply == MAX_TOKENS;
    }
     
}