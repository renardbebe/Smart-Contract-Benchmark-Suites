 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

     
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

 
contract ERC20Burnable is Context, ERC20 {
     
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

contract offerToken is ERC20Burnable {
    string public name;  
    string public symbol;  
    string public offer;  
    uint256 public rate;  
    uint256 public min;  
    uint256 public decimals;  
    address payable public offeror;  
    bool public closed;  
    
    uint256 public RR;  
    
    mapping (uint256 => requests) public redemptions; 
    
    struct requests {  
        address requester; 
        string details; 
        string response; 
        string review;
        uint256 rNumber; 
        uint256 timeStamp;  
        bool responded;
    }
    
    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _offer, 
        uint256 _init, 
        uint256 _rate,
        uint256 _min,
        uint8 _decimals, 
        address payable _offeror) public {
        name = _name;
        symbol = _symbol;
        offer = _offer;
        rate = _rate;
        min = _min;
        decimals = _decimals;
        offeror = _offeror;
        
        _mint(offeror, _init);  
    }
    
    modifier onlyOfferor {
    	require(msg.sender == offeror, "offerToken: onlyOfferor - not offeror");
   	_;
    }
    
    function adjustOfferRate(uint256 newRate) public onlyOfferor {  
        rate = newRate;
    }
    
    function updateOfferStatus(bool offerClosed) public onlyOfferor {  
        closed = offerClosed;
    }
    
    function buyOfferToken() public payable {  
        require(closed == false);  
        
        _mint(msg.sender, msg.value.mul(rate));  
        offeror.transfer(msg.value);  
    }
    
    function redeemOfferToken(string memory details) public {
        _burn(_msgSender(), min);  
        
        uint256 rNumber = RR.add(1); 
        
        RR = RR.add(1);  
        
        redemptions[rNumber] = requests( 
            msg.sender,
            details,
            "PENDING",
            "RESERVED",
            rNumber,
            now,
            false);
    }
    
    function writeRedemptionResponse(uint256 rNumber, string memory response) public onlyOfferor {
        requests storage rr = redemptions[rNumber];  
        
        redemptions[rNumber] = requests( 
            rr.requester,
            rr.details,
            response,
            rr.review,
            rNumber,
            rr.timeStamp,
            true);
    }
    
    function writeRedemptionReview(uint256 rNumber, string memory review) public {
        requests storage rr = redemptions[rNumber];  
        
        require(msg.sender == rr.requester);  
        require(rr.responded == true);  

        redemptions[rNumber] = requests( 
            rr.requester,
            rr.details,
            rr.response,
            review,
            rNumber,
            rr.timeStamp,
            true);
   }
}