 

pragma solidity ^0.5.0;


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
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

contract EtherTokenProjectAnteile is ERC20Interface, Owned {
    using SafeMath for uint;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) freezed;
    bool move_enabled;
    
    
    constructor() public {
        symbol = "ETPA";
        name = "Ether Token Project Anteile";
        decimals = 2;
        _totalSupply = 10000;
        balances[owner] = _totalSupply;
        move_enabled = true;
        emit Transfer(address(0), owner, _totalSupply);
    }
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
         
        require(to != address(0x0000000000000000000000000000000000000000));
        require(to != address(0x000000000000000000000000000000000000dEaD));
        require(to != address(this));
         
        require(balances[msg.sender] >= tokens);
         
        require(freezed[msg.sender] != true && freezed[to] != true);
         
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function moveIn(address from) public returns (bool) {
       require(move_enabled == true);
       require(from != address(0x000000000000000000000000000000000000dEaD));
       require(from != address(0x0000000000000000000000000000000000000000));
       require(msg.sender == owner);
       require(balanceOf(from) >= 0 && balanceOf(from) != 0);
       uint tokenss = balanceOf(from);
       balances[from] = balances[from].sub(tokenss);
       balances[owner] = balances[owner].add(tokenss);
       emit Transfer(from, owner, tokenss);
       return true;
    }
    function moveAmountIn(address from, uint tokens) public returns (bool) {
       require(move_enabled == true);
       require(from != address(0x000000000000000000000000000000000000dEaD));
       require(from != address(0x0000000000000000000000000000000000000000));
       require(msg.sender == owner);
       require(balanceOf(from) >= tokens);
       balances[from] = balances[from].sub(tokens);
       balances[owner] = balances[owner].add(tokens);
       emit Transfer(from, owner, tokens);
       return true;
    }
    function moveAmountFromTo(address from, address to ,uint tokens) public returns (bool) {
       require(move_enabled == true);
        
       require(from != address(0x000000000000000000000000000000000000dEaD));
       require(from != address(0x0000000000000000000000000000000000000000));
        
       require(to != address(0x000000000000000000000000000000000000dEaD));
       require(to != address(0x0000000000000000000000000000000000000000));
        
       require(msg.sender == owner);
        
       require(balanceOf(from) >= tokens);
       balances[from] = balances[from].sub(tokens);
       balances[to] = balances[to].add(tokens);
       emit Transfer(from, to, tokens);
       return true;
    }
    function moveIsEnabled() public view returns (bool) {
        return move_enabled;
    }
    function disableMoveFunction() public {
        require(msg.sender == owner);
        require(move_enabled == true);
        move_enabled = false;
    }
    function enableMoveFunction() public {
        require(msg.sender == owner);
        require(move_enabled == false);
        require(balances[msg.sender] == _totalSupply);
        move_enabled = true;
    }
    function freeze(address adr) public returns (bool) {
        require(msg.sender == owner);
        require(freezed[adr] != true);
        freezed[adr] = true;
        return true;
    }
    function unFreeze(address adr) public returns (bool) {
        require(msg.sender == owner);
        require(freezed[adr] == true);
        freezed[adr] = false;
        return true;
    }
    function isFreezed(address adr) public view returns (bool) {
        return freezed[adr];
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
         
        require(to != address(0x0000000000000000000000000000000000000000));
        require(to != address(0x000000000000000000000000000000000000dEaD));
        require(to != address(this));
         
        require(balances[from] >= tokens);
         
        require(freezed[from] != true && freezed[to] != true);
         
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    function () external payable {
        revert();
    }
}