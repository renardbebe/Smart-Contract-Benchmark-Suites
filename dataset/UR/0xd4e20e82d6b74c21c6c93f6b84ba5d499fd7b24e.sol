 

 

pragma solidity ^0.5.13;

interface IPPTokenController {
  event Mint(address indexed to, uint256 indexed tokenId);
  event SetGeoDataManager(address indexed geoDataManager);
  event SetFeeManager(address indexed feeManager);
  event SetFeeCollector(address indexed feeCollector);
  event NewProposal(
    uint256 indexed proposalId,
    uint256 indexed tokenId,
    address indexed creator
  );
  event ProposalExecuted(uint256 indexed proposalId);
  event ProposalExecutionFailed(uint256 indexed proposalId);
  event ProposalApproval(
    uint256 indexed proposalId,
    uint256 indexed tokenId
  );
  event ProposalRejection(
    uint256 indexed proposalId,
    uint256 indexed tokenId
  );
  event ProposalCancellation(
    uint256 indexed proposalId,
    uint256 indexed tokenId
  );
  event SetMinter(address indexed minter);
  event SetBurner(address indexed burner);
  event SetBurnTimeout(uint256 indexed tokenId, uint256 timeout);
  event InitiateTokenBurn(uint256 indexed tokenId, uint256 timeoutAt);
  event BurnTokenByTimeout(uint256 indexed tokenId);
  event CancelTokenBurn(uint256 indexed tokenId);
  event SetFee(bytes32 indexed key, uint256 value);
  event WithdrawEth(address indexed to, uint256 amount);
  event WithdrawErc20(address indexed to, address indexed tokenAddress, uint256 amount);

  enum PropertyInitialSetupStage {
    PENDING,
    DETAILS,
    DONE
  }

  function fees(bytes32) external view returns (uint256);
  function setBurner(address _burner) external;
  function setGeoDataManager(address _geoDataManager) external;
  function setFeeManager(address _feeManager) external;
  function setFeeCollector(address _feeCollector) external;
  function setBurnTimeoutDuration(uint256 _tokenId, uint256 _duration) external;
  function setFee(bytes32 _key, uint256 _value) external;
  function withdrawErc20(address _tokenAddress, address _to) external;
  function withdrawEth(address payable _to) external;
  function initiateTokenBurn(uint256 _tokenId) external;
  function cancelTokenBurn(uint256 _tokenId) external;
  function burnTokenByTimeout(uint256 _tokenId) external;
  function propose(bytes calldata _data, string calldata _dataLink) external payable;
  function approve(uint256 _proposalId) external;
  function execute(uint256 _proposalId) external;
  function fetchTokenId(bytes calldata _data) external pure returns (uint256 tokenId);
  function() external payable;
}

interface IACL {
  function setRole(bytes32 _role, address _candidate, bool _allow) external;
  function hasRole(address _candidate, bytes32 _role) external view returns (bool);
}

interface IPPGlobalRegistry {
  function setContract(bytes32 _key, address _value) external;

   
  function getContract(bytes32 _key) external view returns (address);
  function getACL() external view returns (IACL);
  function getGaltTokenAddress() external view returns (address);
  function getPPTokenRegistryAddress() external view returns (address);
  function getPPLockerRegistryAddress() external view returns (address);
  function getPPMarketAddress() external view returns (address);
}

interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

     
    function balanceOf(address owner) public view returns (uint256 balance);

     
    function ownerOf(uint256 tokenId) public view returns (address owner);

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
     
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

interface IPPToken {
  event SetBaseURI(string baseURI);
  event SetContractDataLink(string indexed dataLink);
  event SetLegalAgreementIpfsHash(bytes32 legalAgreementIpfsHash);
  event SetController(address indexed controller);
  event SetDetails(
    address indexed geoDataManager,
    uint256 indexed privatePropertyId
  );
  event SetContour(
    address indexed geoDataManager,
    uint256 indexed privatePropertyId
  );
  event SetHumanAddress(uint256 indexed tokenId, string humanAddress);
  event SetDataLink(uint256 indexed tokenId, string dataLink);
  event SetLedgerIdentifier(uint256 indexed tokenId, bytes32 ledgerIdentifier);
  event SetVertexRootHash(uint256 indexed tokenId, bytes32 ledgerIdentifier);
  event SetVertexStorageLink(uint256 indexed tokenId, string vertexStorageLink);
  event SetArea(uint256 indexed tokenId, uint256 area, AreaSource areaSource);
  event SetExtraData(bytes32 indexed key, bytes32 value);
  event SetPropertyExtraData(uint256 indexed propertyId, bytes32 indexed key, bytes32 value);
  event Mint(address indexed to, uint256 indexed privatePropertyId);
  event Burn(address indexed from, uint256 indexed privatePropertyId);

