 

pragma solidity ^0.5.2;

 

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
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
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
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

 

contract FoundationOwnable is Pausable {

	address public foundation;

	event FoundationTransferred(address oldAddr, address newAddr);

	constructor() public {
		foundation = msg.sender;
	}

	modifier onlyFoundation() {
		require(msg.sender == foundation, 'foundation required');
		_;
	}

	function transferFoundation(address f) public onlyFoundation {
		require(f != address(0), 'empty address');
		emit FoundationTransferred(foundation, f);
		_removePauser(foundation);
		_addPauser(f);
		foundation = f;
	}
}

 

contract TeleportOwnable {

	address public teleport;

	event TeleportTransferred(address oldAddr, address newAddr);

	constructor() public {
		teleport = msg.sender;
	}

	modifier onlyTeleport() {
		require(msg.sender == teleport, 'caller not teleport');
		_;
	}

	function transferTeleport(address f) public onlyTeleport {
		require(f != address(0));
		emit TeleportTransferred(teleport, f);
		teleport = f;
	}
}

 

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

 

 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 

contract PortedToken is TeleportOwnable, ERC20, ERC20Detailed{

	constructor(string memory name, string memory symbol, uint8 decimals)
		public ERC20Detailed(name, symbol, decimals) {}

	function mint(address to, uint256 value) public onlyTeleport {
		super._mint(to, value);
	}

	function burn(address from, uint256 value) public onlyTeleport {
		super._burn(from, value);
	}
}

 

 
 
 
 
 
 
 
 
