 

pragma solidity ^0.4.24;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

 
 
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b != 0);
        c = a / b;
        return c;
    }
}

contract GGCToken is ERC20Interface{
    using SafeMath for uint256;
    using SafeMath for uint8;

     
     
     
     
    event ListLog(address addr, uint8 indexed typeNo, bool active);
    event Trans(address indexed fromAddr, address indexed toAddr, uint256 transAmount, uint256 ggcAmount, uint256 ggeAmount, uint64 time);
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event Deposit(address indexed sender, uint value);

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint8 public ggcFee; 
    uint8 public ggeFee; 
    uint8 public maxFee;
    uint256 public _totalSupply;

    bool public feeLocked; 
    bool public transContractLocked;

    address public owner;
    address public ggcPoolAddr;
    address public ggePoolAddr;     
    address private ownerContract = address(0x0);
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) public whiteList;
    mapping(address => bool) public allowContractList;
    mapping(address => bool) public blackList;
    
    constructor() public {
        symbol = "GGC";
        name = "GramGold Coin";
        owner = msg.sender;
        decimals = 8;
        ggcFee = 2;
        ggeFee = 1; 
        maxFee = 3;
        _totalSupply = 600 * 10**uint256(decimals);
        balances[owner] = _totalSupply;
        ggcPoolAddr = address(0x0);
        ggePoolAddr = address(0x0);
        feeLocked = false;
        transContractLocked = true;
        whiteList[owner] = true; 
        emit ListLog(owner, 1, true);
        emit Transfer(address(0x0), owner, _totalSupply);
    }
    
     
    function AssignGGCOwner(address _ownerContract) 
    public 
    onlyOwner 
    notNull(_ownerContract) 
    {
        uint256 remainTokens = balances[owner];
        ownerContract = _ownerContract;
        balances[owner] = 0;
        balances[ownerContract] = balances[ownerContract].add(remainTokens);
        whiteList[ownerContract] = true; 
        emit ListLog(ownerContract, 1, true);
        emit Transfer(owner, ownerContract, remainTokens);
        emit OwnershipTransferred(owner, ownerContract);
        owner = ownerContract;
    }

     
    function isContract(address _addr) 
    private 
    view 
    returns (bool) 
    {
        if(allowContractList[_addr] || !transContractLocked){
            return false;
        }

        uint256 codeLength = 0;

        assembly {
            codeLength := extcodesize(_addr)
        }
        
        return (codeLength > 0);
    }

     
    function transfer(address _to, uint256 _value) 
    public 
    notNull(_to) 
    returns (bool success) 
    {
        uint256 ggcFeeFrom;
        uint256 ggeFeeFrom;
        uint256 ggcFeeTo;
        uint256 ggeFeeTo;

        if (feeLocked) {
            ggcFeeFrom = 0;
            ggeFeeFrom = 0;
            ggcFeeTo = 0;
            ggeFeeTo = 0;
        }else{
            (ggcFeeFrom, ggeFeeFrom) = feesCal(msg.sender, _value);
            (ggcFeeTo, ggeFeeTo) = feesCal(_to, _value);
        }

        require(balances[msg.sender] >= _value.add(ggcFeeFrom).add(ggeFeeFrom));
        success = _transfer(msg.sender, _to, _value.sub(ggcFeeTo).sub(ggeFeeTo));
        require(success);
        success = _transfer(msg.sender, ggcPoolAddr, ggcFeeFrom.add(ggcFeeTo));
        require(success);
        success = _transfer(msg.sender, ggePoolAddr, ggeFeeFrom.add(ggeFeeTo));
        require(success);

        balances[msg.sender] = balances[msg.sender].sub(_value.add(ggcFeeFrom).add(ggeFeeFrom));
        balances[_to] = balances[_to].add(_value.sub(ggcFeeTo).sub(ggeFeeTo));
        balances[ggcPoolAddr] = balances[ggcPoolAddr].add(ggcFeeFrom).add(ggcFeeTo);
        balances[ggePoolAddr] = balances[ggePoolAddr].add(ggeFeeFrom).add(ggeFeeTo); 

        emit Trans(msg.sender, _to, _value, ggcFeeFrom.add(ggcFeeTo), ggeFeeFrom.add(ggeFeeTo), uint64(now));
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) 
    public 
    notNull(_to) 
    returns (bool success) 
    {
        uint256 ggcFeeFrom;
        uint256 ggeFeeFrom;
        uint256 ggcFeeTo;
        uint256 ggeFeeTo;

        if (feeLocked) {
            ggcFeeFrom = 0;
            ggeFeeFrom = 0;
            ggcFeeTo = 0;
            ggeFeeTo = 0;
        }else{
            (ggcFeeFrom, ggeFeeFrom) = feesCal(_from, _value);
            (ggcFeeTo, ggeFeeTo) = feesCal(_to, _value);
        }

        require(balances[_from] >= _value.add(ggcFeeFrom).add(ggeFeeFrom));
        require(allowed[_from][msg.sender] >= _value.add(ggcFeeFrom).add(ggeFeeFrom));

        success = _transfer(_from, _to, _value.sub(ggcFeeTo).sub(ggeFeeTo));
        require(success);
        success = _transfer(_from, ggcPoolAddr, ggcFeeFrom.add(ggcFeeTo));
        require(success);
        success = _transfer(_from, ggePoolAddr, ggeFeeFrom.add(ggeFeeTo));
        require(success);

        balances[_from] = balances[_from].sub(_value.add(ggcFeeFrom).add(ggeFeeFrom));
        balances[_to] = balances[_to].add(_value.sub(ggcFeeTo).sub(ggeFeeTo));
        balances[ggcPoolAddr] = balances[ggcPoolAddr].add(ggcFeeFrom).add(ggcFeeTo);
        balances[ggePoolAddr] = balances[ggePoolAddr].add(ggeFeeFrom).add(ggeFeeTo); 

        emit Trans(_from, _to, _value, ggcFeeFrom.add(ggcFeeTo), ggeFeeFrom.add(ggeFeeTo), uint64(now));
        return true;
    }

     
    function feesCal(address _addr, uint256 _value)
    public
    view
    notNull(_addr) 
    returns (uint256 _ggcFee, uint256 _ggeFee)
    {
        if(whiteList[_addr]){
            return (0, 0);
        }else{
            _ggcFee = _value.mul(ggcFee).div(1000).div(2);
            _ggeFee = _value.mul(ggeFee).div(1000).div(2);
            return (_ggcFee, _ggeFee);
        }
    }

     
    function _transfer(address _from, address _to, uint256 _value) 
    internal 
    notNull(_from) 
    notNull(_to) 
    returns (bool) 
    {
        require(!blackList[_from]);
        require(!blackList[_to]);       
        require(!isContract(_to));
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }

     
    function approve(address _spender, uint256 _value) 
    public 
    returns (bool success) 
    {
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
            return false;
        }

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _tokenOwner, address _spender) 
    public 
    view 
    returns (uint256 remaining) 
    {
        return allowed[_tokenOwner][_spender];
    }
    
    function() 
    payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

     
    function tokenFallback(address from_, uint256 value_, bytes data_) 
    external 
    {
        from_;
        value_;
        data_;
        revert();
    }
    
     
     
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0x0));
        _;
    }

     
     
     
    function setGGCAddress(address _addr) 
    public 
    notNull(_addr) 
    onlyOwner 
    {
        if(ggcPoolAddr == address(0x0)){
            ggcPoolAddr = _addr;    
        }else{
            ggcPoolAddr = owner;
        }
        
        emit ListLog(ggcPoolAddr, 6, false);
    }

    function setGGEAddress(address _addr) 
    public 
    notNull(_addr) 
    onlyOwner 
    {
        if(ggePoolAddr == address(0x0)){
            ggePoolAddr = _addr;    
        }else{
            ggePoolAddr = owner;
        }
                        
        emit ListLog(ggePoolAddr, 7, false);
    }

    function setGGCFee(uint8 _val) 
    public 
    onlyOwner 
    {
        require(ggeFee.add(_val) <= maxFee);
        ggcFee = _val;
    }

    function setGGEFee(uint8 _val) 
    public 
    onlyOwner 
    {
        require(ggcFee.add(_val) <= maxFee);
        ggeFee = _val;
    }
    
    function addBlacklist(address _addr) public notNull(_addr) onlyOwner {
        blackList[_addr] = true; 
        emit ListLog(_addr, 3, true);
    }
    
    function delBlackList(address _addr) public notNull(_addr) onlyOwner {
        delete blackList[_addr];                
        emit ListLog(_addr, 3, false);
    }

    function setFeeLocked(bool _lock) 
    public 
    onlyOwner 
    {
        feeLocked = _lock;    
        emit ListLog(address(0x0), 4, _lock); 
    }

    function setTransContractLocked(bool _lock) 
    public 
    onlyOwner 
    {
        transContractLocked = _lock;                  
        emit ListLog(address(0x0), 5, _lock); 
    }

    function transferAnyERC20Token(address _tokenAddress, uint256 _tokens) 
    public 
    onlyOwner 
    returns (bool success) 
    {
        return ERC20Interface(_tokenAddress).transfer(owner, _tokens);
    }

    function reclaimEther(address _addr) 
    external 
    onlyOwner 
    {
        assert(_addr.send(this.balance));
    }
  
    function mintToken(address _targetAddr, uint256 _mintedAmount) 
    public 
    onlyOwner 
    {
        balances[_targetAddr] = balances[_targetAddr].add(_mintedAmount);
        _totalSupply = _totalSupply.add(_mintedAmount);
        
        emit Transfer(address(0x0), _targetAddr, _mintedAmount);
    }
 
    function burnToken(uint256 _burnedAmount) 
    public 
    onlyOwner 
    {
        require(balances[owner] >= _burnedAmount);
        
        balances[owner] = balances[owner].sub(_burnedAmount);
        _totalSupply = _totalSupply.sub(_burnedAmount);
        
        emit Transfer(owner, address(0x0), _burnedAmount);
    }

    function addWhiteList(address _addr) 
    public 
    notNull(_addr) 
    onlyOwner 
    {
        whiteList[_addr] = true; 
        emit ListLog(_addr, 1, true);
    }
  
    function delWhiteList(address _addr) 
    public 
    notNull(_addr) 
    onlyOwner
    {
        delete whiteList[_addr];
        emit ListLog(_addr, 1, false);
    }

    function addAllowContractList(address _addr) 
    public 
    notNull(_addr) 
    onlyOwner 
    {
        allowContractList[_addr] = true; 
        emit ListLog(_addr, 2, true);
    }
  
    function delAllowContractList(address _addr) 
    public 
    notNull(_addr) 
    onlyOwner 
    {
        delete allowContractList[_addr];
        emit ListLog(_addr, 2, false);
    }

    function increaseApproval(address _spender, uint256 _addedValue) 
    public 
    notNull(_spender) 
    onlyOwner returns (bool) 
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
   }

    function decreaseApproval(address _spender, uint256 _subtractedValue) 
    public 
    notNull(_spender) 
    onlyOwner returns (bool) 
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) { 
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function changeName(string _name, string _symbol) 
    public
    onlyOwner
    {
        name = _name;
        symbol = _symbol;
    }
     
     
     
    function balanceOf(address _tokenOwner) 
    public 
    view 
    returns (uint256 balance) 
    {
        return balances[_tokenOwner];
    }
    
    function totalSupply() 
    public 
    view 
    returns (uint256) 
    {
        return _totalSupply.sub(balances[address(0x0)]);
    }
}