 

pragma solidity 0.4.24;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}   

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract ERC20Interface {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
}

 
contract TestToken is ERC20Interface, Ownable {
    using SafeMath for uint256;
    
     
    string  internal constant NAME = "Test Token";
    
     
    string  internal constant SYMBOL = "TEST";     
    
     
    uint8   internal constant DECIMALS = 8;        
    
     
    uint256 internal constant DECIMALFACTOR = 10 ** uint(DECIMALS); 
    
     
    uint256 internal constant TOTAL_SUPPLY = 300000000 * uint256(DECIMALFACTOR);  
    
     
    uint8 internal constant standardDefrostingValue = 2;
    
     
    uint8 internal constant standardDefrostingNumerator = 10;

    
     
    mapping(address => bool)    public frostbite;
    
     
    mapping(address => uint256) public frozenTokensReceived;
    
     
    mapping(address => uint256) public frozenBalance;
    
     
    mapping(address => uint8) public customDefrostingRate;
    
     
    mapping(address => uint256) internal balances; 
    
     
    mapping(address => mapping(address => uint256)) internal allowed; 
    
    
     
    event FrostbiteGranted(
        address recipient, 
        uint256 frozenAmount, 
        uint256 defrostingRate);
    
     
    event FrostBiteTerminated(
        address recipient,
        uint256 frozenBalance);
    
     
    event FrozenTokensTransferred(
        address owner, 
        address recipient, 
        uint256 frozenAmount, 
        uint256 defrostingRate);
    
     
    event CustomTokenDefrosting(
        address owner,
        uint256 percentage,
        uint256 defrostedAmount);
        
     
    event CalculatedTokenDefrosting(
        address owner,
        uint256 defrostedAmount);
    
     
    event RecipientRecovered(
        address recipient,
        uint256 customDefrostingRate,
        uint256 frozenBalance,
        bool frostbite);
     
     
    event FrozenBalanceDefrosted(
        address recipient,
        uint256 frozenBalance,
        bool frostbite);
    
     
    event DefrostingRateChanged(
        address recipient,
        uint256 defrostingRate);
        
     
    event FrozenBalanceChanged(
        address recipient, 
        uint256 defrostedAmount);
    
    
     
    constructor() public {
        balances[msg.sender] = TOTAL_SUPPLY;
    }


     
    function frozenTokenTransfer(address _recipient, uint256 _frozenAmount, uint8 _customDefrostingRate) external onlyOwner returns (bool) {
        require(_recipient != address(0));
        require(_frozenAmount <= balances[msg.sender]);
        
        frozenTokensReceived[_recipient] = _frozenAmount;
               frozenBalance[_recipient] = _frozenAmount;
        customDefrostingRate[_recipient] = _customDefrostingRate;
                   frostbite[_recipient] = true;

        balances[msg.sender] = balances[msg.sender].sub(_frozenAmount);
        balances[_recipient] = balances[_recipient].add(_frozenAmount);
        
        emit FrozenTokensTransferred(msg.sender, _recipient, _frozenAmount, customDefrostingRate[_recipient]);
        return true;
    }
    
     
    function changeCustomDefrostingRate(address _recipient, uint8 _newCustomDefrostingRate) external onlyOwner returns (bool) {
        require(_recipient != address(0));
        require(frostbite[_recipient]);
        
        customDefrostingRate[_recipient] = _newCustomDefrostingRate;
        
        emit DefrostingRateChanged(_recipient, _newCustomDefrostingRate);
        return true;
    }
    
     
    function changeFrozenBalance(address _recipient, uint256 _defrostedAmount) external onlyOwner returns (bool) {
        require(_recipient != address(0));
        require(_defrostedAmount <= frozenBalance[_recipient]);
        require(frostbite[_recipient]);
        
        frozenBalance[_recipient] = frozenBalance[_recipient].sub(_defrostedAmount);
        
        emit FrozenBalanceChanged(_recipient, _defrostedAmount);
        return true;
    }
    
     
    function removeFrozenTokenConfigurations(address[] _recipients) external onlyOwner returns (bool) {
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (frostbite[_recipients[i]]) {
                customDefrostingRate[_recipients[i]] = 0;
                       frozenBalance[_recipients[i]] = 0;
                           frostbite[_recipients[i]] = false;
                
                emit RecipientRecovered(_recipients[i], customDefrostingRate[_recipients[i]], frozenBalance[_recipients[i]], false);
            }
        }
        return true;
    }
    
     
    function standardTokenDefrosting(address[] _recipients) external onlyOwner returns (bool) {
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (frostbite[_recipients[i]]) {
                uint256 defrostedAmount = (frozenTokensReceived[_recipients[i]].mul(standardDefrostingValue).div(standardDefrostingNumerator)).div(100);
                
                frozenBalance[_recipients[i]] = frozenBalance[_recipients[i]].sub(defrostedAmount);
                
                emit CalculatedTokenDefrosting(msg.sender, defrostedAmount);
            }
            if (frozenBalance[_recipients[i]] == 0) {
                         frostbite[_recipients[i]] = false;
                         
                emit FrozenBalanceDefrosted(_recipients[i], frozenBalance[_recipients[i]], false);
            }
        }
        return true;
    }
    
     
    function customTokenDefrosting(address[] _recipients) external onlyOwner returns (bool) {
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (frostbite[_recipients[i]]) {
                uint256 defrostedAmount = (frozenTokensReceived[_recipients[i]].mul(customDefrostingRate[_recipients[i]])).div(100);
                
                frozenBalance[_recipients[i]] = frozenBalance[_recipients[i]].sub(defrostedAmount);
               
                emit CustomTokenDefrosting(msg.sender, customDefrostingRate[_recipients[i]], defrostedAmount);
            }
            if (frozenBalance[_recipients[i]] == 0) {
                         frostbite[_recipients[i]] = false;
                         
                    emit FrozenBalanceDefrosted(_recipients[i], frozenBalance[_recipients[i]], false);
            }
        }
        return true;
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        if (frostbite[msg.sender]) {
            require(_value <= balances[msg.sender].sub(frozenBalance[msg.sender]));
        }
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
         
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        if (frostbite[_from]) {
            require(_value <= balances[_from].sub(frozenBalance[_from]));
            require(_value <= allowed[_from][msg.sender]);
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
        
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
     
    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;
    }
    
     
    function decimals() public view returns (uint8) {
        return DECIMALS;
    }
            
     
    function symbol() public view returns (string) {
        return SYMBOL;
    }
    
     
    function name() public view returns (string) {
        return NAME;
    }
}