 

pragma solidity ^0.5.0;

 
contract TellorGetters {
    using SafeMath for uint256;

    using TellorTransfer for TellorStorage.TellorStorageStruct;
    using TellorGettersLibrary for TellorStorage.TellorStorageStruct;
    using TellorStake for TellorStorage.TellorStorageStruct;

    TellorStorage.TellorStorageStruct tellor;

     
    function allowance(address _user, address _spender) external view returns (uint256) {
        return tellor.allowance(_user, _spender);
    }

     
    function allowedToTrade(address _user, uint256 _amount) external view returns (bool) {
        return tellor.allowedToTrade(_user, _amount);
    }

     
    function balanceOf(address _user) external view returns (uint256) {
        return tellor.balanceOf(_user);
    }

     
    function balanceOfAt(address _user, uint256 _blockNumber) external view returns (uint256) {
        return tellor.balanceOfAt(_user, _blockNumber);
    }

     
    function didMine(bytes32 _challenge, address _miner) external view returns (bool) {
        return tellor.didMine(_challenge, _miner);
    }

     
    function didVote(uint256 _disputeId, address _address) external view returns (bool) {
        return tellor.didVote(_disputeId, _address);
    }

     
    function getAddressVars(bytes32 _data) external view returns (address) {
        return tellor.getAddressVars(_data);
    }

     
    function getAllDisputeVars(uint256 _disputeId)
        public
        view
        returns (bytes32, bool, bool, bool, address, address, address, uint256[9] memory, int256)
    {
        return tellor.getAllDisputeVars(_disputeId);
    }

     
    function getCurrentVariables() external view returns (bytes32, uint256, uint256, string memory, uint256, uint256) {
        return tellor.getCurrentVariables();
    }

     
    function getDisputeIdByDisputeHash(bytes32 _hash) external view returns (uint256) {
        return tellor.getDisputeIdByDisputeHash(_hash);
    }

     
    function getDisputeUintVars(uint256 _disputeId, bytes32 _data) external view returns (uint256) {
        return tellor.getDisputeUintVars(_disputeId, _data);
    }

     
    function getLastNewValue() external view returns (uint256, bool) {
        return tellor.getLastNewValue();
    }

     
    function getLastNewValueById(uint256 _requestId) external view returns (uint256, bool) {
        return tellor.getLastNewValueById(_requestId);
    }

     
    function getMinedBlockNum(uint256 _requestId, uint256 _timestamp) external view returns (uint256) {
        return tellor.getMinedBlockNum(_requestId, _timestamp);
    }

     
    function getMinersByRequestIdAndTimestamp(uint256 _requestId, uint256 _timestamp) external view returns (address[5] memory) {
        return tellor.getMinersByRequestIdAndTimestamp(_requestId, _timestamp);
    }

     
    function getName() external view returns (string memory) {
        return tellor.getName();
    }

     
    function getNewValueCountbyRequestId(uint256 _requestId) external view returns (uint256) {
        return tellor.getNewValueCountbyRequestId(_requestId);
    }

     
    function getRequestIdByRequestQIndex(uint256 _index) external view returns (uint256) {
        return tellor.getRequestIdByRequestQIndex(_index);
    }

     
    function getRequestIdByTimestamp(uint256 _timestamp) external view returns (uint256) {
        return tellor.getRequestIdByTimestamp(_timestamp);
    }

     
    function getRequestIdByQueryHash(bytes32 _request) external view returns (uint256) {
        return tellor.getRequestIdByQueryHash(_request);
    }

     
    function getRequestQ() public view returns (uint256[51] memory) {
        return tellor.getRequestQ();
    }

     
    function getRequestUintVars(uint256 _requestId, bytes32 _data) external view returns (uint256) {
        return tellor.getRequestUintVars(_requestId, _data);
    }

     
    function getRequestVars(uint256 _requestId) external view returns (string memory, string memory, bytes32, uint256, uint256, uint256) {
        return tellor.getRequestVars(_requestId);
    }

     
    function getStakerInfo(address _staker) external view returns (uint256, uint256) {
        return tellor.getStakerInfo(_staker);
    }

     
    function getSubmissionsByTimestamp(uint256 _requestId, uint256 _timestamp) external view returns (uint256[5] memory) {
        return tellor.getSubmissionsByTimestamp(_requestId, _timestamp);
    }

     
    function getSymbol() external view returns (string memory) {
        return tellor.getSymbol();
    }

     
    function getTimestampbyRequestIDandIndex(uint256 _requestID, uint256 _index) external view returns (uint256) {
        return tellor.getTimestampbyRequestIDandIndex(_requestID, _index);
    }

     
    function getUintVar(bytes32 _data) public view returns (uint256) {
        return tellor.getUintVar(_data);
    }

     
    function getVariablesOnDeck() external view returns (uint256, uint256, string memory) {
        return tellor.getVariablesOnDeck();
    }

     
    function isInDispute(uint256 _requestId, uint256 _timestamp) external view returns (bool) {
        return tellor.isInDispute(_requestId, _timestamp);
    }

     
    function retrieveData(uint256 _requestId, uint256 _timestamp) external view returns (uint256) {
        return tellor.retrieveData(_requestId, _timestamp);
    }

     
    function totalSupply() external view returns (uint256) {
        return tellor.totalSupply();
    }

}


 
contract TellorMaster is TellorGetters {
    event NewTellorAddress(address _newTellor);

     
    constructor(address _tellorContract) public {
        tellor.init();
        tellor.addressVars[keccak256("_owner")] = msg.sender;
        tellor.addressVars[keccak256("_deity")] = msg.sender;
        tellor.addressVars[keccak256("tellorContract")] = _tellorContract;
        emit NewTellorAddress(_tellorContract);
    }

     

    function changeDeity(address _newDeity) external {
        tellor.changeDeity(_newDeity);
    }

     
    function changeTellorContract(address _tellorContract) external {
        tellor.changeTellorContract(_tellorContract);
    }

     
    function() external payable {
        address addr = tellor.addressVars[keccak256("tellorContract")];
        bytes memory _calldata = msg.data;
        assembly {
            let result := delegatecall(not(0), addr, add(_calldata, 0x20), mload(_calldata), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
             
             
            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }
}




 
library TellorTransfer {
    using SafeMath for uint256;

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);  
    event Transfer(address indexed _from, address indexed _to, uint256 _value);  

     

     
    function transfer(TellorStorage.TellorStorageStruct storage self, address _to, uint256 _amount) public returns (bool success) {
        doTransfer(self, msg.sender, _to, _amount);
        return true;
    }

     
    function transferFrom(TellorStorage.TellorStorageStruct storage self, address _from, address _to, uint256 _amount)
        public
        returns (bool success)
    {
        require(self.allowed[_from][msg.sender] >= _amount, "Allowance is wrong");
        self.allowed[_from][msg.sender] -= _amount;
        doTransfer(self, _from, _to, _amount);
        return true;
    }

     
    function approve(TellorStorage.TellorStorageStruct storage self, address _spender, uint256 _amount) public returns (bool) {
        require(_spender != address(0), "Spender is 0-address");
        self.allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(TellorStorage.TellorStorageStruct storage self, address _user, address _spender) public view returns (uint256) {
        return self.allowed[_user][_spender];
    }

     
    function doTransfer(TellorStorage.TellorStorageStruct storage self, address _from, address _to, uint256 _amount) public {
        require(_amount > 0, "Tried to send non-positive amount");
        require(_to != address(0), "Receiver is 0 address");
         
        require(allowedToTrade(self, _from, _amount), "Stake amount was not removed from balance");
        uint256 previousBalance = balanceOfAt(self, _from, block.number);
        updateBalanceAtNow(self.balances[_from], previousBalance - _amount);
        previousBalance = balanceOfAt(self, _to, block.number);
        require(previousBalance + _amount >= previousBalance, "Overflow happened");  
        updateBalanceAtNow(self.balances[_to], previousBalance + _amount);
        emit Transfer(_from, _to, _amount);
    }

     
    function balanceOf(TellorStorage.TellorStorageStruct storage self, address _user) public view returns (uint256) {
        return balanceOfAt(self, _user, block.number);
    }

     
    function balanceOfAt(TellorStorage.TellorStorageStruct storage self, address _user, uint256 _blockNumber) public view returns (uint256) {
        if ((self.balances[_user].length == 0) || (self.balances[_user][0].fromBlock > _blockNumber)) {
            return 0;
        } else {
            return getBalanceAt(self.balances[_user], _blockNumber);
        }
    }

     
    function getBalanceAt(TellorStorage.Checkpoint[] storage checkpoints, uint256 _block) public view returns (uint256) {
        if (checkpoints.length == 0) return 0;
        if (_block >= checkpoints[checkpoints.length - 1].fromBlock) return checkpoints[checkpoints.length - 1].value;
        if (_block < checkpoints[0].fromBlock) return 0;
         
        uint256 min = 0;
        uint256 max = checkpoints.length - 1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min].value;
    }

     
    function allowedToTrade(TellorStorage.TellorStorageStruct storage self, address _user, uint256 _amount) public view returns (bool) {
        if (self.stakerDetails[_user].currentStatus > 0) {
             
            if (balanceOf(self, _user).sub(self.uintVars[keccak256("stakeAmount")]).sub(_amount) >= 0) {
                return true;
            }
        } else if (balanceOf(self, _user).sub(_amount) >= 0) {
            return true;
        }
        return false;
    }

     
    function updateBalanceAtNow(TellorStorage.Checkpoint[] storage checkpoints, uint256 _value) public {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            TellorStorage.Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            TellorStorage.Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = uint128(_value);
        }
    }
}


 

 

