 

pragma solidity ^0.4.11;

contract Safe {
     
    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

     
    function safeSubtract(uint a, uint b) internal returns (uint) {
        uint c = a - b;
        assert(b <= a && c <= a);
        return c;
    }

    function safeMultiply(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || (c / a) == b);
        return c;
    }

    function shrink128(uint a) internal returns (uint128) {
        assert(a < 0x100000000000000000000000000000000);
        return uint128(a);
    }

     
    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length == numWords * 32 + 4);
        _;
    }

     
    function () payable { }
}

 

contract NumeraireShared is Safe {

    address public numerai = this;

     
    uint256 public supply_cap = 21000000e18;  
    uint256 public weekly_disbursement = 96153846153846153846153;

    uint256 public initial_disbursement;
    uint256 public deploy_time;

    uint256 public total_minted;

     
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    mapping (uint => Tournament) public tournaments;   

    struct Tournament {
        uint256 creationTime;
        uint256[] roundIDs;
        mapping (uint256 => Round) rounds;   
    } 

    struct Round {
        uint256 creationTime;
        uint256 endTime;
        uint256 resolutionTime;
        mapping (address => mapping (bytes32 => Stake)) stakes;   
    }

     
     
     
     
    struct Stake {
        uint128 amount;  
        uint128 confidence;
        bool successful;
        bool resolved;
    }

     
    event Mint(uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Staked(address indexed staker, bytes32 tag, uint256 totalAmountStaked, uint256 confidence, uint256 indexed tournamentID, uint256 indexed roundID);
    event RoundCreated(uint256 indexed tournamentID, uint256 indexed roundID, uint256 endTime, uint256 resolutionTime);
    event TournamentCreated(uint256 indexed tournamentID);
    event StakeDestroyed(uint256 indexed tournamentID, uint256 indexed roundID, address indexed stakerAddress, bytes32 tag);
    event StakeReleased(uint256 indexed tournamentID, uint256 indexed roundID, address indexed stakerAddress, bytes32 tag, uint256 etherReward);

     
    function getMintable() constant returns (uint256) {
        return
            safeSubtract(
                safeAdd(initial_disbursement,
                    safeMultiply(weekly_disbursement,
                        safeSubtract(block.timestamp, deploy_time))
                    / 1 weeks),
                total_minted);
    }
}

 
 
contract Shareable {
   

   
  struct PendingState {
    uint yetNeeded;
    uint ownersDone;
    uint index;
  }


   

   
  uint public required;

   
  address[256] owners;
  uint constant c_maxOwners = 250;
   
  mapping(address => uint) ownerIndex;
   
  mapping(bytes32 => PendingState) pendings;
  bytes32[] pendingsIndex;


   

   
   
  event Confirmation(address owner, bytes32 operation);
  event Revoke(address owner, bytes32 operation);


   

  address thisContract = this;

   
  modifier onlyOwner {
    if (isOwner(msg.sender))
      _;
  }

   
   
   
  modifier onlyManyOwners(bytes32 _operation) {
    if (confirmAndCheck(_operation))
      _;
  }


   

   
   
  function Shareable(address[] _owners, uint _required) {
    owners[1] = msg.sender;
    ownerIndex[msg.sender] = 1;
    for (uint i = 0; i < _owners.length; ++i) {
      owners[2 + i] = _owners[i];
      ownerIndex[_owners[i]] = 2 + i;
    }
    if (required > owners.length) throw;
    required = _required;
  }


   
   
   
  function changeShareable(address[] _owners, uint _required) onlyManyOwners(sha3(msg.data)) {
    for (uint i = 0; i < _owners.length; ++i) {
      owners[1 + i] = _owners[i];
      ownerIndex[_owners[i]] = 1 + i;
    }
    if (required > owners.length) throw;
    required = _required;
  }

   

   
  function revoke(bytes32 _operation) external {
    uint index = ownerIndex[msg.sender];
     
    if (index == 0) return;
    uint ownerIndexBit = 2**index;
    var pending = pendings[_operation];
    if (pending.ownersDone & ownerIndexBit > 0) {
      pending.yetNeeded++;
      pending.ownersDone -= ownerIndexBit;
      Revoke(msg.sender, _operation);
    }
  }

   
  function getOwner(uint ownerIndex) external constant returns (address) {
    return address(owners[ownerIndex + 1]);
  }

  function isOwner(address _addr) constant returns (bool) {
    return ownerIndex[_addr] > 0;
  }

  function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
    var pending = pendings[_operation];
    uint index = ownerIndex[_owner];

     
    if (index == 0) return false;

     
    uint ownerIndexBit = 2**index;
    return !(pending.ownersDone & ownerIndexBit == 0);
  }

   

  function confirmAndCheck(bytes32 _operation) internal returns (bool) {
     
    uint index = ownerIndex[msg.sender];
     
    if (index == 0) return;

    var pending = pendings[_operation];
     
    if (pending.yetNeeded == 0) {
       
      pending.yetNeeded = required;
       
      pending.ownersDone = 0;
      pending.index = pendingsIndex.length++;
      pendingsIndex[pending.index] = _operation;
    }
     
    uint ownerIndexBit = 2**index;
     
    if (pending.ownersDone & ownerIndexBit == 0) {
      Confirmation(msg.sender, _operation);
       
      if (pending.yetNeeded <= 1) {
         
        delete pendingsIndex[pendings[_operation].index];
        delete pendings[_operation];
        return true;
      }
      else
        {
           
          pending.yetNeeded--;
          pending.ownersDone |= ownerIndexBit;
        }
    }
  }

  function clearPending() internal {
    uint length = pendingsIndex.length;
    for (uint i = 0; i < length; ++i)
    if (pendingsIndex[i] != 0)
      delete pendings[pendingsIndex[i]];
    delete pendingsIndex;
  }
}

 
 
