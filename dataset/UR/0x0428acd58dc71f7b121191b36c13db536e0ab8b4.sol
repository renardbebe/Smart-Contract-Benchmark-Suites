 

pragma solidity 0.4.25;
 
 
 
library ECDSA {

   
  function recover(bytes32 hash, bytes signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (signature.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract DecoBaseProjectsMarketplace is Ownable {
    using SafeMath for uint256;

     
    address public relayContractAddress;

     
    function () public payable {
        require(msg.value == 0, "Blocking any incoming ETH.");
    }

     
    function setRelayContractAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Relay address must not be 0x0.");
        relayContractAddress = _newAddress;
    }

     
    function transferAnyERC20Token(
        address _tokenAddress,
        uint _tokens
    )
        public
        onlyOwner
        returns (bool success)
    {
        IERC20 token = IERC20(_tokenAddress);
        return token.transfer(owner(), _tokens);
    }
}


interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract DecoRelay is DecoBaseProjectsMarketplace {
    address public projectsContractAddress;
    address public milestonesContractAddress;
    address public escrowFactoryContractAddress;
    address public arbitrationContractAddress;

    address public feesWithdrawalAddress;

    uint8 public shareFee;

    function setProjectsContractAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Address should not be 0x0.");
        projectsContractAddress = _newAddress;
    }

    function setMilestonesContractAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Address should not be 0x0.");
        milestonesContractAddress = _newAddress;
    }

    function setEscrowFactoryContractAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Address should not be 0x0.");
        escrowFactoryContractAddress = _newAddress;
    }

    function setArbitrationContractAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Address should not be 0x0.");
        arbitrationContractAddress = _newAddress;
    }

    function setFeesWithdrawalAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Address should not be 0x0.");
        feesWithdrawalAddress = _newAddress;
    }

    function setShareFee(uint8 _shareFee) external onlyOwner {
        require(_shareFee <= 100, "Deconet share fee must be less than 100%.");
        shareFee = _shareFee;
    }
}

 
contract DecoEscrow is DecoBaseProjectsMarketplace {
    using SafeMath for uint256;

     
    bool internal isInitialized;

     
    uint8 public shareFee;

     
    address public authorizedAddress;

     
     
    uint public balance;

     
     
    mapping (address => uint) public withdrawalAllowanceForAddress;

     
    mapping(address => uint) public tokensBalance;

     
    mapping(address => mapping(address => uint)) public tokensWithdrawalAllowanceForAddress;

     
     
    uint public blockedBalance;

     
     
    mapping(address => uint) public blockedTokensBalance;

     
    event FundsOperation (
        address indexed sender,
        address indexed target,
        address tokenAddress,
        uint amount,
        PaymentType paymentType,
        OperationType indexed operationType
    );

     
    event FundsDistributionAuthorization (
        address targetAddress,
        bool isAuthorized
    );

     
    enum PaymentType { Ether, Erc20 }

     
    enum OperationType { Receive, Send, Block, Unblock, Distribute }

     
    modifier onlyAuthorized() {
        require(authorizedAddress == msg.sender, "Only authorized addresses allowed.");
        _;
    }

     
    function () public payable {
        deposit();
    }

     
    function initialize(
        address _newOwner,
        address _authorizedAddress,
        uint8 _shareFee,
        address _relayContractAddress
    )
        external
    {
        require(!isInitialized, "Only uninitialized contracts allowed.");
        isInitialized = true;
        authorizedAddress = _authorizedAddress;
        emit FundsDistributionAuthorization(_authorizedAddress, true);
        _transferOwnership(_newOwner);
        shareFee = _shareFee;
        relayContractAddress = _relayContractAddress;
    }

     
    function depositErc20(address _tokenAddress, uint _amount) external {
        require(_tokenAddress != address(0x0), "Token Address shouldn't be 0x0.");
        IERC20 token = IERC20(_tokenAddress);
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer operation should be successful."
        );
        tokensBalance[_tokenAddress] = tokensBalance[_tokenAddress].add(_amount);
        emit FundsOperation (
            msg.sender,
            address(this),
            _tokenAddress,
            _amount,
            PaymentType.Erc20,
            OperationType.Receive
        );
    }

     
    function withdraw(uint _amount) external {
        withdrawForAddress(msg.sender, _amount);
    }

     
    function withdrawErc20(address _tokenAddress, uint _amount) external {
        withdrawErc20ForAddress(msg.sender, _tokenAddress, _amount);
    }

     
    function blockFunds(uint _amount) external onlyAuthorized {
        require(_amount <= balance, "Amount to block should be less or equal than balance.");
        balance = balance.sub(_amount);
        blockedBalance = blockedBalance.add(_amount);
        emit FundsOperation (
            address(this),
            msg.sender,
            address(0x0),
            _amount,
            PaymentType.Ether,
            OperationType.Block
        );
    }

     
    function blockTokenFunds(address _tokenAddress, uint _amount) external onlyAuthorized {
        uint accountedTokensBalance = tokensBalance[_tokenAddress];
        require(
            _amount <= accountedTokensBalance,
            "Tokens mount to block should be less or equal than balance."
        );
        tokensBalance[_tokenAddress] = accountedTokensBalance.sub(_amount);
        blockedTokensBalance[_tokenAddress] = blockedTokensBalance[_tokenAddress].add(_amount);
        emit FundsOperation (
            address(this),
            msg.sender,
            _tokenAddress,
            _amount,
            PaymentType.Erc20,
            OperationType.Block
        );
    }

     
    function distributeFunds(
        address _destination,
        uint _amount
    )
        external
        onlyAuthorized
    {
        require(
            _amount <= blockedBalance,
            "Amount to distribute should be less or equal than blocked balance."
        );
        uint amount = _amount;
        if (shareFee > 0 && relayContractAddress != address(0x0)) {
            DecoRelay relayContract = DecoRelay(relayContractAddress);
            address feeDestination = relayContract.feesWithdrawalAddress();
            uint fee = amount.mul(shareFee).div(100);
            amount = amount.sub(fee);
            blockedBalance = blockedBalance.sub(fee);
            withdrawalAllowanceForAddress[feeDestination] =
                withdrawalAllowanceForAddress[feeDestination].add(fee);
            emit FundsOperation(
                msg.sender,
                feeDestination,
                address(0x0),
                fee,
                PaymentType.Ether,
                OperationType.Distribute
            );
        }
        if (_destination == owner()) {
            unblockFunds(amount);
            return;
        }
        blockedBalance = blockedBalance.sub(amount);
        withdrawalAllowanceForAddress[_destination] = withdrawalAllowanceForAddress[_destination].add(amount);
        emit FundsOperation(
            msg.sender,
            _destination,
            address(0x0),
            amount,
            PaymentType.Ether,
            OperationType.Distribute
        );
    }

     
    function distributeTokenFunds(
        address _destination,
        address _tokenAddress,
        uint _amount
    )
        external
        onlyAuthorized
    {
        require(
            _amount <= blockedTokensBalance[_tokenAddress],
            "Amount to distribute should be less or equal than blocked balance."
        );
        uint amount = _amount;
        if (shareFee > 0 && relayContractAddress != address(0x0)) {
            DecoRelay relayContract = DecoRelay(relayContractAddress);
            address feeDestination = relayContract.feesWithdrawalAddress();
            uint fee = amount.mul(shareFee).div(100);
            amount = amount.sub(fee);
            blockedTokensBalance[_tokenAddress] = blockedTokensBalance[_tokenAddress].sub(fee);
            uint allowance = tokensWithdrawalAllowanceForAddress[feeDestination][_tokenAddress];
            tokensWithdrawalAllowanceForAddress[feeDestination][_tokenAddress] = allowance.add(fee);
            emit FundsOperation(
                msg.sender,
                feeDestination,
                _tokenAddress,
                fee,
                PaymentType.Erc20,
                OperationType.Distribute
            );
        }
        if (_destination == owner()) {
            unblockTokenFunds(_tokenAddress, amount);
            return;
        }
        blockedTokensBalance[_tokenAddress] = blockedTokensBalance[_tokenAddress].sub(amount);
        uint allowanceForSender = tokensWithdrawalAllowanceForAddress[_destination][_tokenAddress];
        tokensWithdrawalAllowanceForAddress[_destination][_tokenAddress] = allowanceForSender.add(amount);
        emit FundsOperation(
            msg.sender,
            _destination,
            _tokenAddress,
            amount,
            PaymentType.Erc20,
            OperationType.Distribute
        );
    }

     
    function withdrawForAddress(address _targetAddress, uint _amount) public {
        require(
            _amount <= address(this).balance,
            "Amount to withdraw should be less or equal than balance."
        );
        if (_targetAddress == owner()) {
            balance = balance.sub(_amount);
        } else {
            uint withdrawalAllowance = withdrawalAllowanceForAddress[_targetAddress];
            withdrawalAllowanceForAddress[_targetAddress] = withdrawalAllowance.sub(_amount);
        }
        _targetAddress.transfer(_amount);
        emit FundsOperation (
            address(this),
            _targetAddress,
            address(0x0),
            _amount,
            PaymentType.Ether,
            OperationType.Send
        );
    }

     
    function withdrawErc20ForAddress(address _targetAddress, address _tokenAddress, uint _amount) public {
        IERC20 token = IERC20(_tokenAddress);
        require(
            _amount <= token.balanceOf(this),
            "Token amount to withdraw should be less or equal than balance."
        );
        if (_targetAddress == owner()) {
            tokensBalance[_tokenAddress] = tokensBalance[_tokenAddress].sub(_amount);
        } else {
            uint tokenWithdrawalAllowance = getTokenWithdrawalAllowance(_targetAddress, _tokenAddress);
            tokensWithdrawalAllowanceForAddress[_targetAddress][_tokenAddress] = tokenWithdrawalAllowance.sub(
                _amount
            );
        }
        token.transfer(_targetAddress, _amount);
        emit FundsOperation (
            address(this),
            _targetAddress,
            _tokenAddress,
            _amount,
            PaymentType.Erc20,
            OperationType.Send
        );
    }

     
    function getTokenWithdrawalAllowance(address _account, address _tokenAddress) public view returns(uint) {
        return tokensWithdrawalAllowanceForAddress[_account][_tokenAddress];
    }

     
    function deposit() public payable {
        require(msg.value > 0, "Deposited amount should be greater than 0.");
        balance = balance.add(msg.value);
        emit FundsOperation (
            msg.sender,
            address(this),
            address(0x0),
            msg.value,
            PaymentType.Ether,
            OperationType.Receive
        );
    }

     
    function unblockFunds(uint _amount) public onlyAuthorized {
        require(
            _amount <= blockedBalance,
            "Amount to unblock should be less or equal than balance"
        );
        blockedBalance = blockedBalance.sub(_amount);
        balance = balance.add(_amount);
        emit FundsOperation (
            msg.sender,
            address(this),
            address(0x0),
            _amount,
            PaymentType.Ether,
            OperationType.Unblock
        );
    }

     
    function unblockTokenFunds(address _tokenAddress, uint _amount) public onlyAuthorized {
        uint accountedBlockedTokensAmount = blockedTokensBalance[_tokenAddress];
        require(
            _amount <= accountedBlockedTokensAmount,
            "Tokens amount to unblock should be less or equal than balance"
        );
        blockedTokensBalance[_tokenAddress] = accountedBlockedTokensAmount.sub(_amount);
        tokensBalance[_tokenAddress] = tokensBalance[_tokenAddress].add(_amount);
        emit FundsOperation (
            msg.sender,
            address(this),
            _tokenAddress,
            _amount,
            PaymentType.Erc20,
            OperationType.Unblock
        );
    }

     
    function transferAnyERC20Token(
        address _tokenAddress,
        uint _tokens
    )
        public
        onlyOwner
        returns (bool success)
    {
        return false;
    }
}

