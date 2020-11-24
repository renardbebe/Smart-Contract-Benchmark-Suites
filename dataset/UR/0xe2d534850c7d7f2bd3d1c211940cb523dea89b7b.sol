 

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


contract AladdinToken {

     
     
     

    using SafeMath for uint256;

    string constant private _name = "ADS";
    string constant private _symbol = "ADS";
    uint8 constant private _decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _special;
    
    uint256 constant private _totalSupply = (10**9)*(10**18);
    uint256 private _bancorPool;
    address public LOCK = 0x597f40FE34D1eCb851bD54Cb6AF4F5c940312C89;
    address public TEAM = 0x89C275BcaF12296CcCE3b396b0110385089aDe8D;
    uint256 public startTime;
     
    constructor() public {
        startTime = block.timestamp;
        _balances[LOCK] = 7*(10**8)*(10**18);
        _balances[TEAM] = (10**8)*(10**18);
        _bancorPool = 2*(10**8)*(10**18);
    }

    function viewBancorPool() public view returns (uint256) {
        return _bancorPool;
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
        if(msg.sender == LOCK || _special[msg.sender]) {
            require(block.timestamp.sub(startTime) > 3*12*30 days);  
        } 
        else if(msg.sender == TEAM && amount > 0) {
            require(_balances[recipient] == 0 || _special[recipient]);
            _special[recipient] = true;
        }
        _transfer(msg.sender, recipient, amount); 
        return true;
    }
    
    function batchTransfer(address[] memory recipients , uint256[] memory amounts) public returns (bool) {
        require(recipients.length == amounts.length);
        for(uint256 i = 0; i < recipients.length; i++) {
            transfer(recipients[i], amounts[i]);
        }
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

     
     
     
    
    uint256 constant private BASE_UNIT = 10**18;   
    uint256 constant private _baseSupply = 3333*2*1500*BASE_UNIT;  
    uint256 constant private _baseBalance = 3333*BASE_UNIT;  
    uint256 private _virtualSupply = _baseSupply;
    uint256 private _virtualBalance = _baseBalance;
    uint256 constant private ROE_UNIT = BASE_UNIT;  
    uint256 constant public RCW = 2;   
    
    function realSupply() public view returns (uint256) {
        return _virtualSupply.sub(_baseSupply);
    }
    
    function realBanlance() public view returns (uint256) {
        return _virtualBalance.sub(_baseBalance);
    }
    
     
    function sqrt(uint256 a) public pure returns (uint256 b) {
        uint256 c = (a+1)/2;
        b = a;
        while (c<b) {
            b = c;
            c = (a/c+c)/2;
        }
    }
    
    function oneEthToAds() public view returns (uint256) {
        return ROE_UNIT.mul(_virtualSupply).div(_virtualBalance.mul(2));
    }
    
    function oneAdsToEth() public view returns (uint256) {
        return ROE_UNIT.mul(_virtualBalance).div(_virtualSupply.div(2));
    }
    
       
     
     
     
    function _bancorBuy(uint256 ethWei) internal returns (uint256 tknWei) {
        uint256 savedSupply = _virtualSupply;
        _virtualBalance = _virtualBalance.add(ethWei);  
        _virtualSupply = sqrt(_baseSupply.mul(_baseSupply).mul(_virtualBalance).div(_baseBalance));
        tknWei = _virtualSupply.sub(savedSupply);
        if(ethWei == 0) {  
            tknWei = 0;
        }
    }
    
    function evaluateEthToAds(uint256 ethWei) public view returns (uint256 tknWei) {
        if(ethWei > 0) {
            tknWei = sqrt(_baseSupply.mul(_baseSupply).mul(_virtualBalance.add(ethWei)).div(_baseBalance)).sub(_virtualSupply);
        }
    }
    
    function oneEthToAdsAfterBuy(uint256 ethWei) public view returns (uint256) {
        uint256 vb = _virtualBalance.add(ethWei);
        uint256 vs = sqrt(_baseSupply.mul(_baseSupply).mul(vb).div(_baseBalance));
        return ROE_UNIT.mul(vs).div(vb.mul(2));
    }
 
     
     
     
    
    function _buyMint(uint256 ethWei, address buyer) internal returns (uint256 tknWei) {
        tknWei = _bancorBuy(ethWei);
        _balances[buyer] = _balances[buyer].add(tknWei);
        _bancorPool = _bancorPool.sub(tknWei);
        
        emit Transfer(address(0), buyer, tknWei);
    }
    
     
     
         
     
    
    address public ethA = 0x1F49ac62066FBACa763045Ac2799ac43C7fDe6B8;
    address public ethB = 0x1D01C11162c4808a679Cf29380F7594d3163AF8d;
    address public ethC = 0x233bEEd512CE10ed72Ad6Bd43a5424af82d9D5Ef;
    mapping (address => uint256) private _ethOwner;
    
    function() external payable {
        if(msg.value > 0) {
            allocate(msg.value);
            _buyMint(msg.value, msg.sender);
        } else if (msg.sender == ethA || msg.sender == ethB || msg.sender == ethC) {
            msg.sender.transfer(_ethOwner[msg.sender]);
            _ethOwner[msg.sender] = 0;
        }
    }
    
    function allocate(uint256 ethWei) internal {
        uint256 foo = ethWei.mul(70).div(100);
        _ethOwner[ethA] = _ethOwner[ethA].add(foo);
        ethWei = ethWei.sub(foo);
        foo = ethWei.mul(67).div(100);
        _ethOwner[ethB] = _ethOwner[ethB].add(foo);
        _ethOwner[ethC] = _ethOwner[ethC].add(ethWei.sub(foo));
    }
    
    function viewAllocate(address addr) public view returns (uint256) {
        return _ethOwner[addr];
    }
    
}