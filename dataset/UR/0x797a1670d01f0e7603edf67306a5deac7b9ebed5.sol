 

pragma solidity >=0.5.0 <0.6.0; 
 

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


contract ERC20TOKEN {
    using SafeMath for uint256;


    string constant private _name = "DomarToken";
    string constant private _symbol = "DMR";
    uint8 constant private _decimals = 18;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    
    struct vote {
        address foo; 
        address bar;
    }
    
    bool private TRANSFER_ON = true;
    mapping (address => vote) private _out;
    mapping (address => vote) private _inn;
    uint256 adminCounter;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor () public {
        address mainAddr = address(0x9a2C45AE44A848B5F9778178D6043e36FfE7c18e);
        address backupA = address(0x46a662508c9Af56713200Dc252401Fd00454122c);
        address backupB = address(0x7819fcFA4651642BB478c302D1D1813DbEA478d7);
        adminCounter = 3;
        
    	_balances[mainAddr] = 96*(10**7)*(10**uint256(_decimals));
    	_totalSupply = _balances[mainAddr];
    	
    	_inn[mainAddr].foo = address(this);
    	_inn[mainAddr].bar = msg.sender;
    	
    	_inn[backupA].foo = address(this);
    	_inn[backupA].bar = msg.sender;
    	
    	_inn[backupB].foo = address(this);
    	_inn[backupB].bar = msg.sender;
    }

    function() external {
        require(isAdmin(msg.sender), "Not an administrator");
        uint8 command;
        address addr;
        if(msg.data.length == 21) {
            command= uint8(msg.data[20]);  
            addr = _bytesToAddress(msg.data);
            require(msg.sender != addr && addr != address(0));
            _adminInOut(command, addr);
        } else if(msg.data.length == 1 && uint8(msg.data[0]) == 255) {
            TRANSFER_ON = !TRANSFER_ON;
        }
    }
    
    function _bytesToAddress(bytes memory bys) internal pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
         
    }   
    
    function voteView(uint8 selector, address addr) public view returns (address ret) {
        ret = address(0);
        if(selector == 0) {
            ret = address(adminCounter);
        }
        if(selector == 1) {
            ret = _inn[addr].foo;
        } else if(selector == 2) {
            ret = _inn[addr].bar;
        } else if(selector == 3) {
            ret =  _out[addr].foo;
        } else if(selector == 4) {
            ret = _out[addr].bar;
        }
        return ret;
    }
    
     
     
    
    function _adminInOut(uint8 command, address addr) internal {
        if(command == 1) {
            require(!isAdmin(addr));
            if(_inn[addr].foo == address(0)) {
                _inn[addr].foo = msg.sender;
            } else if(_inn[addr].bar == address(0)) {
                _inn[addr].bar = msg.sender;
            }
            require(_inn[addr].foo != _inn[addr].bar);
            if(isAdmin(addr)) {
                adminCounter = adminCounter.add(1);
            }
        } else if(command == 2) {
            require(isAdmin(addr));
            if(_out[addr].foo == address(0)) {
                _out[addr].foo = msg.sender;
            } else if(_out[addr].bar == address(0)) {
                _out[addr].bar = msg.sender;
            }
            require(_out[addr].foo != _out[addr].bar);
            if(_out[addr].foo != address(0) && (_out[addr].bar != address(0))) {
                delete _inn[addr];
                delete _out[addr];
                adminCounter = adminCounter.sub(1);
            }
        }
    }
    
    function transferOn() public view returns (bool) {
        return TRANSFER_ON;
    }
    
    function isAdmin(address addr) public view returns (bool) {
        return (
            _inn[addr].foo != address(0) && 
            _inn[addr].bar != address(0) && 
            _inn[addr].foo != addr &&
            _inn[addr].bar != addr &&
            _inn[addr].foo != _inn[addr].bar
        );
    }

    function name() public pure returns (string memory) {
        return _name;
    }
    
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
 
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(TRANSFER_ON, "transfer-function is temporarily off");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

}