contract CloneFactory {

  event CloneCreated(address indexed target, address clone);

  function createClone(address target) internal returns (address result) {
    bytes memory clone = hex"600034603b57603080600f833981f36000368180378080368173bebebebebebebebebebebebebebebebebebebebe5af43d82803e15602c573d90f35b3d90fd";
    bytes20 targetBytes = bytes20(target);
    for (uint i = 0; i < 20; i++) {
      clone[26 + i] = targetBytes[i];
    }
    assembly {
      let len := mload(clone)
      let data := add(clone, 0x20)
      result := create(0, data, len)
    }
  }
}

 
contract DecoEscrowFactory is DecoBaseProjectsMarketplace, CloneFactory {

     
    address public libraryAddress;

     
    event EscrowCreated(address newEscrowAddress);

     
    constructor(address _libraryAddress) public {
        libraryAddress = _libraryAddress;
    }

     
    function setLibraryAddress(address _libraryAddress) external onlyOwner {
        require(libraryAddress != _libraryAddress);
        require(_libraryAddress != address(0x0));

        libraryAddress = _libraryAddress;
    }

     
    function createEscrow(
        address _ownerAddress,
        address _authorizedAddress
    )
        external
        returns(address)
    {
        address clone = createClone(libraryAddress);
        DecoRelay relay = DecoRelay(relayContractAddress);
        DecoEscrow(clone).initialize(
            _ownerAddress,
            _authorizedAddress,
            relay.shareFee(),
            relayContractAddress
        );
        emit EscrowCreated(clone);
        return clone;
    }
}