library TellorDispute {
    using SafeMath for uint256;
    using SafeMath for int256;

     
    event NewDispute(uint256 indexed _disputeId, uint256 indexed _requestId, uint256 _timestamp, address _miner);
     
    event Voted(uint256 indexed _disputeID, bool _position, address indexed _voter);
     
    event DisputeVoteTallied(uint256 indexed _disputeID, int256 _result, address indexed _reportedMiner, address _reportingParty, bool _active);
    event NewTellorAddress(address _newTellor);  

     

     
    function beginDispute(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp, uint256 _minerIndex) public {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
         
        require(now - _timestamp <= 1 days, "The value was mined more than a day ago");
        require(_request.minedBlockNum[_timestamp] > 0, "Mined block is 0");
        require(_minerIndex < 5, "Miner index is wrong");

         
         
        address _miner = _request.minersByValue[_timestamp][_minerIndex];
        bytes32 _hash = keccak256(abi.encodePacked(_miner, _requestId, _timestamp));

         
        require(self.disputeIdByDisputeHash[_hash] == 0, "Dispute is already open");
        TellorTransfer.doTransfer(self, msg.sender, address(this), self.uintVars[keccak256("disputeFee")]);

         
        self.uintVars[keccak256("disputeCount")] = self.uintVars[keccak256("disputeCount")] + 1;

         
        uint256 disputeId = self.uintVars[keccak256("disputeCount")];

         
        self.disputeIdByDisputeHash[_hash] = disputeId;
         
        self.disputesById[disputeId] = TellorStorage.Dispute({
            hash: _hash,
            isPropFork: false,
            reportedMiner: _miner,
            reportingParty: msg.sender,
            proposedForkAddress: address(0),
            executed: false,
            disputeVotePassed: false,
            tally: 0
        });

         
        self.disputesById[disputeId].disputeUintVars[keccak256("requestId")] = _requestId;
        self.disputesById[disputeId].disputeUintVars[keccak256("timestamp")] = _timestamp;
        self.disputesById[disputeId].disputeUintVars[keccak256("value")] = _request.valuesByTimestamp[_timestamp][_minerIndex];
        self.disputesById[disputeId].disputeUintVars[keccak256("minExecutionDate")] = now + 7 days;
        self.disputesById[disputeId].disputeUintVars[keccak256("blockNumber")] = block.number;
        self.disputesById[disputeId].disputeUintVars[keccak256("minerSlot")] = _minerIndex;
        self.disputesById[disputeId].disputeUintVars[keccak256("fee")] = self.uintVars[keccak256("disputeFee")];

         
         
         
        if (_minerIndex == 2) {
            self.requestDetails[_requestId].inDispute[_timestamp] = true;
        }
        self.stakerDetails[_miner].currentStatus = 3;
        emit NewDispute(disputeId, _requestId, _timestamp, _miner);
    }

     
    function vote(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId, bool _supportsDispute) public {
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];

         
        uint256 voteWeight = TellorTransfer.balanceOfAt(self, msg.sender, disp.disputeUintVars[keccak256("blockNumber")]);

         
        require(disp.voted[msg.sender] != true, "Sender has already voted");

         
        require(voteWeight > 0, "User balance is 0");

         
        require(self.stakerDetails[msg.sender].currentStatus != 3, "Miner is under dispute");

         
        disp.voted[msg.sender] = true;

         
        disp.disputeUintVars[keccak256("numberOfVotes")] += 1;

         
        disp.disputeUintVars[keccak256("quorum")] += voteWeight;

         
         
        if (_supportsDispute) {
            disp.tally = disp.tally.add(int256(voteWeight));
        } else {
            disp.tally = disp.tally.sub(int256(voteWeight));
        }

         
        emit Voted(_disputeId, _supportsDispute, msg.sender);
    }

     
    function tallyVotes(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId) public {
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];
        TellorStorage.Request storage _request = self.requestDetails[disp.disputeUintVars[keccak256("requestId")]];

         
        require(disp.executed == false, "Dispute has been already executed");

         
        require(now > disp.disputeUintVars[keccak256("minExecutionDate")], "Time for voting haven't elapsed");

         
        if (disp.isPropFork == false) {
            TellorStorage.StakeInfo storage stakes = self.stakerDetails[disp.reportedMiner];
             
             
            if (disp.tally > 0) {

                 
                if (stakes.currentStatus == 3) {
                     
                     
                    stakes.currentStatus = 0;
                    stakes.startDate = now - (now % 86400);
     
                     
                    self.uintVars[keccak256("stakerCount")]--;
                    updateDisputeFee(self);
     
                     
                    TellorTransfer.doTransfer(self, disp.reportedMiner, disp.reportingParty, self.uintVars[keccak256("stakeAmount")]);
     
                     
                    TellorTransfer.doTransfer(self, address(this), disp.reportingParty, disp.disputeUintVars[keccak256("fee")]);
                    
                 
                } else{
                    TellorTransfer.doTransfer(self, address(this), disp.reportingParty, disp.disputeUintVars[keccak256("fee")]);
                }

                 
                disp.disputeVotePassed = true;


                 
                 
                if (_request.inDispute[disp.disputeUintVars[keccak256("timestamp")]] == true) {
                    _request.finalValues[disp.disputeUintVars[keccak256("timestamp")]] = 0;
                }
                 
                 
            } else {
                 
                stakes.currentStatus = 1;
                 
                TellorTransfer.doTransfer(self, address(this), disp.reportedMiner, disp.disputeUintVars[keccak256("fee")]);
                if (_request.inDispute[disp.disputeUintVars[keccak256("timestamp")]] == true) {
                    _request.inDispute[disp.disputeUintVars[keccak256("timestamp")]] = false;
                }
            }
             
        } else {
            if (disp.tally > 0) {
                require(
                    disp.disputeUintVars[keccak256("quorum")] > ((self.uintVars[keccak256("total_supply")] * 20) / 100),
                    "Quorum is not reached"
                );
                self.addressVars[keccak256("tellorContract")] = disp.proposedForkAddress;
                disp.disputeVotePassed = true;
                emit NewTellorAddress(disp.proposedForkAddress);
            }
        }

         
        disp.executed = true;
        emit DisputeVoteTallied(_disputeId, disp.tally, disp.reportedMiner, disp.reportingParty, disp.disputeVotePassed);
    }

     
    function proposeFork(TellorStorage.TellorStorageStruct storage self, address _propNewTellorAddress) public {
        bytes32 _hash = keccak256(abi.encodePacked(_propNewTellorAddress));
        require(self.disputeIdByDisputeHash[_hash] == 0, "");
        TellorTransfer.doTransfer(self, msg.sender, address(this), self.uintVars[keccak256("disputeFee")]);  
        self.uintVars[keccak256("disputeCount")]++;
        uint256 disputeId = self.uintVars[keccak256("disputeCount")];
        self.disputeIdByDisputeHash[_hash] = disputeId;
        self.disputesById[disputeId] = TellorStorage.Dispute({
            hash: _hash,
            isPropFork: true,
            reportedMiner: msg.sender,
            reportingParty: msg.sender,
            proposedForkAddress: _propNewTellorAddress,
            executed: false,
            disputeVotePassed: false,
            tally: 0
        });
        self.disputesById[disputeId].disputeUintVars[keccak256("blockNumber")] = block.number;
        self.disputesById[disputeId].disputeUintVars[keccak256("fee")] = self.uintVars[keccak256("disputeFee")];
        self.disputesById[disputeId].disputeUintVars[keccak256("minExecutionDate")] = now + 7 days;
    }

     
    function updateDisputeFee(TellorStorage.TellorStorageStruct storage self) public {
         
        if ((self.uintVars[keccak256("stakerCount")] * 1000) / self.uintVars[keccak256("targetMiners")] < 1000) {
             
             
            self.uintVars[keccak256("disputeFee")] = SafeMath.max(
                15e18,
                self.uintVars[keccak256("stakeAmount")].mul(
                    1000 - (self.uintVars[keccak256("stakerCount")] * 1000) / self.uintVars[keccak256("targetMiners")]
                ) /
                    1000
            );
        } else {
             
            self.uintVars[keccak256("disputeFee")] = 15e18;
        }
    }
}


 

