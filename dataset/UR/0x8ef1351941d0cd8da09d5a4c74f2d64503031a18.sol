 

pragma solidity ^0.4.18;

 

 

pragma solidity 0.4.18;


 
contract PermissionEvents {
    event Authorized(address indexed agent, string callingContext);
    event AuthorizationRevoked(address indexed agent, string callingContext);
}


library PermissionsLib {

     
     
     
    event Authorized(address indexed agent, string callingContext);
    event AuthorizationRevoked(address indexed agent, string callingContext);

    struct Permissions {
        mapping (address => bool) authorized;
        mapping (address => uint) agentToIndex;  
        address[] authorizedAgents;
    }

    function authorize(
        Permissions storage self,
        address agent,
        string callingContext
    )
        internal
    {
        require(isNotAuthorized(self, agent));

        self.authorized[agent] = true;
        self.authorizedAgents.push(agent);
        self.agentToIndex[agent] = self.authorizedAgents.length - 1;
        Authorized(agent, callingContext);
    }

    function revokeAuthorization(
        Permissions storage self,
        address agent,
        string callingContext
    )
        internal
    {
         
        require(isAuthorized(self, agent));

        uint indexOfAgentToRevoke = self.agentToIndex[agent];
        uint indexOfAgentToMove = self.authorizedAgents.length - 1;
        address agentToMove = self.authorizedAgents[indexOfAgentToMove];

         
        delete self.authorized[agent];

         
        self.authorizedAgents[indexOfAgentToRevoke] = agentToMove;

         
        self.agentToIndex[agentToMove] = indexOfAgentToRevoke;
        delete self.agentToIndex[agent];

         
        delete self.authorizedAgents[indexOfAgentToMove];
        self.authorizedAgents.length -= 1;

        AuthorizationRevoked(agent, callingContext);
    }

    function isAuthorized(Permissions storage self, address agent)
        internal
        view
        returns (bool)
    {
        return self.authorized[agent];
    }

    function isNotAuthorized(Permissions storage self, address agent)
        internal
        view
        returns (bool)
    {
        return !isAuthorized(self, agent);
    }

    function getAuthorizedAgents(Permissions storage self)
        internal
        view
        returns (address[])
    {
        return self.authorizedAgents;
    }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
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

 

 

pragma solidity 0.4.18;





 
contract DebtRegistry is Pausable, PermissionEvents {
    using SafeMath for uint;
    using PermissionsLib for PermissionsLib.Permissions;

    struct Entry {
        address version;
        address beneficiary;
        address underwriter;
        uint underwriterRiskRating;
        address termsContract;
        bytes32 termsContractParameters;
        uint issuanceBlockTimestamp;
    }

     
    mapping (bytes32 => Entry) internal registry;

     
    mapping (address => bytes32[]) internal debtorToDebts;

    PermissionsLib.Permissions internal entryInsertPermissions;
    PermissionsLib.Permissions internal entryEditPermissions;

    string public constant INSERT_CONTEXT = "debt-registry-insert";
    string public constant EDIT_CONTEXT = "debt-registry-edit";

    event LogInsertEntry(
        bytes32 indexed agreementId,
        address indexed beneficiary,
        address indexed underwriter,
        uint underwriterRiskRating,
        address termsContract,
        bytes32 termsContractParameters
    );

    event LogModifyEntryBeneficiary(
        bytes32 indexed agreementId,
        address indexed previousBeneficiary,
        address indexed newBeneficiary
    );

    modifier onlyAuthorizedToInsert() {
        require(entryInsertPermissions.isAuthorized(msg.sender));
        _;
    }

    modifier onlyAuthorizedToEdit() {
        require(entryEditPermissions.isAuthorized(msg.sender));
        _;
    }

    modifier onlyExtantEntry(bytes32 agreementId) {
        require(doesEntryExist(agreementId));
        _;
    }

    modifier nonNullBeneficiary(address beneficiary) {
        require(beneficiary != address(0));
        _;
    }

     
    function doesEntryExist(bytes32 agreementId)
        public
        view
        returns (bool exists)
    {
        return registry[agreementId].beneficiary != address(0);
    }

     
    function insert(
        address _version,
        address _beneficiary,
        address _debtor,
        address _underwriter,
        uint _underwriterRiskRating,
        address _termsContract,
        bytes32 _termsContractParameters,
        uint _salt
    )
        public
        onlyAuthorizedToInsert
        whenNotPaused
        nonNullBeneficiary(_beneficiary)
        returns (bytes32 _agreementId)
    {
        Entry memory entry = Entry(
            _version,
            _beneficiary,
            _underwriter,
            _underwriterRiskRating,
            _termsContract,
            _termsContractParameters,
            block.timestamp
        );

        bytes32 agreementId = _getAgreementId(entry, _debtor, _salt);

        require(registry[agreementId].beneficiary == address(0));

        registry[agreementId] = entry;
        debtorToDebts[_debtor].push(agreementId);

        LogInsertEntry(
            agreementId,
            entry.beneficiary,
            entry.underwriter,
            entry.underwriterRiskRating,
            entry.termsContract,
            entry.termsContractParameters
        );

        return agreementId;
    }

     
    function modifyBeneficiary(bytes32 agreementId, address newBeneficiary)
        public
        onlyAuthorizedToEdit
        whenNotPaused
        onlyExtantEntry(agreementId)
        nonNullBeneficiary(newBeneficiary)
    {
        address previousBeneficiary = registry[agreementId].beneficiary;

        registry[agreementId].beneficiary = newBeneficiary;

        LogModifyEntryBeneficiary(
            agreementId,
            previousBeneficiary,
            newBeneficiary
        );
    }

     
    function addAuthorizedInsertAgent(address agent)
        public
        onlyOwner
    {
        entryInsertPermissions.authorize(agent, INSERT_CONTEXT);
    }

     
    function addAuthorizedEditAgent(address agent)
        public
        onlyOwner
    {
        entryEditPermissions.authorize(agent, EDIT_CONTEXT);
    }

     
    function revokeInsertAgentAuthorization(address agent)
        public
        onlyOwner
    {
        entryInsertPermissions.revokeAuthorization(agent, INSERT_CONTEXT);
    }

     
    function revokeEditAgentAuthorization(address agent)
        public
        onlyOwner
    {
        entryEditPermissions.revokeAuthorization(agent, EDIT_CONTEXT);
    }

     
    function get(bytes32 agreementId)
        public
        view
        returns(address, address, address, uint, address, bytes32, uint)
    {
        return (
            registry[agreementId].version,
            registry[agreementId].beneficiary,
            registry[agreementId].underwriter,
            registry[agreementId].underwriterRiskRating,
            registry[agreementId].termsContract,
            registry[agreementId].termsContractParameters,
            registry[agreementId].issuanceBlockTimestamp
        );
    }

     
    function getBeneficiary(bytes32 agreementId)
        public
        view
        onlyExtantEntry(agreementId)
        returns(address)
    {
        return registry[agreementId].beneficiary;
    }

     
    function getTermsContract(bytes32 agreementId)
        public
        view
        onlyExtantEntry(agreementId)
        returns (address)
    {
        return registry[agreementId].termsContract;
    }

     
    function getTermsContractParameters(bytes32 agreementId)
        public
        view
        onlyExtantEntry(agreementId)
        returns (bytes32)
    {
        return registry[agreementId].termsContractParameters;
    }

     
    function getTerms(bytes32 agreementId)
        public
        view
        onlyExtantEntry(agreementId)
        returns(address, bytes32)
    {
        return (
            registry[agreementId].termsContract,
            registry[agreementId].termsContractParameters
        );
    }

     
    function getIssuanceBlockTimestamp(bytes32 agreementId)
        public
        view
        onlyExtantEntry(agreementId)
        returns (uint timestamp)
    {
        return registry[agreementId].issuanceBlockTimestamp;
    }

     
    function getAuthorizedInsertAgents()
        public
        view
        returns(address[])
    {
        return entryInsertPermissions.getAuthorizedAgents();
    }

     
    function getAuthorizedEditAgents()
        public
        view
        returns(address[])
    {
        return entryEditPermissions.getAuthorizedAgents();
    }

     
    function getDebtorsDebts(address debtor)
        public
        view
        returns(bytes32[])
    {
        return debtorToDebts[debtor];
    }

     
    function _getAgreementId(Entry _entry, address _debtor, uint _salt)
        internal
        pure
        returns(bytes32)
    {
        return keccak256(
            _entry.version,
            _debtor,
            _entry.underwriter,
            _entry.underwriterRiskRating,
            _entry.termsContract,
            _entry.termsContractParameters,
            _salt
        );
    }
}

 

 

pragma solidity 0.4.18;


 
interface ERC165 {
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);  

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);
  
  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);
  
  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;  
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;
}

 

 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}

 
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}

 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 

 