contract IDecoArbitrationTarget {

     
    function disputeStartedFreeze(bytes32 _idHash) public;

     
    function disputeSettledTerminate(
        bytes32 _idHash,
        address _respondent,
        uint8 _respondentShare,
        address _initiator,
        uint8 _initiatorShare,
        bool _isInternal,
        address _arbiterWithdrawalAddress
    )
        public;

     
    function checkEligibility(bytes32 _idHash, address _addressToCheck) public view returns(bool);

     
    function canStartDispute(bytes32 _idHash) public view returns(bool);
}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface IDecoArbitration {

     
    event LogStartedDispute(
        address indexed sender,
        bytes32 indexed idHash,
        uint timestamp,
        int respondentShareProposal
    );

     
    event LogRejectedProposal(
        address indexed sender,
        bytes32 indexed idHash,
        uint timestamp,
        uint8 rejectedProposal
    );

     
    event LogSettledDispute(
        address indexed sender,
        bytes32 indexed idHash,
        uint timestamp,
        uint8 respondentShare,
        uint8 initiatorShare
    );

     
    event LogFeesUpdated(
        uint timestamp,
        uint fixedFee,
        uint8 shareFee
    );

     
    event LogProposalTimeLimitUpdated(
        uint timestamp,
        uint proposalActionTimeLimit
    );

     
    event LogWithdrawalAddressChanged(
        uint timestamp,
        address newWithdrawalAddress
    );

     
    function startDispute(bytes32 _idHash, address _respondent, int _respondentShareProposal) external;

     
    function acceptProposal(bytes32 _idHash) external;

     
    function rejectProposal(bytes32 _idHash) external;

     
    function settleDispute(bytes32 _idHash, uint _respondentShare, uint _initiatorShare) external;

     
    function getWithdrawalAddress() external view returns(address);

     
    function getFixedAndShareFees() external view returns(uint, uint8);

     
    function getTimeLimitForReplyOnProposal() external view returns(uint);

}



