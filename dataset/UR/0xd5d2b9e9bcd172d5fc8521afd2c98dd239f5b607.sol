 

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 

pragma solidity 0.5.9;


interface ERC20Interface {
   
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
   
  function mint(address to, uint256 value) external returns (bool);
  function burn(address from, uint256 value) external returns (bool);
}

 

pragma solidity 0.5.9;





 
 
 
 
contract ERC20Base is ERC20Interface, ERC20, MinterRole {
  string public name;
  string public symbol;
  uint8 public decimals = 18;

  constructor(string memory _name, string memory _symbol) public {
    name = _name;
    symbol = _symbol;
  }

  function transferAndCall(address to, uint256 value, bytes4 sig, bytes memory data) public returns (bool) {
    require(to != address(this));
    _transfer(msg.sender, to, value);
    (bool success,) = to.call(abi.encodePacked(sig, uint256(msg.sender), value, data));
    require(success);
    return true;
  }

  function mint(address to, uint256 value) public onlyMinter returns (bool) {
    _mint(to, value);
    return true;
  }

  function burn(address from, uint256 value) public onlyMinter returns (bool) {
    _burn(from, value);
    return true;
  }
}

 

pragma solidity 0.5.9;




contract SnapshotToken is ERC20Base {
  using SafeMath for uint256;

   
   
   
   
   
  mapping (address => mapping(uint256 => uint256)) _votingPower;
  mapping (address => uint256) public votingPowerChangeCount;
  uint256 public votingPowerChangeNonce = 0;

   
  function historicalVotingPowerAtIndex(address owner, uint256 index) public view returns (uint256) {
    require(index <= votingPowerChangeCount[owner]);
    return _votingPower[owner][index] & ((1 << 192) - 1);   
  }

   
   
   
  function historicalVotingPowerAtNonce(address owner, uint256 nonce) public view returns (uint256) {
    require(nonce <= votingPowerChangeNonce && nonce < (1 << 64));
    uint256 start = 0;
    uint256 end = votingPowerChangeCount[owner];
    while (start < end) {
      uint256 mid = start.add(end).add(1).div(2);  
      if ((_votingPower[owner][mid] >> 192) > nonce) {   
         
        end = mid.sub(1);
      } else {
         
        start = mid;
      }
    }
    return historicalVotingPowerAtIndex(owner, start);
  }

  function _transfer(address from, address to, uint256 value) internal {
    super._transfer(from, to, value);
    votingPowerChangeNonce = votingPowerChangeNonce.add(1);
    _changeVotingPower(from);
    _changeVotingPower(to);
  }

  function _mint(address account, uint256 amount) internal {
    super._mint(account, amount);
    votingPowerChangeNonce = votingPowerChangeNonce.add(1);
    _changeVotingPower(account);
  }

  function _burn(address account, uint256 amount) internal {
    super._burn(account, amount);
    votingPowerChangeNonce = votingPowerChangeNonce.add(1);
    _changeVotingPower(account);
  }

  function _changeVotingPower(address account) internal {
    uint256 currentIndex = votingPowerChangeCount[account];
    uint256 newPower = balanceOf(account);
    require(newPower < (1 << 192));
    require(votingPowerChangeNonce < (1 << 64));
    currentIndex = currentIndex.add(1);
    votingPowerChangeCount[account] = currentIndex;
    _votingPower[account][currentIndex] = (votingPowerChangeNonce << 192) | newPower;
  }
}

 

pragma solidity 0.5.9;




 
contract BandToken is ERC20Base("BandToken", "BAND"), SnapshotToken {}

 

pragma solidity 0.5.9;

interface WhiteListInterface {
  function verify(address reader) external view returns (bool);
}

 

pragma solidity 0.5.9;


interface BandExchangeInterface {
  function convertFromEthToBand() external payable returns (uint256);
}

 

pragma solidity 0.5.9;






 
 
 
 
contract BandRegistry is Ownable {
  BandToken public band;
  BandExchangeInterface public exchange;
  WhiteListInterface public whiteList;

  constructor(BandToken _band, BandExchangeInterface _exchange) public {
    band = _band;
    exchange = _exchange;
  }

  function verify(address reader) public view returns (bool) {
    if (address(whiteList) == address(0)) return true;
    return whiteList.verify(reader);
  }

  function setWhiteList(WhiteListInterface _whiteList) public onlyOwner {
    whiteList = _whiteList;
  }

  function setExchange(BandExchangeInterface _exchange) public onlyOwner {
    exchange = _exchange;
  }
}

 

