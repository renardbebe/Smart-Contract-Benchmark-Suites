 

pragma solidity 0.4.18;

 
 
 
 

contract Ownable {
    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed _by, address indexed _to);
    event OwnershipTransferred(address indexed _from, address indexed _to);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerCandidate() {
        require(msg.sender == newOwnerCandidate);
        _;
    }

     
     
    function requestOwnershipTransfer(address _newOwnerCandidate) external onlyOwner {
        require(_newOwnerCandidate != address(0));

        newOwnerCandidate = _newOwnerCandidate;

        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
    function acceptOwnership() external onlyOwnerCandidate {
        address previousOwner = owner;

        owner = newOwnerCandidate;
        newOwnerCandidate = address(0);

        OwnershipTransferred(previousOwner, owner);
    }
}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function toPower2(uint256 a) internal pure returns (uint256) {
        return mul(a, a);
    }

    function sqrt(uint256 a) internal pure returns (uint256) {
        uint256 c = (a + 1) / 2;
        uint256 b = a;
        while (c < b) {
            b = c;
            c = (a / c + c) / 2;
        }
        return b;
    }
}

 
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address _owner) constant public returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}



 
contract ERC677 is ERC20 {
    function transferAndCall(address to, uint value, bytes data) public returns (bool ok);

    event TransferAndCall(address indexed from, address indexed to, uint value, bytes data);
}

 
 
contract ERC223Receiver {
    function tokenFallback(address _sender, uint _value, bytes _data) external returns (bool ok);
}




 
 
contract BasicToken is ERC20 {
    using SafeMath for uint256;

    uint256 public totalSupply;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) balances;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool) {
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
            revert();
        }

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


     
     
     
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

        return true;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        var _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = _allowance.sub(_value);

        Transfer(_from, _to, _value);

        return true;
    }
}






 

contract Standard677Token is ERC677, BasicToken {

   
   
   
   
  function transferAndCall(address _to, uint _value, bytes _data) public returns (bool) {
    require(super.transfer(_to, _value));  
    TransferAndCall(msg.sender, _to, _value, _data);
     
    if (isContract(_to)) return contractFallback(_to, _value, _data);
    return true;
  }

   
   
   
   
  function contractFallback(address _to, uint _value, bytes _data) private returns (bool) {
    ERC223Receiver receiver = ERC223Receiver(_to);
    require(receiver.tokenFallback(msg.sender, _value, _data));
    return true;
  }

   
   
   
  function isContract(address _addr) private constant returns (bool is_contract) {
     
    uint length;
    assembly { length := extcodesize(_addr) }
    return length > 0;
  }
}





 
contract TokenHolder is Ownable {
     
     
     
    function transferAnyERC20Token(address _tokenAddress, uint256 _amount) public onlyOwner returns (bool success) {
        return ERC20(_tokenAddress).transfer(owner, _amount);
    }
}






 
 
