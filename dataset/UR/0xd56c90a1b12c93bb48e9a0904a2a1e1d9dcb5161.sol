 

pragma solidity ^0.5.0;


 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
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


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
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

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0), "");
        require(!has(role, account), "");

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0), "");
        require(has(role, account), "");

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "");
        return role.bearer[account];
    }
}


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 
 
 
 
contract FCS is ERC20Interface, Owned, SafeMath, MinterRole {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    address private _owner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    constructor() public {
        symbol = "FCS";
        name = "Five Color Stone";
        decimals = 18;
        _totalSupply = 2000000000000000000000000000;
        _owner = 0xa45760889D1c27804Dc6D6B89D4095e8Eb99ab72;
        
        balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

     
     
     
    function totalSupply() public view returns (uint) {
        return  safeSub(_totalSupply, balances[address(0)]);
    }

     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
       
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
     
     
        
     
     
     
     


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }

     
    function burnOwner(uint256 value) public onlyOwner {

        require(msg.sender != address(0), "");

        _totalSupply = safeSub(_totalSupply, value);
        balances[_owner] = safeSub(balances[_owner], value);

        emit Transfer(_owner, address(0), value);
    }

     
    function mint(address account, uint256 value) public onlyMinter returns (bool) {
        
        require(account != address(0), "");
        require(account != _owner, "");

         

        balances[account] = safeAdd(balances[account], value);
        balances[_owner] = safeSub(balances[_owner], value);
        emit Transfer(_owner, account, value);

        return true;
    }

     
    function mintOwner(uint256 value) public onlyMinter returns (bool) {
        
        require(msg.sender != address(0), "");
        require(msg.sender == _owner, "");

        _totalSupply = safeAdd(_totalSupply, value);

        balances[_owner] = safeAdd(balances[_owner], value);
        emit Transfer(address(0), _owner, value);

        return true;
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "");
        require(account != _owner, "");

        balances[account] = safeSub(balances[account], value);
        balances[_owner] = safeAdd(balances[_owner], value);
        emit Transfer(account, _owner, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        allowed[account][msg.sender] = safeSub(allowed[account][msg.sender], value);
        _burn(account, value);
        emit Approval(account, msg.sender, allowed[account][msg.sender]);
    }
}