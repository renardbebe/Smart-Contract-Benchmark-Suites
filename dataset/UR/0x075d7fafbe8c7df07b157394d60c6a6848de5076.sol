 

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



pragma solidity ^0.5.0;

 
 
 
 

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}



pragma solidity ^0.5.0;

 
 
 
 

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}



pragma solidity ^0.5.0;

 
 
 
 

 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}



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



pragma solidity ^0.5.0;

 
 
 
 

contract Owned {

    address public owner;

    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() internal {
        owner = msg.sender;
		emit OwnershipTransferred(address(0), owner);
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



pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 

 
 
 
 

contract FITHToken is ERC20Interface, Owned, Pausable {

    using SafeMath for uint;


    string public symbol;
    string public name;
	string public standard;

    uint8 public decimals;

    uint public _totalSupply;



	bool locked = false;

    mapping(address => uint) balances;

	mapping(address => mapping(address => uint)) allowed;


     
     
     
    constructor() public onlyOwner {

        symbol = "FITH";
        name = "FITH Token";
		standard = "FITH Token v1.0";

        decimals = 4;

        _totalSupply = 10000000000 * 10**uint(decimals);
		
        if(locked) revert();
        locked = true;
		
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

	

     
     
     
	function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }



     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }



     
     
     
     
     
    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
		require(to != address(0));
		require(balances[msg.sender] >= tokens);
		
		balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
		
		emit Transfer(msg.sender, to, tokens);

        return true;
    }



     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public whenNotPaused returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;
    }



     
     
     
     
     
     
     
     
	 
     
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
		require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);
		
		balances[from] = balances[from].sub(tokens);

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);
		
		emit Transfer(from, to, tokens);

        return true;
    }



     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


	
     
     
     
    function () external payable {
        revert();
    }



     
     
     
    function recoverAnyERC20Token(address tokenAddress, address loser, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(loser, tokens);
    }

}