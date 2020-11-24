 

pragma solidity 0.5.4;

 
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

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor (address owner) internal {
        _owner = owner;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
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
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
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

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

 
contract LympoToken is ERC20, Ownable {
    using SafeMath for uint;
    
    string constant public name = "Lympo tokens";
    string constant public symbol = "LYM";
    uint8 constant public decimals = 18;
    
    uint constant public TOKENS_PRE_ICO = 265000000e18;  
    uint constant public TOKENS_ICO = 385000000e18;  
    uint constant public TEAM_RESERVE = 100000000e18;  
    uint constant public ECO_LOCK_13 = 73326000e18;  
    uint constant public START_TIME = 1519815600;  
    uint constant public LOCK_RELEASE_DATE_1_YEAR = START_TIME + 365 days;  
    uint constant public LOCK_RELEASE_DATE_2_YEARS = START_TIME + 730 days;  

    address public ecosystemAddr;
    address public advisersAddr;

    bool public reserveClaimed;
    bool public ecosystemPart1Claimed;
    bool public ecosystemPart2Claimed;
    
    address public airdropAddress;
    uint public airdropBalance;
    
    uint private _initialSupply = 1000000000e18;  
    
    constructor(address _ownerAddr, address _advisersAddr, address _ecosystemAddr, address _airdropAddr, uint _airdropBalance) public Ownable(_ownerAddr){
        advisersAddr = _advisersAddr;
        ecosystemAddr = _ecosystemAddr;
        
        _mint(owner(), _initialSupply);  
        
         
        _transfer(owner(), address(this), TEAM_RESERVE.add(ECO_LOCK_13).add(ECO_LOCK_13));
        
         
        airdropAddress = _airdropAddr;
        airdropBalance = _airdropBalance;
        
        if (airdropBalance != 0) {
             _transfer(owner(), airdropAddress, airdropBalance);
        }
    }
    
     
    function claimTeamReserve() public onlyOwner {
        require (now > LOCK_RELEASE_DATE_2_YEARS && !reserveClaimed);
        reserveClaimed = true;
        _transfer(address(this), owner(), TEAM_RESERVE);
    }
    
     
    function claimEcoSystemReservePart1() public {
        require (msg.sender == ecosystemAddr && !ecosystemPart1Claimed);
        require (now > LOCK_RELEASE_DATE_1_YEAR);
        ecosystemPart1Claimed = true;
        _transfer(address(this), ecosystemAddr, ECO_LOCK_13);
    }
    
     
    function claimEcoSystemReservePart2() public {
        require (msg.sender == ecosystemAddr && !ecosystemPart2Claimed);
        require (now > LOCK_RELEASE_DATE_2_YEARS);
        ecosystemPart2Claimed = true;
        _transfer(address(this), ecosystemAddr, ECO_LOCK_13);
    }
    
     
    function recoverToken(address _token) public onlyOwner {
        require (now > LOCK_RELEASE_DATE_2_YEARS + 30 days);
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
    
     
    function airdrop(address[] memory addresses, uint[] memory values) public {
        require(msg.sender == airdropAddress);
        
        for (uint i = 0; i < addresses.length; i ++){
            _transfer(msg.sender, addresses[i], values[i]);
        }
    }
}