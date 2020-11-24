 

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


contract MiningBitcoinToken {
    
    using SafeMath for uint256;
    
    string constant private _name = "MiningBitcoinAndTradingToken";
    string constant private _symbol = "MBT";
    uint8 constant private _decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 constant private _totalSupply = 2*(10**9)*(10**18);
    
    address private _owner;
    address constant public TX_MINING = 0x1C4E479B1962b3AC4D4FCeB2feE85930F314F842;
    address constant public PRIV_SELL = 0x9Cf4cAfC51eAEc3cee22d72dE7f26B94a8622d23;
    address constant public IEO_SELL = 0xC494c313F93e1FA089B7954a8cd36947BD972244;
    address constant public PUB_SELL = 0xbeBdf273fE1BaA392adBaFA949D89588fdCB9022;
    address constant public TEAM_PRIZE = 0xaA2BfF48Ce4EB319bFb6770357D44dec70b79C25;
    address constant public FUND_LOCK = 0x697DE66cC4556c48f225677b38b6D5088FA84BE2;
    address constant public MARKET_OP = 0x01528bcFe4Ec473C3c2BC55578005868c39E32cE;
    
     
    mapping (address => uint256) private _privAmount;
    mapping (address => uint256) private _ethAmount;
    uint256 private _privStart;
    uint256 private _privEnd;
    uint256 private _pubStart;
    uint256 private _pubEnd;
    uint256 private _pubSellRound;
    uint256 private _nthInThisRound;
    uint256 private _privPrice;
    uint256 private _pubPrice;
    uint256 private _pubFactor = 100;
    bool private _privSetable = true;
    bool private _pubSetable = true;
    uint256 constant public WAIT_TIME = 72 hours;
    uint256 constant public UNIT_TIME = 1 weeks;
    uint256 constant public PRIV_TIME = UNIT_TIME;
    uint256 constant public PUB_TIME = 3*UNIT_TIME;
    uint256 constant public PRIVE_LOCK_TIME = 22*UNIT_TIME;  
    
    function viewPrivStart() public view returns (uint256) {
        return _privStart;
    }
    
    function viewPubStart() public view returns (uint256) {
        return _pubStart;
    }
    
    function viewPrivEnd() public view returns (uint256) {
        return _privEnd;
    }
    
    function viewPubEnd() public view returns (uint256) {
        return _pubEnd;
    }
    
    function viewPrivPrice() public view returns (uint256) {
        return _privPrice;
    }
    
    function viewPubPrice() public view returns (uint256) {
        return _pubPrice;
    }
    
    function viewPubFactor() public view returns (uint256) {
        return _pubFactor;
    }
    
    function viewPubSellRound() public view returns (uint256) {
        return _pubSellRound;
    }
    
    function viewNthInThisRound() public view returns (uint256) {
        return _nthInThisRound;
    }
    
    function viewPrivSetable() public view returns (bool) {
        return _privSetable;
    }
    
    function viewPubSetable() public view returns (bool) {
        return _pubSetable;
    }
    
    function viewEthAmount(address addr) public view returns (uint256) {
        return _ethAmount[addr];
    }
    
    constructor() public {
        _owner = msg.sender;
        
        _balances[TX_MINING] = _totalSupply*30/100;  
        _balances[PRIV_SELL] = _totalSupply*5/100;   
        _balances[IEO_SELL] = _totalSupply*5/100;   
        _balances[PUB_SELL] = _totalSupply*25/100;  
        _balances[TEAM_PRIZE] = _totalSupply*15/100;  
        _balances[FUND_LOCK] = _totalSupply*12/100;  
        _balances[MARKET_OP] = _totalSupply*8/100;   
        
        _privStart = block.timestamp.add(200*UNIT_TIME);
        _privEnd = _privStart + PRIV_TIME;
        
        _pubStart = _privStart.add(200*UNIT_TIME);
        _pubEnd = _pubStart +  PUB_TIME;
        
        _privPrice = 2000;
        _pubPrice = 1000;
    }
    
    function() external payable {
        if(msg.value == 0 && msg.sender == _owner) {
            _handleAdmin();
        } else if(msg.value > 0) {
            if(block.timestamp > _privStart &&  block.timestamp < _privEnd) {
                _handlePrivSell();
            } else if(block.timestamp > _pubStart && block.timestamp < _pubEnd) {
                _handlePubSell();
            } else {
                revert();
            }
        } else {
            revert();
        }
    }
    
     
    function _handleAdmin() internal {
        require(msg.sender == _owner);
        if(msg.data.length == 0) {
            msg.sender.transfer(address(this).balance);
        } else {
            uint8 command = uint8(msg.data[0]);
            if(command == 0xFF && _privSetable) {
                _privStart = block.timestamp + WAIT_TIME;
                _privEnd = _privStart + PRIV_TIME;
                if(msg.data.length == 3) {
                    _privPrice = (uint256(uint8(msg.data[1])) << 8) + (uint256(uint8(msg.data[2])));
                }
            } else if(command == 0xFE && _pubSetable) {
                _pubStart = block.timestamp +  WAIT_TIME;
                _pubEnd = _pubStart +  PUB_TIME;
                if(msg.data.length == 3) {
                    _pubPrice = (uint256(uint8(msg.data[1])) << 8) + (uint256(uint8(msg.data[2])));
                }
            } else if(command == 0xFD) {
                _privSetable = false;
            } else if(command == 0xFC) {
                _pubSetable = false;
            }
        }
    }
    
    function _handlePrivSell() internal {
        require(msg.value >= 5 ether);
        uint256 temp = msg.value.mul(_privPrice);
        _balances[PRIV_SELL] = _balances[PRIV_SELL].sub(temp);
        _balances[msg.sender] = _balances[msg.sender].add(temp);
        _privAmount[msg.sender] = _privAmount[msg.sender].add(temp);
        _ethAmount[msg.sender] = _ethAmount[msg.sender].add(msg.value);
    }
    
    function _handlePubSell() internal {
        require(_privAmount[msg.sender] == 0);
        uint256 temp =  block.timestamp.sub(_pubStart).div(UNIT_TIME);
        if(temp > _pubSellRound) {
            _pubSellRound = temp;
            _nthInThisRound = 0;
            _pubFactor = _pubFactor.sub(10);   
        }
        uint256 foo;
        if(msg.value >= 1 ether) {
            _nthInThisRound = _nthInThisRound.add(1);
            if(_nthInThisRound <= 1000) {
                 
                foo = msg.value.mul(_pubPrice).mul(_pubFactor).mul(1001-_nthInThisRound).div(100000);
            }
        }
        temp = msg.value.mul(_pubPrice).add(foo);
        _balances[PUB_SELL] = _balances[PUB_SELL].sub(temp);
        _balances[msg.sender] = _balances[msg.sender].add(temp);
        _ethAmount[msg.sender] = _ethAmount[msg.sender].add(msg.value);
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
    
    function totalSupply() public pure returns (uint256) {
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(block.timestamp < _pubEnd.add(PRIVE_LOCK_TIME)) {   
            require(_privAmount[recipient] == 0);  
            if(_privAmount[sender] > 0) {          
                require(block.timestamp > _pubEnd);
                require(
                    _privAmount[sender].sub(_balances[sender]).add(amount) <= 
                    block.timestamp.sub(_pubEnd).mul(_privAmount[sender]).div(PRIVE_LOCK_TIME)
                );
            }
        }
        
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(block.timestamp < _pubEnd.add(PRIVE_LOCK_TIME));
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    
    
}