pragma solidity 0.5.9;



 
 
 
contract QueryInterface {
  enum QueryStatus { INVALID, OK, NOT_AVAILABLE, DISAGREEMENT }
  event Query(address indexed caller, bytes input, QueryStatus status);
  BandRegistry public registry;

  constructor(BandRegistry _registry) public {
    registry = _registry;
  }

  function query(bytes calldata input)
    external payable returns (bytes32 output, uint256 updatedAt, QueryStatus status)
  {
    require(registry.verify(msg.sender));
    uint256 price = queryPrice();
    require(msg.value >= price);
    if (msg.value > price) msg.sender.transfer(msg.value - price);
    (output, updatedAt, status) = queryImpl(input);
    emit Query(msg.sender, input, status);
  }

  function queryPrice() public view returns (uint256);
  function queryImpl(bytes memory input)
    internal returns (bytes32 output, uint256 updatedAt, QueryStatus status);
}

 

pragma solidity 0.5.9;



 
 
 
library Fractional {
  using SafeMath for uint256;
  uint256 internal constant DENOMINATOR = 1e18;

  function getDenominator() internal pure returns (uint256) {
    return DENOMINATOR;
  }

  function mulFrac(uint256 numerator, uint256 value) internal pure returns(uint256) {
    return numerator.mul(value).div(DENOMINATOR);
  }
}

 

pragma solidity 0.5.9;



 
 
contract ERC20Acceptor {
   
   
   
  modifier requireToken(ERC20Interface token, address sender, uint256 amount) {
    if (msg.sender != address(token)) {
      require(sender == msg.sender);
      require(token.transferFrom(sender, address(this), amount));
    }
    _;
  }
}

 

pragma solidity 0.5.9;


interface Expression {
   
  function evaluate(uint256 x) external view returns (uint256);
}

 

pragma solidity 0.5.9;






 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract Parameters is Ownable {
  using SafeMath for uint256;
  using Fractional for uint256;

  event ProposalProposed(uint256 indexed proposalId, address indexed proposer, bytes32 reasonHash);
  event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool vote, uint256 votingPower);
  event ProposalAccepted(uint256 indexed proposalId);
  event ProposalRejected(uint256 indexed proposalId);
  event ParameterChanged(bytes32 indexed key, uint256 value);
  event ParameterProposed(uint256 indexed proposalId, bytes32 indexed key, uint256 value);

  struct ParameterValue { bool existed; uint256 value; }
  struct KeyValue { bytes32 key; uint256 value; }
  enum ProposalState { INVALID, OPEN, ACCEPTED, REJECTED }

  struct Proposal {
    uint256 changesCount;                    
    mapping (uint256 => KeyValue) changes;   
    uint256 snapshotNonce;                   
    uint256 expirationTime;                  
    uint256 voteSupportRequiredPct;          
    uint256 voteMinParticipation;            
    uint256 totalVotingPower;                
    uint256 yesCount;                        
    uint256 noCount;                         
    mapping (address => bool) isVoted;       
    ProposalState proposalState;             
  }

  SnapshotToken public token;
  Proposal[] public proposals;
  mapping (bytes32 => ParameterValue) public params;

  constructor(SnapshotToken _token) public {
    token = _token;
  }

  function get(bytes8 namespace, bytes24 key) public view returns (uint256) {
    uint8 namespaceSize = 0;
    while (namespaceSize < 8 && namespace[namespaceSize] != byte(0)) ++namespaceSize;
    return getRaw(bytes32(namespace) | (bytes32(key) >> (8 * namespaceSize)));
  }

  function getRaw(bytes32 rawKey) public view returns (uint256) {
    ParameterValue storage param = params[rawKey];
    require(param.existed);
    return param.value;
  }

  function set(bytes8 namespace, bytes24[] memory keys, uint256[] memory values) public onlyOwner {
    require(keys.length == values.length);
    bytes32[] memory rawKeys = new bytes32[](keys.length);
    uint8 namespaceSize = 0;
    while (namespaceSize < 8 && namespace[namespaceSize] != byte(0)) ++namespaceSize;
    for (uint256 i = 0; i < keys.length; i++) {
      rawKeys[i] = bytes32(namespace) | bytes32(keys[i]) >> (8 * namespaceSize);
    }
    setRaw(rawKeys, values);
  }

  function setRaw(bytes32[] memory rawKeys, uint256[] memory values) public onlyOwner {
    require(rawKeys.length == values.length);
    for (uint256 i = 0; i < rawKeys.length; i++) {
      params[rawKeys[i]].existed = true;
      params[rawKeys[i]].value = values[i];
      emit ParameterChanged(rawKeys[i], values[i]);
    }
  }

  function getProposalChange(uint256 proposalId, uint256 changeIndex) public view returns (bytes32, uint256) {
    KeyValue memory keyValue = proposals[proposalId].changes[changeIndex];
    return (keyValue.key, keyValue.value);
  }

  function propose(bytes32 reasonHash, bytes32[] calldata keys, uint256[] calldata values) external {
    require(keys.length == values.length);
    uint256 proposalId = proposals.length;
    proposals.push(Proposal({
      changesCount: keys.length,
      snapshotNonce: token.votingPowerChangeNonce(),
      expirationTime: now.add(getRaw("params:expiration_time")),
      voteSupportRequiredPct: getRaw("params:support_required_pct"),
      voteMinParticipation: getRaw("params:min_participation_pct").mulFrac(token.totalSupply()),
      totalVotingPower: token.totalSupply(),
      yesCount: 0,
      noCount: 0,
      proposalState: ProposalState.OPEN
    }));
    emit ProposalProposed(proposalId, msg.sender, reasonHash);
    for (uint256 index = 0; index < keys.length; ++index) {
      bytes32 key = keys[index];
      uint256 value = values[index];
      emit ParameterProposed(proposalId, key, value);
      proposals[proposalId].changes[index] = KeyValue({key: key, value: value});
    }
  }

  function vote(uint256 proposalId, bool accepted) public {
    Proposal storage proposal = proposals[proposalId];
    require(proposal.proposalState == ProposalState.OPEN);
    require(now < proposal.expirationTime);
    require(!proposal.isVoted[msg.sender]);
    uint256 votingPower = token.historicalVotingPowerAtNonce(msg.sender, proposal.snapshotNonce);
    require(votingPower > 0);
    if (accepted) {
      proposal.yesCount = proposal.yesCount.add(votingPower);
    } else {
      proposal.noCount = proposal.noCount.add(votingPower);
    }
    proposal.isVoted[msg.sender] = true;
    emit ProposalVoted(proposalId, msg.sender, accepted, votingPower);
    uint256 minVoteToAccept = proposal.voteSupportRequiredPct.mulFrac(proposal.totalVotingPower);
    uint256 minVoteToReject = proposal.totalVotingPower.sub(minVoteToAccept);
    if (proposal.yesCount >= minVoteToAccept) {
      _acceptProposal(proposalId);
    } else if (proposal.noCount > minVoteToReject) {
      _rejectProposal(proposalId);
    }
  }

  function resolve(uint256 proposalId) public {
    Proposal storage proposal = proposals[proposalId];
    require(proposal.proposalState == ProposalState.OPEN);
    require(now >= proposal.expirationTime);
    uint256 yesCount = proposal.yesCount;
    uint256 noCount = proposal.noCount;
    uint256 totalCount = yesCount.add(noCount);
    if (totalCount >= proposal.voteMinParticipation &&
        yesCount.mul(Fractional.getDenominator()) >= proposal.voteSupportRequiredPct.mul(totalCount)) {
      _acceptProposal(proposalId);
    } else {
      _rejectProposal(proposalId);
    }
  }

  function _acceptProposal(uint256 proposalId) internal {
    Proposal storage proposal = proposals[proposalId];
    proposal.proposalState = ProposalState.ACCEPTED;
    for (uint256 index = 0; index < proposal.changesCount; ++index) {
      bytes32 key = proposal.changes[index].key;
      uint256 value = proposal.changes[index].value;
      params[key].existed = true;
      params[key].value = value;
      emit ParameterChanged(key, value);
    }
    emit ProposalAccepted(proposalId);
  }

  function _rejectProposal(uint256 proposalId) internal {
    Proposal storage proposal = proposals[proposalId];
    proposal.proposalState = ProposalState.REJECTED;
    emit ProposalRejected(proposalId);
  }
}

 