pragma solidity 0.4.25;




 
contract DecoProjects is DecoBaseProjectsMarketplace {
    using SafeMath for uint256;
    using ECDSA for bytes32;

     
    struct Project {
        string agreementId;
        address client;
        address maker;
        address arbiter;
        address escrowContractAddress;
        uint startDate;
        uint endDate;
        uint8 milestoneStartWindow;
        uint8 feedbackWindow;
        uint8 milestonesCount;

        uint8 customerSatisfaction;
        uint8 makerSatisfaction;

        bool agreementsEncrypted;
    }

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Proposal {
        string agreementId;
        address arbiter;
    }

    bytes32 constant private EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant private PROPOSAL_TYPEHASH = keccak256(
        "Proposal(string agreementId,address arbiter)"
    );

    bytes32 private DOMAIN_SEPARATOR;

     
    enum ProjectState { Active, Completed, Terminated }

     
    enum ScoreType { CustomerSatisfaction, MakerSatisfaction }

     
    event LogProjectStateUpdate (
        bytes32 indexed agreementHash,
        address updatedBy,
        uint timestamp,
        ProjectState state
    );

     
    event LogProjectRated (
        bytes32 indexed agreementHash,
        address indexed ratedBy,
        address indexed ratingTarget,
        uint8 rating,
        uint timestamp
    );

     
    mapping (bytes32 => Project) public projects;

     
    mapping (address => bytes32[]) public makerProjects;

     
    mapping (address => bytes32[]) public clientProjects;

     
    mapping (bytes32 => uint) public projectArbiterFixedFee;

     
    mapping (bytes32 => uint8) public projectArbiterShareFee;

     
    modifier eitherClientOrMaker(bytes32 _agreementHash) {
        Project memory project = projects[_agreementHash];
        require(
            project.client == msg.sender || project.maker == msg.sender,
            "Only project owner or maker can perform this operation."
        );
        _;
    }

     
    modifier eitherClientOrMakerOrMilestoneContract(bytes32 _agreementHash) {
        Project memory project = projects[_agreementHash];
        DecoRelay relay = DecoRelay(relayContractAddress);
        require(
            project.client == msg.sender ||
            project.maker == msg.sender ||
            relay.milestonesContractAddress() == msg.sender,
            "Only project owner or maker can perform this operation."
        );
        _;
    }

     
    modifier onlyMilestonesContract(bytes32 _agreementHash) {
        DecoRelay relay = DecoRelay(relayContractAddress);
        require(
            msg.sender == relay.milestonesContractAddress(),
            "Only milestones contract can perform this operation."
        );
        Project memory project = projects[_agreementHash];
        _;
    }

    constructor (uint256 _chainId) public {
        require(_chainId != 0, "You must specify a nonzero chainId");

        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "Deco.Network",
            version: "1",
            chainId: _chainId,
            verifyingContract: address(this)
        }));
    }

     
    function startProject(
        string _agreementId,
        address _client,
        address _arbiter,
        address _maker,
        bytes _makersSignature,
        uint8 _milestonesCount,
        uint8 _milestoneStartWindow,
        uint8 _feedbackWindow,
        bool _agreementEncrypted
    )
        external
    {
        require(msg.sender == _client, "Only the client can kick off the project.");
        require(_client != _maker, "Client can`t be a maker on her own project.");
        require(_arbiter != _maker && _arbiter != _client, "Arbiter must not be a client nor a maker.");

        require(
            isMakersSignatureValid(_maker, _makersSignature, _agreementId, _arbiter),
            "Maker should sign the hash of immutable agreement doc."
        );
        require(_milestonesCount >= 1 && _milestonesCount <= 24, "Milestones count is not in the allowed 1-24 range.");
        bytes32 hash = keccak256(_agreementId);
        require(projects[hash].client == address(0x0), "Project shouldn't exist yet.");

        saveCurrentArbitrationFees(_arbiter, hash);

        address newEscrowCloneAddress = deployEscrowClone(msg.sender);
        projects[hash] = Project(
            _agreementId,
            msg.sender,
            _maker,
            _arbiter,
            newEscrowCloneAddress,
            now,
            0,  
            _milestoneStartWindow,
            _feedbackWindow,
            _milestonesCount,
            0,  
            0,  
            _agreementEncrypted
        );
        makerProjects[_maker].push(hash);
        clientProjects[_client].push(hash);
        emit LogProjectStateUpdate(hash, msg.sender, now, ProjectState.Active);
    }

     
    function terminateProject(bytes32 _agreementHash)
        external
        eitherClientOrMakerOrMilestoneContract(_agreementHash)
    {
        Project storage project = projects[_agreementHash];
        require(project.client != address(0x0), "Only allowed for existing projects.");
        require(project.endDate == 0, "Only allowed for active projects.");
        address milestoneContractAddress = DecoRelay(relayContractAddress).milestonesContractAddress();
        if (msg.sender != milestoneContractAddress) {
            DecoMilestones milestonesContract = DecoMilestones(milestoneContractAddress);
            milestonesContract.terminateLastMilestone(_agreementHash, msg.sender);
        }

        project.endDate = now;
        emit LogProjectStateUpdate(_agreementHash, msg.sender, now, ProjectState.Terminated);
    }

     
    function completeProject(
        bytes32 _agreementHash
    )
        external
        onlyMilestonesContract(_agreementHash)
    {
        Project storage project = projects[_agreementHash];
        require(project.client != address(0x0), "Only allowed for existing projects.");
        require(project.endDate == 0, "Only allowed for active projects.");
        projects[_agreementHash].endDate = now;
        DecoMilestones milestonesContract = DecoMilestones(
            DecoRelay(relayContractAddress).milestonesContractAddress()
        );
        bool isLastMilestoneAccepted;
        uint8 milestoneNumber;
        (isLastMilestoneAccepted, milestoneNumber) = milestonesContract.isLastMilestoneAccepted(
            _agreementHash
        );
        require(
            milestoneNumber == projects[_agreementHash].milestonesCount,
            "The last milestone should be the last for that project."
        );
        require(isLastMilestoneAccepted, "Only allowed when all milestones are completed.");
        emit LogProjectStateUpdate(_agreementHash, msg.sender, now, ProjectState.Completed);
    }

     
    function rateProjectSecondParty(
        bytes32 _agreementHash,
        uint8 _rating
    )
        external
        eitherClientOrMaker(_agreementHash)
    {
        require(_rating >= 1 && _rating <= 10, "Project rating should be in the range 1-10.");
        Project storage project = projects[_agreementHash];
        require(project.endDate != 0, "Only allowed for active projects.");
        address ratingTarget;
        if (msg.sender == project.client) {
            require(project.customerSatisfaction == 0, "CSAT is allowed to provide only once.");
            project.customerSatisfaction = _rating;
            ratingTarget = project.maker;
        } else {
            require(project.makerSatisfaction == 0, "MSAT is allowed to provide only once.");
            project.makerSatisfaction = _rating;
            ratingTarget = project.client;
        }
        emit LogProjectRated(_agreementHash, msg.sender, ratingTarget, _rating, now);
    }

     
    function getProjectEscrowAddress(bytes32 _agreementHash) public view returns(address) {
        return projects[_agreementHash].escrowContractAddress;
    }

     
    function getProjectClient(bytes32 _agreementHash) public view returns(address) {
        return projects[_agreementHash].client;
    }

     
    function getProjectMaker(bytes32 _agreementHash) public view returns(address) {
        return projects[_agreementHash].maker;
    }

     
    function getProjectArbiter(bytes32 _agreementHash) public view returns(address) {
        return projects[_agreementHash].arbiter;
    }

     
    function getProjectFeedbackWindow(bytes32 _agreementHash) public view returns(uint8) {
        return projects[_agreementHash].feedbackWindow;
    }

     
    function getProjectMilestoneStartWindow(bytes32 _agreementHash) public view returns(uint8) {
        return projects[_agreementHash].milestoneStartWindow;
    }

     
    function getProjectStartDate(bytes32 _agreementHash) public view returns(uint) {
        return projects[_agreementHash].startDate;
    }

     
    function makersAverageRating(address _maker) public view returns(uint, uint) {
        return calculateScore(_maker, ScoreType.CustomerSatisfaction);
    }

     
    function clientsAverageRating(address _client) public view returns(uint, uint) {
        return calculateScore(_client, ScoreType.MakerSatisfaction);
    }

     
    function getClientProjects(address _client) public view returns(bytes32[]) {
        return clientProjects[_client];
    }

     
    function getMakerProjects(address _maker) public view returns(bytes32[]) {
        return makerProjects[_maker];
    }

     
    function checkIfProjectExists(bytes32 _agreementHash) public view returns(bool) {
        return projects[_agreementHash].client != address(0x0);
    }

     
    function getProjectEndDate(bytes32 _agreementHash) public view returns(uint) {
        return projects[_agreementHash].endDate;
    }

     
    function getProjectMilestonesCount(bytes32 _agreementHash) public view returns(uint8) {
        return projects[_agreementHash].milestonesCount;
    }

     
    function getProjectArbitrationFees(bytes32 _agreementHash) public view returns(uint, uint8) {
        return (
            projectArbiterFixedFee[_agreementHash],
            projectArbiterShareFee[_agreementHash]
        );
    }

    function getInfoForDisputeAndValidate(
        bytes32 _agreementHash,
        address _respondent,
        address _initiator,
        address _arbiter
    )
        public
        view
        returns(uint, uint8, address)
    {
        require(checkIfProjectExists(_agreementHash), "Project must exist.");
        Project memory project = projects[_agreementHash];
        address client = project.client;
        address maker = project.maker;
        require(project.arbiter == _arbiter, "Arbiter should be same as saved in project.");
        require(
            (_initiator == client && _respondent == maker) ||
            (_initiator == maker && _respondent == client),
            "Initiator and respondent must be different and equal to maker/client addresses."
        );
        (uint fixedFee, uint8 shareFee) = getProjectArbitrationFees(_agreementHash);
        return (fixedFee, shareFee, project.escrowContractAddress);
    }

     
    function saveCurrentArbitrationFees(address _arbiter, bytes32 _agreementHash) internal {
        IDecoArbitration arbitration = IDecoArbitration(_arbiter);
        uint fixedFee;
        uint8 shareFee;
        (fixedFee, shareFee) = arbitration.getFixedAndShareFees();
        projectArbiterFixedFee[_agreementHash] = fixedFee;
        projectArbiterShareFee[_agreementHash] = shareFee;
    }

     
    function calculateScore(
        address _address,
        ScoreType _scoreType
    )
        internal
        view
        returns(uint, uint)
    {
        bytes32[] memory allProjectsHashes = getProjectsByScoreType(_address, _scoreType);
        uint rating = 0;
        uint endedProjectsCount = 0;
        for (uint index = 0; index < allProjectsHashes.length; index++) {
            bytes32 agreementHash = allProjectsHashes[index];
            if (projects[agreementHash].endDate == 0) {
                continue;
            }
            uint8 score = getProjectScoreByType(agreementHash, _scoreType);
            if (score == 0) {
                continue;
            }
            endedProjectsCount++;
            rating = rating.add(score);
        }
        return (rating, endedProjectsCount);
    }

     
    function getProjectsByScoreType(address _address, ScoreType _scoreType) internal view returns(bytes32[]) {
        if (_scoreType == ScoreType.CustomerSatisfaction) {
            return makerProjects[_address];
        } else {
            return clientProjects[_address];
        }
    }

     
    function getProjectScoreByType(bytes32 _agreementHash, ScoreType _scoreType) internal view returns(uint8) {
        if (_scoreType == ScoreType.CustomerSatisfaction) {
            return projects[_agreementHash].customerSatisfaction;
        } else {
            return projects[_agreementHash].makerSatisfaction;
        }
    }

     
    function deployEscrowClone(address _newContractOwner) internal returns(address) {
        DecoRelay relay = DecoRelay(relayContractAddress);
        DecoEscrowFactory factory = DecoEscrowFactory(relay.escrowFactoryContractAddress());
        return factory.createEscrow(_newContractOwner, relay.milestonesContractAddress());
    }

     
    function isMakersSignatureValid(address _maker, bytes _signature, string _agreementId, address _arbiter) internal view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(Proposal(_agreementId, _arbiter))
        ));
        address signatureAddress = digest.recover(_signature);
        return signatureAddress == _maker;
    }

    function hash(EIP712Domain eip712Domain) internal view returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function hash(Proposal proposal) internal view returns (bytes32) {
        return keccak256(abi.encode(
            PROPOSAL_TYPEHASH,
            keccak256(bytes(proposal.agreementId)),
            proposal.arbiter
        ));
    }
}



 
contract DecoMilestones is IDecoArbitrationTarget, DecoBaseProjectsMarketplace {

    address public constant ETH_TOKEN_ADDRESS = address(0x0);

     
    struct Milestone {
        uint8 milestoneNumber;

         
        uint32 duration;

         
         
         
         
        uint32 adjustedDuration;

        uint depositAmount;
        address tokenAddress;

        uint startedTime;
        uint deliveredTime;
        uint acceptedTime;

         
        bool isOnHold;
    }

     
    enum MilestoneState { Active, Delivered, Accepted, Rejected, Terminated, Paused }

     
    mapping (bytes32 => Milestone[]) public projectMilestones;

     
    event LogMilestoneStateUpdated (
        bytes32 indexed agreementHash,
        address indexed sender,
        uint timestamp,
        uint8 milestoneNumber,
        MilestoneState indexed state
    );

    event LogMilestoneDurationAdjusted (
        bytes32 indexed agreementHash,
        address indexed sender,
        uint32 amountAdded,
        uint8 milestoneNumber
    );

     
    function startMilestone(
        bytes32 _agreementHash,
        uint _depositAmount,
        address _tokenAddress,
        uint32 _duration
    )
        external
    {
        uint8 completedMilestonesCount = uint8(projectMilestones[_agreementHash].length);
        if (completedMilestonesCount > 0) {
            Milestone memory lastMilestone = projectMilestones[_agreementHash][completedMilestonesCount - 1];
            require(lastMilestone.acceptedTime > 0, "All milestones must be accepted prior starting a new one.");
        }
        DecoProjects projectsContract = DecoProjects(
            DecoRelay(relayContractAddress).projectsContractAddress()
        );
        require(projectsContract.checkIfProjectExists(_agreementHash), "Project must exist.");
        require(
            projectsContract.getProjectClient(_agreementHash) == msg.sender,
            "Only project's client starts a miestone"
        );
        require(
            projectsContract.getProjectMilestonesCount(_agreementHash) > completedMilestonesCount,
            "Milestones count should not exceed the number configured in the project."
        );
        require(
            projectsContract.getProjectEndDate(_agreementHash) == 0,
            "Project should be active."
        );
        blockFundsInEscrow(
            projectsContract.getProjectEscrowAddress(_agreementHash),
            _depositAmount,
            _tokenAddress
        );
        uint nowTimestamp = now;
        projectMilestones[_agreementHash].push(
            Milestone(
                completedMilestonesCount + 1,
                _duration,
                _duration,
                _depositAmount,
                _tokenAddress,
                nowTimestamp,
                0,
                0,
                false
            )
        );
        emit LogMilestoneStateUpdated(
            _agreementHash,
            msg.sender,
            nowTimestamp,
            completedMilestonesCount + 1,
            MilestoneState.Active
        );
    }

     
    function deliverLastMilestone(bytes32 _agreementHash) external {
        DecoProjects projectsContract = DecoProjects(
            DecoRelay(relayContractAddress).projectsContractAddress()
        );
        require(projectsContract.checkIfProjectExists(_agreementHash), "Project must exist.");
        require(projectsContract.getProjectEndDate(_agreementHash) == 0, "Project should be active.");
        require(projectsContract.getProjectMaker(_agreementHash) == msg.sender, "Sender must be a maker.");
        uint nowTimestamp = now;
        uint8 milestonesCount = uint8(projectMilestones[_agreementHash].length);
        require(milestonesCount > 0, "There must be milestones to make a delivery.");
        Milestone storage milestone = projectMilestones[_agreementHash][milestonesCount - 1];
        require(
            milestone.startedTime > 0 && milestone.deliveredTime == 0 && milestone.acceptedTime == 0,
            "Milestone must be active, not delivered and not accepted."
        );
        require(!milestone.isOnHold, "Milestone must not be paused.");
        milestone.deliveredTime = nowTimestamp;
        emit LogMilestoneStateUpdated(
            _agreementHash,
            msg.sender,
            nowTimestamp,
            milestonesCount,
            MilestoneState.Delivered
        );
    }

     
    function acceptLastMilestone(bytes32 _agreementHash) external {
        DecoProjects projectsContract = DecoProjects(
            DecoRelay(relayContractAddress).projectsContractAddress()
        );
        require(projectsContract.checkIfProjectExists(_agreementHash), "Project must exist.");
        require(projectsContract.getProjectEndDate(_agreementHash) == 0, "Project should be active.");
        require(projectsContract.getProjectClient(_agreementHash) == msg.sender, "Sender must be a client.");
        uint8 milestonesCount = uint8(projectMilestones[_agreementHash].length);
        require(milestonesCount > 0, "There must be milestones to accept a delivery.");
        Milestone storage milestone = projectMilestones[_agreementHash][milestonesCount - 1];
        require(
            milestone.startedTime > 0 &&
            milestone.acceptedTime == 0 &&
            milestone.deliveredTime > 0 &&
            milestone.isOnHold == false,
            "Milestone should be active and delivered, but not rejected, or already accepted, or put on hold."
        );
        uint nowTimestamp = now;
        milestone.acceptedTime = nowTimestamp;
        if (projectsContract.getProjectMilestonesCount(_agreementHash) == milestonesCount) {
            projectsContract.completeProject(_agreementHash);
        }
        distributeFundsInEscrow(
            projectsContract.getProjectEscrowAddress(_agreementHash),
            projectsContract.getProjectMaker(_agreementHash),
            milestone.depositAmount,
            milestone.tokenAddress
        );
        emit LogMilestoneStateUpdated(
            _agreementHash,
            msg.sender,
            nowTimestamp,
            milestonesCount,
            MilestoneState.Accepted
        );
    }

     
    function rejectLastDeliverable(bytes32 _agreementHash) external {
        DecoProjects projectsContract = DecoProjects(
            DecoRelay(relayContractAddress).projectsContractAddress()
        );
        require(projectsContract.checkIfProjectExists(_agreementHash), "Project must exist.");
        require(projectsContract.getProjectEndDate(_agreementHash) == 0, "Project should be active.");
        require(projectsContract.getProjectClient(_agreementHash) == msg.sender, "Sender must be a client.");
        uint8 milestonesCount = uint8(projectMilestones[_agreementHash].length);
        require(milestonesCount > 0, "There must be milestones to reject a delivery.");
        Milestone storage milestone = projectMilestones[_agreementHash][milestonesCount - 1];
        require(
            milestone.startedTime > 0 &&
            milestone.acceptedTime == 0 &&
            milestone.deliveredTime > 0 &&
            milestone.isOnHold == false,
            "Milestone should be active and delivered, but not rejected, or already accepted, or on hold."
        );
        uint nowTimestamp = now;
        if (milestone.startedTime.add(milestone.adjustedDuration) > milestone.deliveredTime) {
            uint32 timeToAdd = uint32(nowTimestamp.sub(milestone.deliveredTime));
            milestone.adjustedDuration += timeToAdd;
            emit LogMilestoneDurationAdjusted (
                _agreementHash,
                msg.sender,
                timeToAdd,
                milestonesCount
            );
        }
        milestone.deliveredTime = 0;
        emit LogMilestoneStateUpdated(
            _agreementHash,
            msg.sender,
            nowTimestamp,
            milestonesCount,
            MilestoneState.Rejected
        );
    }

     
    function disputeStartedFreeze(bytes32 _idHash) public {
        address projectsContractAddress = DecoRelay(relayContractAddress).projectsContractAddress();
        DecoProjects projectsContract = DecoProjects(projectsContractAddress);
        require(
            projectsContract.getProjectArbiter(_idHash) == msg.sender,
            "Freezing upon dispute start can be sent only by arbiter."
        );
        uint milestonesCount = projectMilestones[_idHash].length;
        require(milestonesCount > 0, "There must be active milestone.");
        Milestone storage lastMilestone = projectMilestones[_idHash][milestonesCount - 1];
        lastMilestone.isOnHold = true;
        emit LogMilestoneStateUpdated(
            _idHash,
            msg.sender,
            now,
            uint8(milestonesCount),
            MilestoneState.Paused
        );
    }

     
    function disputeSettledTerminate(
        bytes32 _idHash,
        address _respondent,
        uint8 _respondentShare,
        address _initiator,
        uint8 _initiatorShare,
        bool _isInternal,
        address _arbiterWithdrawalAddress
    )
        public
    {
        uint milestonesCount = projectMilestones[_idHash].length;
        require(milestonesCount > 0, "There must be at least one milestone.");
        Milestone memory lastMilestone = projectMilestones[_idHash][milestonesCount - 1];
        require(lastMilestone.isOnHold, "Last milestone must be on hold.");
        require(uint(_respondentShare).add(uint(_initiatorShare)) == 100, "Shares must be 100% in sum.");
        DecoProjects projectsContract = DecoProjects(
            DecoRelay(relayContractAddress).projectsContractAddress()
        );
        (
            uint fixedFee,
            uint8 shareFee,
            address escrowAddress
        ) = projectsContract.getInfoForDisputeAndValidate (
            _idHash,
            _respondent,
            _initiator,
            msg.sender
        );
        distributeDisputeFunds(
            escrowAddress,
            lastMilestone.tokenAddress,
            _respondent,
            _initiator,
            _initiatorShare,
            _isInternal,
            _arbiterWithdrawalAddress,
            lastMilestone.depositAmount,
            fixedFee,
            shareFee
        );
        projectsContract.terminateProject(_idHash);
        emit LogMilestoneStateUpdated(
            _idHash,
            msg.sender,
            now,
            uint8(milestonesCount),
            MilestoneState.Terminated
        );
    }

     
    function checkEligibility(bytes32 _idHash, address _addressToCheck) public view returns(bool) {
        address projectsContractAddress = DecoRelay(relayContractAddress).projectsContractAddress();
        DecoProjects projectsContract = DecoProjects(projectsContractAddress);
        return _addressToCheck == projectsContract.getProjectClient(_idHash) ||
            _addressToCheck == projectsContract.getProjectMaker(_idHash);
    }

     
    function canStartDispute(bytes32 _idHash) public view returns(bool) {
        uint milestonesCount = projectMilestones[_idHash].length;
        if (milestonesCount == 0)
            return false;
        Milestone memory lastMilestone = projectMilestones[_idHash][milestonesCount - 1];
        if (lastMilestone.isOnHold || lastMilestone.acceptedTime > 0)
            return false;
        address projectsContractAddress = DecoRelay(relayContractAddress).projectsContractAddress();
        DecoProjects projectsContract = DecoProjects(projectsContractAddress);
        uint feedbackWindow = uint(projectsContract.getProjectFeedbackWindow(_idHash)).mul(24 hours);
        uint nowTimestamp = now;
        uint plannedDeliveryTime = lastMilestone.startedTime.add(uint(lastMilestone.adjustedDuration));
        if (plannedDeliveryTime < lastMilestone.deliveredTime || plannedDeliveryTime < nowTimestamp) {
            return false;
        }
        if (lastMilestone.deliveredTime > 0 &&
            lastMilestone.deliveredTime.add(feedbackWindow) < nowTimestamp)
            return false;
        return true;
    }

     
    function terminateLastMilestone(bytes32 _agreementHash, address _initiator) public {
        address projectsContractAddress = DecoRelay(relayContractAddress).projectsContractAddress();
        require(msg.sender == projectsContractAddress, "Method should be called by Project contract.");
        DecoProjects projectsContract = DecoProjects(projectsContractAddress);
        require(projectsContract.checkIfProjectExists(_agreementHash), "Project must exist.");
        address projectClient = projectsContract.getProjectClient(_agreementHash);
        address projectMaker = projectsContract.getProjectMaker(_agreementHash);
        require(
            _initiator == projectClient ||
            _initiator == projectMaker,
            "Initiator should be either maker or client address."
        );
        if (_initiator == projectClient) {
            require(canClientTerminate(_agreementHash));
        } else {
            require(canMakerTerminate(_agreementHash));
        }
        uint milestonesCount = projectMilestones[_agreementHash].length;
        if (milestonesCount == 0) return;
        Milestone memory lastMilestone = projectMilestones[_agreementHash][milestonesCount - 1];
        if (lastMilestone.acceptedTime > 0) return;
        address projectEscrowContractAddress = projectsContract.getProjectEscrowAddress(_agreementHash);
        if (_initiator == projectClient) {
            unblockFundsInEscrow(
                projectEscrowContractAddress,
                lastMilestone.depositAmount,
                lastMilestone.tokenAddress
            );
        } else {
            distributeFundsInEscrow(
                projectEscrowContractAddress,
                _initiator,
                lastMilestone.depositAmount,
                lastMilestone.tokenAddress
            );
        }
        emit LogMilestoneStateUpdated(
            _agreementHash,
            msg.sender,
            now,
            uint8(milestonesCount),
            MilestoneState.Terminated
        );
    }

     
    function isLastMilestoneAccepted(
        bytes32 _agreementHash
    )
        public
        view
        returns(bool isAccepted, uint8 milestoneNumber)
    {
        milestoneNumber = uint8(projectMilestones[_agreementHash].length);
        if (milestoneNumber > 0) {
            isAccepted = projectMilestones[_agreementHash][milestoneNumber - 1].acceptedTime > 0;
        } else {
            isAccepted = false;
        }
    }

     
    function canClientTerminate(bytes32 _agreementHash) public view returns(bool) {
        uint milestonesCount = projectMilestones[_agreementHash].length;
        if (milestonesCount == 0) return false;
        Milestone memory lastMilestone = projectMilestones[_agreementHash][milestonesCount - 1];
        return lastMilestone.acceptedTime == 0 &&
            !lastMilestone.isOnHold &&
            lastMilestone.startedTime.add(uint(lastMilestone.adjustedDuration)) < now;
    }

     
    function canMakerTerminate(bytes32 _agreementHash) public view returns(bool) {
        address projectsContractAddress = DecoRelay(relayContractAddress).projectsContractAddress();
        DecoProjects projectsContract = DecoProjects(projectsContractAddress);
        uint feedbackWindow = uint(projectsContract.getProjectFeedbackWindow(_agreementHash)).mul(24 hours);
        uint milestoneStartWindow = uint(projectsContract.getProjectMilestoneStartWindow(
            _agreementHash
        )).mul(24 hours);
        uint projectStartDate = projectsContract.getProjectStartDate(_agreementHash);
        uint milestonesCount = projectMilestones[_agreementHash].length;
        if (milestonesCount == 0) return now.sub(projectStartDate) > milestoneStartWindow;
        Milestone memory lastMilestone = projectMilestones[_agreementHash][milestonesCount - 1];
        uint nowTimestamp = now;
        if (!lastMilestone.isOnHold &&
            lastMilestone.acceptedTime > 0 &&
            nowTimestamp.sub(lastMilestone.acceptedTime) > milestoneStartWindow)
            return true;
        return !lastMilestone.isOnHold &&
            lastMilestone.acceptedTime == 0 &&
            lastMilestone.deliveredTime > 0 &&
            nowTimestamp.sub(feedbackWindow) > lastMilestone.deliveredTime;
    }

     
    function blockFundsInEscrow(
        address _projectEscrowContractAddress,
        uint _amount,
        address _tokenAddress
    )
        internal
    {
        if (_amount == 0) return;
        DecoEscrow escrow = DecoEscrow(_projectEscrowContractAddress);
        if (_tokenAddress == ETH_TOKEN_ADDRESS) {
            escrow.blockFunds(_amount);
        } else {
            escrow.blockTokenFunds(_tokenAddress, _amount);
        }
    }

     
    function unblockFundsInEscrow(
        address _projectEscrowContractAddress,
        uint _amount,
        address _tokenAddress
    )
        internal
    {
        if (_amount == 0) return;
        DecoEscrow escrow = DecoEscrow(_projectEscrowContractAddress);
        if (_tokenAddress == ETH_TOKEN_ADDRESS) {
            escrow.unblockFunds(_amount);
        } else {
            escrow.unblockTokenFunds(_tokenAddress, _amount);
        }
    }

     
    function distributeFundsInEscrow(
        address _projectEscrowContractAddress,
        address _distributionTargetAddress,
        uint _amount,
        address _tokenAddress
    )
        internal
    {
        if (_amount == 0) return;
        DecoEscrow escrow = DecoEscrow(_projectEscrowContractAddress);
        if (_tokenAddress == ETH_TOKEN_ADDRESS) {
            escrow.distributeFunds(_distributionTargetAddress, _amount);
        } else {
            escrow.distributeTokenFunds(_distributionTargetAddress, _tokenAddress, _amount);
        }
    }

     
    function distributeDisputeFunds(
        address _projectEscrowContractAddress,
        address _tokenAddress,
        address _respondent,
        address _initiator,
        uint8 _initiatorShare,
        bool _isInternal,
        address _arbiterWithdrawalAddress,
        uint _amount,
        uint _fixedFee,
        uint8 _shareFee
    )
        internal
    {
        if (!_isInternal && _arbiterWithdrawalAddress != address(0x0)) {
            uint arbiterFee = getArbiterFeeAmount(_fixedFee, _shareFee, _amount, _tokenAddress);
            distributeFundsInEscrow(
                _projectEscrowContractAddress,
                _arbiterWithdrawalAddress,
                arbiterFee,
                _tokenAddress
            );
            _amount = _amount.sub(arbiterFee);
        }
        uint initiatorAmount = _amount.mul(_initiatorShare).div(100);
        distributeFundsInEscrow(
            _projectEscrowContractAddress,
            _initiator,
            initiatorAmount,
            _tokenAddress
        );
        distributeFundsInEscrow(
            _projectEscrowContractAddress,
            _respondent,
            _amount.sub(initiatorAmount),
            _tokenAddress
        );
    }

     
    function getArbiterFeeAmount(uint _fixedFee, uint8 _shareFee, uint _amount, address _tokenAddress)
        internal
        pure
        returns(uint)
    {
        if (_tokenAddress != ETH_TOKEN_ADDRESS) {
            _fixedFee = 0;
        }
        return _amount.sub(_fixedFee).mul(uint(_shareFee)).div(100).add(_fixedFee);
    }
}

