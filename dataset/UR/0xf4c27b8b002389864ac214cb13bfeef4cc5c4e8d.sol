 

pragma solidity ^0.4.18;

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
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

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    string public constant name = "";
    string public constant symbol = "";
    uint8 public constant decimals = 0;
}

 
 
contract Ethen is Pausable {
     
    uint public constant BUY = 1;  
    uint public constant SELL = 0;  

     
    uint public FEE_MUL = 1000000;

     
    uint public constant MAX_FEE = 5000;

     
     
     
     
     
     
     
     
     
    uint public expireDelay = 300;

    uint public constant MAX_EXPIRE_DELAY = 600;

     
     
     
     
     
    bytes32 public constant ETH_SIGN_TYPED_DATA_ARGHASH =
        0x3da4a05d8449a7bc291302cce8a490cf367b98ec37200076c3f13f1f2308fd74;

     
    uint public constant PRICE_MUL = 1e18;

     
     
     

     
    address public feeCollector;

     
    uint public makeFee = 0;

     
    uint public takeFee = 2500;

     
    mapping (address => uint) public balances;

     
    mapping (address => mapping (address => uint)) public tokens;

     
    mapping (address => mapping (uint => uint)) public filled;

     
    mapping (address => mapping (uint => bool)) public trades;

     
    address public signer;

     
     
    struct Coeff {
        uint8   coeff;  
        uint128 expire;
    }
    mapping (address => Coeff) public coeffs;

     
     
    mapping(uint => uint) public packs;

     
     
     

    event NewMakeFee(uint makeFee);
    event NewTakeFee(uint takeFee);

    event NewFeeCoeff(address user, uint8 coeff, uint128 expire, uint price);

    event DepositEther(address user, uint amount, uint total);
    event WithdrawEther(address user, uint amount, uint total);
    event DepositToken(address user, address token, uint amount, uint total);
    event WithdrawToken(address user, address token, uint amount, uint total);

    event Cancel(
        uint8 order,
        address owner,
        uint nonce,
        address token,
        uint price,
        uint amount
    );

    event Order(
        address orderOwner,
        uint orderNonce,
        uint orderPrice,
        uint tradeTokens,
        uint orderFilled,
        uint orderOwnerFinalTokens,
        uint orderOwnerFinalEther,
        uint fees
    );

    event Trade(
        address trader,
        uint nonce,
        uint trade,
        address token,
        uint traderFinalTokens,
        uint traderFinalEther
    );

    event NotEnoughTokens(
        address owner, address token, uint shouldHaveAmount, uint actualAmount
    );
    event NotEnoughEther(
        address owner, uint shouldHaveAmount, uint actualAmount
    );

     
     
     

    function Ethen(address _signer) public {
        feeCollector = msg.sender;
        signer       = _signer;
    }

     
     
     

    function setFeeCollector(address _addr) external onlyOwner {
        feeCollector = _addr;
    }

    function setSigner(address _addr) external onlyOwner {
        signer = _addr;
    }

    function setMakeFee(uint _makeFee) external onlyOwner {
        require(_makeFee <= MAX_FEE);
        makeFee = _makeFee;
        NewMakeFee(makeFee);
    }

    function setTakeFee(uint _takeFee) external onlyOwner {
        require(_takeFee <= MAX_FEE);
        takeFee = _takeFee;
        NewTakeFee(takeFee);
    }

    function addPack(
        uint8 _coeff, uint128 _duration, uint _price
    ) external onlyOwner {
        require(_coeff < 100);
        require(_duration > 0);
        require(_price > 0);

        uint key = packKey(_coeff, _duration);
        packs[key] = _price;
    }

    function delPack(uint8 _coeff, uint128 _duration) external onlyOwner {
        uint key = packKey(_coeff, _duration);
        delete packs[key];
    }

    function setExpireDelay(uint _expireDelay) external onlyOwner {
        require(_expireDelay <= MAX_EXPIRE_DELAY);
        expireDelay = _expireDelay;
    }

     
     
     

    function getPack(
        uint8 _coeff, uint128 _duration
    ) public view returns (uint) {
        uint key = packKey(_coeff, _duration);
        return packs[key];
    }

     
    function buyPack(
        uint8 _coeff, uint128 _duration
    ) external payable {
        require(now >= coeffs[msg.sender].expire);

        uint key = packKey(_coeff, _duration);
        uint price = packs[key];

        require(price > 0);
        require(msg.value == price);

        updateCoeff(msg.sender, _coeff, uint128(now) + _duration, price);

        balances[feeCollector] = SafeMath.add(
            balances[feeCollector], msg.value
        );
    }

     
    function setCoeff(
        uint8 _coeff, uint128 _expire, uint8 _v, bytes32 _r, bytes32 _s
    ) external {
        bytes32 hash = keccak256(this, msg.sender, _coeff, _expire);
        require(ecrecover(hash, _v, _r, _s) == signer);

        require(_coeff < 100);
        require(uint(_expire) > now);
        require(uint(_expire) <= now + 35 days);

        updateCoeff(msg.sender, _coeff, _expire, 0);
    }

     
     
     

    function () external payable {
        balances[msg.sender] = SafeMath.add(balances[msg.sender], msg.value);
        DepositEther(msg.sender, msg.value, balances[msg.sender]);
    }

    function depositEther() external payable {
        balances[msg.sender] = SafeMath.add(balances[msg.sender], msg.value);
        DepositEther(msg.sender, msg.value, balances[msg.sender]);
    }

    function withdrawEther(uint _amount) external {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        msg.sender.transfer(_amount);
        WithdrawEther(msg.sender, _amount, balances[msg.sender]);
    }

    function depositToken(address _token, uint _amount) external {
        require(ERC20(_token).transferFrom(msg.sender, this, _amount));
        tokens[msg.sender][_token] = SafeMath.add(
            tokens[msg.sender][_token], _amount
        );
        DepositToken(msg.sender, _token, _amount, tokens[msg.sender][_token]);
    }

    function withdrawToken(address _token, uint _amount) external {
        tokens[msg.sender][_token] = SafeMath.sub(
            tokens[msg.sender][_token], _amount
        );
        require(ERC20(_token).transfer(msg.sender, _amount));
        WithdrawToken(msg.sender, _token, _amount, tokens[msg.sender][_token]);
    }

     
     
     

     
    function cancel(
        uint8   _order,  
        address _token,
        uint    _nonce,
        uint    _price,  
        uint    _amount,
        uint    _expire,
        uint    _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_order == BUY || _order == SELL);

        if (now > _expire + expireDelay) {
             
            return;
        }

        getVerifiedHash(
            msg.sender,
            _order, _token, _nonce, _price, _amount, _expire,
            _v, _r, _s
        );

        filled[msg.sender][_nonce] = _amount;

        Cancel(_order, msg.sender, _nonce, _token, _price, _amount);
    }

     
     
    function trade(
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
        uint[] _nums,
         
         
         
         
        address[] _addrs,
         
         
         
         
         
         
         
        bytes32[] _rss
    ) public whenNotPaused {
         
        uint N = _addrs.length - 1;

        require(_nums.length == 6*N+4);
        require(_rss.length == 2*N+2);

         
         
        require(_nums[0] == BUY || _nums[0] == SELL);

         
        saveNonce(_nums[1]);

         
        require(now <= _nums[3]);

         
         
         
         
         
        bytes32 tradeHash = keccak256(
            this, msg.sender, uint8(_nums[0]), _addrs[0], _nums[1], _nums[3]
        );

         
        bytes32 orderHash;

        for (uint i = 0; i < N; i++) {
            checkExpiration(i, _nums);

            orderHash = verifyOrder(i, _nums, _addrs, _rss);

             
            tradeHash = keccak256(tradeHash, orderHash, _nums[6*i+9]);

            tradeOrder(i, _nums, _addrs);
        }

        checkTradeSignature(tradeHash, _nums, _rss);

        sendTradeEvent(_nums, _addrs);
    }

     
     
     

    function saveNonce(uint _nonce) private {
        require(trades[msg.sender][_nonce] == false);
        trades[msg.sender][_nonce] = true;
    }

     
    function checkExpiration(
        uint _i,  
        uint[] _nums
    ) private view {
         
        require(now <= _nums[6*_i+7] + expireDelay);
    }

     
    function verifyOrder(
        uint _i,  
        uint[] _nums,
        address[] _addrs,
        bytes32[] _rss
    ) private view returns (bytes32 _orderHash) {
         
         
        uint8 order = _nums[0] == BUY ? uint8(SELL) : uint8(BUY);

         
         
        address owner = _addrs[_i+1];
        address token = _addrs[0];

         
         
         
         
        uint nonce = _nums[6*_i+4];
        uint price = _nums[6*_i+5];
        uint amount = _nums[6*_i+6];
        uint expire = _nums[6*_i+7];

         
         
         
        uint v = _nums[6*_i+8];
        bytes32 r = _rss[2*_i+2];
        bytes32 s = _rss[2*_i+3];

        _orderHash = getVerifiedHash(
            owner,
            order, token, nonce, price, amount,
            expire, v, r, s
        );
    }

     
    function tradeOrder(
        uint _i,  
        uint[] _nums,
        address[] _addrs
    ) private {
         
         
         
         
         
         
         
        executeOrder(
            _nums[0],
            _addrs[0],
            _addrs[_i+1],
            _nums[6*_i+4],
            _nums[6*_i+5],
            _nums[6*_i+6],
            _nums[6*_i+9]
        );
    }

    function checkTradeSignature(
        bytes32 _tradeHash,
        uint[] _nums,
        bytes32[] _rss
    ) private view {
         
         
         
        require(ecrecover(
            _tradeHash, uint8(_nums[2]), _rss[0], _rss[1]
        ) == signer);
    }

    function sendTradeEvent(
        uint[] _nums, address[] _addrs
    ) private {
         
         
         
        Trade(
            msg.sender, _nums[1], _nums[0], _addrs[0],
            tokens[msg.sender][_addrs[0]], balances[msg.sender]
        );
    }

     
    function executeOrder(
        uint    _trade,
        address _token,
        address _orderOwner,
        uint    _orderNonce,
        uint    _orderPrice,
        uint    _orderAmount,
        uint    _tradeAmount
    ) private {
        var (tradeTokens, tradeEther) = getTradeParameters(
            _trade, _token, _orderOwner, _orderNonce, _orderPrice,
            _orderAmount, _tradeAmount
        );

        filled[_orderOwner][_orderNonce] = SafeMath.add(
            filled[_orderOwner][_orderNonce],
            tradeTokens
        );

         
        require(filled[_orderOwner][_orderNonce] <= _orderAmount);

        uint makeFees = getFees(tradeEther, makeFee, _orderOwner);
        uint takeFees = getFees(tradeEther, takeFee, msg.sender);

        swap(
            _trade, _token, _orderOwner, tradeTokens, tradeEther,
            makeFees, takeFees
        );

        balances[feeCollector] = SafeMath.add(
            balances[feeCollector],
            SafeMath.add(takeFees, makeFees)
        );

        sendOrderEvent(
            _orderOwner, _orderNonce, _orderPrice, tradeTokens,
            _token, SafeMath.add(takeFees, makeFees)
        );
    }

    function swap(
        uint _trade,
        address _token,
        address _orderOwner,
        uint _tradeTokens,
        uint _tradeEther,
        uint _makeFees,
        uint _takeFees
    ) private {
        if (_trade == BUY) {
            tokens[msg.sender][_token] = SafeMath.add(
                tokens[msg.sender][_token], _tradeTokens
            );
            tokens[_orderOwner][_token] = SafeMath.sub(
                tokens[_orderOwner][_token], _tradeTokens
            );
            balances[msg.sender] = SafeMath.sub(
                balances[msg.sender], SafeMath.add(_tradeEther, _takeFees)
            );
            balances[_orderOwner] = SafeMath.add(
                balances[_orderOwner], SafeMath.sub(_tradeEther, _makeFees)
            );
        } else {
            tokens[msg.sender][_token] = SafeMath.sub(
                tokens[msg.sender][_token], _tradeTokens
            );
            tokens[_orderOwner][_token] = SafeMath.add(
                tokens[_orderOwner][_token], _tradeTokens
            );
            balances[msg.sender] = SafeMath.add(
                balances[msg.sender], SafeMath.sub(_tradeEther, _takeFees)
            );
            balances[_orderOwner] = SafeMath.sub(
                balances[_orderOwner], SafeMath.add(_tradeEther, _makeFees)
            );
        }
    }

    function sendOrderEvent(
        address _orderOwner,
        uint _orderNonce,
        uint _orderPrice,
        uint _tradeTokens,
        address _token,
        uint _fees
    ) private {
        Order(
            _orderOwner,
            _orderNonce,
            _orderPrice,
            _tradeTokens,
            filled[_orderOwner][_orderNonce],
            tokens[_orderOwner][_token],
            balances[_orderOwner],
            _fees
        );
    }

     
    function getTradeParameters(
        uint _trade, address _token, address _orderOwner,
        uint _orderNonce, uint _orderPrice, uint _orderAmount, uint _tradeAmount
    ) private returns (uint _tokens, uint _totalPrice) {
         
        _tokens = SafeMath.sub(
            _orderAmount, filled[_orderOwner][_orderNonce]
        );

         
        if (_tokens > _tradeAmount) {
            _tokens = _tradeAmount;
        }

        if (_trade == BUY) {
             
            if (_tokens > tokens[_orderOwner][_token]) {
                NotEnoughTokens(
                    _orderOwner, _token, _tokens, tokens[_orderOwner][_token]
                );
                _tokens = tokens[_orderOwner][_token];
            }
        } else {
             
            if (_tokens > tokens[msg.sender][_token]) {
                NotEnoughTokens(
                    msg.sender, _token, _tokens, tokens[msg.sender][_token]
                );
                _tokens = tokens[msg.sender][_token];
            }
        }

        uint shouldHave = getPrice(_tokens, _orderPrice);

        uint spendable;
        if (_trade == BUY) {
             
            spendable = reversePercent(
                balances[msg.sender],
                applyCoeff(takeFee, msg.sender)
            );
        } else {
             
            spendable = reversePercent(
                balances[_orderOwner],
                applyCoeff(makeFee, _orderOwner)
            );
        }

        if (shouldHave <= spendable) {
             
            _totalPrice = shouldHave;
            return;
        }

         
        _tokens = SafeMath.div(
            SafeMath.mul(spendable, PRICE_MUL), _orderPrice
        );
        _totalPrice = getPrice(_tokens, _orderPrice);

        if (_trade == BUY) {
            NotEnoughEther(
                msg.sender,
                addFees(shouldHave, applyCoeff(takeFee, msg.sender)),
                _totalPrice
            );
        } else {
            NotEnoughEther(
                _orderOwner,
                addFees(shouldHave, applyCoeff(makeFee, _orderOwner)),
                _totalPrice
            );
        }
    }

     
     
    function getPrice(
        uint _tokens, uint _orderPrice
    ) private pure returns (uint) {
        return SafeMath.div(
            SafeMath.mul(_tokens, _orderPrice), PRICE_MUL
        );
    }

    function getFees(
        uint _eth, uint _fee, address _payer
    ) private view returns (uint) {
         
        return SafeMath.div(
            SafeMath.mul(_eth, applyCoeff(_fee, _payer)),
            FEE_MUL
        );
    }

    function applyCoeff(uint _fees, address _user) private view returns (uint) {
        if (now >= coeffs[_user].expire) {
            return _fees;
        }
        return SafeMath.div(
            SafeMath.mul(_fees, coeffs[_user].coeff), 100
        );
    }

    function addFees(uint _eth, uint _fee) private view returns (uint) {
         
        return SafeMath.div(
            SafeMath.mul(_eth, SafeMath.add(FEE_MUL, _fee)),
            FEE_MUL
        );
    }

    function subFees(uint _eth, uint _fee) private view returns (uint) {
         
        return SafeMath.div(
            SafeMath.mul(_eth, SafeMath.sub(FEE_MUL, _fee)),
            FEE_MUL
        );
    }

     
    function reversePercent(
        uint _balance, uint _fee
    ) private view returns (uint) {
         
         
         
        return SafeMath.div(
            SafeMath.mul(_balance, FEE_MUL),
            SafeMath.add(FEE_MUL, _fee)
        );
    }

     
     
    function hashOrderTyped(
        uint8 _order, address _token, uint _nonce, uint _price, uint _amount,
        uint _expire
    ) private view returns (bytes32) {
        require(_order == BUY || _order == SELL);
        return keccak256(
            ETH_SIGN_TYPED_DATA_ARGHASH,
            keccak256(
                this,
                _order == BUY ? "BUY" : "SELL",
                _token,
                _nonce,
                _price,
                _amount,
                _expire
            )
        );
    }

     
    function hashOrder(
        uint8 _order, address _token, uint _nonce, uint _price, uint _amount,
        uint _expire
    ) private view returns (bytes32) {
        return keccak256(
            "\x19Ethereum Signed Message:\n32",
            keccak256(this, _order, _token, _nonce, _price, _amount, _expire)
        );
    }

     
     
    function getVerifiedHash(
        address _signer,
        uint8 _order, address _token,
        uint _nonce, uint _price, uint _amount, uint _expire,
        uint _v, bytes32 _r, bytes32 _s
    ) private view returns (bytes32 _hash) {
        if (_v < 1000) {
            _hash = hashOrderTyped(
                _order, _token, _nonce, _price, _amount, _expire
            );
            require(ecrecover(_hash, uint8(_v), _r, _s) == _signer);
        } else {
            _hash = hashOrder(
                _order, _token, _nonce, _price, _amount, _expire
            );
            require(ecrecover(_hash, uint8(_v - 1000), _r, _s) == _signer);
        }
    }

    function packKey(
        uint8 _coeff, uint128 _duration
    ) private pure returns (uint) {
        return (uint(_duration) << 8) + uint(_coeff);
    }

    function updateCoeff(
        address _user, uint8 _coeff, uint128 _expire, uint price
    ) private {
        coeffs[_user] = Coeff(_coeff, _expire);
        NewFeeCoeff(_user, _coeff, _expire, price);
    }
}