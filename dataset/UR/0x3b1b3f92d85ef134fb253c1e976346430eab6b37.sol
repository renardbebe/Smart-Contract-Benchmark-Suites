 

pragma solidity 0.4.25;

library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns(uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns(uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0);
        return a % b;
    }
}

interface ICaelumMiner {
    function getMiningReward() external returns (uint) ;
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract InterfaceContracts is Ownable {
    InterfaceContracts public _internalMod;
    
    function setModifierContract (address _t) onlyOwner public {
        _internalMod = InterfaceContracts(_t);
    }

    modifier onlyMiningContract() {
      require(msg.sender == _internalMod._contract_miner(), "Wrong sender");
          _;
      }

    modifier onlyTokenContract() {
      require(msg.sender == _internalMod._contract_token(), "Wrong sender");
      _;
    }
    
    modifier onlyMasternodeContract() {
      require(msg.sender == _internalMod._contract_masternode(), "Wrong sender");
      _;
    }
    
    modifier onlyVotingOrOwner() {
      require(msg.sender == _internalMod._contract_voting() || msg.sender == owner, "Wrong sender");
      _;
    }
    
    modifier onlyVotingContract() {
      require(msg.sender == _internalMod._contract_voting() || msg.sender == owner, "Wrong sender");
      _;
    }
      
    function _contract_voting () public view returns (address) {
        return _internalMod._contract_voting();
    }
    
    function _contract_masternode () public view returns (address) {
        return _internalMod._contract_masternode();
    }
    
    function _contract_token () public view returns (address) {
        return _internalMod._contract_token();
    }
    
    function _contract_miner () public view returns (address) {
        return _internalMod._contract_miner();
    }
}

contract CaelumAbstractMasternode is Ownable {

    struct MasterNode {
        address accountOwner;
        bool isActive;
        bool isTeamMember;
        uint storedIndex;
        uint startingRound;
        uint nodeCount;
        uint[] indexcounter;

    }

    mapping(address => MasterNode) public userByAddress;
    mapping(uint => MasterNode) public masternodeByIndex;

    uint public userCounter = 0;
    uint public masternodeIDcounter = 0;
    uint public masternodeRound = 0;
    uint public masternodeCandidate;

    uint public MINING_PHASE_DURATION_BLOCKS = 4500;

    uint public miningEpoch;
    uint public rewardsProofOfWork;
    uint public rewardsMasternode;

    bool genesisAdded = false;

    event NewMasternode(address candidateAddress, uint timeStamp);
    event RemovedMasternode(address candidateAddress, uint timeStamp);


    address [] public genesisList = [
      0xdb93CE3cCA2444CE5DA5522a85758af79Af0092D,
      0x375E97e59dE97BE46D332Ba17185620B81bdB7cc,
      0x14dB686439Aad3C076B793335BC14D9039F32C54,
      0x1Ba4b0280163889e7Ee4ab5269C442971F48d13e,
      0xE4Ac657af0690E9437f36D3E96886DC880b24404,
      0x08Fcf0027E1e91a12981fBc6371dE39A269C3a47,
      0x3d664B7B0Eb158798f3E797e194FEe50dD748742,
      0xB85aC167079020d93033a014efEaD75f14018522,
      0xc6d00915CbcF9ABE9B27403F8d2338551f4ac43b,
      0x5256fE3F8e50E0f7f701525e814A2767da2cca06,
      0x2cf23c6610A70d58D61eFbdEfD6454960b200c2C
    ];

    function addGenesis() onlyOwner public {
        require(!genesisAdded);

        for (uint i=0; i<genesisList.length; i++) {
          addMasternode(genesisList[i]);
        }

        genesisAdded = true;  
    }

    function addOwner() onlyOwner public {
        addMasternode(owner);
        updateMasternodeAsTeamMember(owner);
    }

    function addMasternode(address _candidate) internal {
         
        userByAddress[_candidate].isActive = true;
        userByAddress[_candidate].accountOwner = _candidate;
        userByAddress[_candidate].storedIndex = masternodeIDcounter;
        userByAddress[_candidate].startingRound = masternodeRound + 1;
        userByAddress[_candidate].indexcounter.push(masternodeIDcounter);

        masternodeByIndex[masternodeIDcounter].isActive = true;
        masternodeByIndex[masternodeIDcounter].accountOwner = _candidate;
        masternodeByIndex[masternodeIDcounter].storedIndex = masternodeIDcounter;
        masternodeByIndex[masternodeIDcounter].startingRound = masternodeRound + 1;

        masternodeIDcounter++;
        userCounter++;
    }

    function updateMasternode(uint _index) internal returns(bool) {
        masternodeByIndex[_index].startingRound++;
        return true;
    }

    function updateMasternodeAsTeamMember(address _candidate) internal returns(bool) {
        userByAddress[_candidate].isTeamMember = true;
        return (true);
    }

    function deleteMasternode(uint _index) internal {
        address getUserFrom = getUserFromID(_index);
        userByAddress[getUserFrom].isActive = false;
        masternodeByIndex[_index].isActive = false;
        userCounter--;
    }

    function getLastActiveBy(address _candidate) public view returns(uint) {
      uint lastFound;
      for (uint i = 0; i < userByAddress[_candidate].indexcounter.length; i++) {
          if (masternodeByIndex[userByAddress[_candidate].indexcounter[i]].isActive == true) {
              lastFound = masternodeByIndex[userByAddress[_candidate].indexcounter[i]].storedIndex;
          }
      }
      return lastFound;
    }

    function userHasActiveNodes(address _candidate) public view returns(bool) {

        bool lastFound;

        for (uint i = 0; i < userByAddress[_candidate].indexcounter.length; i++) {
            if (masternodeByIndex[userByAddress[_candidate].indexcounter[i]].isActive == true) {
                lastFound = true;
            }
        }
        return lastFound;
    }

    function setMasternodeCandidate() internal returns(address) {

        uint hardlimitCounter = 0;

        while (getFollowingCandidate() == 0x0) {
             
            require(hardlimitCounter < 6, "Failsafe switched on");
             
            if (hardlimitCounter == 5) return (0);
            masternodeRound = masternodeRound + 1;
            masternodeCandidate = 0;
            hardlimitCounter++;
        }

        if (masternodeCandidate == masternodeIDcounter - 1) {
            masternodeRound = masternodeRound + 1;
            masternodeCandidate = 0;
        }

        for (uint i = masternodeCandidate; i < masternodeIDcounter; i++) {
            if (masternodeByIndex[i].isActive) {
                if (masternodeByIndex[i].startingRound == masternodeRound) {
                    updateMasternode(i);
                    masternodeCandidate = i;
                    return (masternodeByIndex[i].accountOwner);
                }
            }
        }

        masternodeRound = masternodeRound + 1;
        return (0);

    }

    function getFollowingCandidate() public view returns(address _address) {
        uint tmpRound = masternodeRound;
        uint tmpCandidate = masternodeCandidate;

        if (tmpCandidate == masternodeIDcounter - 1) {
            tmpRound = tmpRound + 1;
            tmpCandidate = 0;
        }

        for (uint i = masternodeCandidate; i < masternodeIDcounter; i++) {
            if (masternodeByIndex[i].isActive) {
                if (masternodeByIndex[i].startingRound == tmpRound) {
                    tmpCandidate = i;
                    return (masternodeByIndex[i].accountOwner);
                }
            }
        }

        tmpRound = tmpRound + 1;
        return (0);
    }

    function calculateRewardStructures() internal {
         
        uint _global_reward_amount = getMiningReward();
        uint getStageOfMining = miningEpoch / MINING_PHASE_DURATION_BLOCKS * 10;

        if (getStageOfMining < 10) {
            rewardsProofOfWork = _global_reward_amount / 100 * 5;
            rewardsMasternode = 0;
            return;
        }

        if (getStageOfMining > 90) {
            rewardsProofOfWork = _global_reward_amount / 100 * 2;
            rewardsMasternode = _global_reward_amount / 100 * 98;
            return;
        }

        uint _mnreward = (_global_reward_amount / 100) * getStageOfMining;
        uint _powreward = (_global_reward_amount - _mnreward);

        setBaseRewards(_powreward, _mnreward);
    }

    function setBaseRewards(uint _pow, uint _mn) internal {
        rewardsMasternode = _mn;
        rewardsProofOfWork = _pow;
    }

    function _arrangeMasternodeFlow() internal {
        calculateRewardStructures();
        setMasternodeCandidate();
        miningEpoch++;
    }

    function isMasternodeOwner(address _candidate) public view returns(bool) {
        if (userByAddress[_candidate].indexcounter.length <= 0) return false;
        if (userByAddress[_candidate].accountOwner == _candidate)
            return true;
    }

    function belongsToUser(address _candidate) public view returns(uint[]) {
        return userByAddress[_candidate].indexcounter;
    }

    function getLastPerUser(address _candidate) public view returns(uint) {
        return userByAddress[_candidate].indexcounter[userByAddress[_candidate].indexcounter.length - 1];
    }

    function getUserFromID(uint _index) public view returns(address) {
        return masternodeByIndex[_index].accountOwner;
    }

    function getMiningReward() public view returns(uint) {
        return 50 * 1e8;
    }

    function masternodeInfo(uint _index) public view returns
        (
            address,
            bool,
            uint,
            uint
        ) {
            return (
                masternodeByIndex[_index].accountOwner,
                masternodeByIndex[_index].isActive,
                masternodeByIndex[_index].storedIndex,
                masternodeByIndex[_index].startingRound
            );
        }

    function contractProgress() public view returns
        (
            uint epoch,
            uint candidate,
            uint round,
            uint miningepoch,
            uint globalreward,
            uint powreward,
            uint masternodereward,
            uint usercount
        ) {
            return (
                0,
                masternodeCandidate,
                masternodeRound,
                miningEpoch,
                getMiningReward(),
                rewardsProofOfWork,
                rewardsMasternode,
                userCounter
            );
        }

}

contract CaelumMasternode is InterfaceContracts, CaelumAbstractMasternode {

    bool minerSet = false;
    bool tokenSet = false;
    uint swapStartedBlock = now;

    address cloneDataFrom = 0x7600bF5112945F9F006c216d5d6db0df2806eDc6;


     

    function _externalArrangeFlow() onlyMiningContract public {
        _arrangeMasternodeFlow();
    }

     
    function _externalAddMasternode(address _received) onlyTokenContract public {
        addMasternode(_received);
    }

     
    function _externalStopMasternode(address _received) onlyTokenContract public {
        deleteMasternode(getLastActiveBy(_received));
    }

    function getMiningReward() public view returns(uint) {
        return ICaelumMiner(_contract_miner()).getMiningReward();
    }

     
    function VoteModifierContract (address _contract) onlyVotingContract external {
         
        setModifierContract(_contract);
    }

    function getDataFromContract() onlyOwner public returns(uint) {

        CaelumMasternode prev = CaelumMasternode(cloneDataFrom);
        (
          uint epoch,
          uint candidate,
          uint round,
          uint miningepoch,
          uint globalreward,
          uint powreward,
          uint masternodereward,
          uint usercounter
        ) = prev.contractProgress();

        masternodeRound = round;
        miningEpoch = miningepoch;
        rewardsProofOfWork = powreward;
        rewardsMasternode = masternodereward;
    }

}