 

pragma solidity ^0.4.11;

 
contract IOwned {
     
    function owner() public constant returns (address owner) { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 
contract IERC20Token {
     
    function name() public constant returns (string name) { name; }
    function symbol() public constant returns (string symbol) { symbol; }
    function decimals() public constant returns (uint8 decimals) { decimals; }
    function totalSupply() public constant returns (uint256 totalSupply) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

 
contract ISmartToken is ITokenHolder, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

 
contract SafeMath {
     
    function SafeMath() {
    }

     
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 
contract ERC20Token is IERC20Token, SafeMath {
    string public standard = 'Token 0.1';
    string public name = '';
    string public symbol = '';
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function ERC20Token(string _name, string _symbol, uint8 _decimals) {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0);  

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
         
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 
contract TokenHolder is ITokenHolder, Owned {
     
    function TokenHolder() {
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}

 
contract SmartToken is ISmartToken, ERC20Token, Owned, TokenHolder {
    string public version = '0.2';

    bool public transfersEnabled = true;     

     
    event NewSmartToken(address _token);
     
    event Issuance(uint256 _amount);
     
    event Destruction(uint256 _amount);

     
    function SmartToken(string _name, string _symbol, uint8 _decimals)
        ERC20Token(_name, _symbol, _decimals)
    {
        require(bytes(_symbol).length <= 6);  
        NewSmartToken(address(this));
    }

     
    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

     
    function disableTransfers(bool _disable) public ownerOnly {
        transfersEnabled = !_disable;
    }

     
    function issue(address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_to)
        notThis(_to)
    {
        totalSupply = safeAdd(totalSupply, _amount);
        balanceOf[_to] = safeAdd(balanceOf[_to], _amount);

        Issuance(_amount);
        Transfer(this, _to, _amount);
    }

     
    function destroy(address _from, uint256 _amount)
        public
        ownerOnly
    {
        balanceOf[_from] = safeSub(balanceOf[_from], _amount);
        totalSupply = safeSub(totalSupply, _amount);

        Transfer(_from, this, _amount);
        Destruction(_amount);
    }

     

     
    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transfer(_to, _value));

         
        if (_to == address(this)) {
            balanceOf[_to] -= _value;
            totalSupply -= _value;
            Destruction(_value);
        }

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transferFrom(_from, _to, _value));

         
        if (_to == address(this)) {
            balanceOf[_to] -= _value;
            totalSupply -= _value;
            Destruction(_value);
        }

        return true;
    }
}

 
 
 
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
            throw;
        }

        _;
    }

     
     
    function transferOwnership(address _newOwnerCandidate) onlyOwner {
        require(_newOwnerCandidate != address(0));

        newOwnerCandidate = _newOwnerCandidate;

        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
    function acceptOwnership() {
        if (msg.sender == newOwnerCandidate) {
            owner = newOwnerCandidate;
            newOwnerCandidate = address(0);

            OwnershipTransferred(owner, newOwnerCandidate);
        }
    }
}

 
library SaferMath {
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


 
contract StoxSmartToken is SmartToken {
    function StoxSmartToken() SmartToken('Stox', 'STX', 18) {
        disableTransfers(true);
    }
}


 
contract Trustee is Ownable {
    using SaferMath for uint256;

     
    StoxSmartToken public stox;

    struct Grant {
        uint256 value;
        uint256 start;
        uint256 cliff;
        uint256 end;
        uint256 transferred;
        bool revokable;
    }

     
    mapping (address => Grant) public grants;

     
    uint256 public totalVesting;

    event NewGrant(address indexed _from, address indexed _to, uint256 _value);
    event UnlockGrant(address indexed _holder, uint256 _value);
    event RevokeGrant(address indexed _holder, uint256 _refund);

     
     
    function Trustee(StoxSmartToken _stox) {
        require(_stox != address(0));

        stox = _stox;
    }

     
     
     
     
     
     
     
    function grant(address _to, uint256 _value, uint256 _start, uint256 _cliff, uint256 _end, bool _revokable)
        public onlyOwner {
        require(_to != address(0));
        require(_value > 0);

         
        require(grants[_to].value == 0);

         
        require(_start <= _cliff && _cliff <= _end);

         
        require(totalVesting.add(_value) <= stox.balanceOf(address(this)));

         
        grants[_to] = Grant({
            value: _value,
            start: _start,
            cliff: _cliff,
            end: _end,
            transferred: 0,
            revokable: _revokable
        });

         
        totalVesting = totalVesting.add(_value);

        NewGrant(msg.sender, _to, _value);
    }

     
     
    function revoke(address _holder) public onlyOwner {
        Grant grant = grants[_holder];

        require(grant.revokable);

         
        uint256 refund = grant.value.sub(grant.transferred);

         
        delete grants[_holder];

        totalVesting = totalVesting.sub(refund);
        stox.transfer(msg.sender, refund);

        RevokeGrant(_holder, refund);
    }

     
     
     
     
    function vestedTokens(address _holder, uint256 _time) public constant returns (uint256) {
        Grant grant = grants[_holder];
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

         
         return _grant.value.mul(_time.sub(_grant.start)).div(_grant.end.sub(_grant.start));
    }

     
     
    function unlockVestedTokens() public {
        Grant grant = grants[msg.sender];
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
        stox.transfer(msg.sender, transferable);

        UnlockGrant(msg.sender, transferable);
    }
}


 
contract StoxSmartTokenSale is Ownable {
    using SaferMath for uint256;

    uint256 public constant DURATION = 14 days;

    bool public isFinalized = false;
    bool public isDistributed = false;

     
    StoxSmartToken public stox;

     
    Trustee public trustee;

    uint256 public startTime = 0;
    uint256 public endTime = 0;
    address public fundingRecipient;

    uint256 public tokensSold = 0;

     
    uint256 public constant ETH_CAP = 148000;
    uint256 public constant EXCHANGE_RATE = 200;  
    uint256 public constant TOKEN_SALE_CAP = ETH_CAP * EXCHANGE_RATE * 10 ** 18;

    event TokensIssued(address indexed _to, uint256 _tokens);

     
    modifier onlyDuringSale() {
        if (tokensSold >= TOKEN_SALE_CAP || now < startTime || now >= endTime) {
            throw;
        }

        _;
    }

     
    modifier onlyAfterSale() {
        if (!(tokensSold >= TOKEN_SALE_CAP || now >= endTime)) {
            throw;
        }

        _;
    }

     
     
     
    function StoxSmartTokenSale(address _stox, address _fundingRecipient, uint256 _startTime) {
        require(_stox != address(0));
        require(_fundingRecipient != address(0));
        require(_startTime > now);

        stox = StoxSmartToken(_stox);

        fundingRecipient = _fundingRecipient;
        startTime = _startTime;
        endTime = startTime + DURATION;
    }

     
    function distributePartnerTokens() external onlyOwner {
        require(!isDistributed);

        assert(tokensSold == 0);
        assert(stox.totalSupply() == 0);

         
         
         
         
        issueTokens(0x9065260ef6830f6372F1Bde408DeC57Fe3150530, 14800000 * 10 ** 18);

        isDistributed = true;
    }

     
    function finalize() external onlyAfterSale {
        if (isFinalized) {
            throw;
        }

         
         
         
        trustee = new Trustee(stox);

         
         
        uint256 unsoldTokens = tokensSold;

         
        uint256 strategicPartnershipTokens = unsoldTokens.mul(55).div(100);

         
         
        stox.issue(0xbC14105ccDdeAadB96Ba8dCE18b40C45b6bACf58, strategicPartnershipTokens);

         
        stox.issue(trustee, unsoldTokens.sub(strategicPartnershipTokens));

         
        trustee.grant(0xb54c6a870d4aD65e23d471Fb7941aD271D323f5E, unsoldTokens.mul(25).div(100), now, now,
            now.add(1 years), true);

         
        trustee.grant(0x4eB4Cd1D125d9d281709Ff38d65b99a6927b46c1, unsoldTokens.mul(20).div(100), now, now,
            now.add(2 years), true);

         
        stox.disableTransfers(false);

        isFinalized = true;
    }

     
     
    function create(address _recipient) public payable onlyDuringSale {
        require(_recipient != address(0));
        require(msg.value > 0);

        assert(isDistributed);

        uint256 tokens = SaferMath.min256(msg.value.mul(EXCHANGE_RATE), TOKEN_SALE_CAP.sub(tokensSold));
        uint256 contribution = tokens.div(EXCHANGE_RATE);

        issueTokens(_recipient, tokens);

         
        fundingRecipient.transfer(contribution);

         
         
        uint256 refund = msg.value.sub(contribution);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
    }

     
     
     
    function issueTokens(address _recipient, uint256 _tokens) private {
         
        tokensSold = tokensSold.add(_tokens);

        stox.issue(_recipient, _tokens);

        TokensIssued(_recipient, _tokens);
    }

     
    function () external payable onlyDuringSale {
        create(msg.sender);
    }

     
     
     
     
     
     
     
    function transferSmartTokenOwnership(address _newOwnerCandidate) external onlyOwner {
        stox.transferOwnership(_newOwnerCandidate);
    }

     
     
    function acceptSmartTokenOwnership() external onlyOwner {
        stox.acceptOwnership();
    }

     
     
     
     
     
     
     
    function transferTrusteeOwnership(address _newOwnerCandidate) external onlyOwner {
        trustee.transferOwnership(_newOwnerCandidate);
    }

     
     
    function acceptTrusteeOwnership() external onlyOwner {
        trustee.acceptOwnership();
    }
}