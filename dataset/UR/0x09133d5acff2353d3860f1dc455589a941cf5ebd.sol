 

pragma solidity ^0.4.13;


 
contract Ownable {
    address public owner;

     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

 
contract LoggedERC20 is Ownable {
     
    struct LogValueBlock {
    uint256 value;
    uint256 block;
    }

     
    string public standard = 'LogValueBlockToken 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    LogValueBlock[] public loggedTotalSupply;

    bool public locked;

    uint256 public creationBlock;

     
    mapping (address => LogValueBlock[]) public loggedBalances;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    function LoggedERC20(
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol,
    bool transferAllSupplyToOwner,
    bool _locked
    ) {
        LogValueBlock memory valueBlock = LogValueBlock(initialSupply, block.number);

        loggedTotalSupply.push(valueBlock);

        if(transferAllSupplyToOwner) {
            loggedBalances[msg.sender].push(valueBlock);
        }
        else {
            loggedBalances[this].push(valueBlock);
        }

        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
        locked = _locked;
    }

    function valueAt(LogValueBlock [] storage checkpoints, uint256 block) internal returns (uint256) {
        if(checkpoints.length == 0) {
            return 0;
        }

        LogValueBlock memory prevLogValueBlock;

        for(uint256 i = 0; i < checkpoints.length; i++) {

            LogValueBlock memory checkpoint = checkpoints[i];

            if(checkpoint.block > block) {
                return prevLogValueBlock.value;
            }

            prevLogValueBlock = checkpoint;
        }

        return prevLogValueBlock.value;
    }

    function setBalance(address _address, uint256 value) internal {
        loggedBalances[_address].push(LogValueBlock(value, block.number));
    }

    function totalSupply() returns (uint256) {
        return valueAt(loggedTotalSupply, block.number);
    }

    function balanceOf(address _address) returns (uint256) {
        return valueAt(loggedBalances[_address], block.number);
    }

    function transferInternal(address _from, address _to, uint256 value) internal returns (bool success) {
        uint256 balanceFrom = valueAt(loggedBalances[_from], block.number);
        uint256 balanceTo = valueAt(loggedBalances[_to], block.number);

        if(value == 0) {
            return false;
        }

        if(frozenAccount[_from] == true) {
            return false;
        }

        if(balanceFrom < value) {
            return false;
        }

        if(balanceTo + value <= balanceTo) {
            return false;
        }

        loggedBalances[_from].push(LogValueBlock(balanceFrom - value, block.number));
        loggedBalances[_to].push(LogValueBlock(balanceTo + value, block.number));

        Transfer(_from, _to, value);

        return true;
    }

     
    function transfer(address _to, uint256 _value) {
        require(locked == false);

        bool status = transferInternal(msg.sender, _to, _value);

        require(status == true);
    }

     
    function approve(address _spender, uint256 _value) returns (bool success) {
        if(locked) {
            return false;
        }

        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        if(locked) {
            return false;
        }

        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if(locked) {
            return false;
        }

        if(allowance[_from][msg.sender] < _value) {
            return false;
        }

        bool _success = transferInternal(_from, _to, _value);

        if(_success) {
            allowance[_from][msg.sender] -= _value;
        }

        return _success;
    }
}

 
contract LoggedReward is Ownable, LoggedERC20 {
     
    struct Reward {
    uint256 id;

    uint256 block;
    uint256 time;
    uint256 amount;

    uint256 claimedAmount;
    uint256 transferedBack;

    uint256 totalSupply;
    uint256 recycleTime;

    bool recycled;

    mapping (address => bool) claimed;
    }

     
    Reward [] public rewards;

    mapping (address => uint256) rewardsClaimed;

     
    event RewardTransfered(uint256 id, address indexed _address, uint256 _block, uint256 _amount, uint256 _totalSupply);
    event RewardClaimed(uint256 id, address indexed _address, uint256 _claim);
    event UnclaimedRewardTransfer(uint256 id, uint256 _value);
    event RewardRecycled(uint256 id, address indexed _recycler, uint256 _blockNumber, uint256 _amount, uint256 _totalSupply);

    function LoggedReward(
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol,
    bool transferAllSupplyToOwner,
    bool _locked
    ) LoggedERC20(initialSupply, tokenName, decimalUnits, tokenSymbol, transferAllSupplyToOwner, _locked) {

    }

    function addReward(uint256 recycleTime) payable onlyOwner {
        require(msg.sender == owner);
        require(msg.value > 0);

        uint256 id = rewards.length;
        uint256 _totalSupply = valueAt(loggedTotalSupply, block.number);

        rewards.push(
        Reward(
        id,
        block.number,
        now,
        msg.value,
        0,
        0,
        _totalSupply,
        recycleTime,
        false
        )
        );

        RewardTransfered(id, msg.sender, block.number, msg.value, _totalSupply);
    }

    function claimedRewardHook(uint256 rewardId, address _address, uint256 claimed) internal {
        RewardClaimed(rewardId, _address, claimed);
    }

    function claimReward(uint256 rewardId) public returns (bool) {
        if(rewards.length - 1 < rewardId) {
            return false;
        }

        Reward storage reward = rewards[rewardId];

        if(reward.claimed[msg.sender] == true) {
            return false;
        }

        if(reward.recycled == true) {
            return false;
        }

        if(now >= reward.time + reward.recycleTime) {
            return false;
        }

        uint256 balance = valueAt(loggedBalances[msg.sender], reward.block);

        if(balance == 0) {
            return false;
        }

        uint256 claim = balance * reward.amount / reward.totalSupply;

        reward.claimed[msg.sender] = true;

        reward.claimedAmount = reward.claimedAmount + claim;

        if (claim > 0) {
            claimedRewardHook(rewardId, msg.sender, claim);

            msg.sender.transfer(claim);

            return true;
        }

        return false;
    }

    function claimRewards() public {
        require(rewardsClaimed[msg.sender] < rewards.length);
        for (uint i = rewardsClaimed[msg.sender]; i < rewards.length; i++) {
            if ((rewards[i].claimed[msg.sender] == false) && (rewards[i].recycled == false)) {
                rewardsClaimed[msg.sender] = i + 1;
                claimReward(i);
            }
        }
    }

    function recycleReward(uint256 rewardId) public onlyOwner returns (bool success) {
        if(rewards.length - 1 < rewardId) {
            return false;
        }

        Reward storage reward = rewards[rewardId];

        if(reward.recycled) {
            return false;
        }

        reward.recycled = true;

        return true;
    }

    function refundUnclaimedEthers(uint256 rewardId) public onlyOwner returns (bool success) {
        if(rewards.length - 1 < rewardId) {
            return false;
        }

        Reward storage reward = rewards[rewardId];

        if(reward.recycled == false) {
            if(now < reward.time + reward.recycleTime) {
                return false;
            }
        }

        uint256 claimedBackAmount = reward.amount - reward.claimedAmount;

        reward.transferedBack = claimedBackAmount;

        if(claimedBackAmount > 0) {
            owner.transfer(claimedBackAmount);

            UnclaimedRewardTransfer(rewardId, claimedBackAmount);

            return true;
        }

        return false;
    }
}

 
contract Inonit is LoggedReward {
     
    event AddressRecovered(address indexed from, address indexed to);
    event InactivityHolderResetBalance(address indexed _holder);

    function Inonit(
    uint256 initialSupply,
    string standardName,
    string tokenName,
    string tokenSymbol
    ) LoggedReward(initialSupply, tokenName, 18, tokenSymbol, true, false) {
        standard = standardName;
    }

    function balanceOf(address _address) returns (uint256) {
        if(rewards.length > 0) {
            Reward storage reward = rewards[0];

            if(reward.recycled) {
                return 0;
            }

            if(now >= reward.time + reward.recycleTime) {
                return 0;
            }
        }

        uint256 holderBalance = valueAt(loggedBalances[_address], block.number);

        return holderBalance;
    }

    function claimedRewardHook(uint256 rewardId, address _address, uint256 claimed) internal {
        setBalance(_address, 0);

        super.claimedRewardHook(rewardId, _address, claimed);
    }

    function recover(address _from, address _to) onlyOwner {
        uint256 tokens = balanceOf(_from);

        setBalance(_from, 0);
        setBalance(_to, tokens);

        AddressRecovered(_from, _to);
    }

    function setLocked(bool _locked) onlyOwner {
        locked = _locked;
    }
}