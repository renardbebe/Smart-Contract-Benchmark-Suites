 

pragma solidity ^0.4.15;

 
 
 
contract Ownable {
    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed _by, address indexed _to);
    event OwnershipTransferred(address indexed _from, address indexed _to);

     
     
    function Ownable() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }

        _;
    }

    modifier onlyOwnerCandidate() {
        if (msg.sender != newOwnerCandidate) {
            revert();
        }

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
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}

 
contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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

     
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


     
     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

        return true;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = _allowance.sub(_value);

        Transfer(_from, _to, _value);

        return true;
    }
}


 
contract TokenHolder is Ownable {
     
     
     
    function transferAnyERC20Token(address _tokenAddress, uint256 _amount) onlyOwner returns (bool success) {
        return ERC20(_tokenAddress).transfer(owner, _amount);
    }
}


 
contract KinToken is Ownable, BasicToken, TokenHolder {
    using SafeMath for uint256;

    string public constant name = "Kin";
    string public constant symbol = "KIN";

     
    uint8 public constant decimals = 18;

     
     
    bool public isMinting = true;

    event MintingEnded();

    modifier onlyDuringMinting() {
        require(isMinting);

        _;
    }

    modifier onlyAfterMinting() {
        require(!isMinting);

        _;
    }

     
     
     
    function mint(address _to, uint256 _amount) external onlyOwner onlyDuringMinting {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        Transfer(0x0, _to, _amount);
    }

     
    function endMinting() external onlyOwner {
        if (isMinting == false) {
            return;
        }

        isMinting = false;

        MintingEnded();
    }

     
     
     
    function approve(address _spender, uint256 _value) public onlyAfterMinting returns (bool) {
        return super.approve(_spender, _value);
    }

     
     
     
    function transfer(address _to, uint256 _value) public onlyAfterMinting returns (bool) {
        return super.transfer(_to, _value);
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public onlyAfterMinting returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}


 
contract VestingTrustee is Ownable {
    using SafeMath for uint256;

     
    KinToken public kin;

     
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

     
     
    function VestingTrustee(KinToken _kin) {
        require(_kin != address(0));

        kin = _kin;
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

         
        require(totalVesting.add(_value) <= kin.balanceOf(address(this)));

         
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

         
        uint256 refund = grant.value.sub(grant.transferred);

         
        delete grants[_holder];

         
        totalVesting = totalVesting.sub(refund);
        kin.transfer(msg.sender, refund);

        GrantRevoked(_holder, refund);
    }

     
     
     
     
    function vestedTokens(address _holder, uint256 _time) external constant returns (uint256) {
        Grant memory grant = grants[_holder];
        if (grant.value == 0) {
            return 0;
        }

        return calculateVestedTokens(grant, _time);
    }

     
     
     
     
    function calculateVestedTokens(Grant _grant, uint256 _time) private constant returns (uint256) {
         
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

     
    function unlockVestedTokens() external {
        Grant storage grant = grants[msg.sender];

         
        require(grant.value != 0);

         
        uint256 vested = calculateVestedTokens(grant, now);
        if (vested == 0) {
            return;
        }

         
        uint256 transferable = vested.sub(grant.transferred);
        if (transferable == 0) {
            return;
        }

         
        grant.transferred = grant.transferred.add(transferable);
        totalVesting = totalVesting.sub(transferable);
        kin.transfer(msg.sender, transferable);

        TokensUnlocked(msg.sender, transferable);
    }
}


 
contract KinTokenSale is Ownable, TokenHolder {
    using SafeMath for uint256;

     

     
    KinToken public kin;

     
    VestingTrustee public trustee;

     
    address public fundingRecipient;

     
     
     
    uint256 public constant TOKEN_UNIT = 10 ** 18;

     
    uint256 public constant MAX_TOKENS = 10 ** 13 * TOKEN_UNIT;

     
    uint256 public constant MAX_TOKENS_SOLD = 512195121951 * TOKEN_UNIT;

     
    uint256 public constant WEI_PER_USD = uint256(1 ether) / 289;

     
     
    uint256 public constant KIN_PER_USD = 6829 * TOKEN_UNIT;

     
    uint256 public constant KIN_PER_WEI = KIN_PER_USD / WEI_PER_USD;

     
    uint256 public constant SALE_DURATION = 14 days;
    uint256 public startTime;
    uint256 public endTime;

     
    uint256 public tokensSold = 0;

     
    uint256 public constant TIER_1_CAP = 100000 * WEI_PER_USD;
    uint256 public constant TIER_2_CAP = uint256(-1);  

     
    mapping (address => uint256) public participationHistory;

     
    mapping (address => uint256) public participationCaps;

     
    uint256 public hardParticipationCap = 4393 * WEI_PER_USD;

     
    struct TokenGrant {
        uint256 value;
        uint256 startOffset;
        uint256 cliffOffset;
        uint256 endOffset;
        uint256 installmentLength;
        uint8 percentVested;
    }

    address[] public tokenGrantees;
    mapping (address => TokenGrant) public tokenGrants;
    uint256 public lastGrantedIndex = 0;
    uint256 public constant MAX_TOKEN_GRANTEES = 100;
    uint256 public constant GRANT_BATCH_SIZE = 10;

     
    address public constant KIN_FOUNDATION_ADDRESS = 0x56aE76573EC54754bC5B6A8cBF04bBd7Dc86b0A0;
    address public constant KIK_ADDRESS = 0x3bf4BbE253153678E9E8E540395C22BFf7fCa87d;

    event TokensIssued(address indexed _to, uint256 _tokens);

     
    modifier onlyDuringSale() {
        require(!saleEnded() && now >= startTime);

        _;
    }

     
    modifier onlyAfterSale() {
        require(saleEnded());

        _;
    }

     
     
     
    function KinTokenSale(address _fundingRecipient, uint256 _startTime) {
        require(_fundingRecipient != address(0));
        require(_startTime > now);

         
        kin = new KinToken();

         
        trustee = new VestingTrustee(kin);

        fundingRecipient = _fundingRecipient;
        startTime = _startTime;
        endTime = startTime + SALE_DURATION;

         
        initTokenGrants();
    }

     
    function initTokenGrants() private onlyOwner {
         
         
         
        tokenGrantees.push(KIN_FOUNDATION_ADDRESS);
        tokenGrants[KIN_FOUNDATION_ADDRESS] = TokenGrant(MAX_TOKENS.mul(60).div(100), 0, 0, 3 years, 1 days, 0);

         
        tokenGrantees.push(KIK_ADDRESS);
        tokenGrants[KIK_ADDRESS] = TokenGrant(MAX_TOKENS.mul(30).div(100), 0, 0, 120 weeks, 12 weeks, 100);
    }

     
     
     
    function addTokenGrant(address _grantee, uint256 _value) external onlyOwner {
        require(_grantee != address(0));
        require(_value > 0);
        require(tokenGrantees.length + 1 <= MAX_TOKEN_GRANTEES);

         
        require(tokenGrants[_grantee].value == 0);
        for (uint i = 0; i < tokenGrantees.length; i++) {
            require(tokenGrantees[i] != _grantee);
        }

         
        tokenGrantees.push(_grantee);
        tokenGrants[_grantee] = TokenGrant(_value, 0, 1 years, 1 years, 1 days, 50);
    }

     
     
    function deleteTokenGrant(address _grantee) external onlyOwner {
        require(_grantee != address(0));

         
        for (uint i = 0; i < tokenGrantees.length; i++) {
            if (tokenGrantees[i] == _grantee) {
                delete tokenGrantees[i];

                break;
            }
        }

         
        delete tokenGrants[_grantee];
    }

     
     
     
    function setParticipationCap(address[] _participants, uint256 _cap) private onlyOwner {
        for (uint i = 0; i < _participants.length; i++) {
            participationCaps[_participants[i]] = _cap;
        }
    }

     
     
    function setTier1Participants(address[] _participants) external onlyOwner {
        setParticipationCap(_participants, TIER_1_CAP);
    }

     
     
    function setTier2Participants(address[] _participants) external onlyOwner {
        setParticipationCap(_participants, TIER_2_CAP);
    }

     
     
    function setHardParticipationCap(uint256 _cap) external onlyOwner {
        require(_cap > 0);

        hardParticipationCap = _cap;
    }

     
    function () external payable onlyDuringSale {
        create(msg.sender);
    }

     
     
    function create(address _recipient) public payable onlyDuringSale {
        require(_recipient != address(0));

         
        uint256 weiAlreadyParticipated = participationHistory[msg.sender];
        uint256 participationCap = SafeMath.min256(participationCaps[msg.sender], hardParticipationCap);
        uint256 cappedWeiReceived = SafeMath.min256(msg.value, participationCap.sub(weiAlreadyParticipated));
        require(cappedWeiReceived > 0);

         
        uint256 weiLeftInSale = MAX_TOKENS_SOLD.sub(tokensSold).div(KIN_PER_WEI);
        uint256 weiToParticipate = SafeMath.min256(cappedWeiReceived, weiLeftInSale);
        participationHistory[msg.sender] = weiAlreadyParticipated.add(weiToParticipate);
        fundingRecipient.transfer(weiToParticipate);

         
        uint256 tokensLeftInSale = MAX_TOKENS_SOLD.sub(tokensSold);
        uint256 tokensToIssue = weiToParticipate.mul(KIN_PER_WEI);
        if (tokensLeftInSale.sub(tokensToIssue) < KIN_PER_WEI) {
             
             
            tokensToIssue = tokensLeftInSale;
        }
        tokensSold = tokensSold.add(tokensToIssue);
        issueTokens(_recipient, tokensToIssue);

         
         
        uint256 refund = msg.value.sub(weiToParticipate);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
    }

     
    function finalize() external onlyAfterSale onlyOwner {
        if (!kin.isMinting()) {
            revert();
        }

        require(lastGrantedIndex == tokenGrantees.length);

         
        kin.endMinting();
    }

     
     
     
    function grantTokens() external onlyAfterSale onlyOwner {
        uint endIndex = SafeMath.min256(tokenGrantees.length, lastGrantedIndex + GRANT_BATCH_SIZE);
        for (uint i = lastGrantedIndex; i < endIndex; i++) {
            address grantee = tokenGrantees[i];

             
            TokenGrant memory tokenGrant = tokenGrants[grantee];
            uint256 tokensGranted = tokenGrant.value.mul(tokensSold).div(MAX_TOKENS_SOLD);
            uint256 tokensVesting = tokensGranted.mul(tokenGrant.percentVested).div(100);
            uint256 tokensIssued = tokensGranted.sub(tokensVesting);

             
            if (tokensIssued > 0) {
                issueTokens(grantee, tokensIssued);
            }

             
            if (tokensVesting > 0) {
                issueTokens(trustee, tokensVesting);
                trustee.grant(grantee, tokensVesting, now.add(tokenGrant.startOffset), now.add(tokenGrant.cliffOffset),
                    now.add(tokenGrant.endOffset), tokenGrant.installmentLength, true);
            }

            lastGrantedIndex++;
        }
    }

     
     
     
    function issueTokens(address _recipient, uint256 _tokens) private {
         
        kin.mint(_recipient, _tokens);

        TokensIssued(_recipient, _tokens);
    }

     
     
    function saleEnded() private constant returns (bool) {
        return tokensSold >= MAX_TOKENS_SOLD || now >= endTime;
    }

     
     
     
     
     
     
     
    function requestKinTokenOwnershipTransfer(address _newOwnerCandidate) external onlyOwner {
        kin.requestOwnershipTransfer(_newOwnerCandidate);
    }

     
     
    function acceptKinTokenOwnership() external onlyOwner {
        kin.acceptOwnership();
    }

     
     
     
     
     
     
     
    function requestVestingTrusteeOwnershipTransfer(address _newOwnerCandidate) external onlyOwner {
        trustee.requestOwnershipTransfer(_newOwnerCandidate);
    }

     
     
    function acceptVestingTrusteeOwnership() external onlyOwner {
        trustee.acceptOwnership();
    }
}