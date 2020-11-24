 

pragma solidity ^0.4.24;

 

contract Multiownable {

     

    uint256 public ownersGeneration;
    uint256 public howManyOwnersDecide;
    address[] public owners;
    bytes32[] public allOperations;
    address internal insideCallSender;
    uint256 internal insideCallCount;

     
    mapping(address => uint) public ownersIndices;  
    mapping(bytes32 => uint) public allOperationsIndicies;

     
    mapping(bytes32 => uint256) public votesMaskByOperation;
    mapping(bytes32 => uint256) public votesCountByOperation;

     

    event OwnershipTransferred(address[] previousOwners, uint howManyOwnersDecide, address[] newOwners, uint newHowManyOwnersDecide);
    event OperationCreated(bytes32 operation, uint howMany, uint ownersCount, address proposer);
    event OperationUpvoted(bytes32 operation, uint votes, uint howMany, uint ownersCount, address upvoter);
    event OperationPerformed(bytes32 operation, uint howMany, uint ownersCount, address performer);
    event OperationDownvoted(bytes32 operation, uint votes, uint ownersCount,  address downvoter);
    event OperationCancelled(bytes32 operation, address lastCanceller);
    
     

    function isOwner(address wallet) public constant returns(bool) {
        return ownersIndices[wallet] > 0;
    }

    function ownersCount() public constant returns(uint) {
        return owners.length;
    }

    function allOperationsCount() public constant returns(uint) {
        return allOperations.length;
    }

     

     
    modifier onlyAnyOwner {
        if (checkHowManyOwners(1)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = 1;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

     
    modifier onlyManyOwners {
        if (checkHowManyOwners(howManyOwnersDecide)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = howManyOwnersDecide;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

     
    modifier onlyAllOwners {
        if (checkHowManyOwners(owners.length)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = owners.length;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

     
    modifier onlySomeOwners(uint howMany) {
        require(howMany > 0, "onlySomeOwners: howMany argument is zero");
        require(howMany <= owners.length, "onlySomeOwners: howMany argument exceeds the number of owners");
        
        if (checkHowManyOwners(howMany)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = howMany;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

     

    constructor() public {
        owners.push(msg.sender);
        ownersIndices[msg.sender] = 1;
        howManyOwnersDecide = 1;
    }

     

     
    function checkHowManyOwners(uint howMany) internal returns(bool) {
        if (insideCallSender == msg.sender) {
            require(howMany <= insideCallCount, "checkHowManyOwners: nested owners modifier check require more owners");
            return true;
        }

        uint ownerIndex = ownersIndices[msg.sender] - 1;
        require(ownerIndex < owners.length, "checkHowManyOwners: msg.sender is not an owner");
        bytes32 operation = keccak256(msg.data, ownersGeneration);

        require((votesMaskByOperation[operation] & (2 ** ownerIndex)) == 0, "checkHowManyOwners: owner already voted for the operation");
        votesMaskByOperation[operation] |= (2 ** ownerIndex);
        uint operationVotesCount = votesCountByOperation[operation] + 1;
        votesCountByOperation[operation] = operationVotesCount;
        if (operationVotesCount == 1) {
            allOperationsIndicies[operation] = allOperations.length;
            allOperations.push(operation);
            emit OperationCreated(operation, howMany, owners.length, msg.sender);
        }
        emit OperationUpvoted(operation, operationVotesCount, howMany, owners.length, msg.sender);

         
        if (votesCountByOperation[operation] == howMany) {
            deleteOperation(operation);
            emit OperationPerformed(operation, howMany, owners.length, msg.sender);
            return true;
        }

        return false;
    }

     
    function deleteOperation(bytes32 operation) internal {
        uint index = allOperationsIndicies[operation];
        if (index < allOperations.length - 1) {  
            allOperations[index] = allOperations[allOperations.length - 1];
            allOperationsIndicies[allOperations[index]] = index;
        }
        allOperations.length--;

        delete votesMaskByOperation[operation];
        delete votesCountByOperation[operation];
        delete allOperationsIndicies[operation];
    }

     

     
    function cancelPending(bytes32 operation) public onlyAnyOwner {
        uint ownerIndex = ownersIndices[msg.sender] - 1;
        require((votesMaskByOperation[operation] & (2 ** ownerIndex)) != 0, "cancelPending: operation not found for this user");
        votesMaskByOperation[operation] &= ~(2 ** ownerIndex);
        uint operationVotesCount = votesCountByOperation[operation] - 1;
        votesCountByOperation[operation] = operationVotesCount;
        emit OperationDownvoted(operation, operationVotesCount, owners.length, msg.sender);
        if (operationVotesCount == 0) {
            deleteOperation(operation);
            emit OperationCancelled(operation, msg.sender);
        }
    }

     
    function transferOwnership(address[] newOwners) public {
        transferOwnershipWithHowMany(newOwners, newOwners.length);
    }

     
    function transferOwnershipWithHowMany(address[] newOwners, uint256 newHowManyOwnersDecide) public onlyManyOwners {
        require(newOwners.length > 0, "transferOwnershipWithHowMany: owners array is empty");
        require(newOwners.length <= 256, "transferOwnershipWithHowMany: owners count is greater then 256");
        require(newHowManyOwnersDecide > 0, "transferOwnershipWithHowMany: newHowManyOwnersDecide equal to 0");
        require(newHowManyOwnersDecide <= newOwners.length, "transferOwnershipWithHowMany: newHowManyOwnersDecide exceeds the number of owners");

         
        for (uint j = 0; j < owners.length; j++) {
            delete ownersIndices[owners[j]];
        }
        for (uint i = 0; i < newOwners.length; i++) {
            require(newOwners[i] != address(0), "transferOwnershipWithHowMany: owners array contains zero");
            require(ownersIndices[newOwners[i]] == 0, "transferOwnershipWithHowMany: owners array contains duplicates");
            ownersIndices[newOwners[i]] = i + 1;
        }
        
        emit OwnershipTransferred(owners, howManyOwnersDecide, newOwners, newHowManyOwnersDecide);
        owners = newOwners;
        howManyOwnersDecide = newHowManyOwnersDecide;
        allOperations.length = 0;
        ownersGeneration++;
    }

}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

library BadERC20Aware {
    using SafeMath for uint;

    function isContract(address addr) internal view returns(bool result) {
         
        assembly {
            result := gt(extcodesize(addr), 0)
        }
    }

    function handleReturnBool() internal pure returns(bool result) {
         
        assembly {
            switch returndatasize()
            case 0 {  
                result := 1
            }
            case 32 {  
                returndatacopy(0, 0, 32)
                result := mload(0)
            }
            default {  
                revert(0, 0)
            }
        }
    }

    function asmTransfer(ERC20 _token, address _to, uint256 _value) internal returns(bool) {
        require(isContract(_token));
         
        require(address(_token).call(bytes4(keccak256("transfer(address,uint256)")), _to, _value));
        return handleReturnBool();
    }

    function safeTransfer(ERC20 _token, address _to, uint256 _value) internal {
        require(asmTransfer(_token, _to, _value));
    }
}

 

 







contract TokenSwap is Ownable, Multiownable {

     

    using BadERC20Aware for ERC20;
    using SafeMath for uint256;

     

    enum Status {AddParties, WaitingDeposits, SwapConfirmed, SwapCanceled}

    struct SwapOffer {
        address participant;
        ERC20 token;

        uint256 tokensForSwap;
        uint256 withdrawnTokensForSwap;

        uint256 tokensFee;
        uint256 withdrawnFee;

        uint256 tokensTotal;
        uint256 withdrawnTokensTotal;
    }

    struct LockupStage {
        uint256 secondsSinceLockupStart;
        uint8 unlockedTokensPercentage;
    }

     
    Status public status = Status.AddParties;

    uint256 internal startLockupAt;
    LockupStage[] internal lockupStages;

    address[] internal participants;
    mapping(address => bool) internal isParticipant;
    mapping(address => address) internal tokenByParticipant;
    mapping(address => SwapOffer) internal offerByToken;

     
    event AddLockupStage(uint256 secondsSinceLockupStart, uint8 unlockedTokensPercentage);
    event StatusUpdate(Status oldStatus, Status newStatus);
    event AddParty(address participant, ERC20 token, uint256 amount);
    event RemoveParty(address participant);
    event ConfirmParties();
    event CancelSwap();
    event ConfirmSwap();
    event StartLockup(uint256 startLockupAt);
    event Withdraw(address participant, ERC20 token, uint256 amount);
    event WithdrawFee(ERC20 token, uint256 amount);
    event Reclaim(address participant, ERC20 token, uint256 amount);

     
    modifier onlyParticipant {
        require(
            isParticipant[msg.sender] == true,
            "Only swap participants allowed to call the method"
        );
        _;
    }

    modifier canAddParty {
        require(status == Status.AddParties, "Unable to add new parties in the current status");
        _;
    }

    modifier canRemoveParty {
        require(status == Status.AddParties, "Unable to remove parties in the current status");
        _;
    }

    modifier canConfirmParties {
        require(
            status == Status.AddParties,
            "Unable to confirm parties in the current status"
        );
        require(participants.length > 1, "Need at least two participants");
        _;
    }

    modifier canCancelSwap {
        require(
            status == Status.WaitingDeposits,
            "Unable to cancel swap in the current status"
        );
        _;
    }

    modifier canConfirmSwap {
        require(status == Status.WaitingDeposits, "Unable to confirm in the current status");
        require(
            _haveEveryoneDeposited(),
            "Unable to confirm swap before all parties have deposited tokens"
        );
        _;
    }

    modifier canWithdraw {
        require(status == Status.SwapConfirmed, "Unable to withdraw tokens in the current status");
        require(startLockupAt != 0, "Lockup has not been started");
        _;
    }

    modifier canWithdrawFee {
        require(status == Status.SwapConfirmed, "Unable to withdraw fee in the current status");
        require(startLockupAt != 0, "Lockup has not been started");
        _;
    }

    modifier canReclaim {
        require(
            status == Status.SwapConfirmed || status == Status.SwapCanceled,
            "Unable to reclaim in the current status"
        );
        _;
    }

     
    constructor() public {
        _initializeLockupStages();
        _validateLockupStages();
    }

     
     
    function addParty(
        address _participant,
        ERC20 _token,
        uint256 _tokensForSwap,
        uint256 _tokensFee,
        uint256 _tokensTotal
    )
        external
        onlyOwner
        canAddParty
    {
        require(_participant != address(0), "_participant is invalid address");
        require(_token != address(0), "_token is invalid address");
        require(_tokensForSwap > 0, "_tokensForSwap must be positive");
        require(_tokensFee > 0, "_tokensFee must be positive");
        require(_tokensTotal == _tokensForSwap.add(_tokensFee), "token amounts inconsistency");
        require(
            isParticipant[_participant] == false,
            "Unable to add the same party multiple times"
        );

        isParticipant[_participant] = true;
        SwapOffer memory offer = SwapOffer({
            participant: _participant,
            token: _token,
            tokensForSwap: _tokensForSwap,
            withdrawnTokensForSwap: 0,
            tokensFee: _tokensFee,
            withdrawnFee: 0,
            tokensTotal: _tokensTotal,
            withdrawnTokensTotal: 0
        });
        participants.push(offer.participant);
        offerByToken[offer.token] = offer;
        tokenByParticipant[offer.participant] = offer.token;

        emit AddParty(offer.participant, offer.token, offer.tokensTotal);
    }

     
    function removeParty(uint256 _participantIndex) external onlyOwner canRemoveParty {
        require(_participantIndex < participants.length, "Participant does not exist");

        address participant = participants[_participantIndex];
        address token = tokenByParticipant[participant];

        delete isParticipant[participant];
        participants[_participantIndex] = participants[participants.length - 1];
        participants.length--;
        delete offerByToken[token];
        delete tokenByParticipant[participant];

        emit RemoveParty(participant);
    }

     
    function confirmParties() external onlyOwner canConfirmParties {
        address[] memory newOwners = new address[](participants.length + 1);

        for (uint256 i = 0; i < participants.length; i++) {
            newOwners[i] = participants[i];
        }

        newOwners[newOwners.length - 1] = owner;
        transferOwnershipWithHowMany(newOwners, newOwners.length - 1);
        _changeStatus(Status.WaitingDeposits);
        emit ConfirmParties();
    }

     
    function confirmSwap() external canConfirmSwap onlyManyOwners {
        emit ConfirmSwap();
        _changeStatus(Status.SwapConfirmed);
        _startLockup();
    }

     
    function cancelSwap() external canCancelSwap onlyManyOwners {
        emit CancelSwap();
        _changeStatus(Status.SwapCanceled);
    }

     
    function withdraw() external onlyParticipant canWithdraw {
        for (uint i = 0; i < participants.length; i++) {
            address token = tokenByParticipant[participants[i]];
            SwapOffer storage offer = offerByToken[token];

            if (offer.participant == msg.sender) {
                continue;
            }

            uint256 tokenReceivers = participants.length - 1;
            uint256 tokensAmount = _withdrawableAmount(offer).div(tokenReceivers);

            offer.token.safeTransfer(msg.sender, tokensAmount);
            emit Withdraw(msg.sender, offer.token, tokensAmount);
            offer.withdrawnTokensForSwap = offer.withdrawnTokensForSwap.add(tokensAmount);
            offer.withdrawnTokensTotal = offer.withdrawnTokensTotal.add(tokensAmount);
        }
    }

     
    function withdrawFee() external onlyOwner canWithdrawFee {
        for (uint i = 0; i < participants.length; i++) {
            address token = tokenByParticipant[participants[i]];
            SwapOffer storage offer = offerByToken[token];

            uint256 tokensAmount = _withdrawableFee(offer);

            offer.token.safeTransfer(msg.sender, tokensAmount);
            emit WithdrawFee(offer.token, tokensAmount);
            offer.withdrawnFee = offer.withdrawnFee.add(tokensAmount);
            offer.withdrawnTokensTotal = offer.withdrawnTokensTotal.add(tokensAmount);
        }
    }

     
    function reclaim() external onlyParticipant canReclaim {
        address token = tokenByParticipant[msg.sender];

        SwapOffer storage offer = offerByToken[token];
        uint256 currentBalance = offer.token.balanceOf(address(this));
        uint256 availableForReclaim = currentBalance;

        if (status != Status.SwapCanceled) {
            uint256 lockedTokens = offer.tokensTotal.sub(offer.withdrawnTokensTotal);
            availableForReclaim = currentBalance.sub(lockedTokens);
        }

        if (availableForReclaim > 0) {
            offer.token.safeTransfer(offer.participant, availableForReclaim);
        }

        emit Reclaim(offer.participant, offer.token, availableForReclaim);
    }

     
     
    function tokenFallback(address _from, uint256 _value, bytes _data) public {

    }

     
     
    function _initializeLockupStages() internal {
        _addLockupStage(LockupStage(0, 10));
        _addLockupStage(LockupStage(30 days, 20));
        _addLockupStage(LockupStage(60 days, 30));
        _addLockupStage(LockupStage(90 days, 40));
        _addLockupStage(LockupStage(120 days, 50));
        _addLockupStage(LockupStage(150 days, 60));
        _addLockupStage(LockupStage(180 days, 70));
        _addLockupStage(LockupStage(210 days, 80));
        _addLockupStage(LockupStage(240 days, 90));
        _addLockupStage(LockupStage(270 days, 100));
    }

     
    function _addLockupStage(LockupStage _stage) internal {
        emit AddLockupStage(_stage.secondsSinceLockupStart, _stage.unlockedTokensPercentage);
        lockupStages.push(_stage);
    }

     
    function _validateLockupStages() internal view {
        for (uint i = 0; i < lockupStages.length; i++) {
            LockupStage memory stage = lockupStages[i];

            require(
                stage.unlockedTokensPercentage >= 0,
                "LockupStage.unlockedTokensPercentage must not be negative"
            );
            require(
                stage.unlockedTokensPercentage <= 100,
                "LockupStage.unlockedTokensPercentage must not be greater than 100"
            );

            if (i == 0) {
                continue;
            }

            LockupStage memory previousStage = lockupStages[i - 1];
            require(
                stage.secondsSinceLockupStart > previousStage.secondsSinceLockupStart,
                "LockupStage.secondsSinceLockupStart must increase monotonically"
            );
            require(
                stage.unlockedTokensPercentage > previousStage.unlockedTokensPercentage,
                "LockupStage.unlockedTokensPercentage must increase monotonically"
            );
        }

        require(
            lockupStages[0].secondsSinceLockupStart == 0,
            "The first lockup stage must start immediately"
        );
        require(
            lockupStages[lockupStages.length - 1].unlockedTokensPercentage == 100,
            "The last lockup stage must unlock 100% of tokens"
        );
    }

     
    function _changeStatus(Status _newStatus) internal {
        emit StatusUpdate(status, _newStatus);
        status = _newStatus;
    }

     
    function _haveEveryoneDeposited() internal view returns(bool) {
        for (uint i = 0; i < participants.length; i++) {
            address token = tokenByParticipant[participants[i]];
            SwapOffer memory offer = offerByToken[token];

            if (offer.token.balanceOf(address(this)) < offer.tokensTotal) {
                return false;
            }
        }

        return true;
    }

     
    function _startLockup() internal {
        startLockupAt = now;
        emit StartLockup(startLockupAt);
    }

     
    function _withdrawableAmount(SwapOffer _offer) internal view returns(uint256) {
        return _unlockedAmount(_offer.tokensForSwap).sub(_offer.withdrawnTokensForSwap);
    }

     
    function _withdrawableFee(SwapOffer _offer) internal view returns(uint256) {
        return _unlockedAmount(_offer.tokensFee).sub(_offer.withdrawnFee);
    }

     
    function _unlockedAmount(uint256 totalAmount) internal view returns(uint256) {
        return totalAmount.mul(_getUnlockedTokensPercentage()).div(100);
    }

     
    function _getUnlockedTokensPercentage() internal view returns(uint256) {
        for (uint256 i = lockupStages.length; i > 0; i--) {
            LockupStage storage stage = lockupStages[i - 1];
            uint256 stageBecomesActiveAt = startLockupAt.add(stage.secondsSinceLockupStart);

            if (now < stageBecomesActiveAt) {
                continue;
            }

            return stage.unlockedTokensPercentage;
        }
    }
}