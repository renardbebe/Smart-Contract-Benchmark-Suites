 

contract Ambi {
    function getNodeAddress(bytes32) constant returns (address);
    function addNode(bytes32, address) external returns (bool);
    function hasRelation(bytes32, bytes32, address) constant returns (bool);
}

contract AmbiEnabled {
    Ambi ambiC;
    bytes32 public name;

    modifier checkAccess(bytes32 _role) {
        if(address(ambiC) != 0x0 && ambiC.hasRelation(name, _role, msg.sender)){
            _
        }
    }
    
    function getAddress(bytes32 _name) returns (address) {
        return ambiC.getNodeAddress(_name);
    }

    function setAmbiAddress(address _ambi, bytes32 _name) returns (bool){
        if(address(ambiC) != 0x0){
            return false;
        }
        Ambi ambiContract = Ambi(_ambi);
        if(ambiContract.getNodeAddress(_name)!=address(this)) {
            bool isNode = ambiContract.addNode(_name, address(this));
            if (!isNode){
                return false;
            }   
        }
        name = _name;
        ambiC = ambiContract;
        return true;
    }

    function remove(){
        if(msg.sender == address(ambiC)){
            suicide(msg.sender);
        }
    }
}

contract ElcoinDb {
    function getBalance(address addr) constant returns(uint balance);
}

contract ElcoinInterface {
    function rewardTo(address _to, uint _amount) returns (bool);
}

contract PosRewards is AmbiEnabled {

    event Reward(address indexed beneficiary, uint indexed cycle, uint value, uint position);

    uint public cycleLength;  
    uint public startTime;    
    uint public cycleLimit;   
    uint public minimalRewardedBalance;  
                              
    uint[] public bannedCycles;

    enum RewardStatuses { Unsent, Sent, TooSmallToSend }

    struct Account {
        address recipient;
        RewardStatuses status;
    }

     
    mapping (uint => mapping (address => int)) public accountsBalances;
     
    mapping (uint => Account[]) public accountsUsed;

    function PosRewards() {
        cycleLength = 864000;  
        cycleLimit = 255;  
        minimalRewardedBalance = 1000000;  
        startTime = now;
    }

     
     
     
    function setStartTime(uint _startTime) checkAccess("owner") {
        startTime = _startTime;
    }

     
    function setCycleLimit(uint _cycleLimit) checkAccess("owner") {
        cycleLimit = _cycleLimit;
    }

     
     
    function setBannedCycles(uint[] _cycles) checkAccess("owner") {
        bannedCycles = _cycles;
    }

     
    function setMinimalRewardedBalance(uint _balance) checkAccess("owner") {
        minimalRewardedBalance = _balance;
    }

    function kill() checkAccess("owner") {
        suicide(msg.sender);  
    }

     
     
     
     
     
    function getRate(uint cycle) constant returns (uint) {
        if (cycle <= 9) {
            return 50;
        }
        if (cycle <= 18) {
            return 40;
        }
        if (cycle <= 27) {
            return 30;
        }
        if (cycle <= 35) {  
            return 20;
        }
        if (cycle == 36) {
            return 40;
        }
        if (cycle <= cycleLimit) {
            if (cycle % 36 == 0) {
                 
                 
                return 20;
            }

            return 10;
        }
        return 0;
    }

     
    function currentCycle() constant returns (uint) {
        if (startTime > now) {
            return 0;
        }

        return 1 + ((now - startTime) / cycleLength);
    }

    function _isCycleValid(uint _cycle) constant internal returns (bool) {
        if (_cycle >= currentCycle() || _cycle == 0) {
            return false;
        }
        for (uint i; i<bannedCycles.length; i++) {
            if (bannedCycles[i] == _cycle) {
                return false;
            }
        }

        return true;
    }

     
     
    function getInterest(uint amount, uint cycle) constant returns (uint) {
        return (amount * getRate(cycle)) / 3650;
    }

     
    function transfer(address _from, address _to) checkAccess("elcoin") {
        if (startTime == 0) {
            return;  
        }

        _storeBalanceRecord(_from);
        _storeBalanceRecord(_to);
    }

    function _storeBalanceRecord(address _addr) internal {
        ElcoinDb db = ElcoinDb(getAddress("elcoinDb"));
        uint cycle = currentCycle();

        if (cycle > cycleLimit) {
            return;
        }

        int balance = int(db.getBalance(_addr));
        bool accountNotUsedInCycle = (accountsBalances[cycle][_addr] == 0);

         
         
         
        if (accountsBalances[cycle][_addr] != -1 && (accountNotUsedInCycle || accountsBalances[cycle][_addr] > balance)) {
            if (balance == 0) {
                balance = -1;
            }
            accountsBalances[cycle][_addr] = balance;

            if (accountNotUsedInCycle) {
                 
                accountsUsed[cycle].push(Account(_addr, RewardStatuses.Unsent));
            }
        }
    }

     
    function getMinimalBalance(uint _cycle, address _addr) constant returns(int) {
        int balance = accountsBalances[_cycle][_addr];
        if (balance == -1) {
            balance = 0;
        }

        return balance;
    }

     
    function getAccountInfo(uint _cycle, uint _position) constant returns(address, RewardStatuses, int) {
        return (
            accountsUsed[_cycle][_position].recipient,
            accountsUsed[_cycle][_position].status,
            accountsBalances[_cycle][accountsUsed[_cycle][_position].recipient]
          );
    }

     
    function getRewardsCount(uint _cycle) constant returns(uint) {
        return accountsUsed[_cycle].length;
    }

    function sendReward(uint _cycle, uint _position) returns(bool) {
         
        if (!_isCycleValid(_cycle) || _position >= accountsUsed[_cycle].length) {
            return false;
        }

         
        Account claimant = accountsUsed[_cycle][_position];
        if (claimant.status != RewardStatuses.Unsent) {
            return false;
        }

         
        int minimalAccountBalance = accountsBalances[_cycle][claimant.recipient];
        if (minimalAccountBalance < int(minimalRewardedBalance)) {
            claimant.status = RewardStatuses.TooSmallToSend;
            return false;
        }

        uint rewardAmount = getInterest(uint(minimalAccountBalance), _cycle);

         
        ElcoinInterface elcoin = ElcoinInterface(getAddress("elcoin"));
        bool result = elcoin.rewardTo(claimant.recipient, rewardAmount);
        if (result) {
            Reward(claimant.recipient, _cycle, rewardAmount, _position);
            claimant.status = RewardStatuses.Sent;
        }

        return true;
    }
}