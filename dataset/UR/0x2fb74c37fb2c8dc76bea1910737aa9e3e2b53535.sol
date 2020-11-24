 

 

 

pragma solidity ^0.5.7;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return a / b;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 
interface IERC20{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

     
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

  
}

 
contract Pausable is Ownable {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

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

     
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 
contract Skt is Ownable, Pausable, IERC20 {
    using SafeMath for uint256;

    string private _name = "7.SKT";
    string private _symbol = "7.SKT";
    uint8 private _decimals = 6;              
    uint256 private _cap = 500000000000000;   
    uint256 private _totalSupply;

    
    event Mint(address indexed to, uint256 value);
    event MinterChanged(address account, bool state);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    bool private _allowWhitelistRegistration;
    mapping(address => address) private _referrer;
    mapping(address => uint256) private _refCount;

    event SktSaleWhitelistRegistered(address indexed addr, address indexed refAddr);
    event SktSaleWhitelistTransferred(address indexed previousAddr, address indexed _newAddr);
    event SktSaleWhitelistRegistrationEnabled();
    event SktSaleWhitelistRegistrationDisabled();

    uint256 private _whitelistRegistrationValue = 9000000;   
    uint256[3] private _whitelistRefRewards = [                
        4000000,   
        3000000,   
        2000000   
       
    ];

    event Donate(address indexed account, uint256 amount);

    event WithdrawToken(address indexed from, address indexed to, uint256 value);

     
    constructor() public {
       
        _allowWhitelistRegistration = true;

        emit SktSaleWhitelistRegistrationEnabled();
        _referrer[msg.sender] = msg.sender;
        emit SktSaleWhitelistRegistered(msg.sender, msg.sender);
    }


     
    function () external payable {
        emit Donate(msg.sender, msg.value);
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

     
    function cap() public view returns (uint256) {
        return _cap;
    }

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }
    
    


     
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
	
        if (_allowWhitelistRegistration && value == _whitelistRegistrationValue
            && inWhitelist(to) && !inWhitelist(msg.sender) && isNotContract(msg.sender)) {
             
			_regWhitelist(msg.sender, to);
            return true;
        } else {
             
            _transfer(msg.sender, to, value);
            return true;
        }
    }
	
	
    function _regWhitelist(address account, address refAccount) private {
		
        _refCount[refAccount] = _refCount[refAccount].add(1);
        
		_referrer[account] = refAccount;

        emit SktSaleWhitelistRegistered(account, refAccount);

         
        _transfer(msg.sender, address(this), _whitelistRegistrationValue);
		
		
        address cursor = account;
	
        uint256 remain = _whitelistRegistrationValue;
		
        for(uint i = 0; i < _whitelistRefRewards.length; i++) {
            
			address receiver = _referrer[cursor];
			
			if (cursor == receiver) {
                
                break;
            }

            _transfer(address(this), receiver, _whitelistRefRewards[i]);
					
            remain = remain.sub(_whitelistRefRewards[i]);
                
            

            cursor = _referrer[cursor];
        }


    }

     
    function approve(address spender, uint256 value) public onlyOwner returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public onlyOwner returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public onlyOwner returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }
     
    function transferFrom(address from, address to, uint256 value) public whenNotPaused  returns (bool) {
        require(_allowed[from][msg.sender] >= value);
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _approve(address owner, address spender, uint256 value) private {
        require(owner != address(0));
        require(spender != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }




     
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }

     
    function _mint(address account, uint256 value) private {
        require(_totalSupply.add(value) <= _cap);
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Mint(account, value);
        emit Transfer(address(0), account, value);
    }

     
    modifier onlyInWhitelist() {
        require(_referrer[msg.sender] != address(0));
        _;
    }

     
    function allowWhitelistRegistration() public view returns (bool) {
        return _allowWhitelistRegistration;
    }

     
    function inWhitelist(address account) public view returns (bool) {
        return _referrer[account] != address(0);
    }

     
    function referrer(address account) public view returns (address) {
        return _referrer[account];
    }

     
    function refCount(address account) public view returns (uint256) {
        return _refCount[account];
    }

     
    function disableSktSaleWhitelistRegistration() external onlyOwner {
        _allowWhitelistRegistration = false;
        emit SktSaleWhitelistRegistrationDisabled();
    }

 

     
    function isNotContract(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size == 0;
    }

     
    function calculateTheRewardOfDirectWhitelistRegistration(address whitelistedAccount) external view returns (uint256 reward) {
        if (!inWhitelist(whitelistedAccount)) {
            return 0;
        }

        address cursor = whitelistedAccount;
        uint256 remain = _whitelistRegistrationValue;
        for(uint i = 1; i < _whitelistRefRewards.length; i++) {
            address receiver = _referrer[cursor];

            if (cursor != receiver) {
                if (_refCount[receiver] > i) {
                    remain = remain.sub(_whitelistRefRewards[i]);
                }
            } else {
                reward = reward.add(remain);
                break;
            }

            cursor = _referrer[cursor];
        }

        return reward;
    }

     
    function withdrawToken(address _to, uint256 _value) public onlyOwner {
        require (_value > 0);
        require (_to != address(0));
        _transfer(address(this), _to, _value);
        emit WithdrawToken(address(this), _to, _value);
    }

}