library TellorStake {
    event NewStake(address indexed _sender);  
    event StakeWithdrawn(address indexed _sender);  
    event StakeWithdrawRequested(address indexed _sender);  

     

     
    function init(TellorStorage.TellorStorageStruct storage self) public {
        require(self.uintVars[keccak256("decimals")] == 0, "Too many decimals");
         
        TellorTransfer.updateBalanceAtNow(self.balances[address(this)], 2**256 - 1 - 6000e18);

         
         
        address payable[6] memory _initalMiners = [
            address(0xE037EC8EC9ec423826750853899394dE7F024fee),
            address(0xcdd8FA31AF8475574B8909F135d510579a8087d3),
            address(0xb9dD5AfD86547Df817DA2d0Fb89334A6F8eDd891),
            address(0x230570cD052f40E14C14a81038c6f3aa685d712B),
            address(0x3233afA02644CCd048587F8ba6e99b3C00A34DcC),
            address(0xe010aC6e0248790e08F42d5F697160DEDf97E024)
        ];
         
        for (uint256 i = 0; i < 6; i++) {
             
             
            TellorTransfer.updateBalanceAtNow(self.balances[_initalMiners[i]], 1000e18);

            newStake(self, _initalMiners[i]);
        }

         
        self.uintVars[keccak256("total_supply")] += 6000e18;  
         
        self.uintVars[keccak256("decimals")] = 18;
        self.uintVars[keccak256("targetMiners")] = 200;
        self.uintVars[keccak256("stakeAmount")] = 1000e18;
        self.uintVars[keccak256("disputeFee")] = 970e18;
        self.uintVars[keccak256("timeTarget")] = 600;
        self.uintVars[keccak256("timeOfLastNewValue")] = now - (now % self.uintVars[keccak256("timeTarget")]);
        self.uintVars[keccak256("difficulty")] = 1;
    }

     
    function requestStakingWithdraw(TellorStorage.TellorStorageStruct storage self) public {
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];
         
        require(stakes.currentStatus == 1, "Miner is not staked");

         
        stakes.currentStatus = 2;

         
         
        stakes.startDate = now - (now % 86400);

         
        self.uintVars[keccak256("stakerCount")] -= 1;
        TellorDispute.updateDisputeFee(self);
        emit StakeWithdrawRequested(msg.sender);
    }

     
    function withdrawStake(TellorStorage.TellorStorageStruct storage self) public {
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];
         
         
        require(now - (now % 86400) - stakes.startDate >= 7 days, "7 days didn't pass");
        require(stakes.currentStatus == 2, "Miner was not locked for withdrawal");
        stakes.currentStatus = 0;
        emit StakeWithdrawn(msg.sender);
    }

     
    function depositStake(TellorStorage.TellorStorageStruct storage self) public {
        newStake(self, msg.sender);
         
        TellorDispute.updateDisputeFee(self);
    }

     
    function newStake(TellorStorage.TellorStorageStruct storage self, address staker) internal {
        require(TellorTransfer.balanceOf(self, staker) >= self.uintVars[keccak256("stakeAmount")], "Balance is lower than stake amount");
         
         
        require(self.stakerDetails[staker].currentStatus == 0 || self.stakerDetails[staker].currentStatus == 2, "Miner is in the wrong state");
        self.uintVars[keccak256("stakerCount")] += 1;
        self.stakerDetails[staker] = TellorStorage.StakeInfo({
            currentStatus: 1,  
            startDate: now - (now % 86400)
        });
        emit NewStake(staker);
    }
}


 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256 c) {
        if (b > 0) {
            c = a + b;
            assert(c >= a);
        } else {
            c = a + b;
            assert(c <= a);
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (uint256) {
        return a > b ? uint256(a) : uint256(b);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        if (b > 0) {
            c = a - b;
            assert(c <= a);
        } else {
            c = a - b;
            assert(c >= a);
        }

    }
}



 

library TellorStorage {
     
    struct Details {
        uint256 value;
        address miner;
    }

    struct Dispute {
        bytes32 hash;  
        int256 tally;  
        bool executed;  
        bool disputeVotePassed;  
        bool isPropFork;  
        address reportedMiner;  
        address reportingParty;  
        address proposedForkAddress;  
        mapping(bytes32 => uint256) disputeUintVars;
         
         
         
         
         
         
         
         
         
         
         
         
        mapping(address => bool) voted;  
    }

    struct StakeInfo {
        uint256 currentStatus;  
        uint256 startDate;  
    }

     
    struct Checkpoint {
        uint128 fromBlock;  
        uint128 value;  
    }

    struct Request {
        string queryString;  
        string dataSymbol;  
        bytes32 queryHash;  
        uint256[] requestTimestamps;  
        mapping(bytes32 => uint256) apiUintVars;
         
         
         
         
         
         
        mapping(uint256 => uint256) minedBlockNum;  
         
        mapping(uint256 => uint256) finalValues;
        mapping(uint256 => bool) inDispute;  
        mapping(uint256 => address[5]) minersByValue;
        mapping(uint256 => uint256[5]) valuesByTimestamp;
    }

    struct TellorStorageStruct {
        bytes32 currentChallenge;  
        uint256[51] requestQ;  
        uint256[] newValueTimestamps;  
        Details[5] currentMiners;  
        mapping(bytes32 => address) addressVars;
         
         
         
         
         
         
        mapping(bytes32 => uint256) uintVars;
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
        mapping(bytes32 => mapping(address => bool)) minersByChallenge;
        mapping(uint256 => uint256) requestIdByTimestamp;  
        mapping(uint256 => uint256) requestIdByRequestQIndex;  
        mapping(uint256 => Dispute) disputesById;  
        mapping(address => Checkpoint[]) balances;  
        mapping(address => mapping(address => uint256)) allowed;  
        mapping(address => StakeInfo) stakerDetails;  
        mapping(uint256 => Request) requestDetails;  
        mapping(bytes32 => uint256) requestIdByQueryHash;  
        mapping(bytes32 => uint256) disputeIdByDisputeHash;  
    }
}



 
 

library Utilities {
     
    function getMax(uint256[51] memory data) internal pure returns (uint256 max, uint256 maxIndex) {
        max = data[1];
        maxIndex;
        for (uint256 i = 1; i < data.length; i++) {
            if (data[i] > max) {
                max = data[i];
                maxIndex = i;
            }
        }
    }

     
    function getMin(uint256[51] memory data) internal pure returns (uint256 min, uint256 minIndex) {
        minIndex = data.length - 1;
        min = data[minIndex];
        for (uint256 i = data.length - 1; i > 0; i--) {
            if (data[i] < min) {
                min = data[i];
                minIndex = i;
            }
        }
    }

}


 
library TellorGettersLibrary {
    using SafeMath for uint256;

    event NewTellorAddress(address _newTellor);  

     

     
     
     
    function changeDeity(TellorStorage.TellorStorageStruct storage self, address _newDeity) internal {
        require(self.addressVars[keccak256("_deity")] == msg.sender, "Sender is not deity");
        self.addressVars[keccak256("_deity")] = _newDeity;
    }

     
     
    function changeTellorContract(TellorStorage.TellorStorageStruct storage self, address _tellorContract) internal {
        require(self.addressVars[keccak256("_deity")] == msg.sender, "Sender is not deity");
        self.addressVars[keccak256("tellorContract")] = _tellorContract;
        emit NewTellorAddress(_tellorContract);
    }

     

     
    function didMine(TellorStorage.TellorStorageStruct storage self, bytes32 _challenge, address _miner) internal view returns (bool) {
        return self.minersByChallenge[_challenge][_miner];
    }

     
    function didVote(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId, address _address) internal view returns (bool) {
        return self.disputesById[_disputeId].voted[_address];
    }

     
    function getAddressVars(TellorStorage.TellorStorageStruct storage self, bytes32 _data) internal view returns (address) {
        return self.addressVars[_data];
    }

     
    function getAllDisputeVars(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId)
        internal
        view
        returns (bytes32, bool, bool, bool, address, address, address, uint256[9] memory, int256)
    {
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];
        return (
            disp.hash,
            disp.executed,
            disp.disputeVotePassed,
            disp.isPropFork,
            disp.reportedMiner,
            disp.reportingParty,
            disp.proposedForkAddress,
            [
                disp.disputeUintVars[keccak256("requestId")],
                disp.disputeUintVars[keccak256("timestamp")],
                disp.disputeUintVars[keccak256("value")],
                disp.disputeUintVars[keccak256("minExecutionDate")],
                disp.disputeUintVars[keccak256("numberOfVotes")],
                disp.disputeUintVars[keccak256("blockNumber")],
                disp.disputeUintVars[keccak256("minerSlot")],
                disp.disputeUintVars[keccak256("quorum")],
                disp.disputeUintVars[keccak256("fee")]
            ],
            disp.tally
        );
    }

     
    function getCurrentVariables(TellorStorage.TellorStorageStruct storage self)
        internal
        view
        returns (bytes32, uint256, uint256, string memory, uint256, uint256)
    {
        return (
            self.currentChallenge,
            self.uintVars[keccak256("currentRequestId")],
            self.uintVars[keccak256("difficulty")],
            self.requestDetails[self.uintVars[keccak256("currentRequestId")]].queryString,
            self.requestDetails[self.uintVars[keccak256("currentRequestId")]].apiUintVars[keccak256("granularity")],
            self.requestDetails[self.uintVars[keccak256("currentRequestId")]].apiUintVars[keccak256("totalTip")]
        );
    }

     
    function getDisputeIdByDisputeHash(TellorStorage.TellorStorageStruct storage self, bytes32 _hash) internal view returns (uint256) {
        return self.disputeIdByDisputeHash[_hash];
    }

     
    function getDisputeUintVars(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId, bytes32 _data)
        internal
        view
        returns (uint256)
    {
        return self.disputesById[_disputeId].disputeUintVars[_data];
    }

     
    function getLastNewValue(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256, bool) {
        return (
            retrieveData(
                self,
                self.requestIdByTimestamp[self.uintVars[keccak256("timeOfLastNewValue")]],
                self.uintVars[keccak256("timeOfLastNewValue")]
            ),
            true
        );
    }

     
    function getLastNewValueById(TellorStorage.TellorStorageStruct storage self, uint256 _requestId) internal view returns (uint256, bool) {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        if (_request.requestTimestamps.length > 0) {
            return (retrieveData(self, _requestId, _request.requestTimestamps[_request.requestTimestamps.length - 1]), true);
        } else {
            return (0, false);
        }
    }

     
    function getMinedBlockNum(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp)
        internal
        view
        returns (uint256)
    {
        return self.requestDetails[_requestId].minedBlockNum[_timestamp];
    }

     
    function getMinersByRequestIdAndTimestamp(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp)
        internal
        view
        returns (address[5] memory)
    {
        return self.requestDetails[_requestId].minersByValue[_timestamp];
    }

     
    function getName(TellorStorage.TellorStorageStruct storage self) internal pure returns (string memory) {
        return "Tellor Tributes";
    }

     
    function getNewValueCountbyRequestId(TellorStorage.TellorStorageStruct storage self, uint256 _requestId) internal view returns (uint256) {
        return self.requestDetails[_requestId].requestTimestamps.length;
    }

     
    function getRequestIdByRequestQIndex(TellorStorage.TellorStorageStruct storage self, uint256 _index) internal view returns (uint256) {
        require(_index <= 50, "RequestQ index is above 50");
        return self.requestIdByRequestQIndex[_index];
    }

     
    function getRequestIdByTimestamp(TellorStorage.TellorStorageStruct storage self, uint256 _timestamp) internal view returns (uint256) {
        return self.requestIdByTimestamp[_timestamp];
    }

     
    function getRequestIdByQueryHash(TellorStorage.TellorStorageStruct storage self, bytes32 _queryHash) internal view returns (uint256) {
        return self.requestIdByQueryHash[_queryHash];
    }

     
    function getRequestQ(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256[51] memory) {
        return self.requestQ;
    }

     
    function getRequestUintVars(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, bytes32 _data)
        internal
        view
        returns (uint256)
    {
        return self.requestDetails[_requestId].apiUintVars[_data];
    }

     
    function getRequestVars(TellorStorage.TellorStorageStruct storage self, uint256 _requestId)
        internal
        view
        returns (string memory, string memory, bytes32, uint256, uint256, uint256)
    {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        return (
            _request.queryString,
            _request.dataSymbol,
            _request.queryHash,
            _request.apiUintVars[keccak256("granularity")],
            _request.apiUintVars[keccak256("requestQPosition")],
            _request.apiUintVars[keccak256("totalTip")]
        );
    }

     
    function getStakerInfo(TellorStorage.TellorStorageStruct storage self, address _staker) internal view returns (uint256, uint256) {
        return (self.stakerDetails[_staker].currentStatus, self.stakerDetails[_staker].startDate);
    }

     
    function getSubmissionsByTimestamp(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp)
        internal
        view
        returns (uint256[5] memory)
    {
        return self.requestDetails[_requestId].valuesByTimestamp[_timestamp];
    }

     
    function getSymbol(TellorStorage.TellorStorageStruct storage self) internal pure returns (string memory) {
        return "TT";
    }

     
    function getTimestampbyRequestIDandIndex(TellorStorage.TellorStorageStruct storage self, uint256 _requestID, uint256 _index)
        internal
        view
        returns (uint256)
    {
        return self.requestDetails[_requestID].requestTimestamps[_index];
    }

     
    function getUintVar(TellorStorage.TellorStorageStruct storage self, bytes32 _data) internal view returns (uint256) {
        return self.uintVars[_data];
    }

     
    function getVariablesOnDeck(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256, uint256, string memory) {
        uint256 newRequestId = getTopRequestID(self);
        return (
            newRequestId,
            self.requestDetails[newRequestId].apiUintVars[keccak256("totalTip")],
            self.requestDetails[newRequestId].queryString
        );
    }

     
    function getTopRequestID(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256 _requestId) {
        uint256 _max;
        uint256 _index;
        (_max, _index) = Utilities.getMax(self.requestQ);
        _requestId = self.requestIdByRequestQIndex[_index];
    }

     
    function isInDispute(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp) internal view returns (bool) {
        return self.requestDetails[_requestId].inDispute[_timestamp];
    }

     
    function retrieveData(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp)
        internal
        view
        returns (uint256)
    {
        return self.requestDetails[_requestId].finalValues[_timestamp];
    }

     
    function totalSupply(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256) {
        return self.uintVars[keccak256("total_supply")];
    }

}


 
library TellorLibrary {
    using SafeMath for uint256;

    event TipAdded(address indexed _sender, uint256 indexed _requestId, uint256 _tip, uint256 _totalTips);
     
    event DataRequested(
        address indexed _sender,
        string _query,
        string _querySymbol,
        uint256 _granularity,
        uint256 indexed _requestId,
        uint256 _totalTips
    );
     
    event NewChallenge(
        bytes32 _currentChallenge,
        uint256 indexed _currentRequestId,
        uint256 _difficulty,
        uint256 _multiplier,
        string _query,
        uint256 _totalTips
    );
     
    event NewRequestOnDeck(uint256 indexed _requestId, string _query, bytes32 _onDeckQueryHash, uint256 _onDeckTotalTips);
     
    event NewValue(uint256 indexed _requestId, uint256 _time, uint256 _value, uint256 _totalTips, bytes32 _currentChallenge);
     
    event NonceSubmitted(address indexed _miner, string _nonce, uint256 indexed _requestId, uint256 _value, bytes32 _currentChallenge);
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event OwnershipProposed(address indexed _previousOwner, address indexed _newOwner);

     

     
 

     
    function addTip(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _tip) public {
        require(_requestId > 0, "RequestId is 0");

         
        if (_tip > 0) {
            TellorTransfer.doTransfer(self, msg.sender, address(this), _tip);
        }

         
        updateOnDeck(self, _requestId, _tip);
        emit TipAdded(msg.sender, _requestId, _tip, self.requestDetails[_requestId].apiUintVars[keccak256("totalTip")]);
    }

     
    function requestData(
        TellorStorage.TellorStorageStruct storage self,
        string memory _c_sapi,
        string memory _c_symbol,
        uint256 _granularity,
        uint256 _tip
    ) public {
         
        require(_granularity > 0, "Too few decimal places");

         
        require(_granularity <= 1e18, "Too many decimal places");

         
        string memory _sapi = _c_sapi;
        string memory _symbol = _c_symbol;
        require(bytes(_sapi).length > 0, "API string length is 0");
        require(bytes(_symbol).length < 64, "API string symbol is greater than 64");
        bytes32 _queryHash = keccak256(abi.encodePacked(_sapi, _granularity));

         
         
        if (self.requestIdByQueryHash[_queryHash] == 0) {
            self.uintVars[keccak256("requestCount")]++;
            uint256 _requestId = self.uintVars[keccak256("requestCount")];
            self.requestDetails[_requestId] = TellorStorage.Request({
                queryString: _sapi,
                dataSymbol: _symbol,
                queryHash: _queryHash,
                requestTimestamps: new uint256[](0)
            });
            self.requestDetails[_requestId].apiUintVars[keccak256("granularity")] = _granularity;
            self.requestDetails[_requestId].apiUintVars[keccak256("requestQPosition")] = 0;
            self.requestDetails[_requestId].apiUintVars[keccak256("totalTip")] = 0;
            self.requestIdByQueryHash[_queryHash] = _requestId;

             
            if (_tip > 0) {
                TellorTransfer.doTransfer(self, msg.sender, address(this), _tip);
            }
            updateOnDeck(self, _requestId, _tip);
            emit DataRequested(
                msg.sender,
                self.requestDetails[_requestId].queryString,
                self.requestDetails[_requestId].dataSymbol,
                _granularity,
                _requestId,
                _tip
            );
             
        } else {
            addTip(self, self.requestIdByQueryHash[_queryHash], _tip);
        }
    }

     
    function newBlock(TellorStorage.TellorStorageStruct storage self, string memory _nonce, uint256 _requestId) internal {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];

         
         
         
        int256 _change = int256(SafeMath.min(1200, (now - self.uintVars[keccak256("timeOfLastNewValue")])));
        _change = (int256(self.uintVars[keccak256("difficulty")]) * (int256(self.uintVars[keccak256("timeTarget")]) - _change)) / 4000;

        if (_change < 2 && _change > -2) {
            if (_change >= 0) {
                _change = 1;
            } else {
                _change = -1;
            }
        }

        if ((int256(self.uintVars[keccak256("difficulty")]) + _change) <= 0) {
            self.uintVars[keccak256("difficulty")] = 1;
        } else {
            self.uintVars[keccak256("difficulty")] = uint256(int256(self.uintVars[keccak256("difficulty")]) + _change);
        }

         
        uint256 _timeOfLastNewValue = now - (now % 1 minutes);
        self.uintVars[keccak256("timeOfLastNewValue")] = _timeOfLastNewValue;

         
        TellorStorage.Details[5] memory a = self.currentMiners;
        uint256 i;
        for (i = 1; i < 5; i++) {
            uint256 temp = a[i].value;
            address temp2 = a[i].miner;
            uint256 j = i;
            while (j > 0 && temp < a[j - 1].value) {
                a[j].value = a[j - 1].value;
                a[j].miner = a[j - 1].miner;
                j--;
            }
            if (j < i) {
                a[j].value = temp;
                a[j].miner = temp2;
            }
        }

         
        for (i = 0; i < 5; i++) {
            TellorTransfer.doTransfer(self, address(this), a[i].miner, 5e18 + self.uintVars[keccak256("currentTotalTips")] / 5);
        }
        emit NewValue(
            _requestId,
            _timeOfLastNewValue,
            a[2].value,
            self.uintVars[keccak256("currentTotalTips")] - (self.uintVars[keccak256("currentTotalTips")] % 5),
            self.currentChallenge
        );

         
        self.uintVars[keccak256("total_supply")] += 275e17;

         
        TellorTransfer.doTransfer(self, address(this), self.addressVars[keccak256("_owner")], 25e17);  
         
        _request.finalValues[_timeOfLastNewValue] = a[2].value;
        _request.requestTimestamps.push(_timeOfLastNewValue);
         
        _request.minersByValue[_timeOfLastNewValue] = [a[0].miner, a[1].miner, a[2].miner, a[3].miner, a[4].miner];
        _request.valuesByTimestamp[_timeOfLastNewValue] = [a[0].value, a[1].value, a[2].value, a[3].value, a[4].value];
        _request.minedBlockNum[_timeOfLastNewValue] = block.number;
         

        self.requestIdByTimestamp[_timeOfLastNewValue] = _requestId;
         
        self.newValueTimestamps.push(_timeOfLastNewValue);
         
        self.uintVars[keccak256("slotProgress")] = 0;
        uint256 _topId = TellorGettersLibrary.getTopRequestID(self);
        self.uintVars[keccak256("currentRequestId")] = _topId;
         
         
        if (_topId > 0) {
             
            self.uintVars[keccak256("currentTotalTips")] = self.requestDetails[_topId].apiUintVars[keccak256("totalTip")];
             
            self.requestQ[self.requestDetails[_topId].apiUintVars[keccak256("requestQPosition")]] = 0;

             
            self.requestIdByRequestQIndex[self.requestDetails[_topId].apiUintVars[keccak256("requestQPosition")]] = 0;

             
            self.requestDetails[_topId].apiUintVars[keccak256("requestQPosition")] = 0;

             
             
            self.requestDetails[_topId].apiUintVars[keccak256("totalTip")] = 0;

             
            uint256 newRequestId = TellorGettersLibrary.getTopRequestID(self);
             
            self.currentChallenge = keccak256(abi.encodePacked(_nonce, self.currentChallenge, blockhash(block.number - 1)));  
            emit NewChallenge(
                self.currentChallenge,
                _topId,
                self.uintVars[keccak256("difficulty")],
                self.requestDetails[_topId].apiUintVars[keccak256("granularity")],
                self.requestDetails[_topId].queryString,
                self.uintVars[keccak256("currentTotalTips")]
            );
            emit NewRequestOnDeck(
                newRequestId,
                self.requestDetails[newRequestId].queryString,
                self.requestDetails[newRequestId].queryHash,
                self.requestDetails[newRequestId].apiUintVars[keccak256("totalTip")]
            );
        } else {
            self.uintVars[keccak256("currentTotalTips")] = 0;
            self.currentChallenge = "";
        }
    }

     
    function submitMiningSolution(TellorStorage.TellorStorageStruct storage self, string memory _nonce, uint256 _requestId, uint256 _value)
        public
    {
         
        require(self.stakerDetails[msg.sender].currentStatus == 1, "Miner status is not staker");

         
        require(_requestId == self.uintVars[keccak256("currentRequestId")], "RequestId is wrong");

         
        require(
            uint256(
                sha256(abi.encodePacked(ripemd160(abi.encodePacked(keccak256(abi.encodePacked(self.currentChallenge, msg.sender, _nonce))))))
            ) %
                self.uintVars[keccak256("difficulty")] ==
                0,
            "Challenge information is not saved"
        );

         
        require(self.minersByChallenge[self.currentChallenge][msg.sender] == false, "Miner already submitted the value");

         
        self.currentMiners[self.uintVars[keccak256("slotProgress")]].value = _value;
        self.currentMiners[self.uintVars[keccak256("slotProgress")]].miner = msg.sender;

         
        self.uintVars[keccak256("slotProgress")]++;

         
        self.minersByChallenge[self.currentChallenge][msg.sender] = true;

        emit NonceSubmitted(msg.sender, _nonce, _requestId, _value, self.currentChallenge);

         
        if (self.uintVars[keccak256("slotProgress")] == 5) {
            newBlock(self, _nonce, _requestId);
        }
    }

     
    function proposeOwnership(TellorStorage.TellorStorageStruct storage self, address payable _pendingOwner) internal {
        require(msg.sender == self.addressVars[keccak256("_owner")], "Sender is not owner");
        emit OwnershipProposed(self.addressVars[keccak256("_owner")], _pendingOwner);
        self.addressVars[keccak256("pending_owner")] = _pendingOwner;
    }

     
    function claimOwnership(TellorStorage.TellorStorageStruct storage self) internal {
        require(msg.sender == self.addressVars[keccak256("pending_owner")], "Sender is not pending owner");
        emit OwnershipTransferred(self.addressVars[keccak256("_owner")], self.addressVars[keccak256("pending_owner")]);
        self.addressVars[keccak256("_owner")] = self.addressVars[keccak256("pending_owner")];
    }

     
    function updateOnDeck(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _tip) internal {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        uint256 onDeckRequestId = TellorGettersLibrary.getTopRequestID(self);
         
        if (_tip > 0) {
            _request.apiUintVars[keccak256("totalTip")] = _request.apiUintVars[keccak256("totalTip")].add(_tip);
        }
         
        uint256 _payout = _request.apiUintVars[keccak256("totalTip")];

         
         
         
        if (self.uintVars[keccak256("currentRequestId")] == 0) {
            _request.apiUintVars[keccak256("totalTip")] = 0;
            self.uintVars[keccak256("currentRequestId")] = _requestId;
            self.uintVars[keccak256("currentTotalTips")] = _payout;
            self.currentChallenge = keccak256(abi.encodePacked(_payout, self.currentChallenge, blockhash(block.number - 1)));  
            emit NewChallenge(
                self.currentChallenge,
                self.uintVars[keccak256("currentRequestId")],
                self.uintVars[keccak256("difficulty")],
                self.requestDetails[self.uintVars[keccak256("currentRequestId")]].apiUintVars[keccak256("granularity")],
                self.requestDetails[self.uintVars[keccak256("currentRequestId")]].queryString,
                self.uintVars[keccak256("currentTotalTips")]
            );
        } else {
             
             
             
            if (_payout > self.requestDetails[onDeckRequestId].apiUintVars[keccak256("totalTip")] || (onDeckRequestId == 0)) {
                 
                emit NewRequestOnDeck(_requestId, _request.queryString, _request.queryHash, _payout);
            }

             
             
            if (_request.apiUintVars[keccak256("requestQPosition")] == 0) {
                uint256 _min;
                uint256 _index;
                (_min, _index) = Utilities.getMin(self.requestQ);
                 
                 
                 
                if (_payout > _min || _min == 0) {
                    self.requestQ[_index] = _payout;
                    self.requestDetails[self.requestIdByRequestQIndex[_index]].apiUintVars[keccak256("requestQPosition")] = 0;
                    self.requestIdByRequestQIndex[_index] = _requestId;
                    _request.apiUintVars[keccak256("requestQPosition")] = _index;
                }
                 
            } else if (_tip > 0) {
                self.requestQ[_request.apiUintVars[keccak256("requestQPosition")]] += _tip;
            }
        }
    }
}


 
contract Tellor {
    using SafeMath for uint256;

    using TellorDispute for TellorStorage.TellorStorageStruct;
    using TellorLibrary for TellorStorage.TellorStorageStruct;
    using TellorStake for TellorStorage.TellorStorageStruct;
    using TellorTransfer for TellorStorage.TellorStorageStruct;

    TellorStorage.TellorStorageStruct tellor;

     

     
 

     
    function beginDispute(uint256 _requestId, uint256 _timestamp, uint256 _minerIndex) external {
        tellor.beginDispute(_requestId, _timestamp, _minerIndex);
    }

     
    function vote(uint256 _disputeId, bool _supportsDispute) external {
        tellor.vote(_disputeId, _supportsDispute);
    }

     
    function tallyVotes(uint256 _disputeId) external {
        tellor.tallyVotes(_disputeId);
    }

     
    function proposeFork(address _propNewTellorAddress) external {
        tellor.proposeFork(_propNewTellorAddress);
    }

     
    function addTip(uint256 _requestId, uint256 _tip) external {
        tellor.addTip(_requestId, _tip);
    }

     
    function requestData(string calldata _c_sapi, string calldata _c_symbol, uint256 _granularity, uint256 _tip) external {
        tellor.requestData(_c_sapi, _c_symbol, _granularity, _tip);
    }

     
    function submitMiningSolution(string calldata _nonce, uint256 _requestId, uint256 _value) external {
        tellor.submitMiningSolution(_nonce, _requestId, _value);
    }

     
    function proposeOwnership(address payable _pendingOwner) external {
        tellor.proposeOwnership(_pendingOwner);
    }

     
    function claimOwnership() external {
        tellor.claimOwnership();
    }

     
    function depositStake() external {
        tellor.depositStake();
    }

     
    function requestStakingWithdraw() external {
        tellor.requestStakingWithdraw();
    }

     
    function withdrawStake() external {
        tellor.withdrawStake();
    }

     
    function approve(address _spender, uint256 _amount) external returns (bool) {
        return tellor.approve(_spender, _amount);
    }

     
    function transfer(address _to, uint256 _amount) external returns (bool) {
        return tellor.transfer(_to, _amount);
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool) {
        return tellor.transferFrom(_from, _to, _amount);
    }

     
    function name() external pure returns (string memory) {
        return "Tellor Tributes";
    }

     
    function symbol() external pure returns (string memory) {
        return "TRB";
    }

     
    function decimals() external pure returns (uint8) {
        return 18;
    }

}