contract ColuLocalNetwork is Ownable, Standard677Token, TokenHolder {
    using SafeMath for uint256;

    string public constant name = "Colu Local Network";
    string public constant symbol = "CLN";

     
    uint8 public constant decimals = 18;

     
     
    bool public isTransferable = false;

    event TokensTransferable();

    modifier transferable() {
        require(msg.sender == owner || isTransferable);
        _;
    }

     
    function ColuLocalNetwork(uint256 _totalSupply) public {
        totalSupply = _totalSupply;
        balances[msg.sender] = totalSupply;
    }

     
    function makeTokensTransferable() external onlyOwner {
        if (isTransferable) {
            return;
        }

        isTransferable = true;

        TokensTransferable();
    }

     
     
     
    function approve(address _spender, uint256 _value) public transferable returns (bool) {
        return super.approve(_spender, _value);
    }

     
     
     
    function transfer(address _to, uint256 _value) public transferable returns (bool) {
        return super.transfer(_to, _value);
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public transferable returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
     
     
     
    function transferAndCall(address _to, uint _value, bytes _data) public transferable returns (bool success) {
      return super.transferAndCall(_to, _value, _data);
    }
}



  

contract Standard223Receiver is ERC223Receiver {
  Tkn tkn;

  struct Tkn {
    address addr;
    address sender;  
    uint256 value;
  }

  bool __isTokenFallback;

  modifier tokenPayable {
    require(__isTokenFallback);
    _;
  }

   
   
   
   
  function tokenFallback(address _sender, uint _value, bytes _data) external returns (bool ok) {
    if (!supportsToken(msg.sender)) {
      return false;
    }

     
     
    tkn = Tkn(msg.sender, _sender, _value);
    __isTokenFallback = true;
    if (!address(this).delegatecall(_data)) {
      __isTokenFallback = false;
      return false;
    }
     
     
    __isTokenFallback = false;

    return true;
  }

  function supportsToken(address token) public constant returns (bool);
}





 
 

contract TokenOwnable is Standard223Receiver, Ownable {
     
    modifier onlyTokenOwner() {
        require(tkn.sender == owner);
        _;
    }
}






 
 
 
 
contract VestingTrustee is TokenOwnable {
    using SafeMath for uint256;

     
    ColuLocalNetwork public cln;

     
    struct Grant {
        uint256 value;
        uint256 start;
        uint256 cliff;
        uint256 end;
        uint256 installmentLength;  
        uint256 transferred;
        bool revokable;
    }

     
    mapping (address => Grant) public grants;

     
    uint256 public totalVesting;

    event NewGrant(address indexed _from, address indexed _to, uint256 _value);
    event TokensUnlocked(address indexed _to, uint256 _value);
    event GrantRevoked(address indexed _holder, uint256 _refund);

    uint constant OK = 1;
    uint constant ERR_INVALID_VALUE = 10001;
    uint constant ERR_INVALID_VESTED = 10002;
    uint constant ERR_INVALID_TRANSFERABLE = 10003;

    event Error(address indexed sender, uint error);

     
     
    function VestingTrustee(ColuLocalNetwork _cln) public {
        require(_cln != address(0));

        cln = _cln;
    }

     
     
    function supportsToken(address token) public constant returns (bool) {
        return (cln == token);
    }

     
     
     
     
     
     
     
    function grant(address _to, uint256 _start, uint256 _cliff, uint256 _end,
        uint256 _installmentLength, bool _revokable)
        external onlyTokenOwner tokenPayable {

        require(_to != address(0));
        require(_to != address(this));  

        uint256 value = tkn.value;

        require(value > 0);

         
        require(grants[_to].value == 0);

         
        require(_start <= _cliff && _cliff <= _end);

         
        require(_installmentLength > 0 && _installmentLength <= _end.sub(_start));

         
        require(totalVesting.add(value) <= cln.balanceOf(address(this)));

         
        grants[_to] = Grant({
            value: value,
            start: _start,
            cliff: _cliff,
            end: _end,
            installmentLength: _installmentLength,
            transferred: 0,
            revokable: _revokable
        });

         
        totalVesting = totalVesting.add(value);

        NewGrant(msg.sender, _to, value);
    }

     
     
     
     
     
     
     
     
    function grant(address _to, uint256 _value, uint256 _start, uint256 _cliff, uint256 _end,
        uint256 _installmentLength, bool _revokable)
        external onlyOwner {

        require(_to != address(0));
        require(_to != address(this));  
        require(_value > 0);

         
        require(grants[_to].value == 0);

         
        require(_start <= _cliff && _cliff <= _end);

         
        require(_installmentLength > 0 && _installmentLength <= _end.sub(_start));

         
        require(totalVesting.add(_value) <= cln.balanceOf(address(this)));

         
        grants[_to] = Grant({
            value: _value,
            start: _start,
            cliff: _cliff,
            end: _end,
            installmentLength: _installmentLength,
            transferred: 0,
            revokable: _revokable
        });

         
        totalVesting = totalVesting.add(_value);

        NewGrant(msg.sender, _to, _value);
    }

     
     
     
    function revoke(address _holder) public onlyOwner {
        Grant memory grant = grants[_holder];

         
        require(grant.revokable);

         
        uint256 vested = calculateVestedTokens(grant, now);

         
        uint256 transferable = vested.sub(grant.transferred);

        if (transferable > 0) {
             
            grant.transferred = grant.transferred.add(transferable);
            totalVesting = totalVesting.sub(transferable);
            require(cln.transfer(_holder, transferable));

            TokensUnlocked(_holder, transferable);
        }

         
        uint256 refund = grant.value.sub(grant.transferred);

         
        delete grants[_holder];

         
        totalVesting = totalVesting.sub(refund);
        require(cln.transfer(msg.sender, refund));

        GrantRevoked(_holder, refund);
    }

     
     
     
    function readyTokens(address _holder) public constant returns (uint256) {
        Grant memory grant = grants[_holder];

        if (grant.value == 0) {
            return 0;
        }

        uint256 vested = calculateVestedTokens(grant, now);

        if (vested == 0) {
            return 0;
        }

        return vested.sub(grant.transferred);
    }

     
     
     
     
    function vestedTokens(address _holder, uint256 _time) public constant returns (uint256) {
        Grant memory grant = grants[_holder];
        if (grant.value == 0) {
            return 0;
        }

        return calculateVestedTokens(grant, _time);
    }

     
     
     
     
    function calculateVestedTokens(Grant _grant, uint256 _time) private pure returns (uint256) {
         
        if (_time < _grant.cliff) {
            return 0;
        }

         
        if (_time >= _grant.end) {
            return _grant.value;
        }

         
         
         
        uint256 installmentsPast = _time.sub(_grant.start).div(_grant.installmentLength);

         
        uint256 vestingDays = _grant.end.sub(_grant.start);

         
        return _grant.value.mul(installmentsPast.mul(_grant.installmentLength)).div(vestingDays);
    }

     
     
    function unlockVestedTokens() external returns (uint) {
        return unlockVestedTokens(msg.sender);
    }

     
     
     
    function unlockVestedTokens(address _grantee) private returns (uint) {
        Grant storage grant = grants[_grantee];

         
        if (grant.value == 0) {
            Error(_grantee, ERR_INVALID_VALUE);
            return ERR_INVALID_VALUE;
        }

         
        uint256 vested = calculateVestedTokens(grant, now);
        if (vested == 0) {
            Error(_grantee, ERR_INVALID_VESTED);
            return ERR_INVALID_VESTED;
        }

         
        uint256 transferable = vested.sub(grant.transferred);
        if (transferable == 0) {
            Error(_grantee, ERR_INVALID_TRANSFERABLE);
            return ERR_INVALID_TRANSFERABLE;
        }

         
        grant.transferred = grant.transferred.add(transferable);
        totalVesting = totalVesting.sub(transferable);
        require(cln.transfer(_grantee, transferable));

        TokensUnlocked(_grantee, transferable);
        return OK;
    }

     
     
     
    function batchUnlockVestedTokens(address[] _grantees) external onlyOwner returns (bool success) {
        for (uint i = 0; i<_grantees.length; i++) {
            unlockVestedTokens(_grantees[i]);
        }
        return true;
    }

     
     
     
    function withdrawERC20(address _tokenAddress, uint256 _amount) public onlyOwner returns (bool success) {
        if (_tokenAddress == address(cln)) {
             
            uint256 availableCLN = cln.balanceOf(this).sub(totalVesting);
            require(_amount <= availableCLN);
        }
        return ERC20(_tokenAddress).transfer(owner, _amount);
    }
}








 
 
contract ColuLocalNetworkSale is Ownable, TokenHolder {
    using SafeMath for uint256;

     

     
    ColuLocalNetwork public cln;

     
    VestingTrustee public trustee;

     
    address public fundingRecipient;

     
    address public communityPoolAddress;
    address public futureDevelopmentPoolAddress;
    address public stakeholdersPoolAddress;

     
     
     
    uint256 public constant TOKEN_DECIMALS = 10 ** 18;

     
    uint256 public constant ALAP = 40701333592592592592614116;

     
    uint256 public constant MAX_TOKENS = 15 * 10 ** 8 * TOKEN_DECIMALS + ALAP;

     
    uint256 public constant MAX_TOKENS_SOLD = 525 * 10 ** 6 * TOKEN_DECIMALS + ALAP;

     
    uint256 public constant MAX_PRESALE_TOKENS_SOLD = 2625 * 10 ** 5 * TOKEN_DECIMALS + ALAP;

     
    uint256 public constant COMMUNITY_POOL = 45 * 10 ** 7 * TOKEN_DECIMALS;

     
    uint256 public constant FUTURE_DEVELOPMENT_POOL = 435 * 10 ** 6 * TOKEN_DECIMALS;

     
    uint256 public constant STAKEHOLDERS_POOL = 9 * 10 ** 7 * TOKEN_DECIMALS;

     
    uint256 public constant CLN_PER_ETH = 8600;

     
    uint256 public constant SALE_DURATION = 4 days;
    uint256 public startTime;
    uint256 public endTime;

     
    uint256 public tokensSold = 0;

     
    uint256 public presaleTokensSold = 0;

     
    mapping (address => uint256) public participationHistory;

     
    mapping (address => uint256) public participationPresaleHistory;

     
     
    mapping (address => uint256) public participationCaps;

     
    uint256 public hardParticipationCap = uint256(-1);

     
    bool public initialized = false;

     
    struct VestingPlan {
        uint256 startOffset;
        uint256 cliffOffset;
        uint256 endOffset;
        uint256 installmentLength;
        uint8 alapPercent;
    }

     
    VestingPlan[] public vestingPlans;

     
    event TokensIssued(address indexed to, uint256 tokens);

     
    modifier onlyBeforeSale() {
        if (now >= startTime) {
            revert();
        }

        _;
    }

     
    modifier onlyDuringSale() {
        if (tokensSold >= MAX_TOKENS_SOLD || now < startTime || now >= endTime) {
            revert();
        }

        _;
    }

     
    modifier onlyAfterSale() {
        if (!(tokensSold >= MAX_TOKENS_SOLD || now >= endTime)) {
            revert();
        }

        _;
    }

     
    modifier notInitialized() {
        if (initialized) {
            revert();
        }

        _;
    }


     
    modifier isInitialized() {
        if (!initialized) {
            revert();
        }

        _;
    }

     
     
     
     
     
     
     
    function ColuLocalNetworkSale(address _owner,
        address _fundingRecipient,
        address _communityPoolAddress,
        address _futureDevelopmentPoolAddress,
        address _stakeholdersPoolAddress,
        uint256 _startTime) public {
        require(_owner != address(0));
        require(_fundingRecipient != address(0));
        require(_communityPoolAddress != address(0));
        require(_futureDevelopmentPoolAddress != address(0));
        require(_stakeholdersPoolAddress != address(0));
        require(_startTime > now);

        owner = _owner;
        fundingRecipient = _fundingRecipient;
        communityPoolAddress = _communityPoolAddress;
        futureDevelopmentPoolAddress = _futureDevelopmentPoolAddress;
        stakeholdersPoolAddress = _stakeholdersPoolAddress;
        startTime = _startTime;
        endTime = startTime + SALE_DURATION;
    }

     
    function initialize() public onlyOwner notInitialized {
        initialized = true;

        uint256 months = 1 years / 12;

        vestingPlans.push(VestingPlan(0, 0, 1, 1, 0));
        vestingPlans.push(VestingPlan(0, 0, 6 * months, 1 * months, 4));
        vestingPlans.push(VestingPlan(0, 0, 1 years, 1 * months, 12));
        vestingPlans.push(VestingPlan(0, 0, 2 years, 1 * months, 26));
        vestingPlans.push(VestingPlan(0, 0, 3 years, 1 * months, 35));

         
        cln = new ColuLocalNetwork(MAX_TOKENS);

         
        trustee = new VestingTrustee(cln);

         
         
        require(transferTokens(communityPoolAddress, COMMUNITY_POOL));

         
        require(transferTokens(stakeholdersPoolAddress, STAKEHOLDERS_POOL));
    }

     
     
     
     
    function presaleAllocation(address _recipient, uint256 _etherValue, uint8 _vestingPlanIndex) external onlyOwner onlyBeforeSale isInitialized {
        require(_recipient != address(0));
        require(_vestingPlanIndex < vestingPlans.length);

         
        VestingPlan memory plan = vestingPlans[_vestingPlanIndex];
        uint256 tokensAndALAPPerEth = CLN_PER_ETH.mul(SafeMath.add(100, plan.alapPercent)).div(100);

        uint256 tokensLeftInPreSale = MAX_PRESALE_TOKENS_SOLD.sub(presaleTokensSold);
        uint256 weiLeftInSale = tokensLeftInPreSale.div(tokensAndALAPPerEth);
        uint256 weiToParticipate = SafeMath.min256(_etherValue, weiLeftInSale);
        require(weiToParticipate > 0);
        participationPresaleHistory[msg.sender] = participationPresaleHistory[msg.sender].add(weiToParticipate);
        uint256 tokensToTransfer = weiToParticipate.mul(tokensAndALAPPerEth);
        presaleTokensSold = presaleTokensSold.add(tokensToTransfer);
        tokensSold = tokensSold.add(tokensToTransfer);

         
        grant(_recipient, tokensToTransfer, startTime.add(plan.startOffset), startTime.add(plan.cliffOffset),
            startTime.add(plan.endOffset), plan.installmentLength, false);
    }

     
     
     
    function setParticipationCap(address[] _participants, uint256 _cap) external onlyOwner isInitialized {
        for (uint i = 0; i < _participants.length; i++) {
            participationCaps[_participants[i]] = _cap;
        }
    }

     
     
    function setHardParticipationCap(uint256 _cap) external onlyOwner isInitialized {
        require(_cap > 0);

        hardParticipationCap = _cap;
    }

     
    function () external payable onlyDuringSale isInitialized {
        participate(msg.sender);
    }

     
     
    function participate(address _recipient) public payable onlyDuringSale isInitialized {
        require(_recipient != address(0));

         
        uint256 weiAlreadyParticipated = participationHistory[_recipient];
        uint256 participationCap = SafeMath.min256(participationCaps[_recipient], hardParticipationCap);
        uint256 cappedWeiReceived = SafeMath.min256(msg.value, participationCap.sub(weiAlreadyParticipated));
        require(cappedWeiReceived > 0);

         
        uint256 tokensLeftInSale = MAX_TOKENS_SOLD.sub(tokensSold);
        uint256 weiLeftInSale = tokensLeftInSale.div(CLN_PER_ETH);
        uint256 weiToParticipate = SafeMath.min256(cappedWeiReceived, weiLeftInSale);
        participationHistory[_recipient] = weiAlreadyParticipated.add(weiToParticipate);
        fundingRecipient.transfer(weiToParticipate);

         
        uint256 tokensToTransfer = weiToParticipate.mul(CLN_PER_ETH);
        if (tokensLeftInSale.sub(tokensToTransfer) < CLN_PER_ETH) {
             
             
            tokensToTransfer = tokensLeftInSale;
        }
        tokensSold = tokensSold.add(tokensToTransfer);
        require(transferTokens(_recipient, tokensToTransfer));

         
         
        uint256 refund = msg.value.sub(weiToParticipate);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
    }

     
    function finalize() external onlyAfterSale onlyOwner isInitialized {
        if (cln.isTransferable()) {
            revert();
        }

         
        uint256 tokensLeftInSale = MAX_TOKENS_SOLD.sub(tokensSold);
        uint256 futureDevelopmentPool = FUTURE_DEVELOPMENT_POOL.add(tokensLeftInSale);
         
        grant(futureDevelopmentPoolAddress, futureDevelopmentPool, startTime, startTime.add(3 years),
            startTime.add(3 years), 1 days, false);

         
        cln.makeTokensTransferable();
    }

    function grant(address _grantee, uint256 _amount, uint256 _start, uint256 _cliff, uint256 _end,
        uint256 _installmentLength, bool _revokable) private {
         
        bytes4 grantSig = 0x5ee7e96d;
         
        uint256 argsSize = 6 * 32;
         
        uint256 dataSize = 4 + argsSize;

        bytes memory m_data = new bytes(dataSize);

        assembly {
             
            mstore(add(m_data, 0x20), grantSig)
             
            mstore(add(m_data, 0x24), _grantee)
            mstore(add(m_data, 0x44), _start)
            mstore(add(m_data, 0x64), _cliff)
            mstore(add(m_data, 0x84), _end)
            mstore(add(m_data, 0xa4), _installmentLength)
            mstore(add(m_data, 0xc4), _revokable)
        }

        require(transferTokens(trustee, _amount, m_data));
    }

     
     
     
    function transferTokens(address _recipient, uint256 _tokens) private returns (bool ans) {
        ans = cln.transfer(_recipient, _tokens);
        if (ans) {
            TokensIssued(_recipient, _tokens);
        }
    }

     
     
     
     
    function transferTokens(address _recipient, uint256 _tokens, bytes _data) private returns (bool ans) {
         
        ans = cln.transferAndCall(_recipient, _tokens, _data);
        if (ans) {
            TokensIssued(_recipient, _tokens);
        }
    }

     
     
     
     
     
     
     
    function requestColuLocalNetworkOwnershipTransfer(address _newOwnerCandidate) external onlyOwner {
        cln.requestOwnershipTransfer(_newOwnerCandidate);
    }

     
     
    function acceptColuLocalNetworkOwnership() external onlyOwner {
        cln.acceptOwnership();
    }

     
     
     
     
     
     
     
    function requestVestingTrusteeOwnershipTransfer(address _newOwnerCandidate) external onlyOwner {
        trustee.requestOwnershipTransfer(_newOwnerCandidate);
    }

     
     
    function acceptVestingTrusteeOwnership() external onlyOwner {
        trustee.acceptOwnership();
    }
}