 

pragma solidity ^0.4.13;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Fysical is StandardToken {
    using SafeMath for uint256;

     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
     
     
     
    struct Uri {
        string value;
    }

     
    struct UriSet {
        uint256[] uniqueUriIdsSortedAscending;     
    }

     
     
     
    struct ChecksumAlgorithm {
        uint256 descriptionUriSetId;     
    }

     
     
     
     
    struct Checksum {
        uint256 algorithmId;  
        uint256 resourceByteCount;
        bytes value;
    }

     
     
     
    struct EncryptionAlgorithm {
        uint256 descriptionUriSetId;     
    }

     
     
     
     
    struct ChecksumPair {
        uint256 encryptedChecksumId;  
        uint256 decryptedChecksumId;  
    }

     
     
     
     
     
     
     
    struct Resource {
        uint256 uriSetId;                 
        uint256 encryptionAlgorithmId;    
        uint256 metaResourceSetId;        
    }

     
     
     
    struct PublicKey {
        bytes value;
    }

     
     
     
     
     
     
     
     
     
     
     
    struct ResourceSet {
        address creator;
        uint256 creatorPublicKeyId;                      
        uint256 proposalEncryptionAlgorithmId;           
        uint256[] uniqueResourceIdsSortedAscending;      
        uint256 metaResourceSetId;                       
    }

     
     
     
     
    struct Agreement {
        uint256 uriSetId;            
        uint256 checksumPairId;      
    }

     
    struct AgreementSet {
        uint256[] uniqueAgreementIdsSortedAscending;  
    }

     
    struct TokenTransfer {
        address source;
        address destination;
        uint256 tokenCount;
    }

     
    struct TokenTransferSet {
        uint256[] uniqueTokenTransferIdsSortedAscending;  
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    struct Proposal {
        uint256 minimumBlockNumberForWithdrawal;
        address creator;
        uint256 creatorPublicKeyId;                  
        uint256 acceptanceEncryptionAlgorithmId;     
        uint256 resourceSetId;                       
        uint256 agreementSetId;                      
        uint256 tokenTransferSetId;                  
    }

     
     
    enum ProposalState {
        Pending,
        WithdrawnByCreator,
        RejectedByResourceSetCreator,
        AcceptedByResourceSetCreator
    }

     
     
     
     
    string public constant name = "Fysical";

     
     
     
     
    string public constant symbol = "FYS";

     
     
     
     
    uint8 public constant decimals = 9;

    uint256 public constant ONE_BILLION = 1000000000;
    uint256 public constant ONE_QUINTILLION = 1000000000000000000;

     
    uint256 public constant MAXIMUM_64_BIT_SIGNED_INTEGER_VALUE = 9223372036854775807;

    uint256 public constant EMPTY_PUBLIC_KEY_ID = 0;
    uint256 public constant NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_ID = 0;
    uint256 public constant NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_SET_ID = 0;
    uint256 public constant NULL_ENCRYPTION_ALGORITHM_ID = 0;
    uint256 public constant EMPTY_RESOURCE_SET_ID = 0;

    mapping(uint256 => Uri) internal urisById;
    uint256 internal uriCount = 0;

    mapping(uint256 => UriSet) internal uriSetsById;
    uint256 internal uriSetCount = 0;

    mapping(uint256 => ChecksumAlgorithm) internal checksumAlgorithmsById;
    uint256 internal checksumAlgorithmCount = 0;

    mapping(uint256 => Checksum) internal checksumsById;
    uint256 internal checksumCount = 0;

    mapping(uint256 => EncryptionAlgorithm) internal encryptionAlgorithmsById;
    uint256 internal encryptionAlgorithmCount = 0;

    mapping(uint256 => ChecksumPair) internal checksumPairsById;
    uint256 internal checksumPairCount = 0;

    mapping(uint256 => Resource) internal resourcesById;
    uint256 internal resourceCount = 0;

    mapping(uint256 => PublicKey) internal publicKeysById;
    uint256 internal publicKeyCount = 0;

    mapping(uint256 => ResourceSet) internal resourceSetsById;
    uint256 internal resourceSetCount = 0;

    mapping(uint256 => Agreement) internal agreementsById;
    uint256 internal agreementCount = 0;

    mapping(uint256 => AgreementSet) internal agreementSetsById;
    uint256 internal agreementSetCount = 0;

    mapping(uint256 => TokenTransfer) internal tokenTransfersById;
    uint256 internal tokenTransferCount = 0;

    mapping(uint256 => TokenTransferSet) internal tokenTransferSetsById;
    uint256 internal tokenTransferSetCount = 0;

    mapping(uint256 => Proposal) internal proposalsById;
    uint256 internal proposalCount = 0;

    mapping(uint256 => ProposalState) internal statesByProposalId;

    mapping(uint256 => mapping(uint256 => bytes)) internal encryptedDecryptionKeysByProposalIdAndResourceId;

    mapping(address => mapping(uint256 => bool)) internal checksumPairAssignmentsByCreatorAndResourceId;

    mapping(address => mapping(uint256 => uint256)) internal checksumPairIdsByCreatorAndResourceId;

    function Fysical() public {
        assert(ProposalState(0) == ProposalState.Pending);

         
         
         
         
         

        assert(0 < ONE_BILLION);
        assert(0 < ONE_QUINTILLION);
        assert(MAXIMUM_64_BIT_SIGNED_INTEGER_VALUE > ONE_BILLION);
        assert(MAXIMUM_64_BIT_SIGNED_INTEGER_VALUE > ONE_QUINTILLION);
        assert(ONE_BILLION == uint256(10)**decimals);
        assert(ONE_QUINTILLION == ONE_BILLION.mul(ONE_BILLION));

        totalSupply_ = ONE_QUINTILLION;

        balances[msg.sender] = totalSupply_;

         
         
        Transfer(0x0, msg.sender, balances[msg.sender]);

         
        assert(EMPTY_PUBLIC_KEY_ID == publicKeyCount);
        publicKeysById[EMPTY_PUBLIC_KEY_ID] = PublicKey(new bytes(0));
        publicKeyCount = publicKeyCount.add(1);
        assert(1 == publicKeyCount);

         
        assert(NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_ID == uriCount);
        urisById[NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_ID] = Uri("https://en.wikipedia.org/wiki/Null_encryption");
        uriCount = uriCount.add(1);
        assert(1 == uriCount);

         
        assert(NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_SET_ID == uriSetCount);
        uint256[] memory uniqueIdsSortedAscending = new uint256[](1);
        uniqueIdsSortedAscending[0] = NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_ID;
        validateIdSet(uniqueIdsSortedAscending, uriCount);
        uriSetsById[NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_SET_ID] = UriSet(uniqueIdsSortedAscending);
        uriSetCount = uriSetCount.add(1);
        assert(1 == uriSetCount);

         
        assert(NULL_ENCRYPTION_ALGORITHM_ID == encryptionAlgorithmCount);
        encryptionAlgorithmsById[NULL_ENCRYPTION_ALGORITHM_ID] = EncryptionAlgorithm(NULL_ENCRYPTION_ALGORITHM_DESCRIPTION_URI_SET_ID);
        encryptionAlgorithmCount = encryptionAlgorithmCount.add(1);
        assert(1 == encryptionAlgorithmCount);

         
         
        assert(EMPTY_RESOURCE_SET_ID == resourceSetCount);
        resourceSetsById[EMPTY_RESOURCE_SET_ID] = ResourceSet(
            msg.sender,
            EMPTY_PUBLIC_KEY_ID,
            NULL_ENCRYPTION_ALGORITHM_ID,
            new uint256[](0),
            EMPTY_RESOURCE_SET_ID
        );
        resourceSetCount = resourceSetCount.add(1);
        assert(1 == resourceSetCount);
    }

    function getUriCount() external view returns (uint256) {
        return uriCount;
    }

    function getUriById(uint256 id) external view returns (string) {
        require(id < uriCount);

        Uri memory object = urisById[id];
        return object.value;
    }

    function getUriSetCount() external view returns (uint256) {
        return uriSetCount;
    }

    function getUriSetById(uint256 id) external view returns (uint256[]) {
        require(id < uriSetCount);

        UriSet memory object = uriSetsById[id];
        return object.uniqueUriIdsSortedAscending;
    }

    function getChecksumAlgorithmCount() external view returns (uint256) {
        return checksumAlgorithmCount;
    }

    function getChecksumAlgorithmById(uint256 id) external view returns (uint256) {
        require(id < checksumAlgorithmCount);

        ChecksumAlgorithm memory object = checksumAlgorithmsById[id];
        return object.descriptionUriSetId;
    }

    function getChecksumCount() external view returns (uint256) {
        return checksumCount;
    }

    function getChecksumById(uint256 id) external view returns (uint256, uint256, bytes) {
        require(id < checksumCount);

        Checksum memory object = checksumsById[id];
        return (object.algorithmId, object.resourceByteCount, object.value);
    }

    function getEncryptionAlgorithmCount() external view returns (uint256) {
        return encryptionAlgorithmCount;
    }

    function getEncryptionAlgorithmById(uint256 id) external view returns (uint256) {
        require(id < encryptionAlgorithmCount);

        EncryptionAlgorithm memory object = encryptionAlgorithmsById[id];
        return object.descriptionUriSetId;
    }

    function getChecksumPairCount() external view returns (uint256) {
        return checksumPairCount;
    }

    function getChecksumPairById(uint256 id) external view returns (uint256, uint256) {
        require(id < checksumPairCount);

        ChecksumPair memory object = checksumPairsById[id];
        return (object.encryptedChecksumId, object.decryptedChecksumId);
    }

    function getResourceCount() external view returns (uint256) {
        return resourceCount;
    }

    function getResourceById(uint256 id) external view returns (uint256, uint256, uint256) {
        require(id < resourceCount);

        Resource memory object = resourcesById[id];
        return (object.uriSetId, object.encryptionAlgorithmId, object.metaResourceSetId);
    }

    function getPublicKeyCount() external view returns (uint256) {
        return publicKeyCount;
    }

    function getPublicKeyById(uint256 id) external view returns (bytes) {
        require(id < publicKeyCount);

        PublicKey memory object = publicKeysById[id];
        return object.value;
    }

    function getResourceSetCount() external view returns (uint256) {
        return resourceSetCount;
    }

    function getResourceSetById(uint256 id) external view returns (address, uint256, uint256, uint256[], uint256) {
        require(id < resourceSetCount);

        ResourceSet memory object = resourceSetsById[id];
        return (object.creator, object.creatorPublicKeyId, object.proposalEncryptionAlgorithmId, object.uniqueResourceIdsSortedAscending, object.metaResourceSetId);
    }

    function getAgreementCount() external view returns (uint256) {
        return agreementCount;
    }

    function getAgreementById(uint256 id) external view returns (uint256, uint256) {
        require(id < agreementCount);

        Agreement memory object = agreementsById[id];
        return (object.uriSetId, object.checksumPairId);
    }

    function getAgreementSetCount() external view returns (uint256) {
        return agreementSetCount;
    }

    function getAgreementSetById(uint256 id) external view returns (uint256[]) {
        require(id < agreementSetCount);

        AgreementSet memory object = agreementSetsById[id];
        return object.uniqueAgreementIdsSortedAscending;
    }

    function getTokenTransferCount() external view returns (uint256) {
        return tokenTransferCount;
    }

    function getTokenTransferById(uint256 id) external view returns (address, address, uint256) {
        require(id < tokenTransferCount);

        TokenTransfer memory object = tokenTransfersById[id];
        return (object.source, object.destination, object.tokenCount);
    }

    function getTokenTransferSetCount() external view returns (uint256) {
        return tokenTransferSetCount;
    }

    function getTokenTransferSetById(uint256 id) external view returns (uint256[]) {
        require(id < tokenTransferSetCount);

        TokenTransferSet memory object = tokenTransferSetsById[id];
        return object.uniqueTokenTransferIdsSortedAscending;
    }

    function getProposalCount() external view returns (uint256) {
        return proposalCount;
    }

    function getProposalById(uint256 id) external view returns (uint256, address, uint256, uint256, uint256, uint256, uint256) {
        require(id < proposalCount);

        Proposal memory object = proposalsById[id];
        return (object.minimumBlockNumberForWithdrawal, object.creator, object.creatorPublicKeyId, object.acceptanceEncryptionAlgorithmId, object.resourceSetId, object.agreementSetId, object.tokenTransferSetId);
    }

    function getStateByProposalId(uint256 proposalId) external view returns (ProposalState) {
        require(proposalId < proposalCount);

        return statesByProposalId[proposalId];
    }

     
    function hasAddressAssignedResourceChecksumPair(address address_, uint256 resourceId) external view returns (bool) {
        require(resourceId < resourceCount);

        return checksumPairAssignmentsByCreatorAndResourceId[address_][resourceId];
    }

     
    function getChecksumPairIdByAssignerAndResourceId(address assigner, uint256 resourceId) external view returns (uint256) {
        require(resourceId < resourceCount);
        require(checksumPairAssignmentsByCreatorAndResourceId[assigner][resourceId]);

        return checksumPairIdsByCreatorAndResourceId[assigner][resourceId];
    }

     
    function getEncryptedResourceDecryptionKey(uint256 proposalId, uint256 resourceId) external view returns (bytes) {
        require(proposalId < proposalCount);
        require(ProposalState.AcceptedByResourceSetCreator == statesByProposalId[proposalId]);
        require(resourceId < resourceCount);

        uint256[] memory validResourceIds = resourceSetsById[proposalsById[proposalId].resourceSetId].uniqueResourceIdsSortedAscending;
        require(0 < validResourceIds.length);

        if (1 == validResourceIds.length) {
            require(resourceId == validResourceIds[0]);

        } else {
            uint256 lowIndex = 0;
            uint256 highIndex = validResourceIds.length.sub(1);
            uint256 middleIndex = lowIndex.add(highIndex).div(2);

            while (resourceId != validResourceIds[middleIndex]) {
                require(lowIndex <= highIndex);

                if (validResourceIds[middleIndex] < resourceId) {
                    lowIndex = middleIndex.add(1);
                } else {
                    highIndex = middleIndex.sub(1);
                }

                middleIndex = lowIndex.add(highIndex).div(2);
            }
        }

        return encryptedDecryptionKeysByProposalIdAndResourceId[proposalId][resourceId];
    }

    function createUri(
        string value
    ) external returns (uint256)
    {
        require(0 < bytes(value).length);

        uint256 id = uriCount;
        uriCount = id.add(1);
        urisById[id] = Uri(
            value
        );

        return id;
    }

    function createUriSet(
        uint256[] uniqueUriIdsSortedAscending
    ) external returns (uint256)
    {
        validateIdSet(uniqueUriIdsSortedAscending, uriCount);

        uint256 id = uriSetCount;
        uriSetCount = id.add(1);
        uriSetsById[id] = UriSet(
            uniqueUriIdsSortedAscending
        );

        return id;
    }

    function createChecksumAlgorithm(
        uint256 descriptionUriSetId
    ) external returns (uint256)
    {
        require(descriptionUriSetId < uriSetCount);

        uint256 id = checksumAlgorithmCount;
        checksumAlgorithmCount = id.add(1);
        checksumAlgorithmsById[id] = ChecksumAlgorithm(
            descriptionUriSetId
        );

        return id;
    }

    function createChecksum(
        uint256 algorithmId,
        uint256 resourceByteCount,
        bytes value
    ) external returns (uint256)
    {
        require(algorithmId < checksumAlgorithmCount);
        require(0 < resourceByteCount);

        uint256 id = checksumCount;
        checksumCount = id.add(1);
        checksumsById[id] = Checksum(
            algorithmId,
            resourceByteCount,
            value
        );

        return id;
    }

    function createEncryptionAlgorithm(
        uint256 descriptionUriSetId
    ) external returns (uint256)
    {
        require(descriptionUriSetId < uriSetCount);

        uint256 id = encryptionAlgorithmCount;
        encryptionAlgorithmCount = id.add(1);
        encryptionAlgorithmsById[id] = EncryptionAlgorithm(
            descriptionUriSetId
        );

        return id;
    }

    function createChecksumPair(
        uint256 encryptedChecksumId,
        uint256 decryptedChecksumId
    ) external returns (uint256)
    {
        require(encryptedChecksumId < checksumCount);
        require(decryptedChecksumId < checksumCount);

        uint256 id = checksumPairCount;
        checksumPairCount = id.add(1);
        checksumPairsById[id] = ChecksumPair(
            encryptedChecksumId,
            decryptedChecksumId
        );

        return id;
    }

    function createResource(
        uint256 uriSetId,
        uint256 encryptionAlgorithmId,
        uint256 metaResourceSetId
    ) external returns (uint256)
    {
        require(uriSetId < uriSetCount);
        require(encryptionAlgorithmId < encryptionAlgorithmCount);
        require(metaResourceSetId < resourceSetCount);

        uint256 id = resourceCount;
        resourceCount = id.add(1);
        resourcesById[id] = Resource(
            uriSetId,
            encryptionAlgorithmId,
            metaResourceSetId
        );

        return id;
    }

    function createPublicKey(
        bytes value
    ) external returns (uint256)
    {
        uint256 id = publicKeyCount;
        publicKeyCount = id.add(1);
        publicKeysById[id] = PublicKey(
            value
        );

        return id;
    }

    function createResourceSet(
        uint256 creatorPublicKeyId,
        uint256 proposalEncryptionAlgorithmId,
        uint256[] uniqueResourceIdsSortedAscending,
        uint256 metaResourceSetId
    ) external returns (uint256)
    {
        require(creatorPublicKeyId < publicKeyCount);
        require(proposalEncryptionAlgorithmId < encryptionAlgorithmCount);
        validateIdSet(uniqueResourceIdsSortedAscending, resourceCount);
        require(metaResourceSetId < resourceSetCount);

        uint256 id = resourceSetCount;
        resourceSetCount = id.add(1);
        resourceSetsById[id] = ResourceSet(
            msg.sender,
            creatorPublicKeyId,
            proposalEncryptionAlgorithmId,
            uniqueResourceIdsSortedAscending,
            metaResourceSetId
        );

        return id;
    }

    function createAgreement(
        uint256 uriSetId,
        uint256 checksumPairId
    ) external returns (uint256)
    {
        require(uriSetId < uriSetCount);
        require(checksumPairId < checksumPairCount);

        uint256 id = agreementCount;
        agreementCount = id.add(1);
        agreementsById[id] = Agreement(
            uriSetId,
            checksumPairId
        );

        return id;
    }

    function createAgreementSet(
        uint256[] uniqueAgreementIdsSortedAscending
    ) external returns (uint256)
    {
        validateIdSet(uniqueAgreementIdsSortedAscending, agreementCount);

        uint256 id = agreementSetCount;
        agreementSetCount = id.add(1);
        agreementSetsById[id] = AgreementSet(
            uniqueAgreementIdsSortedAscending
        );

        return id;
    }

    function createTokenTransfer(
        address source,
        address destination,
        uint256 tokenCount
    ) external returns (uint256)
    {
        require(address(0) != source);
        require(address(0) != destination);
        require(0 < tokenCount);

        uint256 id = tokenTransferCount;
        tokenTransferCount = id.add(1);
        tokenTransfersById[id] = TokenTransfer(
            source,
            destination,
            tokenCount
        );

        return id;
    }

    function createTokenTransferSet(
        uint256[] uniqueTokenTransferIdsSortedAscending
    ) external returns (uint256)
    {
        validateIdSet(uniqueTokenTransferIdsSortedAscending, tokenTransferCount);

        uint256 id = tokenTransferSetCount;
        tokenTransferSetCount = id.add(1);
        tokenTransferSetsById[id] = TokenTransferSet(
            uniqueTokenTransferIdsSortedAscending
        );

        return id;
    }

    function createProposal(
        uint256 minimumBlockNumberForWithdrawal,
        uint256 creatorPublicKeyId,
        uint256 acceptanceEncryptionAlgorithmId,
        uint256 resourceSetId,
        uint256 agreementSetId,
        uint256 tokenTransferSetId
    ) external returns (uint256)
    {
        require(creatorPublicKeyId < publicKeyCount);
        require(acceptanceEncryptionAlgorithmId < encryptionAlgorithmCount);
        require(resourceSetId < resourceSetCount);
        require(agreementSetId < agreementSetCount);
        require(tokenTransferSetId < tokenTransferSetCount);

        transferTokensToEscrow(msg.sender, tokenTransferSetId);

        uint256 id = proposalCount;
        proposalCount = id.add(1);
        proposalsById[id] = Proposal(
            minimumBlockNumberForWithdrawal,
            msg.sender,
            creatorPublicKeyId,
            acceptanceEncryptionAlgorithmId,
            resourceSetId,
            agreementSetId,
            tokenTransferSetId
        );

        return id;
    }

     
     
     
    function assignResourceChecksumPair(
        uint256 resourceId,
        uint256 checksumPairId
    ) external
    {
        require(resourceId < resourceCount);
        require(checksumPairId < checksumPairCount);
        require(false == checksumPairAssignmentsByCreatorAndResourceId[msg.sender][resourceId]);

        checksumPairIdsByCreatorAndResourceId[msg.sender][resourceId] = checksumPairId;
        checksumPairAssignmentsByCreatorAndResourceId[msg.sender][resourceId] = true;
    }

     
     
    function withdrawProposal(
        uint256 proposalId
    ) external
    {
        require(proposalId < proposalCount);
        require(ProposalState.Pending == statesByProposalId[proposalId]);

        Proposal memory proposal = proposalsById[proposalId];
        require(msg.sender == proposal.creator);
        require(block.number >= proposal.minimumBlockNumberForWithdrawal);

        returnTokensFromEscrow(proposal.creator, proposal.tokenTransferSetId);
        statesByProposalId[proposalId] = ProposalState.WithdrawnByCreator;
    }

     
     
    function rejectProposal(
        uint256 proposalId
    ) external
    {
        require(proposalId < proposalCount);
        require(ProposalState.Pending == statesByProposalId[proposalId]);

        Proposal memory proposal = proposalsById[proposalId];
        require(msg.sender == resourceSetsById[proposal.resourceSetId].creator);

        returnTokensFromEscrow(proposal.creator, proposal.tokenTransferSetId);
        statesByProposalId[proposalId] = ProposalState.RejectedByResourceSetCreator;
    }

     
     
     
     
     
     
     
     
     
     
    function acceptProposal(
        uint256 proposalId,
        bytes concatenatedResourceDecryptionKeys,
        uint256[] concatenatedResourceDecryptionKeyLengths
    ) external
    {
        require(proposalId < proposalCount);
        require(ProposalState.Pending == statesByProposalId[proposalId]);

        Proposal memory proposal = proposalsById[proposalId];
        require(msg.sender == resourceSetsById[proposal.resourceSetId].creator);

        storeEncryptedDecryptionKeys(
            proposalId,
            concatenatedResourceDecryptionKeys,
            concatenatedResourceDecryptionKeyLengths
        );

        transferTokensFromEscrow(proposal.tokenTransferSetId);

        statesByProposalId[proposalId] = ProposalState.AcceptedByResourceSetCreator;
    }

    function validateIdSet(uint256[] uniqueIdsSortedAscending, uint256 idCount) private pure {
        if (0 < uniqueIdsSortedAscending.length) {

            uint256 id = uniqueIdsSortedAscending[0];
            require(id < idCount);

            uint256 previousId = id;
            for (uint256 index = 1; index < uniqueIdsSortedAscending.length; index = index.add(1)) {
                id = uniqueIdsSortedAscending[index];
                require(id < idCount);
                require(previousId < id);

                previousId = id;
            }
        }
    }

    function transferTokensToEscrow(address proposalCreator, uint256 tokenTransferSetId) private {
        assert(tokenTransferSetId < tokenTransferSetCount);
        assert(address(0) != proposalCreator);

        uint256[] memory tokenTransferIds = tokenTransferSetsById[tokenTransferSetId].uniqueTokenTransferIdsSortedAscending;
        for (uint256 index = 0; index < tokenTransferIds.length; index = index.add(1)) {
            uint256 tokenTransferId = tokenTransferIds[index];
            assert(tokenTransferId < tokenTransferCount);

            TokenTransfer memory tokenTransfer = tokenTransfersById[tokenTransferId];
            assert(0 < tokenTransfer.tokenCount);
            assert(address(0) != tokenTransfer.source);
            assert(address(0) != tokenTransfer.destination);

            require(tokenTransfer.tokenCount <= balances[tokenTransfer.source]);

            if (tokenTransfer.source != proposalCreator) {
                require(tokenTransfer.tokenCount <= allowed[tokenTransfer.source][proposalCreator]);

                allowed[tokenTransfer.source][proposalCreator] = allowed[tokenTransfer.source][proposalCreator].sub(tokenTransfer.tokenCount);
            }

            balances[tokenTransfer.source] = balances[tokenTransfer.source].sub(tokenTransfer.tokenCount);
            balances[address(0)] = balances[address(0)].add(tokenTransfer.tokenCount);

            Transfer(tokenTransfer.source, address(0), tokenTransfer.tokenCount);
        }
    }

    function returnTokensFromEscrow(address proposalCreator, uint256 tokenTransferSetId) private {
        assert(tokenTransferSetId < tokenTransferSetCount);
        assert(address(0) != proposalCreator);

        uint256[] memory tokenTransferIds = tokenTransferSetsById[tokenTransferSetId].uniqueTokenTransferIdsSortedAscending;
        for (uint256 index = 0; index < tokenTransferIds.length; index = index.add(1)) {
            uint256 tokenTransferId = tokenTransferIds[index];
            assert(tokenTransferId < tokenTransferCount);

            TokenTransfer memory tokenTransfer = tokenTransfersById[tokenTransferId];
            assert(0 < tokenTransfer.tokenCount);
            assert(address(0) != tokenTransfer.source);
            assert(address(0) != tokenTransfer.destination);
            assert(tokenTransfer.tokenCount <= balances[address(0)]);

            balances[tokenTransfer.source] = balances[tokenTransfer.source].add(tokenTransfer.tokenCount);
            balances[address(0)] = balances[address(0)].sub(tokenTransfer.tokenCount);

            Transfer(address(0), tokenTransfer.source, tokenTransfer.tokenCount);
        }
    }

    function transferTokensFromEscrow(uint256 tokenTransferSetId) private {
        assert(tokenTransferSetId < tokenTransferSetCount);

        uint256[] memory tokenTransferIds = tokenTransferSetsById[tokenTransferSetId].uniqueTokenTransferIdsSortedAscending;
        for (uint256 index = 0; index < tokenTransferIds.length; index = index.add(1)) {
            uint256 tokenTransferId = tokenTransferIds[index];
            assert(tokenTransferId < tokenTransferCount);

            TokenTransfer memory tokenTransfer = tokenTransfersById[tokenTransferId];
            assert(0 < tokenTransfer.tokenCount);
            assert(address(0) != tokenTransfer.source);
            assert(address(0) != tokenTransfer.destination);

            balances[address(0)] = balances[address(0)].sub(tokenTransfer.tokenCount);
            balances[tokenTransfer.destination] = balances[tokenTransfer.destination].add(tokenTransfer.tokenCount);
            Transfer(address(0), tokenTransfer.destination, tokenTransfer.tokenCount);
        }
    }

    function storeEncryptedDecryptionKeys(
        uint256 proposalId,
        bytes concatenatedEncryptedResourceDecryptionKeys,
        uint256[] encryptedResourceDecryptionKeyLengths
    ) private
    {
        assert(proposalId < proposalCount);

        uint256 resourceSetId = proposalsById[proposalId].resourceSetId;
        assert(resourceSetId < resourceSetCount);

        ResourceSet memory resourceSet = resourceSetsById[resourceSetId];
        require(resourceSet.uniqueResourceIdsSortedAscending.length == encryptedResourceDecryptionKeyLengths.length);

        uint256 concatenatedEncryptedResourceDecryptionKeysIndex = 0;
        for (uint256 resourceIndex = 0; resourceIndex < encryptedResourceDecryptionKeyLengths.length; resourceIndex = resourceIndex.add(1)) {
            bytes memory encryptedResourceDecryptionKey = new bytes(encryptedResourceDecryptionKeyLengths[resourceIndex]);
            require(0 < encryptedResourceDecryptionKey.length);

            for (uint256 encryptedResourceDecryptionKeyIndex = 0; encryptedResourceDecryptionKeyIndex < encryptedResourceDecryptionKey.length; encryptedResourceDecryptionKeyIndex = encryptedResourceDecryptionKeyIndex.add(1)) {
                require(concatenatedEncryptedResourceDecryptionKeysIndex < concatenatedEncryptedResourceDecryptionKeys.length);
                encryptedResourceDecryptionKey[encryptedResourceDecryptionKeyIndex] = concatenatedEncryptedResourceDecryptionKeys[concatenatedEncryptedResourceDecryptionKeysIndex];
                concatenatedEncryptedResourceDecryptionKeysIndex = concatenatedEncryptedResourceDecryptionKeysIndex.add(1);
            }

            uint256 resourceId = resourceSet.uniqueResourceIdsSortedAscending[resourceIndex];
            assert(resourceId < resourceCount);

            encryptedDecryptionKeysByProposalIdAndResourceId[proposalId][resourceId] = encryptedResourceDecryptionKey;
        }

        require(concatenatedEncryptedResourceDecryptionKeysIndex == concatenatedEncryptedResourceDecryptionKeys.length);
    }
}