pragma solidity ^0.5.0;

 

contract OracleIDDescriptions {

     
    mapping(uint=>bytes32) tellorIDtoBytesID;
    mapping(bytes32 => uint) bytesIDtoTellorID;
    mapping(uint => int) tellorCodeToStatusCode;
    mapping(int => uint) statusCodeToTellorCode;
    address public owner;

     
    event TellorIdMappedToBytes(uint _requestID, bytes32 _id);
    event StatusMapped(uint _tellorStatus, int _status);
    

     
    constructor() public{
        owner =msg.sender;
    }

     
    function transferOwnership(address payable newOwner) external {
        require(msg.sender == owner, "Sender is not owner");
        owner = newOwner;
    }

     
    function defineTellorCodeToStatusCode(uint _tellorStatus, int _status) external{
        require(msg.sender == owner, "Sender is not owner");
        tellorCodeToStatusCode[_tellorStatus] = _status;
        statusCodeToTellorCode[_status] = _tellorStatus;
        emit StatusMapped(_tellorStatus, _status);
    }

      
    function defineTellorIdToBytesID(uint _requestID, bytes32 _id) external{
        require(msg.sender == owner, "Sender is not owner");
        tellorIDtoBytesID[_requestID] = _id;
        bytesIDtoTellorID[_id] = _requestID;
        emit TellorIdMappedToBytes(_requestID,_id);
    }

      
    function getTellorStatusFromStatus(int _status) public view returns(uint _tellorStatus){
        return statusCodeToTellorCode[_status];
    }

      
    function getStatusFromTellorStatus (uint _tellorStatus) public view returns(int _status) {
        return tellorCodeToStatusCode[_tellorStatus];
    }
    
      
    function getTellorIdFromBytes(bytes32 _id) public view  returns(uint _requestId)  {
       return bytesIDtoTellorID[_id];
    }

      
    function getBytesFromTellorID(uint _requestId) public view returns(bytes32 _id) {
        return tellorIDtoBytesID[_requestId];
    }

}


 

