 

pragma solidity ^0.4.13;

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract NoboToken is Ownable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 totalSupply_;

    constructor() public {
        name = "Nobotoken";
        symbol = "NBX";
        decimals = 18;
        totalSupply_ = 0;
    }

     
     
     
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

     
    mapping (address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }



     
     
     

     
    mapping (address => mapping (address => uint256)) internal allowed;

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool success)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(
        address _spender,
        uint256 _value
    )
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function increaseApproval(
        address _spender,
        uint _addedValue
    )
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] =
            allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
        public
        returns (bool success)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

     
     
     
     
    event Mint(
        address indexed to,
        uint256 amount
    );
    event MintFinished();

     
    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }


     
    function mint(
        address _to,
        uint256 _amount
    )
        public
        onlyOwner
        canMint
        returns (bool success)
    {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool success) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

     
    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }

     
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
        wallet.transfer(address(this).balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

     
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }

    function batchRefund(address[] _investors) public {
        require(state == State.Refunding);
        for (uint256 i = 0; i < _investors.length; i++) {
           require(_investors[i] != address(0));
           uint256 _depositedValue = deposited[_investors[i]];
           require(_depositedValue > 0);
           deposited[_investors[i]] = 0;
           _investors[i].transfer(_depositedValue);
           emit Refunded(_investors[i], _depositedValue);
        }
    }
}

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TimedAccess is Ownable {
    
    address public signer;

    function _setSigner(address _signer) internal {
        require(_signer != address(0));
        signer = _signer;
    }

    modifier onlyWithValidCode(
        bytes32 _r,
        bytes32 _s,
        uint8 _v,
        uint256 _blockNum,
        uint256 _etherPrice
    )
    {
        require(
            isValidAccessMessage(
                _r,
                _s,
                _v,
                _blockNum,
                _etherPrice,
                msg.sender
            ),
            "Access code is incorrect or expired."
        );
        _;
    }


     
    function isValidAccessMessage(
        bytes32 _r,
        bytes32 _s,
        uint8 _v,
        uint256 _blockNum,
        uint256 _etherPrice,
        address _sender
    )
        view
        public
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _blockNum,
                _etherPrice,
                _sender
            )
        );
        bool isValid = (
            signer == ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        hash
                    )
                ),
                _v,
                _r,
                _s
            )
        );

         
         
        bool isStillTime = (_blockNum + 123 > block.number);

        return (isValid && isStillTime);
    }
}

