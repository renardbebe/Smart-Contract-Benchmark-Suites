 

pragma solidity ^0.4.13;

contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

     
     
    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            newOwner = _newOwner;
        }
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract LegolasBase is Ownable {

    mapping (address => uint256) public balances;

     
    mapping (address => uint256) public initialAllocations;
     
    mapping (address => uint256) public allocations;
     
    mapping (uint256 => mapping(address => bool)) public eligibleForBonus;
     
    mapping (uint256 => uint256) public unspentAmounts;
     
    mapping (address => bool) public founders;
     
    mapping (address => bool) public advisors;

     
    uint256[12] public ADVISORS_LOCK_DATES = [1521072000, 1523750400, 1526342400,
                                       1529020800, 1531612800, 1534291200,
                                       1536969600, 1539561600, 1542240000,
                                       1544832000, 1547510400, 1550188800];
     
    uint256[12] public FOUNDERS_LOCK_DATES = [1552608000, 1555286400, 1557878400,
                                       1560556800, 1563148800, 1565827200,
                                       1568505600, 1571097600, 1573776000,
                                       1576368000, 1579046400, 1581724800];

     
    uint256[4] public BONUS_DATES = [1534291200, 1550188800, 1565827200, 1581724800];

     
     
    function getLockedAmount(address _address) internal view returns (uint256 lockedAmount) {
         
        if (!advisors[_address] && !founders[_address]) return 0;
         
        uint256[12] memory lockDates = advisors[_address] ? ADVISORS_LOCK_DATES : FOUNDERS_LOCK_DATES;
         
        for (uint8 i = 11; i >= 0; i--) {
            if (now >= lockDates[i]) {
                return (allocations[_address] / 12) * (11 - i);
            }
        }
        return allocations[_address];
    }

    function updateBonusEligibity(address _from) internal {
        if (now < BONUS_DATES[3] &&
            initialAllocations[_from] > 0 &&
            balances[_from] < allocations[_from]) {
            for (uint8 i = 0; i < 4; i++) {
                if (now < BONUS_DATES[i] && eligibleForBonus[BONUS_DATES[i]][_from]) {
                    unspentAmounts[BONUS_DATES[i]] -= initialAllocations[_from];
                    eligibleForBonus[BONUS_DATES[i]][_from] = false;
                }
            }
        }
    }
}

contract EIP20 is EIP20Interface, LegolasBase {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => mapping (address => uint256)) public allowed;


     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  

    function EIP20(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
         
        require(balances[msg.sender] - _value >= getLockedAmount(msg.sender));
        balances[msg.sender] -= _value;
        balances[_to] += _value;

         
        updateBonusEligibity(msg.sender);

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);

         
        require(balances[_from] - _value >= getLockedAmount(_from));

        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }

         
        updateBonusEligibity(_from);

        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Legolas is EIP20 {

     
    string  constant NAME = "LGO Token";
    string  constant SYMBOL = "LGO";
    uint8   constant DECIMALS = 8;
    uint256 constant UNIT = 10**uint256(DECIMALS);

    uint256 constant onePercent = 181415052000000;

     
    uint256 constant ADVISORS_AMOUNT =   5 * onePercent;
     
    uint256 constant FOUNDERS_AMOUNT =  15 * onePercent;
     
    uint256 constant HOLDERS_AMOUNT  =  60 * onePercent;
     
    uint256 constant RESERVE_AMOUNT  =  20 * onePercent;
     
    uint256 constant INITIAL_AMOUNT  = 100 * onePercent;
     
    uint256 constant BONUS_AMOUNT    =  20 * onePercent;
     
    uint256 public advisorsAllocatedAmount = 0;
     
    uint256 public foundersAllocatedAmount = 0;
     
    uint256 public holdersAllocatedAmount = 0;
     
    address[] initialHolders;
     
    mapping (uint256 => mapping(address => bool)) bonusNotDistributed;

    event Allocate(address _address, uint256 _value);

    function Legolas() EIP20(  
        INITIAL_AMOUNT + BONUS_AMOUNT,
        NAME,
        DECIMALS,
        SYMBOL
    ) public {}

     
     
     
     
    function allocate(address _address, uint256 _amount, uint8 _type) public onlyOwner returns (bool success) {
         
        require(allocations[_address] == 0);

        if (_type == 0) {  
             
            require(advisorsAllocatedAmount + _amount <= ADVISORS_AMOUNT);
             
            advisorsAllocatedAmount += _amount;
             
            advisors[_address] = true;
        } else if (_type == 1) {  
             
            require(foundersAllocatedAmount + _amount <= FOUNDERS_AMOUNT);
             
            foundersAllocatedAmount += _amount;
             
            founders[_address] = true;
        } else {
             
            require(holdersAllocatedAmount + _amount <= HOLDERS_AMOUNT + RESERVE_AMOUNT);
             
            holdersAllocatedAmount += _amount;
        }
         
        allocations[_address] = _amount;
        initialAllocations[_address] = _amount;

         
        balances[_address] += _amount;

         
        for (uint8 i = 0; i < 4; i++) {
             
            unspentAmounts[BONUS_DATES[i]] += _amount;
             
            eligibleForBonus[BONUS_DATES[i]][_address] = true;
            bonusNotDistributed[BONUS_DATES[i]][_address] = true;
        }

         
        initialHolders.push(_address);

        Allocate(_address, _amount);

        return true;
    }

     
     
     
    function claimBonus(address _address, uint256 _bonusDate) public returns (bool success) {
         
        require(_bonusDate <= now);
         
        require(bonusNotDistributed[_bonusDate][_address]);
         
        require(eligibleForBonus[_bonusDate][_address]);

         
        uint256 bonusByLgo = (BONUS_AMOUNT / 4) / unspentAmounts[_bonusDate];

         
        uint256 holderBonus = initialAllocations[_address] * bonusByLgo;
        balances[_address] += holderBonus;
        allocations[_address] += holderBonus;

         
        bonusNotDistributed[_bonusDate][_address] = false;
        return true;
    }
}