contract DecoProxy {
    using ECDSA for bytes32;

     
    event Received (address indexed sender, uint value);

     
    event Forwarded (
        bytes signature,
        address indexed signer,
        address indexed destination,
        uint value,
        bytes data,
        bytes32 _hash
    );

     
    event OwnerChanged (
        address indexed newOwner
    );

    bool internal isInitialized;

     
    uint public nonce;

     
    address public owner;


     
    function initialize(address _owner) public {
        require(!isInitialized, "Clone must be initialized only once.");
        isInitialized = true;
        owner = _owner;
    }

     
    function () external payable {
        emit Received(msg.sender, msg.value);
    }

     
    function changeOwner(address _newOwner) public {
        require(owner == msg.sender || address(this) == msg.sender, "Only owner can change owner");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

     
    function forwardFromOwner(address _destination, uint _value, bytes memory _data) public {
        require(owner == msg.sender, "Only owner can use forwardFromOwner method");
        require(executeCall(_destination, _value, _data), "Call must be successfull.");
        emit Forwarded("", owner, _destination, _value, _data, "");
    }

     
    function getHash(
        address _signer,
        address _destination,
        uint _value,
        bytes memory _data
    )
        public
        view
        returns(bytes32)
    {
        return keccak256(abi.encodePacked(address(this), _signer, _destination, _value, _data, nonce));
    }

     
    function forward(bytes memory _signature, address _signer, address _destination, uint _value, bytes memory _data) public {
        bytes32 hash = getHash(_signer, _destination, _value, _data);
        nonce++;
        require(owner == hash.toEthSignedMessageHash().recover(_signature), "Signer must be owner.");
        require(executeCall(_destination, _value, _data), "Call must be successfull.");
        emit Forwarded(_signature, _signer, _destination, _value, _data, hash);
    }

     
    function withdraw(address _to, uint _value) public {
        require(owner == msg.sender || address(this) == msg.sender, "Only owner can withdraw");
        _to.transfer(_value);
    }

     
    function withdrawERC20Token(address _tokenAddress, address _to, uint _tokens) public {
        require(owner == msg.sender || address(this) == msg.sender, "Only owner can withdraw");
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(_to, _tokens), "Tokens transfer must complete successfully.");
    }

     
    function executeCall(address _to, uint256 _value, bytes memory _data) internal returns (bool success) {
        assembly {
            let x := mload(0x40)
            success := call(gas, _to, _value, add(_data, 0x20), mload(_data), 0, 0)
        }
    }
}