contract DeprecatedERC721 is ERC721 {
  function takeOwnership(uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;
  function tokensOf(address _owner) public view returns (uint256[]);
}

 

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 

 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba; 

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

 

 
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;
  
   
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba; 

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }


   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);
    
    Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public canTransfer(_tokenId) {
    transferFrom(_from, _to, _tokenId);
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      Approval(_owner, address(0), _tokenId);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal returns (bool) {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 

 
contract ERC721Token is ERC721, ERC721BasicToken {
   
  string internal name_;

   
  string internal symbol_;

   
  mapping (address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  function ERC721Token(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
  }

   
  function name() public view returns (string) {
    return name_;
  }

   
  function symbol() public view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);
    
    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

     
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

 

 

pragma solidity 0.4.18;

 




 





 
contract DebtToken is ERC721Token, ERC165, Pausable, PermissionEvents {
    using PermissionsLib for PermissionsLib.Permissions;

    DebtRegistry public registry;

    PermissionsLib.Permissions internal tokenCreationPermissions;
    PermissionsLib.Permissions internal tokenURIPermissions;

    string public constant CREATION_CONTEXT = "debt-token-creation";
    string public constant URI_CONTEXT = "debt-token-uri";

     
    function DebtToken(address _registry)
        public
        ERC721Token("DebtToken", "DDT")
    {
        registry = DebtRegistry(_registry);
    }

     
    function supportsInterface(bytes4 interfaceID)
        external
        view
        returns (bool _isSupported)
    {
        return interfaceID == 0x80ac58cd;  
    }

     
    function create(
        address _version,
        address _beneficiary,
        address _debtor,
        address _underwriter,
        uint _underwriterRiskRating,
        address _termsContract,
        bytes32 _termsContractParameters,
        uint _salt
    )
        public
        whenNotPaused
        returns (uint _tokenId)
    {
        require(tokenCreationPermissions.isAuthorized(msg.sender));

        bytes32 entryHash = registry.insert(
            _version,
            _beneficiary,
            _debtor,
            _underwriter,
            _underwriterRiskRating,
            _termsContract,
            _termsContractParameters,
            _salt
        );

        super._mint(_beneficiary, uint(entryHash));

        return uint(entryHash);
    }

     
    function addAuthorizedMintAgent(address _agent)
        public
        onlyOwner
    {
        tokenCreationPermissions.authorize(_agent, CREATION_CONTEXT);
    }

     
    function revokeMintAgentAuthorization(address _agent)
        public
        onlyOwner
    {
        tokenCreationPermissions.revokeAuthorization(_agent, CREATION_CONTEXT);
    }

     
    function getAuthorizedMintAgents()
        public
        view
        returns (address[] _agents)
    {
        return tokenCreationPermissions.getAuthorizedAgents();
    }

     
    function addAuthorizedTokenURIAgent(address _agent)
        public
        onlyOwner
    {
        tokenURIPermissions.authorize(_agent, URI_CONTEXT);
    }

     
    function getAuthorizedTokenURIAgents()
        public
        view
        returns (address[] _agents)
    {
        return tokenURIPermissions.getAuthorizedAgents();
    }

     
    function revokeTokenURIAuthorization(address _agent)
        public
        onlyOwner
    {
        tokenURIPermissions.revokeAuthorization(_agent, URI_CONTEXT);
    }

     
    function approve(address _to, uint _tokenId)
        public
        whenNotPaused
    {
        super.approve(_to, _tokenId);
    }

     
    function setApprovalForAll(address _to, bool _approved)
        public
        whenNotPaused
    {
        super.setApprovalForAll(_to, _approved);
    }

     
    function transfer(address _to, uint _tokenId)
        public
    {
        safeTransferFrom(msg.sender, _to, _tokenId);
    }

     
    function transferFrom(address _from, address _to, uint _tokenId)
        public
        whenNotPaused
    {
        _modifyBeneficiary(_tokenId, _to);
        super.transferFrom(_from, _to, _tokenId);
    }

     
    function safeTransferFrom(address _from, address _to, uint _tokenId)
        public
        whenNotPaused
    {
        _modifyBeneficiary(_tokenId, _to);
        super.safeTransferFrom(_from, _to, _tokenId);
    }

     
    function safeTransferFrom(address _from, address _to, uint _tokenId, bytes _data)
        public
        whenNotPaused
    {
        _modifyBeneficiary(_tokenId, _to);
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

     
    function setTokenURI(uint256 _tokenId, string _uri)
        public
        whenNotPaused
    {
        require(tokenURIPermissions.isAuthorized(msg.sender));
        super._setTokenURI(_tokenId, _uri);
    }

     
    function _modifyBeneficiary(uint _tokenId, address _to)
        internal
    {
        if (registry.getBeneficiary(bytes32(_tokenId)) != _to) {
            registry.modifyBeneficiary(bytes32(_tokenId), _to);
        }
    }
}

 

 

pragma solidity 0.4.18;


interface TermsContract {
      
      
      
      
      
      
      
      
      
      
      
      
      
      
    function registerTermStart(
        bytes32 agreementId,
        address debtor
    ) public returns (bool _success);

      
      
      
      
      
      
      
      
      
    function registerRepayment(
        bytes32 agreementId,
        address payer,
        address beneficiary,
        uint256 unitsOfRepayment,
        address tokenAddress
    ) public returns (bool _success);

      
      
      
      
      
      
    function getExpectedRepaymentValue(
        bytes32 agreementId,
        uint256 timestamp
    ) public view returns (uint256);

      
      
      
    function getValueRepaidToDate(
        bytes32 agreementId
    ) public view returns (uint256);

     
    function getTermEndTimestamp(
        bytes32 _agreementId
    ) public view returns (uint);
}

 

 

pragma solidity 0.4.18;






 
contract TokenTransferProxy is Pausable, PermissionEvents {
    using PermissionsLib for PermissionsLib.Permissions;

    PermissionsLib.Permissions internal tokenTransferPermissions;

    string public constant CONTEXT = "token-transfer-proxy";

     
    function addAuthorizedTransferAgent(address _agent)
        public
        onlyOwner
    {
        tokenTransferPermissions.authorize(_agent, CONTEXT);
    }

     
    function revokeTransferAgentAuthorization(address _agent)
        public
        onlyOwner
    {
        tokenTransferPermissions.revokeAuthorization(_agent, CONTEXT);
    }

     
    function getAuthorizedTransferAgents()
        public
        view
        returns (address[] authorizedAgents)
    {
        return tokenTransferPermissions.getAuthorizedAgents();
    }

     
    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint _amount
    )
        public
        returns (bool _success)
    {
        require(tokenTransferPermissions.isAuthorized(msg.sender));

        return ERC20(_token).transferFrom(_from, _to, _amount);
    }
}

 

 

pragma solidity 0.4.18;








 
contract DebtKernel is Pausable {
    using SafeMath for uint;

    enum Errors {
         
        DEBT_ISSUED,
         
        ORDER_EXPIRED,
         
        ISSUANCE_CANCELLED,
         
        ORDER_CANCELLED,
         
         
        ORDER_INVALID_INSUFFICIENT_OR_EXCESSIVE_FEES,
         
         
        ORDER_INVALID_INSUFFICIENT_PRINCIPAL,
         
        ORDER_INVALID_UNSPECIFIED_FEE_RECIPIENT,
         
        ORDER_INVALID_NON_CONSENSUAL,
         
        CREDITOR_BALANCE_OR_ALLOWANCE_INSUFFICIENT
    }

    DebtToken public debtToken;

     
    address public TOKEN_TRANSFER_PROXY;
    bytes32 constant public NULL_ISSUANCE_HASH = bytes32(0);

     
    uint16 constant public EXTERNAL_QUERY_GAS_LIMIT = 8000;

    mapping (bytes32 => bool) public issuanceCancelled;
    mapping (bytes32 => bool) public debtOrderCancelled;

    event LogDebtOrderFilled(
        bytes32 indexed _agreementId,
        uint _principal,
        address _principalToken,
        address indexed _underwriter,
        uint _underwriterFee,
        address indexed _relayer,
        uint _relayerFee
    );

    event LogIssuanceCancelled(
        bytes32 indexed _agreementId,
        address indexed _cancelledBy
    );

    event LogDebtOrderCancelled(
        bytes32 indexed _debtOrderHash,
        address indexed _cancelledBy
    );

    event LogError(
        uint8 indexed _errorId,
        bytes32 indexed _orderHash
    );

    struct Issuance {
        address version;
        address debtor;
        address underwriter;
        uint underwriterRiskRating;
        address termsContract;
        bytes32 termsContractParameters;
        uint salt;
        bytes32 agreementId;
    }

    struct DebtOrder {
        Issuance issuance;
        uint underwriterFee;
        uint relayerFee;
        uint principalAmount;
        address principalToken;
        uint creditorFee;
        uint debtorFee;
        address relayer;
        uint expirationTimestampInSec;
        bytes32 debtOrderHash;
    }

    function DebtKernel(address tokenTransferProxyAddress)
        public
    {
        TOKEN_TRANSFER_PROXY = tokenTransferProxyAddress;
    }

     
     
     

     
    function setDebtToken(address debtTokenAddress)
        public
        onlyOwner
    {
        debtToken = DebtToken(debtTokenAddress);
    }

     
    function fillDebtOrder(
        address creditor,
        address[6] orderAddresses,
        uint[8] orderValues,
        bytes32[1] orderBytes32,
        uint8[3] signaturesV,
        bytes32[3] signaturesR,
        bytes32[3] signaturesS
    )
        public
        whenNotPaused
        returns (bytes32 _agreementId)
    {
        DebtOrder memory debtOrder = getDebtOrder(orderAddresses, orderValues, orderBytes32);

         
        if (!assertDebtOrderValidityInvariants(debtOrder) ||
            !assertDebtOrderConsensualityInvariants(
                debtOrder,
                creditor,
                signaturesV,
                signaturesR,
                signaturesS) ||
            !assertExternalBalanceAndAllowanceInvariants(creditor, debtOrder)) {
            return NULL_ISSUANCE_HASH;
        }

         
        issueDebtAgreement(creditor, debtOrder.issuance);

         
         
         
         
        if (debtOrder.issuance.termsContract != address(0)) {
            require(
                TermsContract(debtOrder.issuance.termsContract)
                    .registerTermStart(
                        debtOrder.issuance.agreementId,
                        debtOrder.issuance.debtor
                    )
            );
        }

         
        if (debtOrder.principalAmount > 0) {
            require(transferTokensFrom(
                debtOrder.principalToken,
                creditor,
                debtOrder.issuance.debtor,
                debtOrder.principalAmount.sub(debtOrder.debtorFee)
            ));
        }

         
        if (debtOrder.underwriterFee > 0) {
            require(transferTokensFrom(
                debtOrder.principalToken,
                creditor,
                debtOrder.issuance.underwriter,
                debtOrder.underwriterFee
            ));
        }

         
        if (debtOrder.relayerFee > 0) {
            require(transferTokensFrom(
                debtOrder.principalToken,
                creditor,
                debtOrder.relayer,
                debtOrder.relayerFee
            ));
        }

        LogDebtOrderFilled(
            debtOrder.issuance.agreementId,
            debtOrder.principalAmount,
            debtOrder.principalToken,
            debtOrder.issuance.underwriter,
            debtOrder.underwriterFee,
            debtOrder.relayer,
            debtOrder.relayerFee
        );

        return debtOrder.issuance.agreementId;
    }

     
    function cancelIssuance(
        address version,
        address debtor,
        address termsContract,
        bytes32 termsContractParameters,
        address underwriter,
        uint underwriterRiskRating,
        uint salt
    )
        public
        whenNotPaused
    {
        require(msg.sender == debtor || msg.sender == underwriter);

        Issuance memory issuance = getIssuance(
            version,
            debtor,
            underwriter,
            termsContract,
            underwriterRiskRating,
            salt,
            termsContractParameters
        );

        issuanceCancelled[issuance.agreementId] = true;

        LogIssuanceCancelled(issuance.agreementId, msg.sender);
    }

     
    function cancelDebtOrder(
        address[6] orderAddresses,
        uint[8] orderValues,
        bytes32[1] orderBytes32
    )
        public
        whenNotPaused
    {
        DebtOrder memory debtOrder = getDebtOrder(orderAddresses, orderValues, orderBytes32);

        require(msg.sender == debtOrder.issuance.debtor);

        debtOrderCancelled[debtOrder.debtOrderHash] = true;

        LogDebtOrderCancelled(debtOrder.debtOrderHash, msg.sender);
    }

     
     
     

     
    function issueDebtAgreement(address beneficiary, Issuance issuance)
        internal
        returns (bytes32 _agreementId)
    {
         
        uint tokenId = debtToken.create(
            issuance.version,
            beneficiary,
            issuance.debtor,
            issuance.underwriter,
            issuance.underwriterRiskRating,
            issuance.termsContract,
            issuance.termsContractParameters,
            issuance.salt
        );

        assert(tokenId == uint(issuance.agreementId));

        return issuance.agreementId;
    }

     
    function assertDebtOrderConsensualityInvariants(
        DebtOrder debtOrder,
        address creditor,
        uint8[3] signaturesV,
        bytes32[3] signaturesR,
        bytes32[3] signaturesS
    )
        internal
        returns (bool _orderIsConsensual)
    {
         
        if (msg.sender != debtOrder.issuance.debtor) {
            if (!isValidSignature(
                debtOrder.issuance.debtor,
                debtOrder.debtOrderHash,
                signaturesV[0],
                signaturesR[0],
                signaturesS[0]
            )) {
                LogError(uint8(Errors.ORDER_INVALID_NON_CONSENSUAL), debtOrder.debtOrderHash);
                return false;
            }
        }

         
        if (msg.sender != creditor) {
            if (!isValidSignature(
                creditor,
                debtOrder.debtOrderHash,
                signaturesV[1],
                signaturesR[1],
                signaturesS[1]
            )) {
                LogError(uint8(Errors.ORDER_INVALID_NON_CONSENSUAL), debtOrder.debtOrderHash);
                return false;
            }
        }


         
        if (debtOrder.issuance.underwriter != address(0) &&
            msg.sender != debtOrder.issuance.underwriter) {
            if (!isValidSignature(
                debtOrder.issuance.underwriter,
                getUnderwriterMessageHash(debtOrder),
                signaturesV[2],
                signaturesR[2],
                signaturesS[2]
            )) {
                LogError(uint8(Errors.ORDER_INVALID_NON_CONSENSUAL), debtOrder.debtOrderHash);
                return false;
            }
        }

        return true;
    }

     
    function assertDebtOrderValidityInvariants(DebtOrder debtOrder)
        internal
        returns (bool _orderIsValid)
    {
        uint totalFees = debtOrder.creditorFee.add(debtOrder.debtorFee);

         
         
        if (totalFees != debtOrder.relayerFee.add(debtOrder.underwriterFee)) {
            LogError(uint8(Errors.ORDER_INVALID_INSUFFICIENT_OR_EXCESSIVE_FEES), debtOrder.debtOrderHash);
            return false;
        }

         
        if (debtOrder.principalAmount < debtOrder.debtorFee) {
            LogError(uint8(Errors.ORDER_INVALID_INSUFFICIENT_PRINCIPAL), debtOrder.debtOrderHash);
            return false;
        }

         
         
         
         
        if ((debtOrder.issuance.underwriter == address(0) && debtOrder.underwriterFee > 0) ||
            (debtOrder.relayer == address(0) && totalFees != debtOrder.underwriterFee)) {
            LogError(uint8(Errors.ORDER_INVALID_UNSPECIFIED_FEE_RECIPIENT), debtOrder.debtOrderHash);
            return false;
        }

         
         
        if (debtOrder.expirationTimestampInSec < block.timestamp) {
            LogError(uint8(Errors.ORDER_EXPIRED), debtOrder.debtOrderHash);
            return false;
        }

         
        if (debtToken.exists(uint(debtOrder.issuance.agreementId))) {
            LogError(uint8(Errors.DEBT_ISSUED), debtOrder.debtOrderHash);
            return false;
        }

         
        if (issuanceCancelled[debtOrder.issuance.agreementId]) {
            LogError(uint8(Errors.ISSUANCE_CANCELLED), debtOrder.debtOrderHash);
            return false;
        }

         
        if (debtOrderCancelled[debtOrder.debtOrderHash]) {
            LogError(uint8(Errors.ORDER_CANCELLED), debtOrder.debtOrderHash);
            return false;
        }

        return true;
    }

     
    function assertExternalBalanceAndAllowanceInvariants(
        address creditor,
        DebtOrder debtOrder
    )
        internal
        returns (bool _isBalanceAndAllowanceSufficient)
    {
        uint totalCreditorPayment = debtOrder.principalAmount.add(debtOrder.creditorFee);

        if (getBalance(debtOrder.principalToken, creditor) < totalCreditorPayment ||
            getAllowance(debtOrder.principalToken, creditor) < totalCreditorPayment) {
            LogError(uint8(Errors.CREDITOR_BALANCE_OR_ALLOWANCE_INSUFFICIENT), debtOrder.debtOrderHash);
            return false;
        }

        return true;
    }

     
    function transferTokensFrom(
        address token,
        address from,
        address to,
        uint amount
    )
        internal
        returns (bool success)
    {
        return TokenTransferProxy(TOKEN_TRANSFER_PROXY).transferFrom(
            token,
            from,
            to,
            amount
        );
    }

     
    function getIssuance(
        address version,
        address debtor,
        address underwriter,
        address termsContract,
        uint underwriterRiskRating,
        uint salt,
        bytes32 termsContractParameters
    )
        internal
        pure
        returns (Issuance _issuance)
    {
        Issuance memory issuance = Issuance({
            version: version,
            debtor: debtor,
            underwriter: underwriter,
            termsContract: termsContract,
            underwriterRiskRating: underwriterRiskRating,
            salt: salt,
            termsContractParameters: termsContractParameters,
            agreementId: getAgreementId(
                version,
                debtor,
                underwriter,
                termsContract,
                underwriterRiskRating,
                salt,
                termsContractParameters
            )
        });

        return issuance;
    }

     
    function getDebtOrder(address[6] orderAddresses, uint[8] orderValues, bytes32[1] orderBytes32)
        internal
        view
        returns (DebtOrder _debtOrder)
    {
        DebtOrder memory debtOrder = DebtOrder({
            issuance: getIssuance(
                orderAddresses[0],
                orderAddresses[1],
                orderAddresses[2],
                orderAddresses[3],
                orderValues[0],
                orderValues[1],
                orderBytes32[0]
            ),
            principalToken: orderAddresses[4],
            relayer: orderAddresses[5],
            principalAmount: orderValues[2],
            underwriterFee: orderValues[3],
            relayerFee: orderValues[4],
            creditorFee: orderValues[5],
            debtorFee: orderValues[6],
            expirationTimestampInSec: orderValues[7],
            debtOrderHash: bytes32(0)
        });

        debtOrder.debtOrderHash = getDebtOrderHash(debtOrder);

        return debtOrder;
    }

     
    function getAgreementId(
        address version,
        address debtor,
        address underwriter,
        address termsContract,
        uint underwriterRiskRating,
        uint salt,
        bytes32 termsContractParameters
    )
        internal
        pure
        returns (bytes32 _agreementId)
    {
        return keccak256(
            version,
            debtor,
            underwriter,
            underwriterRiskRating,
            termsContract,
            termsContractParameters,
            salt
        );
    }

     
    function getUnderwriterMessageHash(DebtOrder debtOrder)
        internal
        view
        returns (bytes32 _underwriterMessageHash)
    {
        return keccak256(
            address(this),
            debtOrder.issuance.agreementId,
            debtOrder.underwriterFee,
            debtOrder.principalAmount,
            debtOrder.principalToken,
            debtOrder.expirationTimestampInSec
        );
    }

     
    function getDebtOrderHash(DebtOrder debtOrder)
        internal
        view
        returns (bytes32 _debtorMessageHash)
    {
        return keccak256(
            address(this),
            debtOrder.issuance.agreementId,
            debtOrder.underwriterFee,
            debtOrder.principalAmount,
            debtOrder.principalToken,
            debtOrder.debtorFee,
            debtOrder.creditorFee,
            debtOrder.relayer,
            debtOrder.relayerFee,
            debtOrder.expirationTimestampInSec
        );
    }

     
    function isValidSignature(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
        pure
        returns (bool _valid)
    {
        return signer == ecrecover(
            keccak256("\x19Ethereum Signed Message:\n32", hash),
            v,
            r,
            s
        );
    }

     
    function getBalance(
        address token,
        address owner
    )
        internal
        view
        returns (uint _balance)
    {
         
        return ERC20(token).balanceOf.gas(EXTERNAL_QUERY_GAS_LIMIT)(owner);
    }

     
    function getAllowance(
        address token,
        address owner
    )
        internal
        view
        returns (uint _allowance)
    {
         
        return ERC20(token).allowance.gas(EXTERNAL_QUERY_GAS_LIMIT)(owner, TOKEN_TRANSFER_PROXY);
    }
}