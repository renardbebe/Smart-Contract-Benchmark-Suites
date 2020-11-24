 

 

pragma solidity 0.5.9;

 
 
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

 
contract leethSWAP is ERC20 {  
    using SafeMath for uint256;
    
     
    address public leethContractAddress = address(this);
    ERC20 leethContract = ERC20(leethContractAddress);

    ERC20 UNIRING = ERC20(0xe857581Ba3ED180755F65c5403bF06C084987810);
    ERC20 RCLE = ERC20(0x5A844590c5b8f40ae56190771d06c60b9ab1Da1C);
    
    string public name = "Legal Engineering on Ethereum";
    string public symbol = "LEETH";
    uint8 public decimals = 18;
    
     
    uint256 public LR;  
    
    mapping (uint256 => leethRedemption) public leethRequests; 
    
    struct leethRedemption {  
        address requester; 
        string leethRequest; 
        string leethResponse; 
        string leethReview;
        uint256 lrNumber; 
        uint256 timeStamp;  
        bool leethProvided;
    }
    
     
    string public openESQopenOFFER = "Open, ESQ LLC shall provide legal engineering on Ethereum services at the rate of 1 hour per 1 LEETH upon redemption of such LEETH hereby on calling the writeLEETHrequest function.";
    
     
    event Swapped(address indexed swapper, uint256 indexed amount);  
    
     
     
    function redeemRCLE(uint256 amount) public { 
	    require(RCLE.transferFrom(msg.sender, 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20, amount));  
	    require(UNIRING.transferFrom(msg.sender, 0xcC4Dc8e92A6E30b6F5F6E65156b121D9f83Ca18F, 1000000000000000000));  

	    _mint(msg.sender, amount);  
	    
	    emit Swapped(msg.sender, amount);  
    }
    
    function writeLEETHrequest(string memory leethRequest) public {
        _burn(_msgSender(), 1000000000000000000);  
        
        uint256 lrNumber = LR.add(1); 
        
        LR = LR.add(1);  
        
        leethRequests[lrNumber] = leethRedemption( 
                msg.sender,
                leethRequest,
                "PENDING",
                "RESERVED",
                lrNumber,
                now,
                false);
    }
    
    function writeLEETHresponse(uint256 lrNumber, string memory leethResponse) public {
        require(msg.sender == 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20 || msg.sender == 0xcC4Dc8e92A6E30b6F5F6E65156b121D9f83Ca18F);
        
        leethRedemption storage lr = leethRequests[lrNumber];  
        
        leethRequests[lrNumber] = leethRedemption( 
                lr.requester,
                lr.leethRequest,
                leethResponse,
                lr.leethReview,
                lrNumber,
                lr.timeStamp,
                true);
    }
    
    function writeLEETHreview(uint256 lrNumber, string memory leethReview) public {
        leethRedemption storage lr = leethRequests[lrNumber];  
        
        require(msg.sender == lr.requester);
        require(lr.leethProvided == true);
        
        leethRequests[lrNumber] = leethRedemption( 
                msg.sender,
                lr.leethRequest,
                lr.leethResponse,
                leethReview,
                lrNumber,
                lr.timeStamp,
                true);
                
        _mint(msg.sender, 100000000000000000);  
    }
}