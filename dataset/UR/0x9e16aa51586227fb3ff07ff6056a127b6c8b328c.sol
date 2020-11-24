 

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

 
contract IPTGlobal is ERC20Interface, Ownable {
    using SafeMath for uint256;
    
     
    string  internal constant NAME = "IPT Global";
    
     
    string  internal constant SYMBOL = "IPT";     
    
     
    uint8   internal constant DECIMALS = 8;        
    
     
    uint256 internal constant DECIMALFACTOR = 10 ** uint(DECIMALS); 
    
     
    uint256 internal constant TOTAL_SUPPLY = 300000000 * uint256(DECIMALFACTOR);  
    
     
    uint8   internal constant unlockingValue = 2;
    
     
    uint8   internal constant unlockingNumerator = 10;
    
     
    uint256 private unlockedTokensDaily;
     
    uint256 private unlockedTokensTotal;
    
    address[] uniqueLockedTokenReceivers; 
    
     
    mapping(address => bool)    internal uniqueLockedTokenReceiver;
    
     
    mapping(address => bool)    internal isHoldingLockedTokens;
    
     
    mapping(address => bool)    internal excludedFromTokenUnlock;
    
     
    mapping(address => uint256) internal lockedTokenBalance;
    
     
    mapping(address => uint256) internal balances; 
    
     
    mapping(address => mapping(address => uint256)) internal allowed; 
    
    
    event HoldingLockedTokens(
        address recipient, 
        uint256 lockedTokenBalance,
        bool    isHoldingLockedTokens);
    
    event LockedTokensTransferred(
        address recipient, 
        uint256 lockedTokens,
        uint256 lockedTokenBalance);
        
    event TokensUnlocked(
        address recipient,
        uint256 unlockedTokens,
        uint256 lockedTokenBalance);
        
    event LockedTokenBalanceChanged(
        address recipient, 
        uint256 unlockedTokens,
        uint256 lockedTokenBalance);
        
    event ExcludedFromTokenUnlocks(
        address recipient,
        bool    excludedFromTokenUnlocks);
    
    event CompleteTokenBalanceUnlocked(
        address recipient,
        uint256 lockedTokenBalance,
        bool    isHoldingLockedTokens,
        bool    completeTokenBalanceUnlocked);
    
    
     
    constructor() public {
        balances[msg.sender] = TOTAL_SUPPLY;
    }

     
    function lockedTokenTransfer(address[] _recipient, uint256[] _lockedTokens) external onlyOwner {
       
        for (uint256 i = 0; i < _recipient.length; i++) {
            if (!uniqueLockedTokenReceiver[_recipient[i]]) {
                uniqueLockedTokenReceiver[_recipient[i]] = true;
                uniqueLockedTokenReceivers.push(_recipient[i]);
                }
                
            isHoldingLockedTokens[_recipient[i]] = true;
            
            lockedTokenBalance[_recipient[i]] = lockedTokenBalance[_recipient[i]].add(_lockedTokens[i]);
            
            transfer(_recipient[i], _lockedTokens[i]);
            
            emit HoldingLockedTokens(_recipient[i], _lockedTokens[i], isHoldingLockedTokens[_recipient[i]]);
            emit LockedTokensTransferred(_recipient[i], _lockedTokens[i], lockedTokenBalance[_recipient[i]]);
        }
    }

     
    function changeLockedBalanceManually(address _owner, uint256 _unlockedTokens) external onlyOwner {
        require(_owner != address(0));
        require(_unlockedTokens <= lockedTokenBalance[_owner]);
        require(isHoldingLockedTokens[_owner]);
        require(!excludedFromTokenUnlock[_owner]);
        
        lockedTokenBalance[_owner] = lockedTokenBalance[_owner].sub(_unlockedTokens);
        emit LockedTokenBalanceChanged(_owner, _unlockedTokens, lockedTokenBalance[_owner]);
        
        unlockedTokensDaily  = unlockedTokensDaily.add(_unlockedTokens);
        unlockedTokensTotal  = unlockedTokensTotal.add(_unlockedTokens);
        
        if (lockedTokenBalance[_owner] == 0) {
           isHoldingLockedTokens[_owner] = false;
           emit CompleteTokenBalanceUnlocked(_owner, lockedTokenBalance[_owner], isHoldingLockedTokens[_owner], true);
        }
    }

     
    function unlockTokens() external onlyOwner {

        for (uint256 i = 0; i < uniqueLockedTokenReceivers.length; i++) {
            if (isHoldingLockedTokens[uniqueLockedTokenReceivers[i]] && 
                !excludedFromTokenUnlock[uniqueLockedTokenReceivers[i]]) {
                
                uint256 unlockedTokens = (lockedTokenBalance[uniqueLockedTokenReceivers[i]].mul(unlockingValue).div(unlockingNumerator)).div(100);
                lockedTokenBalance[uniqueLockedTokenReceivers[i]] = lockedTokenBalance[uniqueLockedTokenReceivers[i]].sub(unlockedTokens);
                uint256 unlockedTokensToday = unlockedTokensToday.add(unlockedTokens);
                
                emit TokensUnlocked(uniqueLockedTokenReceivers[i], unlockedTokens, lockedTokenBalance[uniqueLockedTokenReceivers[i]]);
            }
            if (lockedTokenBalance[uniqueLockedTokenReceivers[i]] == 0) {
                isHoldingLockedTokens[uniqueLockedTokenReceivers[i]] = false;
                
                emit CompleteTokenBalanceUnlocked(uniqueLockedTokenReceivers[i], lockedTokenBalance[uniqueLockedTokenReceivers[i]], isHoldingLockedTokens[uniqueLockedTokenReceivers[i]], true);
            }  
        }    
        unlockedTokensDaily  = unlockedTokensToday;
        unlockedTokensTotal  = unlockedTokensTotal.add(unlockedTokensDaily);
    }
    
     
    function addExclusionFromTokenUnlocks(address[] _excludedRecipients) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < _excludedRecipients.length; i++) {
            excludedFromTokenUnlock[_excludedRecipients[i]] = true;
            emit ExcludedFromTokenUnlocks(_excludedRecipients[i], excludedFromTokenUnlock[_excludedRecipients[i]]);
        }
        return true;
    }
    
     
    function removeExclusionFromTokenUnlocks(address[] _excludedRecipients) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < _excludedRecipients.length; i++) {
            excludedFromTokenUnlock[_excludedRecipients[i]] = false;
            emit ExcludedFromTokenUnlocks(_excludedRecipients[i], excludedFromTokenUnlock[_excludedRecipients[i]]);
        }
        return true;
    }
    
     
    function checkTokenBalanceState(address _owner) external view returns(uint256 unlockedBalance, uint256 lockedBalance) {
    return (balanceOf(_owner).sub(lockedTokenBalance[_owner]), lockedTokenBalance[_owner]);
    }
    
     
    function checkUniqueLockedTokenReceivers() external view returns (address[]) {
        return uniqueLockedTokenReceivers;
    }
    
      
    function checkUnlockedTokensData() external view returns (uint256 unlockedDaily, uint256 unlockedTotal) {
        return (unlockedTokensDaily, unlockedTokensTotal);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        if (isHoldingLockedTokens[msg.sender]) {
            require(_value <= balances[msg.sender].sub(lockedTokenBalance[msg.sender]));
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
        
        if (isHoldingLockedTokens[_from]) {
            require(_value <= balances[_from].sub(lockedTokenBalance[_from]));
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