contract NoboCrowdsale is TimedAccess {

    using SafeMath for uint256;

     
    using TokenAmountGetter for uint256;

     
     
     

     
    address public supervisor;

     
    address public wallet;

     
    NoboToken public token;

     
    RefundVault public vault;

     
    uint256  public baseRate;

    
    uint256  public startTime;

     
    uint256 public softCap;

     
    uint256 public hardCap;

     
    enum Status { unstarted, started, ended, paused }
    Status public status;

     
    mapping(address => uint256) public balances;

     
    bool public accessAllowed;


     
     
     

     
    event NoAccessCode(address indexed sender);

     
    event CapReached(address indexed sender, uint256 indexed etherAmount);

     
    event PurchaseTooSmall(address indexed sender, uint256 indexed etherAmount);

     
    event TokenPurchase(
        address indexed investor,
        uint256 indexed etherAmount,
        uint256 indexed etherPrice,
        uint256 tokenAmount
    );

     
    event AccessChanged(bool indexed accessAllowed);

     
    event SignerChanged(address indexed previousSigner, address indexed newSigner);

     
    event StatusChanged(
        Status indexed previousStatus,
        Status indexed newStatus
    );

     
     
     

     
    modifier onlyDuring(Status _status) {
        require (status == _status);
        _;
    }

     
    modifier onlySupervisor() {
        require(supervisor == msg.sender);
        _;
    }

     
    modifier whenAccessAllowed() {
        require(accessAllowed);
        _;
    }

     
     
     

     
    constructor (
        address _tokenAddress,
        address _signer,
        address _supervisor,
        address _wallet
    )
        public
    {
        require(_tokenAddress != address(0));
        require(_signer != address(0));
        require(_supervisor!= address(0));
        require(_wallet != address(0));
        signer = _signer;
        supervisor = _supervisor;
        wallet = _wallet;
        token = NoboToken(_tokenAddress);
        vault = new RefundVault(wallet);
        baseRate = 500;
        softCap = 15000 ether;
        hardCap = 250000 ether;
        status = Status.unstarted;
        accessAllowed = false;
    }

     
    function() public payable {
        emit NoAccessCode(msg.sender);
        msg.sender.transfer(msg.value);
    }

     
     
     

     
    function purchaseTokens(
        bytes32 _r,
        bytes32 _s,
        uint8 _v,
        uint256 _blockNum,
        uint256 _etherPrice
    )
        public
        payable
        onlyDuring(Status.started)
        onlyWithValidCode( _r, _s, _v, _blockNum, _etherPrice)
    {
        if (_isPurchaseValid(msg.sender, msg.value)) {
            uint256 _etherAmount = msg.value;
            uint256 _tokenAmount = _etherAmount.getTokenAmount(
                _etherPrice,
                startTime,
                baseRate
            );
            emit TokenPurchase(msg.sender, _etherAmount, _etherPrice, _tokenAmount);
             
            _registerPurchase(msg.sender, _tokenAmount);
        }
    }

     
    function _isPurchaseValid(
        address _sender,
        uint256 _etherAmount
    )
        internal
        returns (bool)
    {
         
        if (getEtherRaised().add(_etherAmount) > hardCap) {
            _sender.transfer(_etherAmount);
            emit CapReached(_sender, getEtherRaised());
            return false;
        }
        if(_etherAmount <  0.5 ether) {
            _sender.transfer(_etherAmount);
            emit PurchaseTooSmall(_sender, _etherAmount);
            return false;
        }
        return true;
    }

     
    function _registerPurchase(
        address _investor,
        uint256 _tokenAmount
    )
        internal
    {
         
        balances[_investor] = balances[_investor].add(_tokenAmount);
         
        vault.deposit.value(msg.value)(_investor);
    }

     
    function _isGoalReached() internal view returns (bool) {
        return (getEtherRaised() >= softCap);
    }

     
    function getEtherRaised() public view returns (uint256) {
        return address(vault).balance;
    }

     
     
     

     
    function startCrowdsale()
        external
        whenAccessAllowed
        onlyOwner
        onlyDuring(Status.unstarted)
    {
        emit StatusChanged(status, Status.started);
        status = Status.started;
        startTime = now;
    }

     
    function endCrowdsale()
        external
        whenAccessAllowed
        onlyOwner
        onlyDuring(Status.started)
    {
        emit StatusChanged(status, Status.ended);
        status = Status.ended;
        if(_isGoalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }
    }

     
    function pauseCrowdsale()
        external
        onlySupervisor
        onlyDuring(Status.started)
    {
        emit StatusChanged(status, Status.paused);
        status = Status.paused;
    }

     
    function resumeCrowdsale()
        external
        onlySupervisor
        onlyDuring(Status.paused)
    {
        emit StatusChanged(status, Status.started);
        status = Status.started;
    }

     
    function cancelCrowdsale()
        external
        onlySupervisor
        onlyDuring(Status.paused)
    {
        emit StatusChanged(status, Status.ended);
        status = Status.ended;
        vault.enableRefunds();
    }

     
     
     

     
    function approveInvestor(
        address _beneficiary
    )
        external
        whenAccessAllowed
        onlyOwner
    {
        uint256 _amount = balances[_beneficiary];
        require(_amount > 0);
        balances[_beneficiary] = 0;
        _deliverTokens(_beneficiary, _amount);
    }

     
    function approveInvestors(
        address[] _beneficiaries
    )
        external
        whenAccessAllowed
        onlyOwner
    {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
           require(_beneficiaries[i] != address(0));
           uint256 _amount = balances[_beneficiaries[i]];
           require(_amount > 0);
           balances[_beneficiaries[i]] = 0;
            _deliverTokens(_beneficiaries[i], _amount);
        }
    }

     
    function mintForPlatform()
        external
        whenAccessAllowed
        onlyOwner
        onlyDuring(Status.ended)
    {
        uint256 _tokensForPlatform = token.totalSupply().mul(49).div(51);
        require(token.mint(wallet, _tokensForPlatform));
        require(token.finishMinting());
    }

     
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        require(token.mint(_beneficiary, _tokenAmount));
    }

     
     
     

     
    function changeSigner(
        address _newSigner
    )
        external
        onlySupervisor
        onlyDuring(Status.paused)
    {
        require(_newSigner != address(0));
        emit SignerChanged(signer, _newSigner);
        signer = _newSigner;
    }

     
    function setAccess(bool value) public onlySupervisor {
        require(accessAllowed != value);
        emit AccessChanged(value);
        accessAllowed = value;
    }

     
     
     

     
    function endExpiredCrowdsale() public {
        require(status != Status.unstarted);
        require(now > startTime + 181 days);
        emit StatusChanged(status, Status.ended);
        status = Status.ended;
        if(_isGoalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }
    }
}