  enum AreaSource {
    USER_INPUT,
    CONTRACT
  }

  enum TokenType {
    NULL,
    LAND_PLOT,
    BUILDING,
    ROOM,
    PACKAGE
  }

  struct Property {
    uint256 setupStage;

     
    TokenType tokenType;
     
    uint256[] contour;
     
    int256 highestPoint;

     
    AreaSource areaSource;
     
     
    uint256 area;

    bytes32 ledgerIdentifier;
    string humanAddress;
    string dataLink;

     
    bytes32 vertexRootHash;
    string vertexStorageLink;
  }

   

  function setContractDataLink(string calldata _dataLink) external;
  function setLegalAgreementIpfsHash(bytes32 _legalAgreementIpfsHash) external;
  function setController(address payable _controller) external;
  function setDetails(
    uint256 _tokenId,
    TokenType _tokenType,
    AreaSource _areaSource,
    uint256 _area,
    bytes32 _ledgerIdentifier,
    string calldata _humanAddress,
    string calldata _dataLink
  )
    external;

  function setContour(
    uint256 _tokenId,
    uint256[] calldata _contour,
    int256 _highestPoint
  )
    external;

  function setArea(uint256 _tokenId, uint256 _area, AreaSource _areaSource) external;
  function setLedgerIdentifier(uint256 _tokenId, bytes32 _ledgerIdentifier) external;
  function setDataLink(uint256 _tokenId, string calldata _dataLink) external;
  function setVertexRootHash(uint256 _tokenId, bytes32 _vertexRootHash) external;
  function setVertexStorageLink(uint256 _tokenId, string calldata _vertexStorageLink) external;

  function incrementSetupStage(uint256 _tokenId) external;

  function mint(address _to) external returns (uint256);
  function burn(uint256 _tokenId) external;
  function transferFrom(address from, address to, uint256 tokenId) external;

   
  function controller() external view returns (address payable);

  function tokensOfOwner(address _owner) external view returns (uint256[] memory);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function exists(uint256 _tokenId) external view returns (bool);
  function getType(uint256 _tokenId) external view returns (TokenType);
  function getContour(uint256 _tokenId) external view returns (uint256[] memory);
  function getContourLength(uint256 _tokenId) external view returns (uint256);
  function getHighestPoint(uint256 _tokenId) external view returns (int256);
  function getHumanAddress(uint256 _tokenId) external view returns (string memory);
  function getArea(uint256 _tokenId) external view returns (uint256);
  function getAreaSource(uint256 _tokenId) external view returns (AreaSource);
  function getLedgerIdentifier(uint256 _tokenId) external view returns (bytes32);
  function getDataLink(uint256 _tokenId) external view returns (string memory);
  function getVertexRootHash(uint256 _tokenId) external view returns (bytes32);
  function getVertexStorageLink(uint256 _tokenId) external view returns (string memory);
  function getSetupStage(uint256 _tokenId) external view returns (uint256);
  function getDetails(uint256 _tokenId)
    external
    view
    returns (
      TokenType tokenType,
      uint256[] memory contour,
      int256 highestPoint,
      AreaSource areaSource,
      uint256 area,
      bytes32 ledgerIdentifier,
      string memory humanAddress,
      string memory dataLink,
      uint256 setupStage,
      bytes32 vertexRootHash,
      string memory vertexStorageLink
    );
}

contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

     
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

         
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract PPTokenController is IPPTokenController, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public constant VERSION = 3;

  bytes32 public constant PROPOSAL_GALT_FEE_KEY = bytes32("CONTROLLER_PROPOSAL_GALT");
  bytes32 public constant PROPOSAL_ETH_FEE_KEY = bytes32("CONTROLLER_PROPOSAL_ETH");

  enum ProposalStatus {
    NULL,
    PENDING,
    APPROVED,
    EXECUTED,
    REJECTED,
    CANCELLED
  }

  struct Proposal {
    address creator;
    ProposalStatus status;
    bool tokenOwnerApproved;
    bool geoDataManagerApproved;
    bytes data;
    string dataLink;
  }

  IPPGlobalRegistry public globalRegistry;
  IPPToken public tokenContract;
  address public geoDataManager;
  address public feeManager;
  address public feeCollector;
  address public minter;
  address public burner;
  uint256 public defaultBurnTimeoutDuration;
  uint256 internal idCounter;

  mapping(uint256 => Proposal) public proposals;
   
  mapping(uint256 => uint256) public burnTimeoutDuration;
   
  mapping(uint256 => uint256) public burnTimeoutAt;
   
  mapping(bytes32 => uint256) public fees;

  modifier onlyMinter() {
    require(msg.sender == minter, "Only minter allowed");

    _;
  }

  constructor(IPPGlobalRegistry _globalRegistry, IPPToken _tokenContract, uint256 _defaultBurnTimeoutDuration) public {
    require(_defaultBurnTimeoutDuration > 0, "Invalid burn timeout duration");

    defaultBurnTimeoutDuration = _defaultBurnTimeoutDuration;
    tokenContract = _tokenContract;
    globalRegistry = _globalRegistry;
  }

  function() external payable {
  }

   

  function setGeoDataManager(address _geoDataManager) external onlyOwner {
    geoDataManager = _geoDataManager;

    emit SetGeoDataManager(_geoDataManager);
  }

  function setFeeManager(address _feeManager) external onlyOwner {
    feeManager = _feeManager;

    emit SetFeeManager(_feeManager);
  }

  function setFeeCollector(address _feeCollector) external onlyOwner {
    feeCollector = _feeCollector;

    emit SetFeeCollector(_feeCollector);
  }

  function setMinter(address _minter) external onlyOwner {
    minter = _minter;

    emit SetMinter(_minter);
  }

  function setBurner(address _burner) external onlyOwner {
    burner = _burner;

    emit SetBurner(_burner);
  }

  function withdrawErc20(address _tokenAddress, address _to) external {
    require(msg.sender == feeCollector, "Missing permissions");

    uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));

    IERC20(_tokenAddress).transfer(_to, balance);

    emit WithdrawErc20(_to, _tokenAddress, balance);
  }

  function withdrawEth(address payable _to) external {
    require(msg.sender == feeCollector, "Missing permissions");

    uint256 balance = address(this).balance;

    _to.transfer(balance);

    emit WithdrawEth(_to, balance);
  }

  function setFee(bytes32 _key, uint256 _value) external {
    require(msg.sender == feeManager, "Missing permissions");

    fees[_key] = _value;
    emit SetFee(_key, _value);
  }

   

  function initiateTokenBurn(uint256 _tokenId) external {
    require(msg.sender == burner, "Only burner allowed");
    require(burnTimeoutAt[_tokenId] == 0, "Burn already initiated");
    require(tokenContract.ownerOf(_tokenId) != address(0), "Token doesn't exists");

    uint256 duration = burnTimeoutDuration[_tokenId];
    if (duration == 0) {
      duration = defaultBurnTimeoutDuration;
    }

    uint256 timeoutAt = block.timestamp.add(duration);
    burnTimeoutAt[_tokenId] = timeoutAt;

    emit InitiateTokenBurn(_tokenId, timeoutAt);
  }

   
  function mint(address _to) external onlyMinter {
    uint256 _tokenId = tokenContract.mint(_to);

    emit Mint(_to, _tokenId);
  }

   

  function setInitialDetails(
    uint256 _privatePropertyId,
    IPPToken.TokenType _tokenType,
    IPPToken.AreaSource _areaSource,
    uint256 _area,
    bytes32 _ledgerIdentifier,
    string calldata _humanAddress,
    string calldata _dataLink
  )
    external
    onlyMinter
  {
     
    tokenContract.ownerOf(_privatePropertyId);

    uint256 setupStage = tokenContract.getSetupStage(_privatePropertyId);
    require(setupStage == uint256(PropertyInitialSetupStage.PENDING), "Requires PENDING setup stage");

    tokenContract.setDetails(_privatePropertyId, _tokenType, _areaSource, _area, _ledgerIdentifier, _humanAddress, _dataLink);

    tokenContract.incrementSetupStage(_privatePropertyId);
  }

  function setInitialContour(
    uint256 _privatePropertyId,
    uint256[] calldata _contour,
    int256 _highestPoint
  )
    external
    onlyMinter
  {
    uint256 setupStage = tokenContract.getSetupStage(_privatePropertyId);

    require(setupStage == uint256(PropertyInitialSetupStage.DETAILS), "Requires DETAILS setup stage");

    tokenContract.setContour(_privatePropertyId, _contour, _highestPoint);

    tokenContract.incrementSetupStage(_privatePropertyId);
  }

   

  function setBurnTimeoutDuration(uint256 _tokenId, uint256 _duration) external {
    require(tokenContract.ownerOf(_tokenId) == msg.sender, "Only token owner allowed");
    require(_duration > 0, "Invalid timeout duration");

    burnTimeoutDuration[_tokenId] = _duration;

    emit SetBurnTimeout(_tokenId, _duration);
  }

  function cancelTokenBurn(uint256 _tokenId) external {
    require(burnTimeoutAt[_tokenId] != 0, "Burn not initiated");
    require(tokenContract.ownerOf(_tokenId) == msg.sender, "Only token owner allowed");

    burnTimeoutAt[_tokenId] = 0;

    emit CancelTokenBurn(_tokenId);
  }

   

  function propose(
    bytes calldata _data,
    string calldata _dataLink
  )
    external
    payable
  {
    address msgSender = msg.sender;
    uint256 tokenId = fetchTokenId(_data);
    uint256 proposalId = _nextId();

    Proposal storage p = proposals[proposalId];

    if (msgSender == geoDataManager) {
      p.geoDataManagerApproved = true;
    } else if (msgSender == tokenContract.ownerOf(tokenId)) {
      _acceptProposalFee();
      p.tokenOwnerApproved = true;
    } else {
      revert("Missing permissions");
    }

    p.creator = msgSender;
    p.data = _data;
    p.dataLink = _dataLink;
    p.status = ProposalStatus.PENDING;

    emit NewProposal(proposalId, tokenId, msg.sender);
  }

  function approve(uint256 _proposalId) external {
    Proposal storage p = proposals[_proposalId];
    uint256 tokenId = fetchTokenId(p.data);

    require(p.status == ProposalStatus.PENDING, "Expect PENDING status");

    if (p.geoDataManagerApproved == true) {
      require(msg.sender == tokenContract.ownerOf(tokenId), "Missing permissions");
      p.tokenOwnerApproved = true;
    } else if (p.tokenOwnerApproved == true) {
      require(msg.sender == geoDataManager, "Missing permissions");
      p.geoDataManagerApproved = true;
    } else {
      revert("Missing permissions");
    }

    emit ProposalApproval(_proposalId, tokenId);

    p.status = ProposalStatus.APPROVED;

    execute(_proposalId);
  }

  function reject(uint256 _proposalId) external {
    Proposal storage p = proposals[_proposalId];
    uint256 tokenId = fetchTokenId(p.data);

    require(p.status == ProposalStatus.PENDING, "Expect PENDING status");

    if (p.geoDataManagerApproved == true) {
      require(msg.sender == tokenContract.ownerOf(tokenId), "Missing permissions");
    } else if (p.tokenOwnerApproved == true) {
      require(msg.sender == geoDataManager, "Missing permissions");
    } else {
      revert("Missing permissions");
    }

    p.status = ProposalStatus.REJECTED;

    emit ProposalRejection(_proposalId, tokenId);
  }

  function cancel(uint256 _proposalId) external {
    Proposal storage p = proposals[_proposalId];
    uint256 tokenId = fetchTokenId(p.data);

    require(p.status == ProposalStatus.PENDING, "Expect PENDING status");

    if (msg.sender == geoDataManager) {
      require(p.geoDataManagerApproved == true, "Only own proposals can be cancelled");
    } else if (msg.sender == tokenContract.ownerOf(tokenId)) {
      require(p.tokenOwnerApproved == true, "Only own proposals can be cancelled");
    } else {
      revert("Missing permissions");
    }

    p.status = ProposalStatus.CANCELLED;

    emit ProposalCancellation(_proposalId, tokenId);
  }

   

  function execute(uint256 _proposalId) public {
    Proposal storage p = proposals[_proposalId];

    require(p.tokenOwnerApproved == true, "Token owner approval required");
    require(p.geoDataManagerApproved == true, "GeoDataManager approval required");
    require(p.status == ProposalStatus.APPROVED, "Expect APPROVED status");

    p.status = ProposalStatus.EXECUTED;

    (bool ok,) = address(tokenContract)
      .call
      .gas(gasleft().sub(50000))(p.data);

    if (ok == false) {
      emit ProposalExecutionFailed(_proposalId);
      p.status = ProposalStatus.APPROVED;
    } else {
      emit ProposalExecuted(_proposalId);
    }
  }

  function burnTokenByTimeout(uint256 _tokenId) external {
    require(burnTimeoutAt[_tokenId] != 0, "Timeout not set");
    require(block.timestamp > burnTimeoutAt[_tokenId], "Timeout has not passed yet");
    require(tokenContract.ownerOf(_tokenId) != address(0), "Token already burned");

    tokenContract.burn(_tokenId);

    emit BurnTokenByTimeout(_tokenId);
  }

   
  function fetchTokenId(bytes memory _data) public pure returns (uint256 tokenId) {
    assembly {
      tokenId := mload(add(_data, 0x24))
    }

    require(tokenId > 0, "Failed fetching tokenId from encoded data");
  }

   

  function _nextId() internal returns (uint256) {
    idCounter += 1;
    return idCounter;
  }

  function _galtToken() internal view returns (IERC20) {
    return IERC20(globalRegistry.getGaltTokenAddress());
  }

  function _acceptProposalFee() internal {
    if (msg.value == 0) {
      _galtToken().transferFrom(msg.sender, address(this), fees[PROPOSAL_GALT_FEE_KEY]);
    } else {
      require(msg.value == fees[PROPOSAL_ETH_FEE_KEY], "Invalid fee");
    }
  }
}

