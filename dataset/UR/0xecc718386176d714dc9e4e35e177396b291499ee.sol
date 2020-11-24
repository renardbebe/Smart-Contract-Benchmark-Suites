 

pragma solidity 0.4.18;

 

 

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

 

 
contract TokenRegistry is Ownable {
    mapping (bytes32 => TokenAttributes) public symbolHashToTokenAttributes;
    string[256] public tokenSymbolList;
    uint8 public tokenSymbolListLength;

    struct TokenAttributes {
         
        address tokenAddress;
         
        uint tokenIndex;
         
        string name;
         
        uint8 numDecimals;
    }

     
    function setTokenAttributes(
        string _symbol,
        address _tokenAddress,
        string _tokenName,
        uint8 _numDecimals
    )
        public onlyOwner
    {
        bytes32 symbolHash = keccak256(_symbol);

         
        TokenAttributes memory attributes = symbolHashToTokenAttributes[symbolHash];

        if (attributes.tokenAddress == address(0)) {
             
            attributes.tokenAddress = _tokenAddress;
            attributes.numDecimals = _numDecimals;
            attributes.name = _tokenName;
            attributes.tokenIndex = tokenSymbolListLength;

            tokenSymbolList[tokenSymbolListLength] = _symbol;
            tokenSymbolListLength++;
        } else {
             
            attributes.tokenAddress = _tokenAddress;
            attributes.numDecimals = _numDecimals;
            attributes.name = _tokenName;
        }

         
        symbolHashToTokenAttributes[symbolHash] = attributes;
    }

     
    function getTokenAddressBySymbol(string _symbol) public view returns (address) {
        bytes32 symbolHash = keccak256(_symbol);

        TokenAttributes storage attributes = symbolHashToTokenAttributes[symbolHash];

        return attributes.tokenAddress;
    }

     
    function getTokenAddressByIndex(uint _index) public view returns (address) {
        string storage symbol = tokenSymbolList[_index];

        return getTokenAddressBySymbol(symbol);
    }

     
    function getTokenIndexBySymbol(string _symbol) public view returns (uint) {
        bytes32 symbolHash = keccak256(_symbol);

        TokenAttributes storage attributes = symbolHashToTokenAttributes[symbolHash];

        return attributes.tokenIndex;
    }

     
    function getTokenSymbolByIndex(uint _index) public view returns (string) {
        return tokenSymbolList[_index];
    }

     
    function getTokenNameBySymbol(string _symbol) public view returns (string) {
        bytes32 symbolHash = keccak256(_symbol);

        TokenAttributes storage attributes = symbolHashToTokenAttributes[symbolHash];

        return attributes.name;
    }

     
    function getNumDecimalsFromSymbol(string _symbol) public view returns (uint8) {
        bytes32 symbolHash = keccak256(_symbol);

        TokenAttributes storage attributes = symbolHashToTokenAttributes[symbolHash];

        return attributes.numDecimals;
    }

     
    function getNumDecimalsByIndex(uint _index) public view returns (uint8) {
        string memory symbol = getTokenSymbolByIndex(_index);

        return getNumDecimalsFromSymbol(symbol);
    }

     
    function getTokenNameByIndex(uint _index) public view returns (string) {
        string memory symbol = getTokenSymbolByIndex(_index);

        string memory tokenName = getTokenNameBySymbol(symbol);

        return tokenName;
    }

     
    function getTokenAttributesBySymbol(string _symbol)
        public
        view
        returns (
            address,
            uint,
            string,
            uint
        )
    {
        bytes32 symbolHash = keccak256(_symbol);

        TokenAttributes storage attributes = symbolHashToTokenAttributes[symbolHash];

        return (
            attributes.tokenAddress,
            attributes.tokenIndex,
            attributes.name,
            attributes.numDecimals
        );
    }

     
    function getTokenAttributesByIndex(uint _index)
        public
        view
        returns (
            address,
            string,
            string,
            uint8
        )
    {
        string memory symbol = getTokenSymbolByIndex(_index);

        bytes32 symbolHash = keccak256(symbol);

        TokenAttributes storage attributes = symbolHashToTokenAttributes[symbolHash];

        return (
            attributes.tokenAddress,
            symbol,
            attributes.name,
            attributes.numDecimals
        );
    }
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









 
contract Collateralizer is Pausable, PermissionEvents {
    using PermissionsLib for PermissionsLib.Permissions;
    using SafeMath for uint;

    address public debtKernelAddress;

    DebtRegistry public debtRegistry;
    TokenRegistry public tokenRegistry;
    TokenTransferProxy public tokenTransferProxy;

     
    mapping(bytes32 => address) public agreementToCollateralizer;

    PermissionsLib.Permissions internal collateralizationPermissions;

    uint public constant SECONDS_IN_DAY = 24*60*60;

    string public constant CONTEXT = "collateralizer";

    event CollateralLocked(
        bytes32 indexed agreementID,
        address indexed token,
        uint amount
    );

    event CollateralReturned(
        bytes32 indexed agreementID,
        address indexed collateralizer,
        address token,
        uint amount
    );

    event CollateralSeized(
        bytes32 indexed agreementID,
        address indexed beneficiary,
        address token,
        uint amount
    );

    modifier onlyAuthorizedToCollateralize() {
        require(collateralizationPermissions.isAuthorized(msg.sender));
        _;
    }

    function Collateralizer(
        address _debtKernel,
        address _debtRegistry,
        address _tokenRegistry,
        address _tokenTransferProxy
    ) public {
        debtKernelAddress = _debtKernel;
        debtRegistry = DebtRegistry(_debtRegistry);
        tokenRegistry = TokenRegistry(_tokenRegistry);
        tokenTransferProxy = TokenTransferProxy(_tokenTransferProxy);
    }

     
    function collateralize(
        bytes32 agreementId,
        address collateralizer
    )
        public
        onlyAuthorizedToCollateralize
        whenNotPaused
        returns (bool _success)
    {
         
        address collateralToken;
         
        uint collateralAmount;
         
         
        uint gracePeriodInDays;
         
        TermsContract termsContract;

         
        (
            collateralToken,
            collateralAmount,
            gracePeriodInDays,
            termsContract
        ) = retrieveCollateralParameters(agreementId);

        require(termsContract == msg.sender);
        require(collateralAmount > 0);
        require(collateralToken != address(0));

         
        require(agreementToCollateralizer[agreementId] == address(0));

        ERC20 erc20token = ERC20(collateralToken);
        address custodian = address(this);

         
        require(erc20token.balanceOf(collateralizer) >= collateralAmount);

         
        require(erc20token.allowance(collateralizer, tokenTransferProxy) >= collateralAmount);

         
         
        agreementToCollateralizer[agreementId] = collateralizer;

         
        require(tokenTransferProxy.transferFrom(
            erc20token,
            collateralizer,
            custodian,
            collateralAmount
        ));

         
        CollateralLocked(agreementId, collateralToken, collateralAmount);

        return true;
    }

     
    function returnCollateral(
        bytes32 agreementId
    )
        public
        whenNotPaused
    {
         
        address collateralToken;
         
        uint collateralAmount;
         
         
        uint gracePeriodInDays;
         
        TermsContract termsContract;

         
        (
            collateralToken,
            collateralAmount,
            gracePeriodInDays,
            termsContract
        ) = retrieveCollateralParameters(agreementId);

         
        require(collateralAmount > 0);
        require(collateralToken != address(0));

         
         
         
        require(agreementToCollateralizer[agreementId] != address(0));

         
        require(
            termsContract.getExpectedRepaymentValue(
                agreementId,
                termsContract.getTermEndTimestamp(agreementId)
            ) <= termsContract.getValueRepaidToDate(agreementId)
        );

         
        address collateralizer = agreementToCollateralizer[agreementId];

         
         
        delete agreementToCollateralizer[agreementId];

         
        require(
            ERC20(collateralToken).transfer(
                collateralizer,
                collateralAmount
            )
        );

         
        CollateralReturned(
            agreementId,
            collateralizer,
            collateralToken,
            collateralAmount
        );
    }

     
    function seizeCollateral(
        bytes32 agreementId
    )
        public
        whenNotPaused
    {

         
        address collateralToken;
         
        uint collateralAmount;
         
         
        uint gracePeriodInDays;
         
        TermsContract termsContract;

         
        (
            collateralToken,
            collateralAmount,
            gracePeriodInDays,
            termsContract
        ) = retrieveCollateralParameters(agreementId);

         
        require(collateralAmount > 0);
        require(collateralToken != address(0));

         
         
         
        require(agreementToCollateralizer[agreementId] != address(0));

         
         
         
         
         
         
        require(
            termsContract.getExpectedRepaymentValue(
                agreementId,
                timestampAdjustedForGracePeriod(gracePeriodInDays)
            ) > termsContract.getValueRepaidToDate(agreementId)
        );

         
         
        delete agreementToCollateralizer[agreementId];

         
        address beneficiary = debtRegistry.getBeneficiary(agreementId);

         
        require(
            ERC20(collateralToken).transfer(
                beneficiary,
                collateralAmount
            )
        );

         
        CollateralSeized(
            agreementId,
            beneficiary,
            collateralToken,
            collateralAmount
        );
    }

     
    function addAuthorizedCollateralizeAgent(address agent)
        public
        onlyOwner
    {
        collateralizationPermissions.authorize(agent, CONTEXT);
    }

     
    function revokeCollateralizeAuthorization(address agent)
        public
        onlyOwner
    {
        collateralizationPermissions.revokeAuthorization(agent, CONTEXT);
    }

     
    function getAuthorizedCollateralizeAgents()
        public
        view
        returns(address[])
    {
        return collateralizationPermissions.getAuthorizedAgents();
    }

     
    function unpackCollateralParametersFromBytes(bytes32 parameters)
        public
        pure
        returns (uint, uint, uint)
    {
         
        bytes32 collateralTokenIndexShifted =
            parameters & 0x0000000000000000000000000000000000000ff0000000000000000000000000;
         
        bytes32 collateralAmountShifted =
            parameters & 0x000000000000000000000000000000000000000fffffffffffffffffffffff00;

         
         
         
        uint collateralTokenIndex = uint(collateralTokenIndexShifted) / 2 ** 100;
        uint collateralAmount = uint(collateralAmountShifted) / 2 ** 8;

         
         
         
         
        bytes32 gracePeriodInDays =
            parameters & 0x00000000000000000000000000000000000000000000000000000000000000ff;

        return (
            collateralTokenIndex,
            collateralAmount,
            uint(gracePeriodInDays)
        );
    }

    function timestampAdjustedForGracePeriod(uint gracePeriodInDays)
        public
        view
        returns (uint)
    {
        return block.timestamp.sub(
            SECONDS_IN_DAY.mul(gracePeriodInDays)
        );
    }

    function retrieveCollateralParameters(bytes32 agreementId)
        internal
        view
        returns (
            address _collateralToken,
            uint _collateralAmount,
            uint _gracePeriodInDays,
            TermsContract _termsContract
        )
    {
        address termsContractAddress;
        bytes32 termsContractParameters;

         
        (termsContractAddress, termsContractParameters) = debtRegistry.getTerms(agreementId);

        uint collateralTokenIndex;
        uint collateralAmount;
        uint gracePeriodInDays;

         
        (
            collateralTokenIndex,
            collateralAmount,
            gracePeriodInDays
        ) = unpackCollateralParametersFromBytes(termsContractParameters);

         
        address collateralTokenAddress = tokenRegistry.getTokenAddressByIndex(collateralTokenIndex);

        return (
            collateralTokenAddress,
            collateralAmount,
            gracePeriodInDays,
            TermsContract(termsContractAddress)
        );
    }
}