interface ADOInterface {
        function resultFor(bytes32 Id) view external returns (uint256 timestamp, int256 outcome, int256 status);
}


 
contract UserContract is ADOInterface{
     
    uint256 public tributePrice;
    address payable public owner;
    address payable public tellorStorageAddress;
    address public oracleIDDescriptionsAddress;
    Tellor _tellor;
    TellorMaster _tellorm;
    OracleIDDescriptions descriptions;

    event OwnershipTransferred(address _previousOwner, address _newOwner);
    event NewPriceSet(uint256 _newPrice);
    event NewDescriptorSet(address _descriptorSet);

     
     
    constructor(address payable _storage) public {
        tellorStorageAddress = _storage;
        _tellor = Tellor(tellorStorageAddress);  
        _tellorm = TellorMaster(tellorStorageAddress);
        owner = msg.sender;
    }

     
     
    function setOracleIDDescriptors(address _oracleDescriptors) external {
        require(msg.sender == owner, "Sender is not owner");
        oracleIDDescriptionsAddress = _oracleDescriptors;
        descriptions = OracleIDDescriptions(_oracleDescriptors);
        emit NewDescriptorSet(_oracleDescriptors);
    }

     
    function transferOwnership(address payable newOwner) external {
        require(msg.sender == owner, "Sender is not owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

     
    function withdrawEther() external {
        require(msg.sender == owner, "Sender is not owner");
        owner.transfer(address(this).balance);
    }

     
    function withdrawTokens() external {
        require(msg.sender == owner, "Sender is not owner");
        _tellor.transfer(owner, _tellorm.balanceOf(address(this)));
    }

     
    function requestDataWithEther(string calldata c_sapi, string calldata _c_symbol, uint256 _granularity) external payable {
        uint _amount = (msg.value / tributePrice)*1e18;
        require(_tellorm.balanceOf(address(this)) >= _amount, "Balance is lower than tip amount");
        _tellor.requestData(c_sapi, _c_symbol, _granularity, _amount);
    }

     
    function addTipWithEther(uint256 _apiId) external payable {
        uint _amount = (msg.value / tributePrice)*1e18;
        require(_tellorm.balanceOf(address(this)) >= _amount, "Balance is lower than tip amount");
        _tellor.addTip(_apiId, _amount);
    }

     
    function setPrice(uint256 _price) public {
        require(msg.sender == owner, "Sender is not owner");
        tributePrice = _price;
        emit NewPriceSet(_price);
    }

     
    function getCurrentValue(uint256 _requestId) public view returns (bool ifRetrieve, uint256 value, uint256 _timestampRetrieved) {
        uint256 _count = _tellorm.getNewValueCountbyRequestId(_requestId);
        if (_count > 0) {
            _timestampRetrieved = _tellorm.getTimestampbyRequestIDandIndex(_requestId, _count - 1);  
            return (true, _tellorm.retrieveData(_requestId, _timestampRetrieved), _timestampRetrieved);
        }
        return (false, 0, 0);
    }

     
    function resultFor(bytes32 _bytesId) view external returns (uint256 timestamp, int outcome, int status) {
        uint _id = descriptions.getTellorIdFromBytes(_bytesId);
        if (_id > 0){
            bool _didGet;
            uint256 _returnedValue;
            uint256 _timestampRetrieved;
            (_didGet,_returnedValue,_timestampRetrieved) = getCurrentValue(_id);
            if(_didGet){
                return (_timestampRetrieved, int(_returnedValue),descriptions.getStatusFromTellorStatus(1));
            }
            else{
                return (0,0,descriptions.getStatusFromTellorStatus(2));
            }
        }
        return (0, 0, descriptions.getStatusFromTellorStatus(0));
    }
     
    function getFirstVerifiedDataAfter(uint256 _requestId, uint256 _timestamp) public view returns (bool, uint256, uint256 _timestampRetrieved) {
        uint256 _count = _tellorm.getNewValueCountbyRequestId(_requestId);
        if (_count > 0) {
            for (uint256 i = _count; i > 0; i--) {
                if (
                    _tellorm.getTimestampbyRequestIDandIndex(_requestId, i - 1) > _timestamp &&
                    _tellorm.getTimestampbyRequestIDandIndex(_requestId, i - 1) < block.timestamp - 86400
                ) {
                    _timestampRetrieved = _tellorm.getTimestampbyRequestIDandIndex(_requestId, i - 1);  
                }
            }
            if (_timestampRetrieved > 0) {
                return (true, _tellorm.retrieveData(_requestId, _timestampRetrieved), _timestampRetrieved);
            }
        }
        return (false, 0, 0);
    }

     
    function getAnyDataAfter(uint256 _requestId, uint256 _timestamp)
        public
        view
        returns (bool _ifRetrieve, uint256 _value, uint256 _timestampRetrieved)
    {
        uint256 _count = _tellorm.getNewValueCountbyRequestId(_requestId);
        if (_count > 0) {
            for (uint256 i = _count; i > 0; i--) {
                if (_tellorm.getTimestampbyRequestIDandIndex(_requestId, i - 1) >= _timestamp) {
                    _timestampRetrieved = _tellorm.getTimestampbyRequestIDandIndex(_requestId, i - 1);  
                }
            }
            if (_timestampRetrieved > 0) {
                return (true, _tellorm.retrieveData(_requestId, _timestampRetrieved), _timestampRetrieved);
            }
        }
        return (false, 0, 0);
    }

}