contract PPTokenControllerFactory {
  event NewPPTokenController(address indexed token, address controller);

   

  function build(
    IPPGlobalRegistry _globalRegistry,
    IPPToken _tokenContract,
    uint256 _defaultBurnTimeoutDuration
  )
    external
    returns (PPTokenController)
  {
    PPTokenController ppTokenController = new PPTokenController(
      _globalRegistry,
      _tokenContract,
      _defaultBurnTimeoutDuration
    );

    ppTokenController.transferOwnership(msg.sender);

    emit NewPPTokenController(address(_tokenContract), address(ppTokenController));

    return ppTokenController;
  }
}

library Strings {
     
    function fromUint256(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC165 is IERC165 {
     
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

     
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
         
         
        _registerInterface(_INTERFACE_ID_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
         
         
         
        uint256 _value;  
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => Counters.Counter) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

     
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721);
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

     
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

     
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

     
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public {
         
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

     
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

     
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

     
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

     
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {
     
    string private _name;

     
    string private _symbol;

     
    mapping(uint256 => string) private _tokenURIs;

     
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

     
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

         
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

     
    function name() external view returns (string memory) {
        return _name;
    }

     
    function symbol() external view returns (string memory) {
        return _symbol;
    }

     
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

     
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

         
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {
     
    mapping(address => uint256[]) private _ownedTokens;

     
    mapping(uint256 => uint256) private _ownedTokensIndex;

     
    uint256[] private _allTokens;

     
    mapping(uint256 => uint256) private _allTokensIndex;

     
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

     
    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

     
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

     
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

     
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

     
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
         
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

     
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

     
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

     
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

     
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
         
         

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

         
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;  
            _ownedTokensIndex[lastTokenId] = tokenIndex;  
        }

         
        _ownedTokens[from].length--;

         
         
    }

     
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
         
         

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

         
         
         
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;  
        _allTokensIndex[lastTokenId] = tokenIndex;  

         
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
         
    }
}

contract PPToken is IPPToken, ERC721Full, Ownable {

  uint256 public constant VERSION = 2;

  uint256 public tokenIdCounter;
  address payable public controller;
  string public contractDataLink;
  string public baseURI;

  bytes32[] public legalAgreementIpfsHashList;

   
  mapping(uint256 => Property) internal properties;
   
  mapping(uint256 => uint256) public propertyCreatedAt;
   
  mapping(uint256 => mapping(bytes32 => bytes32)) public propertyExtraData;
   
  mapping(bytes32 => bytes32) public extraData;

  modifier onlyController() {
    require(msg.sender == controller, "Only controller allowed");

    _;
  }

  constructor(string memory _name, string memory _symbol) public ERC721Full(_name, _symbol) {
    baseURI = "";
  }

   

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    baseURI = _baseURI;

    emit SetBaseURI(baseURI);
  }

  function setContractDataLink(string calldata _dataLink) external onlyOwner {
    contractDataLink = _dataLink;

    emit SetContractDataLink(_dataLink);
  }

  function setLegalAgreementIpfsHash(bytes32 _legalAgreementIpfsHash) external onlyOwner {
    legalAgreementIpfsHashList.push(_legalAgreementIpfsHash);

    emit SetLegalAgreementIpfsHash(_legalAgreementIpfsHash);
  }

  function setController(address payable _controller) external onlyOwner {
    controller = _controller;

    emit SetController(_controller);
  }

   

  function mint(address _to) external onlyController returns(uint256) {
    uint256 id = nextTokenId();

    emit Mint(_to, id);

    _mint(_to, id);

    propertyCreatedAt[id] = block.timestamp;

    return id;
  }

  function incrementSetupStage(uint256 _tokenId) external onlyController {
    properties[_tokenId].setupStage += 1;
  }

  function setDetails(
    uint256 _tokenId,
    TokenType _tokenType,
    AreaSource _areaSource,
    uint256 _area,
    bytes32 _ledgerIdentifier,
    string calldata _humanAddress,
    string calldata _dataLink
  )
    external
    onlyController
  {
    Property storage p = properties[_tokenId];

    p.tokenType = _tokenType;
    p.areaSource = _areaSource;
    p.area = _area;
    p.ledgerIdentifier = _ledgerIdentifier;
    p.humanAddress = _humanAddress;
    p.dataLink = _dataLink;

    emit SetDetails(msg.sender, _tokenId);
  }

  function setContour(
    uint256 _tokenId,
    uint256[] calldata _contour,
    int256 _highestPoint
  )
    external
    onlyController
  {
    Property storage p = properties[_tokenId];

    p.contour = _contour;
    p.highestPoint = _highestPoint;

    emit SetContour(msg.sender, _tokenId);
  }

  function setHumanAddress(uint256 _tokenId, string calldata _humanAddress) external onlyController {
    properties[_tokenId].humanAddress = _humanAddress;

    emit SetHumanAddress(_tokenId, _humanAddress);
  }

  function setArea(uint256 _tokenId, uint256 _area, AreaSource _areaSource) external onlyController {
    properties[_tokenId].area = _area;
    properties[_tokenId].areaSource = _areaSource;

    emit SetArea(_tokenId, _area, _areaSource);
  }

  function setLedgerIdentifier(uint256 _tokenId, bytes32 _ledgerIdentifier) external onlyController {
    properties[_tokenId].ledgerIdentifier = _ledgerIdentifier;

    emit SetLedgerIdentifier(_tokenId, _ledgerIdentifier);
  }

  function setDataLink(uint256 _tokenId, string calldata _dataLink) external onlyController {
    properties[_tokenId].dataLink = _dataLink;

    emit SetDataLink(_tokenId, _dataLink);
  }

  function setVertexRootHash(uint256 _tokenId, bytes32 _vertexRootHash) external onlyController {
    properties[_tokenId].vertexRootHash = _vertexRootHash;

    emit SetVertexRootHash(_tokenId, _vertexRootHash);
  }

  function setVertexStorageLink(uint256 _tokenId, string calldata _vertexStorageLink) external onlyController {
    properties[_tokenId].vertexStorageLink = _vertexStorageLink;

    emit SetVertexStorageLink(_tokenId, _vertexStorageLink);
  }

  function setExtraData(bytes32 _key, bytes32 _value) external onlyController {
    extraData[_key] = _value;

    emit SetExtraData(_key, _value);
  }

  function setPropertyExtraData(uint256 _tokenId, bytes32 _key, bytes32 _value) external onlyController {
    propertyExtraData[_tokenId][_key] = _value;

    emit SetPropertyExtraData(_tokenId, _key, _value);
  }

  function burn(uint256 _tokenId) external onlyController {
    address owner = ownerOf(_tokenId);

    delete properties[_tokenId];

    _burn(owner, _tokenId);

    emit Burn(owner, _tokenId);
  }

   

  function nextTokenId() internal returns (uint256) {
    tokenIdCounter += 1;
    return tokenIdCounter;
  }

   

   
  function tokenURI(uint256 _tokenId) external view returns (string memory) {
    require(_exists(_tokenId), "PPToken: URI query for nonexistent token");

     
    return string(abi.encodePacked(baseURI, Strings.fromUint256(_tokenId)));
  }

  function getLastLegalAgreementIpfsHash() external view returns (bytes32) {
    return legalAgreementIpfsHashList[legalAgreementIpfsHashList.length - 1];
  }

  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
    return _tokensOfOwner(_owner);
  }

  function exists(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  function getType(uint256 _tokenId) external view returns (TokenType) {
    return properties[_tokenId].tokenType;
  }

  function getContour(uint256 _tokenId) external view returns (uint256[] memory) {
    return properties[_tokenId].contour;
  }

  function getHighestPoint(uint256 _tokenId) external view returns (int256) {
    return properties[_tokenId].highestPoint;
  }

  function getHumanAddress(uint256 _tokenId) external view returns (string memory) {
    return properties[_tokenId].humanAddress;
  }

  function getArea(uint256 _tokenId) external view returns (uint256) {
    return properties[_tokenId].area;
  }

  function getAreaSource(uint256 _tokenId) external view returns (AreaSource) {
    return properties[_tokenId].areaSource;
  }

  function getLedgerIdentifier(uint256 _tokenId) external view returns (bytes32) {
    return properties[_tokenId].ledgerIdentifier;
  }

  function getDataLink(uint256 _tokenId) external view returns (string memory) {
    return properties[_tokenId].dataLink;
  }

  function getContourLength(uint256 _tokenId) external view returns (uint256) {
    return properties[_tokenId].contour.length;
  }

  function getVertexRootHash(uint256 _tokenId) external view returns (bytes32) {
    return properties[_tokenId].vertexRootHash;
  }

  function getVertexStorageLink(uint256 _tokenId) external view returns (string memory) {
    return properties[_tokenId].vertexStorageLink;
  }

  function getSetupStage(uint256 _tokenId) external view returns(uint256) {
    return properties[_tokenId].setupStage;
  }

  function getDetails(uint256 _tokenId)
    external
    view
    returns (
      TokenType tokenType,
      uint256[] memory contour,
      int256 highestPoint,
      AreaSource areaSource,
      uint256 area,
      bytes32 ledgerIdentifier,
      string memory humanAddress,
      string memory dataLink,
      uint256 setupStage,
      bytes32 vertexRootHash,
      string memory vertexStorageLink
    )
  {
    Property storage p = properties[_tokenId];

    return (
      p.tokenType,
      p.contour,
      p.highestPoint,
      p.areaSource,
      p.area,
      p.ledgerIdentifier,
      p.humanAddress,
      p.dataLink,
      p.setupStage,
      p.vertexRootHash,
      p.vertexStorageLink
    );
  }
}

