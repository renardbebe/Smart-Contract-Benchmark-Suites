 

pragma solidity ^0.4.24;


 
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

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

     
    constructor () internal {
        _owner = msg.sender;
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

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

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

 
contract ERC20Detailed is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _initSupply;
    
    constructor (string name, string symbol, uint8 decimals, uint256 initSupply) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _initSupply = initSupply.mul(10 **uint256(decimals));
    }

     
    function name() public view returns (string) {
        return _name;
    }

     
    function symbol() public view returns (string) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
     
    function initSupply() public view returns (uint256) {
        return _initSupply;
    }
}

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 
contract C11 is ERC20, ERC20Detailed, Ownable, ReentrancyGuard  {
   using SafeMath for uint256;
   
   mapping (address => bool) status; 
   
    
    address private _walletP;
     
    address private _walletN;
     
     
     
     
    uint256 private _rate;
     
    uint256 private _x;
     
    uint256 private _y;
     
    uint256 private _weiRaised;
    
     
    constructor () public ERC20Detailed("C11", "C11", 18, 20000000
    ) {
        _mint(msg.sender, initSupply());
    }

    
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }
    
    
    function burn(address to, uint256 value) public onlyOwner returns (bool) {
        _burn(to, value);
        return true;
    }
    
    function CheckStatus(address account) public view returns (bool) {
        require(account != address(0));
        bool currentStatus = status[account];
        return currentStatus;
    }
    
     
    function ChangeStatus(address account) public  onlyOwner {
        require(account != address(0));
        bool currentStatus1 = status[account];
       status[account] = (currentStatus1 == true) ? false : true;
    }

    
    function () external payable {
        buyTokens(msg.sender, msg.value);
        }
    function buyTokens(address beneficiary, uint256 weiAmount) public nonReentrant payable {
        require(beneficiary != address(0) && beneficiary !=_walletP && beneficiary !=_walletN);
        require(weiAmount != 0);
        require(_walletP != 0);
        require(_walletN != 0);
        require(CheckStatus(beneficiary) != true);
        
         
        uint256 tokens = weiAmount.div(_y).mul(_x).mul(_rate);
         
        address CurrentFundWallet = (balanceOf(_walletP) > balanceOf(_walletN) == true) ? _walletP : _walletN;
         
        require(balanceOf(CurrentFundWallet) > tokens);
         
        _weiRaised = _weiRaised.add(weiAmount);
         
       _transfer(CurrentFundWallet, beneficiary, tokens);
        
       CurrentFundWallet.transfer(weiAmount);
    }
  
     
    function setRate(uint256 rate) public onlyOwner  {
        require(rate > 1);
        _rate = rate;
    }
     
    function setX(uint256 x) public onlyOwner  {
        require(x >= 1);
        _x = x;
    }
     
    function setY(uint256 y) public onlyOwner  {
        require(y >= 1);
        _y = y;
    }
     
    function setPositivWallet(address PositivWallet) public onlyOwner  {
        _walletP = PositivWallet;
    } 
    
     
    function PositivWallet() public view returns (address) {
        return _walletP;
    }
     
    function setNegativWallet(address NegativWallet) public onlyOwner  {
        _walletN = NegativWallet;
    } 
    
     
    function NegativWallet() public view returns (address) {
        return _walletN;
    }
     
    function Rate() public view returns (uint256) {
        return _rate;
    }
     
    function X() public view returns (uint256) {
        return _x;
    }
     
    function Y() public view returns (uint256) {
        return _y;
    }
     
    function WeiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    
}