contract Port is FoundationOwnable {
	 
	using SafeMath for uint256;

	 

	 
	 
	address payable public beneficiary;

	 
	address[] public registeredMainTokens;

	 
	address[] public registeredClonedTokens;

	 
	 
	 
	 
	 
	 
	 
	 
	mapping (address => mapping (uint256 => bytes)) public breakoutTokens;

	 
	 
	 
	 
	 
	 
	 
	mapping (address => mapping (uint256 => bytes)) public breakinTokens;

	 
	 
	mapping (bytes => bool) proofs;

	 
	 
	 
	 
	 
	 
	mapping (address => mapping (uint256 => uint256)) public minPortValue;


	 

	 
	 
	 
	event Deposit(
		uint256 indexed chain_id,         
		bytes indexed cloned_token_hash,
		bytes indexed alt_addr_hash,
		address main_token,               
		bytes cloned_token,               
		bytes alt_addr,                   
		uint256 value                     
	);

	 
	 
	 
	event Withdraw(
		uint256 indexed chain_id,    
		address indexed main_token,  
		address indexed addr,        
		bytes proof,                 
		bytes cloned_token,          
		uint256 value                
	);

	 
	 
	 
	 
	 
	event RegisterBreakout(
		uint256 indexed chain_id,         
		address indexed main_token,       
		bytes indexed cloned_token_hash,
		bytes cloned_token,               
		bytes old_cloned_token,           
		uint256 minValue                  
	);

	 
	 
	 
	 
	 
	event RegisterBreakin(
		uint256 indexed chain_id,       
		address indexed cloned_token,   
		bytes indexed main_token_hash,
		bytes main_token,               
		bytes old_main_token,           
		uint256 minValue                
	);

	 
	 
	event Mint(
		uint256 indexed chain_id,      
		address indexed cloned_token,  
		address indexed addr,          
		bytes proof,                   
		bytes main_token,              
		uint256 value                  
	);

	 
	 
	event Burn(
		uint256 indexed chain_id,       
		bytes indexed main_token_hash,
		bytes indexed alt_addr_hash,
		address cloned_token,           
		bytes main_token,               
		bytes alt_addr,                 
		uint256 value                   
	);

	constructor(address payable foundation_beneficiary) public {
		beneficiary = foundation_beneficiary;
	}

	function destruct() public onlyFoundation {
		 
		for (uint i=0; i<registeredMainTokens.length; i++) {
			IERC20 token = IERC20(registeredMainTokens[i]);
			uint256 balance = token.balanceOf(address(this));
			token.transfer(beneficiary, balance);
		}

		 
		for (uint i=0; i<registeredClonedTokens.length; i++) {
			PortedToken token = PortedToken(registeredClonedTokens[i]);
			token.transferTeleport(beneficiary);
		}

		selfdestruct(beneficiary);
	}

	modifier breakoutRegistered(uint256 chain_id, address token) {
		require(breakoutTokens[token][chain_id].length != 0, 'unregistered token');
		_;
	}

	modifier breakinRegistered(uint256 chain_id, address token) {
		require(breakinTokens[token][chain_id].length != 0, 'unregistered token');
		_;
	}

	modifier validAmount(uint256 chain_id, address token, uint256 value) {
		require(value >= minPortValue[token][chain_id], "value less than min amount");
		_;
	}

	modifier validProof(bytes memory proof) {
		require(!proofs[proof], 'duplicate proof');
		_;
	}

	function isProofUsed(bytes memory proof) view public returns (bool) {
		return proofs[proof];
	}

	 
	 
	 
	 
	 
	 
	 
	function depositNative(
		uint256 chain_id,
		bytes memory alt_addr
	)
		payable
		public
		whenNotPaused
		breakoutRegistered(chain_id, address(0))
		validAmount(chain_id, address(0), msg.value)
	{
		bytes memory cloned_token = breakoutTokens[address(0)][chain_id];
		emit Deposit(chain_id,
			cloned_token, alt_addr,  
			address(0), cloned_token, alt_addr, msg.value);
	}

	function () payable external {
		revert('not allowed to send value');
	}

	 
	 
	 
	 
	 
	 
	 
	 
	function depositToken(
		address main_token,
		uint256 chain_id,
		bytes memory alt_addr,
		uint256 value
	)
		public
		whenNotPaused
		breakoutRegistered(chain_id, main_token)
		validAmount(chain_id, main_token, value)
	{
		bytes memory cloned_token = breakoutTokens[main_token][chain_id];
		emit Deposit(chain_id,
			cloned_token, alt_addr,  
			main_token, cloned_token, alt_addr, value);

		IERC20 token = IERC20(main_token);
		require(token.transferFrom(msg.sender, address(this), value));
	}

	 
	 
	 
	 
	 
	 
	function withdrawNative(
		uint256 chain_id,
		bytes memory proof,
		address payable addr,
		uint256 value
	)
		public
		whenNotPaused
		onlyFoundation
		breakoutRegistered(chain_id, address(0))
		validProof(proof)
		validAmount(chain_id, address(0), value)
	{
		bytes memory cloned_token = breakoutTokens[address(0)][chain_id];
		emit Withdraw(chain_id, address(0), addr, proof, cloned_token, value);

		proofs[proof] = true;

		addr.transfer(value);
	}

	 
	 
	 
	 
	 
	 
	 
	function withdrawToken(
		uint256 chain_id,
		bytes memory proof,
		address main_token,
		address addr,
		uint256 value
	)
		public
		whenNotPaused
		onlyFoundation
		breakoutRegistered(chain_id, main_token)
		validAmount(chain_id, main_token, value)
		validProof(proof)
	{
		bytes memory cloned_token = breakoutTokens[main_token][chain_id];
		emit Withdraw(chain_id, main_token, addr, proof, cloned_token, value);

		proofs[proof] = true;

		IERC20 token = IERC20(main_token);
		require(token.transfer(addr, value));
	}


	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	function registerBreakout(
		address main_token,
		uint256 chain_id,
		bytes memory old_cloned_token,
		bytes memory cloned_token,
		uint256 minValue
	)
		public
		whenNotPaused
		onlyFoundation
	{
		require(keccak256(breakoutTokens[main_token][chain_id]) == keccak256(old_cloned_token), 'wrong old dest');

		emit RegisterBreakout(chain_id, main_token,
			cloned_token,  
			cloned_token, old_cloned_token, minValue);

		breakoutTokens[main_token][chain_id] = cloned_token;
		minPortValue[main_token][chain_id] = minValue;

		bool firstTimeRegistration = old_cloned_token.length == 0;
		if (main_token != address(0) && firstTimeRegistration) {
			registeredMainTokens.push(main_token);
		}
	}

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	function registerBreakin(
		address cloned_token,
		uint256 chain_id,
		bytes memory old_main_token,
		bytes memory main_token,
		uint256 minValue
	)
		public
		whenNotPaused
		onlyFoundation
	{
		require(keccak256(breakinTokens[cloned_token][chain_id]) == keccak256(old_main_token), 'wrong old src');

		emit RegisterBreakin(chain_id, cloned_token,
			main_token,  
			main_token, old_main_token, minValue);

		breakinTokens[cloned_token][chain_id] = main_token;
		minPortValue[cloned_token][chain_id] = minValue;

		bool firstTimeRegistration = old_main_token.length == 0;
		if (firstTimeRegistration) {
			registeredClonedTokens.push(cloned_token);
		}
	}

	 
	 
	 
	 
	 
	 
	 
	 
	function mint(
		uint256 chain_id,
		bytes memory proof,
		address cloned_token,
		address addr,
		uint256 value
	)
		public
		whenNotPaused
		onlyFoundation
		breakinRegistered(chain_id, cloned_token)
		validAmount(chain_id, cloned_token, value)
		validProof(proof)
	{
		bytes memory main_token = breakinTokens[cloned_token][chain_id];
		emit Mint(chain_id, cloned_token, addr, proof, main_token, value);

		proofs[proof] = true;

		PortedToken token = PortedToken(cloned_token);
		token.mint(addr, value);
	}

	 
	 
	 
	 
	 
	 
	 
	function burn(
		uint256 chain_id,
		address cloned_token,
		bytes memory alt_addr,
		uint256 value
	)
		public
		whenNotPaused
		breakinRegistered(chain_id, cloned_token)
		validAmount(chain_id, cloned_token, value)
	{
		bytes memory main_token = breakinTokens[cloned_token][chain_id];
		emit Burn(chain_id,
			main_token, alt_addr,  
			cloned_token, main_token, alt_addr, value);

		PortedToken token = PortedToken(cloned_token);
		token.burn(msg.sender, value);
	}
}