library TokenAmountGetter {

    using SafeMath for uint256;

     
    function getTokenAmount(
        uint256 _etherAmount,
        uint256 _etherPrice,
        uint256 _startTime,
        uint256 _baseRate
    )
        internal
        view
        returns (uint256)
    {
        uint256 _baseTokenAmount = _etherAmount.mul(_baseRate);
        uint256 _timeBonus = _getTimeBonus(_baseTokenAmount, _startTime);
        uint256 _amountBonus = _getAmountBonus(
            _etherAmount,
            _etherPrice,
            _baseTokenAmount
        );
        uint256 _totalBonus = _timeBonus.add(_amountBonus);

        uint256 _totalAmount = _baseTokenAmount.add(_totalBonus);

         
        if(_startTime + 1 days > now)
            _totalAmount = _totalAmount.add(_totalAmount.mul(2).div(100));

        return _totalAmount;
    }

     
    function _getTimeBonus(
        uint256 _baseTokenAmount,
        uint256 _startTime
    )
        internal
        view
        returns (uint256)
    {
        if (now <= (_startTime + 1 weeks))
            return (_baseTokenAmount.mul(20).div(100));
        if (now <= (_startTime + 2 weeks))
            return (_baseTokenAmount.mul(18).div(100));
        if (now <= (_startTime + 3 weeks))
            return (_baseTokenAmount.mul(16).div(100));
        if (now <= (_startTime + 4 weeks))
            return (_baseTokenAmount.mul(14).div(100));
        if (now <= (_startTime + 5 weeks))
            return (_baseTokenAmount.mul(12).div(100));
        if (now <= (_startTime + 6 weeks))
            return (_baseTokenAmount.mul(10).div(100));
        if (now <= (_startTime + 7 weeks))
            return (_baseTokenAmount.mul(8).div(100));
        if (now <= (_startTime + 8 weeks))
            return (_baseTokenAmount.mul(6).div(100));
        if (now <= (_startTime + 9 weeks))
            return (_baseTokenAmount.mul(4).div(100));
        if (now <= (_startTime + 10 weeks))
            return (_baseTokenAmount.mul(2).div(100));
        return 0;
    }

     
    function _getAmountBonus(
        uint256 _etherAmount,
        uint256 _etherPrice,
        uint256 _baseTokenAmount
    )
        internal
        pure
        returns (uint256)
    {
        uint256 _etherAmountInEuro = _etherAmount.mul(_etherPrice).div(1 ether);
        if (_etherAmountInEuro < 100000)
            return 0;
        if (_etherAmountInEuro >= 100000 && _etherAmountInEuro < 150000)
            return (_baseTokenAmount.mul(3)).div(100);
        if (_etherAmountInEuro >= 150000 && _etherAmountInEuro < 200000)
            return (_baseTokenAmount.mul(6)).div(100);
        if (_etherAmountInEuro >= 200000 && _etherAmountInEuro < 300000)
            return (_baseTokenAmount.mul(9)).div(100);
        if (_etherAmountInEuro >= 300000 && _etherAmountInEuro < 1000000)
            return (_baseTokenAmount.mul(12)).div(100);
        if (_etherAmountInEuro >= 1000000 && _etherAmountInEuro < 1500000)
            return (_baseTokenAmount.mul(15)).div(100);
        if (_etherAmountInEuro >= 1500000)
            return (_baseTokenAmount.mul(20)).div(100);
    }
}