interface IPPTokenRegistry {
  event AddToken(address indexed token, address indexed owener, address indexed factory);
  event SetFactory(address factory);
  event SetLockerRegistry(address lockerRegistry);

  function tokenList(uint256 _index) external view returns (address);
  function isValid(address _tokenContract) external view returns (bool);
  function requireValidToken(address _token) external view;
  function addToken(address _privatePropertyToken) external;
  function getAllTokens() external view returns (address[] memory);
}

contract ChargesFee is Ownable {
  using SafeERC20 for IERC20;

  event SetFeeManager(address addr);
  event SetFeeCollector(address addr);
  event SetEthFee(uint256 ethFee);
  event SetGaltFee(uint256 ethFee);
  event WithdrawEth(address indexed to, uint256 amount);
  event WithdrawErc20(address indexed to, address indexed tokenAddress, uint256 amount);
  event WithdrawErc721(address indexed to, address indexed tokenAddress, uint256 tokenId);

  uint256 public ethFee;
  uint256 public galtFee;

  address public feeManager;
  address public feeCollector;

  modifier onlyFeeManager() {
    require(msg.sender == feeManager, "ChargesFee: caller is not the feeManager");
    _;
  }

  modifier onlyFeeCollector() {
    require(msg.sender == feeCollector, "ChargesFee: caller is not the feeCollector");
    _;
  }

  constructor(uint256 _ethFee, uint256 _galtFee) public {
    ethFee = _ethFee;
    galtFee = _galtFee;
  }

   

  function _galtToken() internal view returns (IERC20);

   

  function setFeeManager(address _addr) external onlyOwner {
    feeManager = _addr;

    emit SetFeeManager(_addr);
  }

  function setFeeCollector(address _addr) external onlyOwner {
    feeCollector = _addr;

    emit SetFeeCollector(_addr);
  }

  function setEthFee(uint256 _ethFee) external onlyFeeManager {
    ethFee = _ethFee;

    emit SetEthFee(_ethFee);
  }

  function setGaltFee(uint256 _galtFee) external onlyFeeManager {
    galtFee = _galtFee;

    emit SetGaltFee(_galtFee);
  }

   

  function withdrawErc20(address _tokenAddress, address _to) external onlyFeeCollector {
    uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));

    IERC20(_tokenAddress).transfer(_to, balance);

    emit WithdrawErc20(_to, _tokenAddress, balance);
  }

  function withdrawErc721(address _tokenAddress, address _to, uint256 _tokenId) external onlyFeeCollector {
    IERC721(_tokenAddress).transferFrom(address(this), _to, _tokenId);

    emit WithdrawErc721(_to, _tokenAddress, _tokenId);
  }

  function withdrawEth(address payable _to) external onlyFeeCollector {
    uint256 balance = address(this).balance;

    _to.transfer(balance);

    emit WithdrawEth(_to, balance);
  }

   

  function _acceptPayment() internal {
    if (msg.value == 0) {
      _galtToken().transferFrom(msg.sender, address(this), galtFee);
    } else {
      require(msg.value == ethFee, "Fee and msg.value not equal");
    }
  }
}