pragma solidity 0.5.9;








contract BondingCurve is ERC20Acceptor {
  using SafeMath for uint256;
  using Fractional for uint256;

  event Buy(address indexed buyer, uint256 bondedTokenAmount, uint256 collateralTokenAmount);
  event Sell(address indexed seller, uint256 bondedTokenAmount, uint256 collateralTokenAmount);
  event Deflate(address indexed burner, uint256 burnedAmount);
  event RevenueCollect(address indexed beneficiary, uint256 bondedTokenAmount);

  ERC20Interface public collateralToken;
  ERC20Interface public bondedToken;
  Parameters public params;

  uint256 public currentMintedTokens;
  uint256 public currentCollateral;
  uint256 public lastInflationTime = now;

  constructor(ERC20Interface _collateralToken, ERC20Interface _bondedToken, Parameters _params) public {
    collateralToken = _collateralToken;
    bondedToken = _bondedToken;
    params = _params;
  }

  function getRevenueBeneficiary() public view returns (address) {
    address beneficiary = address(params.getRaw("bonding:revenue_beneficiary"));
    require(beneficiary != address(0));
    return beneficiary;
  }

  function getInflationRateNumerator() public view returns (uint256) {
    return params.getRaw("bonding:inflation_rate");
  }

  function getLiquiditySpreadNumerator() public view returns (uint256) {
    return params.getRaw("bonding:liquidity_spread");
  }

  function getCollateralExpression() public view returns (Expression) {
    return Expression(address(params.getRaw("bonding:curve_expression")));
  }

  function getCollateralAtSupply(uint256 tokenSupply) public view returns (uint256) {
    Expression collateralExpression = getCollateralExpression();
    uint256 collateralFromEquationAtCurrent = collateralExpression.evaluate(currentMintedTokens);
    uint256 collateralFromEquationAtSupply = collateralExpression.evaluate(tokenSupply);
    if (collateralFromEquationAtCurrent == 0) {
      return collateralFromEquationAtSupply;
    } else {
      return collateralFromEquationAtSupply.mul(currentCollateral).div(collateralFromEquationAtCurrent);
    }
  }

  function curveMultiplier() public view returns (uint256) {
    return currentCollateral.mul(Fractional.getDenominator()).div(getCollateralExpression().evaluate(currentMintedTokens));
  }

  function getBuyPrice(uint256 tokenValue) public view returns (uint256) {
    uint256 nextSupply = currentMintedTokens.add(tokenValue);
    return getCollateralAtSupply(nextSupply).sub(currentCollateral);
  }

  function getSellPrice(uint256 tokenValue) public view returns (uint256) {
    uint256 currentSupply = currentMintedTokens;
    require(currentSupply >= tokenValue);
    uint256 nextSupply = currentMintedTokens.sub(tokenValue);
    return currentCollateral.sub(getCollateralAtSupply(nextSupply));
  }

  modifier _adjustAutoInflation() {
    uint256 currentSupply = currentMintedTokens;
    if (lastInflationTime < now) {
      uint256 pastSeconds = now.sub(lastInflationTime);
      uint256 inflatingSupply = getInflationRateNumerator().mul(pastSeconds).mulFrac(currentSupply);
      if (inflatingSupply != 0) {
        currentMintedTokens = currentMintedTokens.add(inflatingSupply);
        _rewardBondingCurveOwner(inflatingSupply);
      }
    }
    lastInflationTime = now;
    _;
  }

  function buy(address buyer, uint256 priceLimit, uint256 buyAmount)
    public
    requireToken(collateralToken, buyer, priceLimit)
    _adjustAutoInflation
  {
    uint256 liquiditySpread = getLiquiditySpreadNumerator().mulFrac(buyAmount);
    uint256 totalMintAmount = buyAmount.add(liquiditySpread);
    uint256 buyPrice = getBuyPrice(totalMintAmount);
    require(buyPrice > 0 && buyPrice <= priceLimit);
    if (priceLimit > buyPrice) {
      require(collateralToken.transfer(buyer, priceLimit.sub(buyPrice)));
    }
    require(bondedToken.mint(buyer, buyAmount));
    if (liquiditySpread > 0) {
      _rewardBondingCurveOwner(liquiditySpread);
    }
    currentMintedTokens = currentMintedTokens.add(totalMintAmount);
    currentCollateral = currentCollateral.add(buyPrice);
    emit Buy(buyer, buyAmount, buyPrice);
  }

  function sell(address seller, uint256 sellAmount, uint256 priceLimit)
    public
    requireToken(bondedToken, seller, sellAmount)
    _adjustAutoInflation
  {
    uint256 sellPrice = getSellPrice(sellAmount);
    require(sellPrice > 0 && sellPrice >= priceLimit);
    require(bondedToken.burn(address(this), sellAmount));
    require(collateralToken.transfer(seller, sellPrice));
    currentMintedTokens = currentMintedTokens.sub(sellAmount);
    currentCollateral = currentCollateral.sub(sellPrice);
    emit Sell(seller, sellAmount, sellPrice);
  }

  function deflate(address burner, uint256 burnAmount) public requireToken(bondedToken, burner, burnAmount) {
    require(bondedToken.burn(address(this), burnAmount));
    currentMintedTokens = currentMintedTokens.sub(burnAmount);
    emit Deflate(burner, burnAmount);
  }

  function _rewardBondingCurveOwner(uint256 rewardAmount) internal {
    address beneficiary = getRevenueBeneficiary();
    require(bondedToken.mint(beneficiary, rewardAmount));
    emit RevenueCollect(beneficiary, rewardAmount);
  }
}

 

