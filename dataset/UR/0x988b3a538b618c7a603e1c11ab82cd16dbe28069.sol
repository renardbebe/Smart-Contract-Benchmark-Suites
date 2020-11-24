 

 
 
 
pragma solidity ^0.4.25;



 
library SortitionSumTreeFactory {
     

    struct SortitionSumTree {
        uint K;  
         
        uint[] stack;
        uint[] nodes;
         
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIDs;
    }

     

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

     

     
    function createTree(SortitionSumTrees storage self, bytes32 _key, uint _K) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(tree.K == 0, "Tree already exists.");
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.stack.length = 0;
        tree.nodes.length = 0;
        tree.nodes.push(0);
    }

     
    function set(SortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) {  
            if (_value != 0) {  
                 
                 
                if (tree.stack.length == 0) {  
                     
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                     
                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) {  
                        uint parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else {  
                     
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.length--;
                    tree.nodes[treeIndex] = _value;
                }

                 
                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else {  
            if (_value == 0) {  
                 
                 
                uint value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                 
                tree.stack.push(treeIndex);

                 
                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) {  
                 
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

     

     
    function queryLeafs(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint _cursor,
        uint _count
    ) public view returns(uint startIndex, uint[] values, bool hasMore) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

         
        for (uint i = 0; i < tree.nodes.length; i++) {
            if ((tree.K * i) + 1 >= tree.nodes.length) {
                startIndex = i;
                break;
            }
        }

         
        uint loopStartIndex = startIndex + _cursor;
        values = new uint[](loopStartIndex + _count > tree.nodes.length ? tree.nodes.length - loopStartIndex : _count);
        uint valuesIndex = 0;
        for (uint j = loopStartIndex; j < tree.nodes.length; j++) {
            if (valuesIndex < _count) {
                values[valuesIndex] = tree.nodes[j];
                valuesIndex++;
            } else {
                hasMore = true;
                break;
            }
        }
    }

     
    function draw(SortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) public view returns(bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while ((tree.K * treeIndex) + 1 < tree.nodes.length)   
            for (uint i = 1; i <= tree.K; i++) {  
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue;  
                else {  
                    treeIndex = nodeIndex;
                    break;
                }
            }
        
        ID = tree.nodeIndexesToIDs[treeIndex];
    }

     
    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) public view returns(uint value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

     

     
    function updateParents(SortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}


contract RNG{

     
    function contribute(uint _block) public payable;

     
    function requestRN(uint _block) public payable {
        contribute(_block);
    }

     
    function getRN(uint _block) public returns (uint RN);

     
    function getUncorrelatedRN(uint _block) public returns (uint RN) {
        uint baseRN = getRN(_block);
        if (baseRN == 0)
        return 0;
        else
        return uint(keccak256(msg.sender,baseRN));
    }

}


 
contract Arbitrator {

    enum DisputeStatus {Waiting, Appealable, Solved}

    modifier requireArbitrationFee(bytes _extraData) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");
        _;
    }
    modifier requireAppealFee(uint _disputeID, bytes _extraData) {
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");
        _;
    }

     
    event DisputeCreation(uint indexed _disputeID, Arbitrable indexed _arbitrable);

     
    event AppealPossible(uint indexed _disputeID, Arbitrable indexed _arbitrable);

     
    event AppealDecision(uint indexed _disputeID, Arbitrable indexed _arbitrable);

     
    function createDispute(uint _choices, bytes _extraData) public requireArbitrationFee(_extraData) payable returns(uint disputeID) {}

     
    function arbitrationCost(bytes _extraData) public view returns(uint fee);

     
    function appeal(uint _disputeID, bytes _extraData) public requireAppealFee(_disputeID,_extraData) payable {
        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }

     
    function appealCost(uint _disputeID, bytes _extraData) public view returns(uint fee);

     
    function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {}

     
    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status);

     
    function currentRuling(uint _disputeID) public view returns(uint ruling);
}



 


 
interface IArbitrable {
     
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

     
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID, uint _evidenceGroupID);

     
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _evidenceGroupID, address indexed _party, string _evidence);

     
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

     
    function rule(uint _disputeID, uint _ruling) public;
}



 
contract Arbitrable is IArbitrable {
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData;  

    modifier onlyArbitrator {require(msg.sender == address(arbitrator), "Can only be called by the arbitrator."); _;}

     
    constructor(Arbitrator _arbitrator, bytes _arbitratorExtraData) public {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

     
    function rule(uint _disputeID, uint _ruling) public onlyArbitrator {
        emit Ruling(Arbitrator(msg.sender),_disputeID,_ruling);

        executeRuling(_disputeID,_ruling);
    }


     
    function executeRuling(uint _disputeID, uint _ruling) internal;
}


 

 
 
 
 
 
 
 


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

 
 
 
contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.2';  


     
     
     
    struct  Checkpoint {

         
        uint128 fromBlock;

         
        uint128 value;
    }

     
     
    MiniMeToken public parentToken;

     
     
    uint public parentSnapShotBlock;

     
    uint public creationBlock;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;

     
    bool public transfersEnabled;

     
    MiniMeTokenFactory public tokenFactory;

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        doTransfer(_from, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal {

           if (_amount == 0) {
               Transfer(_from, _to, _amount);     
               return;
           }

           require(parentSnapShotBlock < block.number);

            
           require((_to != 0) && (_to != address(this)));

            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);

           require(previousBalanceFrom >= _amount);

            
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

    }

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

         
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
     
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

         
         
         
         
         
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                 
                return 0;
            }

         
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

         
         
         
         
         
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

         
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.changeController(msg.sender);

         
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount
    ) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

     
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

 
 
 
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


 
 
 

 
 
 
contract MiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

 
contract KlerosLiquid is TokenController, Arbitrator {
     

     
    enum Phase {
      staking,  
      generating,  
      drawing  
    }

     
    enum Period {
      evidence,  
      commit,  
      vote,  
      appeal,  
      execution  
    }

     

     
    struct Court {
        uint96 parent;  
        uint[] children;  
        bool hiddenVotes;  
        uint minStake;  
        uint alpha;  
        uint feeForJuror;  
         
        uint jurorsForCourtJump;
        uint[4] timesPerPeriod;  
    }
    struct DelayedSetStake {
        address account;  
        uint96 subcourtID;  
        uint128 stake;  
    }

     
    struct Vote {
        address account;  
        bytes32 commit;  
        uint choice;  
        bool voted;  
    }
    struct VoteCounter {
         
        uint winningChoice;
        mapping(uint => uint) counts;  
        bool tied;  
    }
    struct Dispute {  
        uint96 subcourtID;  
        Arbitrable arbitrated;  
         
        uint numberOfChoices;
        Period period;  
        uint lastPeriodChange;  
         
        Vote[][] votes;
        VoteCounter[] voteCounters;  
        uint[] tokensAtStakePerJuror;  
        uint[] totalFeesForJurors;  
        uint drawsInRound;  
        uint commitsInRound;  
        uint[] votesInEachRound;  
         
        uint[] repartitionsInEachRound;
        uint[] penaltiesInEachRound;  
        bool ruled;  
    }

     
    struct Juror {
         
        uint96[] subcourtIDs;
        uint stakedTokens;  
        uint lockedTokens;  
    }

     

     
    event NewPhase(Phase _phase);

     
    event NewPeriod(uint indexed _disputeID, Period _period);

     
    event StakeSet(address indexed _address, uint _subcourtID, uint128 _stake, uint _newTotalStake);

     
    event Draw(address indexed _address, uint indexed _disputeID, uint _appeal, uint _voteID);

     
    event TokenAndETHShift(address indexed _address, uint indexed _disputeID, int _tokenAmount, int _ETHAmount);

     

     
    uint public constant MAX_STAKE_PATHS = 4;  
    uint public constant MIN_JURORS = 3;  
    uint public constant NON_PAYABLE_AMOUNT = (2 ** 256 - 2) / 2;  
    uint public constant ALPHA_DIVISOR = 1e4;  
     
    address public governor;  
    MiniMeToken public pinakion;  
    RNG public RNGenerator;  
     
    Phase public phase;  
    uint public lastPhaseChange;  
    uint public disputesWithoutJurors;  
     
    uint public RNBlock;
    uint public RN;  
    uint public minStakingTime;  
    uint public maxDrawingTime;  
     
    bool public lockInsolventTransfers = true;
     
    Court[] public courts;  
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;  
    SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;  
     
    mapping(uint => DelayedSetStake) public delayedSetStakes;
     
    uint public nextDelayedSetStake = 1;
    uint public lastDelayedSetStake;  

     
    Dispute[] public disputes;  

     
    mapping(address => Juror) public jurors;  

     

     
    modifier onlyDuringPhase(Phase _phase) {require(phase == _phase); _;}

     
    modifier onlyDuringPeriod(uint _disputeID, Period _period) {require(disputes[_disputeID].period == _period); _;}

     
    modifier onlyByGovernor() {require(governor == msg.sender); _;}

     

     
    constructor(
        address _governor,
        MiniMeToken _pinakion,
        RNG _RNGenerator,
        uint _minStakingTime,
        uint _maxDrawingTime,
        bool _hiddenVotes,
        uint _minStake,
        uint _alpha,
        uint _feeForJuror,
        uint _jurorsForCourtJump,
        uint[4] _timesPerPeriod,
        uint _sortitionSumTreeK
    ) public {
         
        governor = _governor;
        pinakion = _pinakion;
        RNGenerator = _RNGenerator;
        minStakingTime = _minStakingTime;
        maxDrawingTime = _maxDrawingTime;
        lastPhaseChange = now;

         
        courts.push(Court({
            parent: 0,
            children: new uint[](0),
            hiddenVotes: _hiddenVotes,
            minStake: _minStake,
            alpha: _alpha,
            feeForJuror: _feeForJuror,
            jurorsForCourtJump: _jurorsForCourtJump,
            timesPerPeriod: _timesPerPeriod
        }));
        sortitionSumTrees.createTree(bytes32(0), _sortitionSumTreeK);
    }

     

     
    function executeGovernorProposal(address _destination, uint _amount, bytes _data) external onlyByGovernor {
        require(_destination.call.value(_amount)(_data));  
    }

     
    function changeGovernor(address _governor) external onlyByGovernor {
        governor = _governor;
    }

     
    function changePinakion(MiniMeToken _pinakion) external onlyByGovernor {
        pinakion = _pinakion;
    }

     
    function changeRNGenerator(RNG _RNGenerator) external onlyByGovernor {
        RNGenerator = _RNGenerator;
        if (phase == Phase.generating) {
            RNBlock = block.number + 1;
            RNGenerator.requestRN(RNBlock);
        }
    }

     
    function changeMinStakingTime(uint _minStakingTime) external onlyByGovernor {
        minStakingTime = _minStakingTime;
    }

     
    function changeMaxDrawingTime(uint _maxDrawingTime) external onlyByGovernor {
        maxDrawingTime = _maxDrawingTime;
    }

     
    function createSubcourt(
        uint96 _parent,
        bool _hiddenVotes,
        uint _minStake,
        uint _alpha,
        uint _feeForJuror,
        uint _jurorsForCourtJump,
        uint[4] _timesPerPeriod,
        uint _sortitionSumTreeK
    ) external onlyByGovernor {
        require(courts[_parent].minStake <= _minStake, "A subcourt cannot be a child of a subcourt with a higher minimum stake.");

         
        uint96 subcourtID = uint96(
            courts.push(Court({
                parent: _parent,
                children: new uint[](0),
                hiddenVotes: _hiddenVotes,
                minStake: _minStake,
                alpha: _alpha,
                feeForJuror: _feeForJuror,
                jurorsForCourtJump: _jurorsForCourtJump,
                timesPerPeriod: _timesPerPeriod
            })) - 1
        );
        sortitionSumTrees.createTree(bytes32(subcourtID), _sortitionSumTreeK);

         
        courts[_parent].children.push(subcourtID);
    }

     
    function changeSubcourtMinStake(uint96 _subcourtID, uint _minStake) external onlyByGovernor {
        require(_subcourtID == 0 || courts[courts[_subcourtID].parent].minStake <= _minStake);
        for (uint i = 0; i < courts[_subcourtID].children.length; i++) {
            require(
                courts[courts[_subcourtID].children[i]].minStake >= _minStake,
                "A subcourt cannot be the parent of a subcourt with a lower minimum stake."
            );
        }

        courts[_subcourtID].minStake = _minStake;
    }

     
    function changeSubcourtAlpha(uint96 _subcourtID, uint _alpha) external onlyByGovernor {
        courts[_subcourtID].alpha = _alpha;
    }

     
    function changeSubcourtJurorFee(uint96 _subcourtID, uint _feeForJuror) external onlyByGovernor {
        courts[_subcourtID].feeForJuror = _feeForJuror;
    }

     
    function changeSubcourtJurorsForJump(uint96 _subcourtID, uint _jurorsForCourtJump) external onlyByGovernor {
        courts[_subcourtID].jurorsForCourtJump = _jurorsForCourtJump;
    }

     
    function changeSubcourtTimesPerPeriod(uint96 _subcourtID, uint[4] _timesPerPeriod) external onlyByGovernor {
        courts[_subcourtID].timesPerPeriod = _timesPerPeriod;
    }

     
    function passPhase() external {
        if (phase == Phase.staking) {
            require(now - lastPhaseChange >= minStakingTime, "The minimum staking time has not passed yet.");
            require(disputesWithoutJurors > 0, "There are no disputes that need jurors.");
            RNBlock = block.number + 1;
            RNGenerator.requestRN(RNBlock);
            phase = Phase.generating;
        } else if (phase == Phase.generating) {
            RN = RNGenerator.getUncorrelatedRN(RNBlock);
            require(RN != 0, "Random number is not ready yet.");
            phase = Phase.drawing;
        } else if (phase == Phase.drawing) {
            require(disputesWithoutJurors == 0 || now - lastPhaseChange >= maxDrawingTime, "There are still disputes without jurors and the maximum drawing time has not passed yet.");
            phase = Phase.staking;
        }

        lastPhaseChange = now;
        emit NewPhase(phase);
    }

     
    function passPeriod(uint _disputeID) external {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.period == Period.evidence) {
            require(
                dispute.votes.length > 1 || now - dispute.lastPeriodChange >= courts[dispute.subcourtID].timesPerPeriod[uint(dispute.period)],
                "The evidence period time has not passed yet and it is not an appeal."
            );
            require(dispute.drawsInRound == dispute.votes[dispute.votes.length - 1].length, "The dispute has not finished drawing yet.");
            dispute.period = courts[dispute.subcourtID].hiddenVotes ? Period.commit : Period.vote;
        } else if (dispute.period == Period.commit) {
            require(
                now - dispute.lastPeriodChange >= courts[dispute.subcourtID].timesPerPeriod[uint(dispute.period)] || dispute.commitsInRound == dispute.votes[dispute.votes.length - 1].length,
                "The commit period time has not passed yet and not every juror has committed yet."
            );
            dispute.period = Period.vote;
        } else if (dispute.period == Period.vote) {
            require(
                now - dispute.lastPeriodChange >= courts[dispute.subcourtID].timesPerPeriod[uint(dispute.period)] || dispute.votesInEachRound[dispute.votes.length - 1] == dispute.votes[dispute.votes.length - 1].length,
                "The vote period time has not passed yet and not every juror has voted yet."
            );
            dispute.period = Period.appeal;
            emit AppealPossible(_disputeID, dispute.arbitrated);
        } else if (dispute.period == Period.appeal) {
            require(now - dispute.lastPeriodChange >= courts[dispute.subcourtID].timesPerPeriod[uint(dispute.period)], "The appeal period time has not passed yet.");
            dispute.period = Period.execution;
        } else if (dispute.period == Period.execution) {
            revert("The dispute is already in the last period.");
        }

        dispute.lastPeriodChange = now;
        emit NewPeriod(_disputeID, dispute.period);
    }

     
    function setStake(uint96 _subcourtID, uint128 _stake) external {
        require(_setStake(msg.sender, _subcourtID, _stake));
    }

     
    function executeDelayedSetStakes(uint _iterations) external onlyDuringPhase(Phase.staking) {
        uint actualIterations = (nextDelayedSetStake + _iterations) - 1 > lastDelayedSetStake ?
            (lastDelayedSetStake - nextDelayedSetStake) + 1 : _iterations;
        uint newNextDelayedSetStake = nextDelayedSetStake + actualIterations;
        require(newNextDelayedSetStake >= nextDelayedSetStake);
        for (uint i = nextDelayedSetStake; i < newNextDelayedSetStake; i++) {
            DelayedSetStake storage delayedSetStake = delayedSetStakes[i];
            _setStake(delayedSetStake.account, delayedSetStake.subcourtID, delayedSetStake.stake);
            delete delayedSetStakes[i];
        }
        nextDelayedSetStake = newNextDelayedSetStake;
    }

     
    function drawJurors(
        uint _disputeID,
        uint _iterations
    ) external onlyDuringPhase(Phase.drawing) onlyDuringPeriod(_disputeID, Period.evidence) {
        Dispute storage dispute = disputes[_disputeID];
        uint endIndex = dispute.drawsInRound + _iterations;
        require(endIndex >= dispute.drawsInRound);

         
        if (endIndex > dispute.votes[dispute.votes.length - 1].length) endIndex = dispute.votes[dispute.votes.length - 1].length;
        for (uint i = dispute.drawsInRound; i < endIndex; i++) {
             
            (
                address drawnAddress,
                uint subcourtID
            ) = stakePathIDToAccountAndSubcourtID(sortitionSumTrees.draw(bytes32(dispute.subcourtID), uint(keccak256(RN, _disputeID, i))));

             
            dispute.votes[dispute.votes.length - 1][i].account = drawnAddress;
            jurors[drawnAddress].lockedTokens += dispute.tokensAtStakePerJuror[dispute.tokensAtStakePerJuror.length - 1];
            emit Draw(drawnAddress, _disputeID, dispute.votes.length - 1, i);

             
            if (i == dispute.votes[dispute.votes.length - 1].length - 1) disputesWithoutJurors--;
        }
        dispute.drawsInRound = endIndex;
    }

     
    function castCommit(uint _disputeID, uint[] _voteIDs, bytes32 _commit) external onlyDuringPeriod(_disputeID, Period.commit) {
        Dispute storage dispute = disputes[_disputeID];
        require(_commit != bytes32(0));
        for (uint i = 0; i < _voteIDs.length; i++) {
            require(dispute.votes[dispute.votes.length - 1][_voteIDs[i]].account == msg.sender, "The caller has to own the vote.");
            require(dispute.votes[dispute.votes.length - 1][_voteIDs[i]].commit == bytes32(0), "Already committed this vote.");
            dispute.votes[dispute.votes.length - 1][_voteIDs[i]].commit = _commit;
        }
        dispute.commitsInRound += _voteIDs.length;
    }

     
    function castVote(uint _disputeID, uint[] _voteIDs, uint _choice, uint _salt) external onlyDuringPeriod(_disputeID, Period.vote) {
        Dispute storage dispute = disputes[_disputeID];
        require(_voteIDs.length > 0);
        require(_choice <= dispute.numberOfChoices, "The choice has to be less than or equal to the number of choices for the dispute.");

         
        for (uint i = 0; i < _voteIDs.length; i++) {
            require(dispute.votes[dispute.votes.length - 1][_voteIDs[i]].account == msg.sender, "The caller has to own the vote.");
            require(
                !courts[dispute.subcourtID].hiddenVotes || dispute.votes[dispute.votes.length - 1][_voteIDs[i]].commit == keccak256(_choice, _salt),
                "The commit must match the choice in subcourts with hidden votes."
            );
            require(!dispute.votes[dispute.votes.length - 1][_voteIDs[i]].voted, "Vote already cast.");
            dispute.votes[dispute.votes.length - 1][_voteIDs[i]].choice = _choice;
            dispute.votes[dispute.votes.length - 1][_voteIDs[i]].voted = true;
        }
        dispute.votesInEachRound[dispute.votes.length - 1] += _voteIDs.length;

         
        VoteCounter storage voteCounter = dispute.voteCounters[dispute.voteCounters.length - 1];
        voteCounter.counts[_choice] += _voteIDs.length;
        if (_choice == voteCounter.winningChoice) {  
            if (voteCounter.tied) voteCounter.tied = false;  
        } else {  
            if (voteCounter.counts[_choice] == voteCounter.counts[voteCounter.winningChoice]) {  
                if (!voteCounter.tied) voteCounter.tied = true;
            } else if (voteCounter.counts[_choice] > voteCounter.counts[voteCounter.winningChoice]) {  
                voteCounter.winningChoice = _choice;
                voteCounter.tied = false;
            }
        }
    }

     
    function computeTokenAndETHRewards(uint _disputeID, uint _appeal) private view returns(uint tokenReward, uint ETHReward) {
        Dispute storage dispute = disputes[_disputeID];

         
        if (dispute.voteCounters[dispute.voteCounters.length - 1].tied) {
             
            uint activeCount = dispute.votesInEachRound[_appeal];
            if (activeCount > 0) {
                tokenReward = dispute.penaltiesInEachRound[_appeal] / activeCount;
                ETHReward = dispute.totalFeesForJurors[_appeal] / activeCount;
            } else {
                tokenReward = 0;
                ETHReward = 0;
            }
        } else {
             
            uint winningChoice = dispute.voteCounters[dispute.voteCounters.length - 1].winningChoice;
            uint coherentCount = dispute.voteCounters[_appeal].counts[winningChoice];
            tokenReward = dispute.penaltiesInEachRound[_appeal] / coherentCount;
            ETHReward = dispute.totalFeesForJurors[_appeal] / coherentCount;
        }
    }

     
    function execute(uint _disputeID, uint _appeal, uint _iterations) external onlyDuringPeriod(_disputeID, Period.execution) {
        lockInsolventTransfers = false;
        Dispute storage dispute = disputes[_disputeID];
        uint end = dispute.repartitionsInEachRound[_appeal] + _iterations;
        require(end >= dispute.repartitionsInEachRound[_appeal]);
        uint penaltiesInRoundCache = dispute.penaltiesInEachRound[_appeal];  
        (uint tokenReward, uint ETHReward) = (0, 0);

         
        if (
            !dispute.voteCounters[dispute.voteCounters.length - 1].tied &&
            dispute.voteCounters[_appeal].counts[dispute.voteCounters[dispute.voteCounters.length - 1].winningChoice] == 0
        ) {
             
            if (end > dispute.votes[_appeal].length) end = dispute.votes[_appeal].length;
        } else {
             
            (tokenReward, ETHReward) = dispute.repartitionsInEachRound[_appeal] >= dispute.votes[_appeal].length ? computeTokenAndETHRewards(_disputeID, _appeal) : (0, 0);  
            if (end > dispute.votes[_appeal].length * 2) end = dispute.votes[_appeal].length * 2;
        }
        for (uint i = dispute.repartitionsInEachRound[_appeal]; i < end; i++) {
            Vote storage vote = dispute.votes[_appeal][i % dispute.votes[_appeal].length];
            if (
                vote.voted &&
                (vote.choice == dispute.voteCounters[dispute.voteCounters.length - 1].winningChoice || dispute.voteCounters[dispute.voteCounters.length - 1].tied)
            ) {  
                if (i >= dispute.votes[_appeal].length) {  

                     
                    pinakion.transfer(vote.account, tokenReward);
                     
                    vote.account.send(ETHReward);  
                    emit TokenAndETHShift(vote.account, _disputeID, int(tokenReward), int(ETHReward));
                    jurors[vote.account].lockedTokens -= dispute.tokensAtStakePerJuror[_appeal];
                }
            } else {  
                if (i < dispute.votes[_appeal].length) {  

                     
                    uint penalty = dispute.tokensAtStakePerJuror[_appeal] > pinakion.balanceOf(vote.account) ? pinakion.balanceOf(vote.account) : dispute.tokensAtStakePerJuror[_appeal];
                    pinakion.transferFrom(vote.account, this, penalty);
                    emit TokenAndETHShift(vote.account, _disputeID, -int(penalty), 0);
                    penaltiesInRoundCache += penalty;
                    jurors[vote.account].lockedTokens -= dispute.tokensAtStakePerJuror[_appeal];

                     
                    if (pinakion.balanceOf(vote.account) < jurors[vote.account].stakedTokens || !vote.voted)
                        for (uint j = 0; j < jurors[vote.account].subcourtIDs.length; j++)
                            _setStake(vote.account, jurors[vote.account].subcourtIDs[j], 0);

                }
            }
            if (i == dispute.votes[_appeal].length - 1) {
                 
                if (dispute.votesInEachRound[_appeal] == 0 || !dispute.voteCounters[dispute.voteCounters.length - 1].tied && dispute.voteCounters[_appeal].counts[dispute.voteCounters[dispute.voteCounters.length - 1].winningChoice] == 0) {
                     
                    governor.send(dispute.totalFeesForJurors[_appeal]);  
                    pinakion.transfer(governor, penaltiesInRoundCache);
                } else if (i + 1 < end) {
                     
                    dispute.penaltiesInEachRound[_appeal] = penaltiesInRoundCache;
                    (tokenReward, ETHReward) = computeTokenAndETHRewards(_disputeID, _appeal);
                }
            }
        }
        if (dispute.penaltiesInEachRound[_appeal] != penaltiesInRoundCache) dispute.penaltiesInEachRound[_appeal] = penaltiesInRoundCache;
        dispute.repartitionsInEachRound[_appeal] = end;
        lockInsolventTransfers = true;
    }

     
    function executeRuling(uint _disputeID) external onlyDuringPeriod(_disputeID, Period.execution) {
        Dispute storage dispute = disputes[_disputeID];
        require(!dispute.ruled, "Ruling already executed.");
        dispute.ruled = true;
        uint winningChoice = dispute.voteCounters[dispute.voteCounters.length - 1].tied ? 0
            : dispute.voteCounters[dispute.voteCounters.length - 1].winningChoice;
        dispute.arbitrated.rule(_disputeID, winningChoice);
    }

     

     
    function createDispute(
        uint _numberOfChoices,
        bytes _extraData
    ) public payable requireArbitrationFee(_extraData) returns(uint disputeID)  {
        (uint96 subcourtID, uint minJurors) = extraDataToSubcourtIDAndMinJurors(_extraData);
        disputeID = disputes.length++;
        Dispute storage dispute = disputes[disputeID];
        dispute.subcourtID = subcourtID;
        dispute.arbitrated = Arbitrable(msg.sender);
        dispute.numberOfChoices = _numberOfChoices;
        dispute.period = Period.evidence;
        dispute.lastPeriodChange = now;
         
        dispute.votes[dispute.votes.length++].length = msg.value / courts[dispute.subcourtID].feeForJuror;
        dispute.voteCounters[dispute.voteCounters.length++].tied = true;
        dispute.tokensAtStakePerJuror.push((courts[dispute.subcourtID].minStake * courts[dispute.subcourtID].alpha) / ALPHA_DIVISOR);
        dispute.totalFeesForJurors.push(msg.value);
        dispute.votesInEachRound.push(0);
        dispute.repartitionsInEachRound.push(0);
        dispute.penaltiesInEachRound.push(0);
        disputesWithoutJurors++;

        emit DisputeCreation(disputeID, Arbitrable(msg.sender));
    }

     
    function appeal(
        uint _disputeID,
        bytes _extraData
    ) public payable requireAppealFee(_disputeID, _extraData) onlyDuringPeriod(_disputeID, Period.appeal) {
        Dispute storage dispute = disputes[_disputeID];
        require(
            msg.sender == address(dispute.arbitrated),
            "Can only be called by the arbitrable contract."
        );
        if (dispute.votes[dispute.votes.length - 1].length >= courts[dispute.subcourtID].jurorsForCourtJump)  
            dispute.subcourtID = courts[dispute.subcourtID].parent;
        dispute.period = Period.evidence;
        dispute.lastPeriodChange = now;
         
        dispute.votes[dispute.votes.length++].length = msg.value / courts[dispute.subcourtID].feeForJuror;
        dispute.voteCounters[dispute.voteCounters.length++].tied = true;
        dispute.tokensAtStakePerJuror.push((courts[dispute.subcourtID].minStake * courts[dispute.subcourtID].alpha) / ALPHA_DIVISOR);
        dispute.totalFeesForJurors.push(msg.value);
        dispute.drawsInRound = 0;
        dispute.commitsInRound = 0;
        dispute.votesInEachRound.push(0);
        dispute.repartitionsInEachRound.push(0);
        dispute.penaltiesInEachRound.push(0);
        disputesWithoutJurors++;

        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }

     
    function proxyPayment(address _owner) public payable returns(bool allowed) { allowed = false; }

     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool allowed) {
        if (lockInsolventTransfers) {  
            uint newBalance = pinakion.balanceOf(_from) - _amount;
            if (newBalance < jurors[_from].stakedTokens || newBalance < jurors[_from].lockedTokens) return false;
        }
        allowed = true;
    }

     
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool allowed) { allowed = true; }

     

     
    function arbitrationCost(bytes _extraData) public view returns(uint cost) {
        (uint96 subcourtID, uint minJurors) = extraDataToSubcourtIDAndMinJurors(_extraData);
        cost = courts[subcourtID].feeForJuror * minJurors;
    }

     
    function appealCost(uint _disputeID, bytes _extraData) public view returns(uint cost) {
        Dispute storage dispute = disputes[_disputeID];
        uint lastNumberOfJurors = dispute.votes[dispute.votes.length - 1].length;
        if (lastNumberOfJurors >= courts[dispute.subcourtID].jurorsForCourtJump) {  
            if (dispute.subcourtID == 0)  
                cost = NON_PAYABLE_AMOUNT;
            else  
                cost = courts[courts[dispute.subcourtID].parent].feeForJuror * ((lastNumberOfJurors * 2) + 1);
        } else  
            cost = courts[dispute.subcourtID].feeForJuror * ((lastNumberOfJurors * 2) + 1);
    }

     
    function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.period == Period.appeal) {
            start = dispute.lastPeriodChange;
            end = dispute.lastPeriodChange + courts[dispute.subcourtID].timesPerPeriod[uint(Period.appeal)];
        } else {
            start = 0;
            end = 0;
        }
    }

     
    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status) {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.period < Period.appeal) status = DisputeStatus.Waiting;
        else if (dispute.period < Period.execution) status = DisputeStatus.Appealable;
        else status = DisputeStatus.Solved;
    }

     
    function currentRuling(uint _disputeID) public view returns(uint ruling) {
        Dispute storage dispute = disputes[_disputeID];
        ruling = dispute.voteCounters[dispute.voteCounters.length - 1].tied ? 0
            : dispute.voteCounters[dispute.voteCounters.length - 1].winningChoice;
    }

     

     
    function _setStake(address _account, uint96 _subcourtID, uint128 _stake) internal returns(bool succeeded) {
        if (!(_subcourtID < courts.length))
            return false;

         
        if (phase != Phase.staking) {
            delayedSetStakes[++lastDelayedSetStake] = DelayedSetStake({ account: _account, subcourtID: _subcourtID, stake: _stake });
            return true;
        }

        if (!(_stake == 0 || courts[_subcourtID].minStake <= _stake))
            return false;  
        Juror storage juror = jurors[_account];
        bytes32 stakePathID = accountAndSubcourtIDToStakePathID(_account, _subcourtID);
        uint currentStake = sortitionSumTrees.stakeOf(bytes32(_subcourtID), stakePathID);
        if (!(_stake == 0 || currentStake > 0 || juror.subcourtIDs.length < MAX_STAKE_PATHS))
            return false;  
        uint newTotalStake = juror.stakedTokens - currentStake + _stake;  
        if (!(_stake == 0 || pinakion.balanceOf(_account) >= newTotalStake))
            return false;  

         
        juror.stakedTokens = newTotalStake;
        if (_stake == 0) {
            for (uint i = 0; i < juror.subcourtIDs.length; i++)
                if (juror.subcourtIDs[i] == _subcourtID) {
                    juror.subcourtIDs[i] = juror.subcourtIDs[juror.subcourtIDs.length - 1];
                    juror.subcourtIDs.length--;
                    break;
                }
        } else if (currentStake == 0) juror.subcourtIDs.push(_subcourtID);

         
        bool finished = false;
        uint currentSubcourtID = _subcourtID;
        while (!finished) {
            sortitionSumTrees.set(bytes32(currentSubcourtID), _stake, stakePathID);
            if (currentSubcourtID == 0) finished = true;
            else currentSubcourtID = courts[currentSubcourtID].parent;
        }
        emit StakeSet(_account, _subcourtID, _stake, newTotalStake);
        return true;
    }

     
    function extraDataToSubcourtIDAndMinJurors(bytes _extraData) internal view returns (uint96 subcourtID, uint minJurors) {
        if (_extraData.length >= 64) {
            assembly {  
                subcourtID := mload(add(_extraData, 0x20))
                minJurors := mload(add(_extraData, 0x40))
            }
            if (subcourtID >= courts.length) subcourtID = 0;
            if (minJurors == 0) minJurors = MIN_JURORS;
        } else {
            subcourtID = 0;
            minJurors = MIN_JURORS;
        }
    }

     
    function accountAndSubcourtIDToStakePathID(address _account, uint96 _subcourtID) internal pure returns (bytes32 stakePathID) {
        assembly {  
            let ptr := mload(0x40)
            for { let i := 0x00 } lt(i, 0x14) { i := add(i, 0x01) } {
                mstore8(add(ptr, i), byte(add(0x0c, i), _account))
            }
            for { let i := 0x14 } lt(i, 0x20) { i := add(i, 0x01) } {
                mstore8(add(ptr, i), byte(i, _subcourtID))
            }
            stakePathID := mload(ptr)
        }
    }

     
    function stakePathIDToAccountAndSubcourtID(bytes32 _stakePathID) internal pure returns (address account, uint96 subcourtID) {
        assembly {  
            let ptr := mload(0x40)
            for { let i := 0x00 } lt(i, 0x14) { i := add(i, 0x01) } {
                mstore8(add(add(ptr, 0x0c), i), byte(i, _stakePathID))
            }
            account := mload(ptr)
            subcourtID := _stakePathID
        }
    }
    
     

     
    function getSubcourt(uint96 _subcourtID) external view returns(
        uint[] children,
        uint[4] timesPerPeriod
    ) {
        Court storage subcourt = courts[_subcourtID];
        children = subcourt.children;
        timesPerPeriod = subcourt.timesPerPeriod;
    }

     
    function getVote(uint _disputeID, uint _appeal, uint _voteID) external view returns(
        address account,
        bytes32 commit,
        uint choice,
        bool voted
    ) {
        Vote storage vote = disputes[_disputeID].votes[_appeal][_voteID];
        account = vote.account;
        commit = vote.commit;
        choice = vote.choice;
        voted = vote.voted;
    }

     
    function getVoteCounter(uint _disputeID, uint _appeal) external view returns(
        uint winningChoice,
        uint[] counts,
        bool tied
    ) {
        Dispute storage dispute = disputes[_disputeID];
        VoteCounter storage voteCounter = dispute.voteCounters[_appeal];
        winningChoice = voteCounter.winningChoice;
        counts = new uint[](dispute.numberOfChoices + 1);
        for (uint i = 0; i <= dispute.numberOfChoices; i++) counts[i] = voteCounter.counts[i];
        tied = voteCounter.tied;
    }

     
    function getDispute(uint _disputeID) external view returns(
        uint[] votesLengths,
        uint[] tokensAtStakePerJuror,
        uint[] totalFeesForJurors,
        uint[] votesInEachRound,
        uint[] repartitionsInEachRound,
        uint[] penaltiesInEachRound
    ) {
        Dispute storage dispute = disputes[_disputeID];
        votesLengths = new uint[](dispute.votes.length);
        for (uint i = 0; i < dispute.votes.length; i++) votesLengths[i] = dispute.votes[i].length;
        tokensAtStakePerJuror = dispute.tokensAtStakePerJuror;
        totalFeesForJurors = dispute.totalFeesForJurors;
        votesInEachRound = dispute.votesInEachRound;
        repartitionsInEachRound = dispute.repartitionsInEachRound;
        penaltiesInEachRound = dispute.penaltiesInEachRound;
    }

     
    function getJuror(address _account) external view returns(
        uint96[] subcourtIDs
    ) {
        Juror storage juror = jurors[_account];
        subcourtIDs = juror.subcourtIDs;
    }

     
    function stakeOf(address _account, uint96 _subcourtID) external view returns(uint stake) {
        return sortitionSumTrees.stakeOf(bytes32(_subcourtID), accountAndSubcourtIDToStakePathID(_account, _subcourtID));
    }
}