contract PPTokenFactory is Ownable, ChargesFee {
  event Build(address token, address controller);
  event SetGlobalRegistry(address globalRegistry);

  IPPGlobalRegistry public globalRegistry;
  PPTokenControllerFactory public ppTokenControllerFactory;

  constructor(
    address _ppTokenControllerFactory,
    address _globalRegistry,
    uint256 _ethFee,
    uint256 _galtFee
  )
    public
    ChargesFee(_ethFee, _galtFee)
    Ownable()
  {
    ppTokenControllerFactory = PPTokenControllerFactory(_ppTokenControllerFactory);
    globalRegistry = IPPGlobalRegistry(_globalRegistry);
  }

   

  function build(
    string calldata _tokenName,
    string calldata _tokenSymbol,
    string calldata _dataLink,
    uint256 _defaultBurnDuration,
    bytes32[] calldata _feeKeys,
    uint256[] calldata _feeValues,
    bytes32 _legalAgreementIpfsHash
  )
    external
    payable
    returns (address)
  {
    _acceptPayment();

     
    PPToken ppToken = new PPToken(
      _tokenName,
      _tokenSymbol
    );
    PPTokenController ppTokenController = ppTokenControllerFactory.build(globalRegistry, ppToken, _defaultBurnDuration);

     
    ppToken.setContractDataLink(_dataLink);
    ppToken.setLegalAgreementIpfsHash(_legalAgreementIpfsHash);
    ppToken.setController(address(ppTokenController));
    ppTokenController.setMinter(msg.sender);
    ppTokenController.setGeoDataManager(msg.sender);

    ppTokenController.setFeeManager(address(this));

    for (uint256 i = 0; i < _feeKeys.length; i++) {
      ppTokenController.setFee(_feeKeys[i], _feeValues[i]);
    }

    ppTokenController.setFeeManager(msg.sender);
    ppTokenController.setFeeCollector(msg.sender);

     
    ppTokenController.transferOwnership(msg.sender);
    ppToken.transferOwnership(msg.sender);

    IPPTokenRegistry(globalRegistry.getPPTokenRegistryAddress())
      .addToken(address(ppToken));

    emit Build(address(ppToken), address(ppTokenController));

    return address(ppToken);
  }

   

  function _galtToken() internal view returns (IERC20) {
    return IERC20(globalRegistry.getGaltTokenAddress());
  }
}