contract DecoProxyFactory is DecoBaseProjectsMarketplace, CloneFactory {

     
    address public libraryAddress;

     
    event ProxyCreated(address newProxyAddress);

     
    constructor(address _libraryAddress) public {
        libraryAddress = _libraryAddress;
    }

     
    function setLibraryAddress(address _libraryAddress) external onlyOwner {
        require(libraryAddress != _libraryAddress);
        require(_libraryAddress != address(0x0));

        libraryAddress = _libraryAddress;
    }

     
    function createProxy(
        address _ownerAddress
    )
        external
        returns(address)
    {
        address clone = createClone(libraryAddress);
        DecoProxy(clone).initialize(
            _ownerAddress
        );
        emit ProxyCreated(clone);
        return clone;
    }
}

 
contract DecoArbitration is IDecoArbitration, DecoBaseProjectsMarketplace {
    using SafeMath for uint256;

     
    struct Dispute {
        address initiator;
        address respondent;
        uint startedTime;
        uint settledTime;
        uint8 respondentShare;
        uint8 initiatorShare;
    }

     
    address public withdrawalAddress;

     
    uint public fixedFee;

     
    uint8 public shareFee;

     
    uint public timeLimitForReplyOnProposal;

     
    mapping (bytes32 => Dispute) public disputes;

     
    function startDispute(bytes32 _idHash, address _respondent, int _respondentShareProposal) external {
        require(disputes[_idHash].startedTime == 0, "Dispute shouldn't be started yet.");
        require(msg.sender != _respondent, "Dispute initiator must not be a respondent.");
        IDecoArbitrationTarget target = IDecoArbitrationTarget(getTargetContractAddress());
        require(target.canStartDispute(_idHash), "Target should confirm its state to be ready for dispute.");
        require(target.checkEligibility(_idHash, msg.sender), "Check if sender is eligible to perform actions.");
        require(target.checkEligibility(_idHash, _respondent), "Check if respondent is eligible to perform actions.");
        uint8 uRespondentShareProposal;
        uint8 uInitiatorShareProposal;
        if (_respondentShareProposal < 0 || _respondentShareProposal > 100) {
            uRespondentShareProposal = 0;
            uInitiatorShareProposal = 0;
        } else {
            uRespondentShareProposal = uint8(_respondentShareProposal);
            uInitiatorShareProposal = 100 - uRespondentShareProposal;
        }
        uint nowTimestamp = now;
        disputes[_idHash] = Dispute(
            msg.sender,
            _respondent,
            nowTimestamp,
            0,
            uRespondentShareProposal,
            uInitiatorShareProposal
        );

        emit LogStartedDispute(msg.sender, _idHash, nowTimestamp, _respondentShareProposal);

        if (uRespondentShareProposal == 100) {
            this.settleDispute(_idHash, uRespondentShareProposal, uInitiatorShareProposal);
        } else {
            target.disputeStartedFreeze(_idHash);
        }
    }

     
    function acceptProposal(bytes32 _idHash) external {
        Dispute memory dispute = disputes[_idHash];
        require(msg.sender == dispute.respondent, "Proposal can be accepted only by a respondent.");
        this.settleDispute(
            _idHash,
            disputes[_idHash].respondentShare,
            disputes[_idHash].initiatorShare
        );
    }

     
    function rejectProposal(bytes32 _idHash) external {
        Dispute storage dispute = disputes[_idHash];
        require(msg.sender == dispute.respondent, "Proposal can be rejected only by a respondent.");
        uint nowTime = now;
        require(
            dispute.startedTime.add(timeLimitForReplyOnProposal) > nowTime,
            "Respondent should reject within a limited timeframe after the dispute with proposal started."
        );
        uint8 respondentShare = dispute.respondentShare;
        dispute.respondentShare = 0;
        dispute.initiatorShare = 0;
        emit LogRejectedProposal(msg.sender, _idHash, nowTime, respondentShare);
    }

     
    function settleDispute(bytes32 _idHash, uint _respondentShare, uint _initiatorShare) external {
        require(
            msg.sender == address(this) || isOwner(),
            "Settle dispute must be perfomed by this contract or arbiter(contract owner)."
        );
        Dispute storage dispute = disputes[_idHash];
        require(dispute.startedTime != 0, "Dispute must exist.");
        require(dispute.settledTime == 0, "Dispute must be active.");
        uint nowTime = now;

        require(
            canBeSettledByArbiter(_idHash) ||
            canBeSettledWithAcceptedProposal(_idHash, _respondentShare, _initiatorShare),
            "Should be called by this contract(aka accepted proposal) on time, or arbiter outside time limits."
        );
        require(_respondentShare.add(_initiatorShare) == 100, "Sum must be 100%");
        dispute.respondentShare = uint8(_respondentShare);
        dispute.initiatorShare = uint8(_initiatorShare);
        dispute.settledTime = nowTime;
        IDecoArbitrationTarget target = IDecoArbitrationTarget(getTargetContractAddress());
        target.disputeSettledTerminate(
            _idHash,
            dispute.respondent,
            dispute.respondentShare,
            dispute.initiator,
            dispute.initiatorShare,
            msg.sender == address(this),  
            this.getWithdrawalAddress()
        );
        emit LogSettledDispute(msg.sender, _idHash, nowTime, dispute.respondentShare, dispute.initiatorShare);
    }

     
    function setWithdrawalAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Should be not 0 address.");
        withdrawalAddress = _newAddress;
        emit LogWithdrawalAddressChanged(now, _newAddress);
    }

     
    function setRelayContractAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0x0), "Should be not 0 address.");
        relayContractAddress = _newAddress;
    }

     
    function setTimeLimitForReplyOnProposal(uint _newLimit) external onlyOwner {
        timeLimitForReplyOnProposal = _newLimit;
        emit LogProposalTimeLimitUpdated(now, timeLimitForReplyOnProposal);
    }

     
    function setFees(uint _fixedFee, uint _shareFee) external onlyOwner {
        fixedFee = _fixedFee;
        require(
            _shareFee <= 100,
            "Share fee should be in 0-100% range."
        );
        shareFee = uint8(_shareFee);
        emit LogFeesUpdated(now, fixedFee, shareFee);
    }

     
    function getTimeLimitForReplyOnProposal() external view returns(uint) {
        return timeLimitForReplyOnProposal;
    }

     
    function getWithdrawalAddress() external view returns(address) {
        return withdrawalAddress;
    }

     
    function getFixedAndShareFees() external view returns(uint, uint8) {
        return (fixedFee, shareFee);
    }

     
    function getDisputeProposalShare(bytes32 _idHash) public view returns(uint8) {
        return disputes[_idHash].respondentShare;
    }

     
    function getDisputeInitiatorShare(bytes32 _idHash) public view returns(uint8) {
        return disputes[_idHash].initiatorShare;
    }

     
    function getDisputeInitiator(bytes32 _idHash) public view returns(address) {
        return disputes[_idHash].initiator;
    }

     
    function getDisputeRespondent(bytes32 _idHash) public view returns(address) {
        return disputes[_idHash].respondent;
    }

     
    function getDisputeStartedStatus(bytes32 _idHash) public view returns(bool) {
        return disputes[_idHash].startedTime != 0;
    }

     
    function getDisputeStartTime(bytes32 _idHash) public view returns(uint) {
        return disputes[_idHash].startedTime;
    }

     
    function getDisputeSettledStatus(bytes32 _idHash) public view returns(bool) {
        return disputes[_idHash].settledTime != 0;
    }

     
    function getDisputeSettlementTime(bytes32 _idHash) public view returns(uint) {
        return disputes[_idHash].settledTime;
    }

     
    function getTargetContractAddress() internal view returns(address) {
        return DecoRelay(relayContractAddress).milestonesContractAddress();
    }

     
    function canBeSettledWithAcceptedProposal(
        bytes32 _idHash,
        uint _respondentShare,
        uint _initiatorShare
    )
        internal
        view
        returns(bool)
    {
        Dispute memory dispute = disputes[_idHash];
         
        return msg.sender == address(this) &&
             
            dispute.startedTime.add(timeLimitForReplyOnProposal) >= now &&
             
            dispute.respondentShare == _respondentShare && dispute.initiatorShare == _initiatorShare;
    }

     
    function canBeSettledByArbiter(bytes32 _idHash) internal view returns(bool) {
        Dispute memory dispute = disputes[_idHash];
        uint8 sum = dispute.respondentShare + dispute.initiatorShare;
         
        return isOwner() &&
             
            (sum == 0 ||
             
            (sum == 100 && dispute.startedTime.add(timeLimitForReplyOnProposal) < now));
    }
}