contract StoppableShareable is Shareable {
  bool public stopped;
  bool public stoppable = true;

  modifier stopInEmergency { if (!stopped) _; }
  modifier onlyInEmergency { if (stopped) _; }

  function StoppableShareable(address[] _owners, uint _required) Shareable(_owners, _required) {
  }

   
  function emergencyStop() external onlyOwner {
    assert(stoppable);
    stopped = true;
  }

   
  function release() external onlyManyOwners(sha3(msg.data)) {
    assert(stoppable);
    stopped = false;
  }

   
  function disableStopping() external onlyManyOwners(sha3(msg.data)) {
    stoppable = false;
  }
}

 

contract NumeraireBackend is StoppableShareable, NumeraireShared {

    address public delegateContract;
    bool public contractUpgradable = true;
    address[] public previousDelegates;

    string public standard = "ERC20";

     
    string public name = "Numeraire";
    string public symbol = "NMR";
    uint256 public decimals = 18;

    event DelegateChanged(address oldAddress, address newAddress);

    function NumeraireBackend(address[] _owners, uint256 _num_required, uint256 _initial_disbursement) StoppableShareable(_owners, _num_required) {
        totalSupply = 0;
        total_minted = 0;

        initial_disbursement = _initial_disbursement;
        deploy_time = block.timestamp;
    }

    function disableContractUpgradability() onlyManyOwners(sha3(msg.data)) returns (bool) {
        assert(contractUpgradable);
        contractUpgradable = false;
    }

    function changeDelegate(address _newDelegate) onlyManyOwners(sha3(msg.data)) returns (bool) {
        assert(contractUpgradable);

        if (_newDelegate != delegateContract) {
            previousDelegates.push(delegateContract);
            var oldDelegate = delegateContract;
            delegateContract = _newDelegate;
            DelegateChanged(oldDelegate, _newDelegate);
            return true;
        }

        return false;
    }

    function claimTokens(address _token) onlyOwner {
        assert(_token != numerai);
        if (_token == 0x0) {
            msg.sender.transfer(this.balance);
            return;
        }

        NumeraireBackend token = NumeraireBackend(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(msg.sender, balance);
    }

    function mint(uint256 _value) stopInEmergency returns (bool ok) {
        return delegateContract.delegatecall(bytes4(sha3("mint(uint256)")), _value);
    }

    function stake(uint256 _value, bytes32 _tag, uint256 _tournamentID, uint256 _roundID, uint256 _confidence) stopInEmergency returns (bool ok) {
        return delegateContract.delegatecall(bytes4(sha3("stake(uint256,bytes32,uint256,uint256,uint256)")), _value, _tag, _tournamentID, _roundID, _confidence);
    }

    function stakeOnBehalf(address _staker, uint256 _value, bytes32 _tag, uint256 _tournamentID, uint256 _roundID, uint256 _confidence) stopInEmergency onlyPayloadSize(6) returns (bool ok) {
        return delegateContract.delegatecall(bytes4(sha3("stakeOnBehalf(address,uint256,bytes32,uint256,uint256,uint256)")), _staker, _value, _tag, _tournamentID, _roundID, _confidence);
    }

    function releaseStake(address _staker, bytes32 _tag, uint256 _etherValue, uint256 _tournamentID, uint256 _roundID, bool _successful) stopInEmergency onlyPayloadSize(6) returns (bool ok) {
        return delegateContract.delegatecall(bytes4(sha3("releaseStake(address,bytes32,uint256,uint256,uint256,bool)")), _staker, _tag, _etherValue, _tournamentID, _roundID, _successful);
    }

    function destroyStake(address _staker, bytes32 _tag, uint256 _tournamentID, uint256 _roundID) stopInEmergency onlyPayloadSize(4) returns (bool ok) {
        return delegateContract.delegatecall(bytes4(sha3("destroyStake(address,bytes32,uint256,uint256)")), _staker, _tag, _tournamentID, _roundID);
    }

    function numeraiTransfer(address _to, uint256 _value) onlyPayloadSize(2) returns(bool ok) {
        return delegateContract.delegatecall(bytes4(sha3("numeraiTransfer(address,uint256)")), _to, _value);
    }

    function withdraw(address _from, address _to, uint256 _value) onlyPayloadSize(3) returns(bool ok) {
        return delegateContract.delegatecall(bytes4(sha3("withdraw(address,address,uint256)")), _from, _to, _value);
    }

    function createTournament(uint256 _tournamentID) returns (bool ok) {
        return delegateContract.delegatecall(bytes4(sha3("createTournament(uint256)")), _tournamentID);
    }

    function createRound(uint256 _tournamentID, uint256 _roundID, uint256 _endTime, uint256 _resolutionTime) returns (bool ok) {
        return delegateContract.delegatecall(bytes4(sha3("createRound(uint256,uint256,uint256,uint256)")), _tournamentID, _roundID, _endTime, _resolutionTime);
    }

    function getTournament(uint256 _tournamentID) constant returns (uint256, uint256[]) {
        var tournament = tournaments[_tournamentID];
        return (tournament.creationTime, tournament.roundIDs);
    }

    function getRound(uint256 _tournamentID, uint256 _roundID) constant returns (uint256, uint256, uint256) {
        var round = tournaments[_tournamentID].rounds[_roundID];
        return (round.creationTime, round.endTime, round.resolutionTime);
    }

    function getStake(uint256 _tournamentID, uint256 _roundID, address _staker, bytes32 _tag) constant returns (uint256, uint256, bool, bool) {
        var stake = tournaments[_tournamentID].rounds[_roundID].stakes[_staker][_tag];
        return (stake.confidence, stake.amount, stake.successful, stake.resolved);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) stopInEmergency onlyPayloadSize(3) returns (bool ok) {
        require(!isOwner(_from) && _from != numerai);  

         
        require(balanceOf[_from] >= _value);
         
        require(allowance[_from][msg.sender] >= _value);

        balanceOf[_from] = safeSubtract(balanceOf[_from], _value);
        allowance[_from][msg.sender] = safeSubtract(allowance[_from][msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);

         
        Transfer(_from, _to, _value);

        return true;
    }

     
    function transfer(address _to, uint256 _value) stopInEmergency onlyPayloadSize(2) returns (bool ok) {
         
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] = safeSubtract(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);

         
        Transfer(msg.sender, _to, _value);

        return true;
    }

     
    function approve(address _spender, uint256 _value) stopInEmergency onlyPayloadSize(2) returns (bool ok) {
        require((_value == 0) || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) stopInEmergency onlyPayloadSize(3) returns (bool ok) {
        require(allowance[msg.sender][_spender] == _oldValue);
        allowance[msg.sender][_spender] = _newValue;
        Approval(msg.sender, _spender, _newValue);
        return true;
    }
}