 

pragma solidity ^0.4.17;

contract LatiumX {
    string public constant name = "LatiumX";
    string public constant symbol = "LATX";
    uint8 public constant decimals = 8;
    uint256 public constant totalSupply =
        300000000 * 10 ** uint256(decimals);

     
    address public owner;

     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed _from, address indexed _to, uint _value);

     
    function LatiumX() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

     
    function transfer(address _to, uint256 _value) {
         
        require(_to != 0x0);
         
        require(msg.sender != _to);
         
        require(_value > 0 && balanceOf[msg.sender] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        balanceOf[msg.sender] -= _value;
         
        balanceOf[_to] += _value;
         
        Transfer(msg.sender, _to, _value);
    }
}

contract LatiumLocker {
    address private constant _latiumAddress = 0x2f85E502a988AF76f7ee6D83b7db8d6c0A823bf9;
    LatiumX private constant _latium = LatiumX(_latiumAddress);

     
    uint256 private _lockLimit = 0;

     
    uint32[] private _timestamps = [
        1517400000  
        , 1525089600  
        , 1533038400  
        , 1540987200  
        
    ];
    uint32[] private _tokensToRelease = [  
        15000000
        , 15000000
        , 15000000
        , 15000000
       
    ];
    mapping (uint32 => uint256) private _releaseTiers;

     
    address public owner;

     
    function LatiumLocker() {
        owner = msg.sender;
         
         
        for (uint8 i = 0; i < _timestamps.length; i++) {
            _releaseTiers[_timestamps[i]] =
                _tokensToRelease[i] * 10 ** uint256(_latium.decimals());
            _lockLimit += _releaseTiers[_timestamps[i]];
        }
    }

     
     
    function latiumBalance() constant returns (uint256 balance) {
        return _latium.balanceOf(address(this));
    }

     
     
    function lockLimit() constant returns (uint256 limit) {
        return _lockLimit;
    }

     
     
    function lockedTokens() constant returns (uint256 locked) {
        locked = 0;
        uint256 unlocked = 0;
        for (uint8 i = 0; i < _timestamps.length; i++) {
            if (now >= _timestamps[i]) {
                unlocked += _releaseTiers[_timestamps[i]];
            } else {
                locked += _releaseTiers[_timestamps[i]];
            }
        }
        uint256 balance = latiumBalance();
        if (unlocked > balance) {
            locked = 0;
        } else {
            balance -= unlocked;
            if (balance < locked) {
                locked = balance;
            }
        }
    }

     
     
    function canBeWithdrawn() constant returns (uint256 unlockedTokens, uint256 excessTokens) {
        unlockedTokens = 0;
        excessTokens = 0;
        uint256 tiersBalance = 0;
        for (uint8 i = 0; i < _timestamps.length; i++) {
            tiersBalance += _releaseTiers[_timestamps[i]];
            if (now >= _timestamps[i]) {
                unlockedTokens += _releaseTiers[_timestamps[i]];
            }
        }
        uint256 balance = latiumBalance();
        if (unlockedTokens > balance) {
             
             
            unlockedTokens = balance;
        } else if (balance > tiersBalance) {
             
             
             
            excessTokens = (balance - tiersBalance);
        }
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function withdraw(uint256 _amount) onlyOwner {
        var (unlockedTokens, excessTokens) = canBeWithdrawn();
        uint256 totalAmount = unlockedTokens + excessTokens;
        require(totalAmount > 0);
        if (_amount == 0) {
             
            _amount = totalAmount;
        }
        require(totalAmount >= _amount);
        uint256 unlockedToWithdraw =
            _amount > unlockedTokens ?
                unlockedTokens :
                _amount;
        if (unlockedToWithdraw > 0) {
             
            uint8 i = 0;
            while (unlockedToWithdraw > 0 && i < _timestamps.length) {
                if (now >= _timestamps[i]) {
                    uint256 amountToReduce =
                        unlockedToWithdraw > _releaseTiers[_timestamps[i]] ?
                            _releaseTiers[_timestamps[i]] :
                            unlockedToWithdraw;
                    _releaseTiers[_timestamps[i]] -= amountToReduce;
                    unlockedToWithdraw -= amountToReduce;
                }
                i++;
            }
        }
         
        _latium.transfer(msg.sender, _amount);
    }
}