pragma solidity ^0.5.0;

 
library Math {
     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

 

pragma solidity ^0.5.0;


contract CapperRole {
    using Roles for Roles.Role;

    event CapperAdded(address indexed account);
    event CapperRemoved(address indexed account);

    Roles.Role private _cappers;

    constructor () internal {
        _addCapper(msg.sender);
    }

    modifier onlyCapper() {
        require(isCapper(msg.sender), "CapperRole: caller does not have the Capper role");
        _;
    }

    function isCapper(address account) public view returns (bool) {
        return _cappers.has(account);
    }

    function addCapper(address account) public onlyCapper {
        _addCapper(account);
    }

    function renounceCapper() public {
        _removeCapper(msg.sender);
    }

    function _addCapper(address account) internal {
        _cappers.add(account);
        emit CapperAdded(account);
    }

    function _removeCapper(address account) internal {
        _cappers.remove(account);
        emit CapperRemoved(account);
    }
}

 

pragma solidity 0.5.9;






 
 
 
contract LockableToken is ERC20Base, CapperRole {
  using SafeMath for uint256;

  event TokenLocked(address indexed locker, address indexed owner, uint256 value);
  event TokenUnlocked(address indexed locker, address indexed owner, uint256 value);

  uint256 constant NOT_FOUND = uint256(-1);

  struct TokenLock {
    address locker;
    uint256 value;
  }

  mapping (address => TokenLock[]) _locks;

  function getLockedToken(address owner) public view returns (uint256) {
    TokenLock[] storage locks = _locks[owner];
    uint256 maxLock = 0;
    for (uint256 i = 0; i < locks.length; ++i) {
      maxLock = Math.max(maxLock, locks[i].value);
    }
    return maxLock;
  }

  function getLockedTokenAt(address owner, address locker) public view returns (uint256) {
    uint256 index = _getTokenLockIndex(owner, locker);
    if (index != NOT_FOUND) return _locks[owner][index].value;
    else return 0;
  }

  function unlockedBalanceOf(address owner) public view returns (uint256) {
    return balanceOf(owner).sub(getLockedToken(owner));
  }

  function lock(address owner, uint256 value) public onlyCapper returns (bool) {
    uint256 index = _getTokenLockIndex(owner, msg.sender);
    if (index != NOT_FOUND) {
      uint256 currentLock = _locks[owner][index].value;
      require(balanceOf(owner) >= currentLock.add(value));
      _locks[owner][index].value = currentLock.add(value);
    } else {
      require(balanceOf(owner) >= value);
      _locks[owner].push(TokenLock(msg.sender, value));
    }
    emit TokenLocked(msg.sender, owner, value);
    return true;
  }

  function unlock(address owner, uint256 value) public returns (bool) {
    uint256 index = _getTokenLockIndex(owner, msg.sender);
    require(index != NOT_FOUND);
    TokenLock[] storage locks = _locks[owner];
    require(locks[index].value >= value);
    locks[index].value = locks[index].value.sub(value);
    if (locks[index].value == 0) {
      if (index != locks.length - 1) {
        locks[index] = locks[locks.length - 1];
      }
      locks.pop();
    }
    emit TokenUnlocked(msg.sender, owner, value);
    return true;
  }

  function _getTokenLockIndex(address owner, address locker) internal view returns (uint256) {
    TokenLock[] storage locks = _locks[owner];
    for (uint256 i = 0; i < locks.length; ++i) {
      if (locks[i].locker == locker) return i;
    }
    return NOT_FOUND;
  }

  function _transfer(address from, address to, uint256 value) internal {
    require(unlockedBalanceOf(from) >= value);
    super._transfer(from, to, value);
  }

  function _burn(address account, uint256 value) internal {
    require(unlockedBalanceOf(account) >= value);
    super._burn(account, value);
  }
}

 

pragma solidity 0.5.9;








 
 
 
 
 
 
contract TCDBase is QueryInterface {
  using Fractional for uint256;
  using SafeMath for uint256;

  event DataSourceRegistered(address indexed dataSource, address indexed owner, uint256 stake);
  event DataSourceStaked(address indexed dataSource, address indexed participant, uint256 stake);
  event DataSourceUnstaked(address indexed dataSource, address indexed participant, uint256 unstake);
  event FeeDistributed(address indexed dataSource, uint256 totalReward, uint256 ownerReward);
  event WithdrawReceiptCreated(uint256 receiptIndex, address indexed owner, uint256 amount, uint64 withdrawTime);
  event WithdrawReceiptUnlocked(uint256 receiptIndex, address indexed owner, uint256 amount);

  enum Order {EQ, LT, GT}

  struct DataSourceInfo {
    address owner;
    uint256 stake;
    uint256 totalOwnerships;
    mapping (address => uint256) tokenLocks;
    mapping (address => uint256) ownerships;
  }

  struct WithdrawReceipt {
    address owner;
    uint256 amount;
    uint64 withdrawTime;
    bool isWithdrawn;
  }

  mapping (address => DataSourceInfo) public infoMap;
  mapping (address => address) activeList;
  mapping (address => address) reserveList;
  uint256 public activeCount;
  uint256 public reserveCount;

  address constant internal NOT_FOUND = address(0x00);
  address constant internal ACTIVE_GUARD = address(0x01);
  address constant internal RESERVE_GUARD = address(0x02);
  WithdrawReceipt[] public withdrawReceipts;

  BondingCurve public bondingCurve;
  Parameters public params;
  LockableToken public token;
  uint256 public undistributedReward;
  bytes8 public prefix;

  constructor(bytes8 _prefix, BondingCurve _bondingCurve, Parameters _params, BandRegistry _registry) public QueryInterface(_registry) {
    bondingCurve = _bondingCurve;
    params = _params;
    prefix = _prefix;
    token = LockableToken(address(_bondingCurve.bondedToken()));
    _registry.band().approve(address(_bondingCurve), 2 ** 256 - 1);
    activeList[ACTIVE_GUARD] = ACTIVE_GUARD;
    reserveList[RESERVE_GUARD] = RESERVE_GUARD;
  }

  function getOwnership(address dataSource, address staker) public view returns (uint256) {
    return infoMap[dataSource].ownerships[staker];
  }

  function getStake(address dataSource, address staker) public view returns (uint256) {
    DataSourceInfo storage provider = infoMap[dataSource];
    if (provider.totalOwnerships == 0) return 0;
    return provider.ownerships[staker].mul(provider.stake).div(provider.totalOwnerships);
  }

  function register(address dataSource, address prevDataSource, uint256 initialStake) public {
    require(dataSource != NOT_FOUND && dataSource != ACTIVE_GUARD && dataSource != RESERVE_GUARD);
    require(infoMap[dataSource].totalOwnerships == 0);
    require(initialStake > 0 && initialStake >= params.get(prefix, "min_provider_stake"));
    require(token.lock(msg.sender, initialStake));
    infoMap[dataSource] = DataSourceInfo({
      owner: msg.sender,
      stake: initialStake,
      totalOwnerships: initialStake
    });
    infoMap[dataSource].ownerships[msg.sender] = initialStake;
    infoMap[dataSource].tokenLocks[msg.sender] = initialStake;
    emit DataSourceRegistered(dataSource, msg.sender, initialStake);
    _addDataSource(dataSource, prevDataSource);
    _rebalanceLists();
  }

  function stake(address dataSource, address prevDataSource, address newPrevDataSource, uint256 value) public {
    require(token.lock(msg.sender, value));
    _removeDataSource(dataSource, prevDataSource);
    DataSourceInfo storage provider = infoMap[dataSource];
    uint256 newStakerTokenLock = provider.tokenLocks[msg.sender].add(value);
    provider.tokenLocks[msg.sender] = newStakerTokenLock;
    _stake(msg.sender, value, dataSource);
    if (getStake(dataSource, provider.owner) >= params.get(prefix, "min_provider_stake")) {
      _addDataSource(dataSource, newPrevDataSource);
    }
    _rebalanceLists();
  }

  function unstake(address dataSource, address prevDataSource, address newPrevDataSource, uint256 withdrawOwnership) public {
    DataSourceInfo storage provider = infoMap[dataSource];
    require(withdrawOwnership <= provider.ownerships[msg.sender]);
    _removeDataSource(dataSource, prevDataSource);
    uint256 newOwnership = provider.totalOwnerships.sub(withdrawOwnership);
    uint256 currentStakerStake = getStake(dataSource, msg.sender);
    if (currentStakerStake > provider.tokenLocks[msg.sender]) {
      uint256 unrealizedStake = currentStakerStake.sub(provider.tokenLocks[msg.sender]);
      require(token.transfer(msg.sender, unrealizedStake));
      require(token.lock(msg.sender, unrealizedStake));
    }
    uint256 withdrawAmount = provider.stake.mul(withdrawOwnership).div(provider.totalOwnerships);
    uint256 newStake = provider.stake.sub(withdrawAmount);
    uint256 newStakerTokenLock = currentStakerStake.sub(withdrawAmount);
    uint256 newStakerOwnership = provider.ownerships[msg.sender].sub(withdrawOwnership);
    provider.stake = newStake;
    provider.totalOwnerships = newOwnership;
    provider.ownerships[msg.sender] = newStakerOwnership;
    provider.tokenLocks[msg.sender] = newStakerTokenLock;
    uint256 delay;
    if (msg.sender == provider.owner && (delay = params.get(prefix, "withdraw_delay")) > 0) {
      uint256 withdrawTime = now.add(delay);
      require(withdrawTime < (1 << 64));
      withdrawReceipts.push(WithdrawReceipt({
        owner: provider.owner,
        amount: withdrawAmount,
        withdrawTime: uint64(withdrawTime),
        isWithdrawn: false
      }));
      emit WithdrawReceiptCreated(withdrawReceipts.length - 1, provider.owner, withdrawAmount, uint64(withdrawTime));
    } else {
      require(token.unlock(msg.sender, withdrawAmount));
    }
    emit DataSourceUnstaked(dataSource, msg.sender, withdrawAmount);
    if (getStake(dataSource, provider.owner) >= params.get(prefix, "min_provider_stake")) {
      _addDataSource(dataSource, newPrevDataSource);
    }
    _rebalanceLists();
  }

  function addETHFee() public payable {}

  function addTokenFee(uint256 tokenAmount) public {
    token.transferFrom(msg.sender, address(this), tokenAmount);
    undistributedReward = undistributedReward.add(tokenAmount);
  }

  function distributeFee(uint256 tokenAmount) public {
    require(address(this).balance > 0);
    registry.exchange().convertFromEthToBand.value(address(this).balance)();
    bondingCurve.buy(address(this), registry.band().balanceOf(address(this)), tokenAmount);
    undistributedReward = undistributedReward.add(tokenAmount);
    uint256 providerReward = undistributedReward.div(activeCount);
    uint256 ownerPercentage = params.get(prefix, "owner_revenue_pct");
    uint256 ownerReward = ownerPercentage.mulFrac(providerReward);
    uint256 stakeIncreased = providerReward.sub(ownerReward);
    address dataSourceAddress = activeList[ACTIVE_GUARD];
    while (dataSourceAddress != ACTIVE_GUARD) {
      DataSourceInfo storage provider = infoMap[dataSourceAddress];
      provider.stake = provider.stake.add(stakeIncreased);
      if (ownerReward > 0) _stake(provider.owner, ownerReward, dataSourceAddress);
      undistributedReward = undistributedReward.sub(providerReward);
      emit FeeDistributed(dataSourceAddress, providerReward, ownerReward);
      dataSourceAddress = activeList[dataSourceAddress];
    }
  }

  function distributeStakeReward(uint256 tokenAmount) public {
    token.transferFrom(msg.sender, address(this), tokenAmount);
    uint256 remainingReward = tokenAmount;
    uint256 stakeReward = tokenAmount.div(activeCount);
    address dataSourceAddress = activeList[ACTIVE_GUARD];
    while (dataSourceAddress != ACTIVE_GUARD) {
      DataSourceInfo storage provider = infoMap[dataSourceAddress];
      provider.stake = provider.stake.add(stakeReward);
      remainingReward = remainingReward.sub(stakeReward);
      emit FeeDistributed(dataSourceAddress, stakeReward, 0);
      dataSourceAddress = activeList[dataSourceAddress];
    }
    undistributedReward = undistributedReward.add(remainingReward);
  }

  function unlockTokenFromReceipt(uint256 receiptId) public {
    WithdrawReceipt storage receipt = withdrawReceipts[receiptId];
    require(!receipt.isWithdrawn && now >= receipt.withdrawTime);
    receipt.isWithdrawn = true;
    require(token.unlock(receipt.owner, receipt.amount));
    emit WithdrawReceiptUnlocked(receiptId, receipt.owner, receipt.amount);
  }

  function _stake(address staker, uint256 value, address dataSource) internal {
    DataSourceInfo storage provider = infoMap[dataSource];
    require(provider.totalOwnerships > 0);
    uint256 newStake = provider.stake.add(value);
    uint256 newtotalOwnerships = newStake.mul(provider.totalOwnerships).div(provider.stake);
    uint256 newStakerOwnership = provider.ownerships[staker].add(newtotalOwnerships.sub(provider.totalOwnerships));
    provider.ownerships[staker] = newStakerOwnership;
    provider.stake = newStake;
    provider.totalOwnerships = newtotalOwnerships;
    emit DataSourceStaked(dataSource, staker, value);
  }

  function _compare(address dataSourceLeft, address dataSourceRight) internal view returns (Order) {
    if (dataSourceLeft == dataSourceRight) return Order.EQ;
    DataSourceInfo storage leftProvider = infoMap[dataSourceLeft];
    DataSourceInfo storage rightProvider = infoMap[dataSourceRight];
    if (leftProvider.stake != rightProvider.stake) return leftProvider.stake < rightProvider.stake ? Order.LT : Order.GT;
    return uint256(dataSourceLeft) < uint256(dataSourceRight) ? Order.LT : Order.GT;  
  }

  function _findPrevDataSource(address dataSource) internal view returns (address) {
    if (activeCount != 0 && _compare(dataSource, activeList[ACTIVE_GUARD]) != Order.LT) {
      address currentIndex = ACTIVE_GUARD;
      while (activeList[currentIndex] != ACTIVE_GUARD) {
        address nextIndex = activeList[currentIndex];
        if (_compare(dataSource, nextIndex) == Order.GT) currentIndex = nextIndex;
        else break;
      }
      return currentIndex;
    } else if (reserveCount != 0) {
      address currentIndex = RESERVE_GUARD;
      while (reserveList[currentIndex] != RESERVE_GUARD) {
        address nextIndex = reserveList[currentIndex];
        if (_compare(dataSource, nextIndex) == Order.LT) currentIndex = nextIndex;
        else break;
      }
      return currentIndex;
    } else {
      return RESERVE_GUARD;
    }
  }

  function _addDataSource(address dataSource, address _prevDataSource) internal {
    address prevDataSource = _prevDataSource == NOT_FOUND ? _findPrevDataSource(dataSource) : _prevDataSource;
    if (activeList[prevDataSource] != NOT_FOUND) {
      if (prevDataSource == ACTIVE_GUARD) require(reserveCount == 0 || _compare(dataSource, reserveList[RESERVE_GUARD]) == Order.GT);
      else require(_compare(dataSource, prevDataSource) == Order.GT);
      require(activeList[prevDataSource] == ACTIVE_GUARD || _compare(activeList[prevDataSource], dataSource) == Order.GT);
      activeList[dataSource] = activeList[prevDataSource];
      activeList[prevDataSource] = dataSource;
      activeCount++;
    } else if (reserveList[prevDataSource] != NOT_FOUND) {
      if (prevDataSource == RESERVE_GUARD) require(activeCount == 0 || _compare(activeList[ACTIVE_GUARD], dataSource) == Order.GT);
      else require(_compare(prevDataSource, dataSource) == Order.GT);
      require(reserveList[prevDataSource] == RESERVE_GUARD || _compare(dataSource, reserveList[prevDataSource]) == Order.GT);
      reserveList[dataSource] = reserveList[prevDataSource];
      reserveList[prevDataSource] = dataSource;
      reserveCount++;
    } else {
      revert();
    }
  }

  function _removeDataSource(address dataSource, address _prevDataSource) internal {
    if (activeList[dataSource] == NOT_FOUND && reserveList[dataSource] == NOT_FOUND) return;
    address prevDataSource = _prevDataSource == NOT_FOUND ? _findPrevDataSource(dataSource) : _prevDataSource;
    if (activeList[prevDataSource] != NOT_FOUND) {
      require(dataSource != ACTIVE_GUARD);
      require(activeList[prevDataSource] == dataSource);
      activeList[prevDataSource] = activeList[dataSource];
      activeList[dataSource] = NOT_FOUND;
      activeCount--;
    } else if (reserveList[prevDataSource] != NOT_FOUND) {
      require(dataSource != RESERVE_GUARD);
      require(reserveList[prevDataSource] == dataSource);
      reserveList[prevDataSource] = reserveList[dataSource];
      reserveList[dataSource] = NOT_FOUND;
      reserveCount--;
    }
  }

  function _rebalanceLists() internal {
    uint256 maxProviderCount = params.get(prefix, "max_provider_count");
    while (activeCount < maxProviderCount && reserveCount > 0) {
      address dataSource = reserveList[RESERVE_GUARD];
      _removeDataSource(dataSource, RESERVE_GUARD);
      _addDataSource(dataSource, ACTIVE_GUARD);
    }
    while (activeCount > maxProviderCount) {
      address dataSource = activeList[ACTIVE_GUARD];
      _removeDataSource(dataSource, ACTIVE_GUARD);
      _addDataSource(dataSource, RESERVE_GUARD);
    }
  }
}

 

pragma solidity 0.5.9;




 
 
 
contract OffchainAggTCD is TCDBase {
  using SafeMath for uint256;

  event DataUpdated(bytes key, uint256 value, uint64 timestamp, QueryStatus status);

  struct DataPoint {
    uint256 value;
    uint64 timestamp;
    QueryStatus status;
  }

  mapping (bytes => DataPoint) private aggData;

  constructor(bytes8 _prefix, BondingCurve _bondingCurve, Parameters _params, BandRegistry _registry)
    public TCDBase(_prefix, _bondingCurve, _params, _registry) {}

  function queryPrice() public view returns (uint256) {
    return params.get(prefix, "query_price");
  }

  function report(
    bytes calldata key, uint256 value, uint64 timestamp, QueryStatus status,
    uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s
  ) external {
    require(v.length == r.length && v.length == s.length);
    uint256 validSignatures = 0;
    bytes32 message = keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n32",
      keccak256(abi.encodePacked(key, value, timestamp, status, address(this))))
    );
    address lastSigner = address(0);
    for (uint256 i = 0; i < v.length; ++i) {
      address recovered = ecrecover(message, v[i], r[i], s[i]);
      require(recovered > lastSigner);
      lastSigner = recovered;
      if (activeList[recovered] != NOT_FOUND) {
        validSignatures++;
      }
    }
    require(validSignatures.mul(3) > activeCount.mul(2));
    require(timestamp > aggData[key].timestamp && uint256(timestamp) <= now);
    aggData[key] = DataPoint({
      value: value,
      timestamp: timestamp,
      status: status
    });
    emit DataUpdated(key, value, timestamp, status);
  }

  function queryImpl(bytes memory input) internal returns (bytes32 output, uint256 updatedAt, QueryStatus status) {
    DataPoint storage data = aggData[input];
    if (data.timestamp == 0) return ("", 0, QueryStatus.NOT_AVAILABLE);
    if (data.status != QueryStatus.OK) return ("", data.timestamp, data.status);
    return (bytes32(data.value), data.timestamp, QueryStatus.OK);
  }
}