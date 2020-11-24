 

pragma solidity 0.4.25;
 

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }

}

 
contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns(uint256);

    function transfer(address to, uint256 value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns(uint256);

    function transferFrom(address from, address to, uint256 value) public returns(bool);

    function approve(address spender, uint256 value) public returns(bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StakerToken {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;

    function claimStake() public returns(bool);

    function coinAge() public view returns(uint256);

    function annualInterest() public view returns(uint256);
    event ClaimStake(address indexed _address, uint _reward);
}

contract OMNIS is ERC20, StakerToken, Ownable {
    using SafeMath
    for uint256;

    string public name = "OMNIS-BIT";
    string public symbol = "OMNIS";
    uint public decimals = 18;

    uint public chainStartTime;
    uint public chainStartBlockNumber;
    uint public stakeStartTime;
    uint public stakeMinAge = 3 days;
    uint public stakeMaxAge = 90 days;

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;

    struct Airdrop {
        uint value;
        bool claimed;
    }

    mapping(address => Airdrop) public airdrops;

     
    enum PaymentStatus {
        Pending,
        Completed,
        Refunded
    }

    event NewFeeRate(uint newFee);
    event NewCollectionWallet(address newWallet);
    event PaymentCreation(uint indexed orderId, address indexed customer, uint value);
    event PaymentCompletion(uint indexed orderId, address indexed provider, address indexed customer, uint value, PaymentStatus status);

    struct Payment {
        address provider;
        address customer;
        uint value;
        PaymentStatus status;
        bool refundApproved;
    }

    uint escrowCounter;
    uint public escrowFeePercent = 5;  

    mapping(uint => Payment) public payments;
    address public collectionAddress;
     

    struct transferInStruct {
        uint128 amount;
        uint64 time;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    modifier canPoSclaimStake() {
        require(totalSupply < maxTotalSupply);
        _;
    }

    constructor() public {
        maxTotalSupply = 1000000000 * 10 ** 18;
        totalInitialSupply = 820000000 * 10 ** 18;

        chainStartTime = now;  
        chainStartBlockNumber = block.number;  

        totalSupply = totalInitialSupply;
        
        collectionAddress = msg.sender;  

        balances[msg.sender] = totalInitialSupply;
        emit Transfer(address(0), msg.sender, totalInitialSupply);
    }

    function setCurrentEscrowFee(uint _newFee) onlyOwner public {
        require(_newFee != 0 && _newFee < 1000);
        escrowFeePercent = _newFee;
        emit NewFeeRate(escrowFeePercent);
    }

    function setCollectionWallet(address _newWallet) onlyOwner public {
        require(_newWallet != address(0));
        collectionAddress = _newWallet;
        emit NewCollectionWallet(collectionAddress);
    }

    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));

        if (msg.sender == _to) return claimStake();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        if (transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]), _now));
        transferIns[_to].push(transferInStruct(uint128(_value), _now));
        return true;
    }

    function balanceOf(address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        if (transferIns[_from].length > 0) delete transferIns[_from];
        uint64 _now = uint64(now);
        transferIns[_from].push(transferInStruct(uint128(balances[_from]), _now));
        transferIns[_to].push(transferInStruct(uint128(_value), _now));
        return true;
    }

    function approve(address _spender, uint256 _value) public returns(bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function claimStake() canPoSclaimStake public returns(bool) {
        if (balances[msg.sender] <= 0) return false;
        if (transferIns[msg.sender].length <= 0) return false;

        uint reward = getProofOfStakeReward(msg.sender);
        if (reward <= 0) return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]), uint64(now)));

        emit Transfer(address(0),msg.sender,reward);
        emit ClaimStake(msg.sender, reward);
        return true;
    }

     
    function getBlockNumber() public view returns(uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

     
    function coinAge() public view returns(uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender, now);
    }

     
    function annualInterest() public view returns(uint interest) {
        uint _now = now;
        interest = 0;
        if ((_now.sub(stakeStartTime)).div(365 days) == 0) {
            interest = (106 * 1e15);
        } else if ((_now.sub(stakeStartTime)).div(365 days) == 1) {
            interest = (49 * 1e15);
        } else if ((_now.sub(stakeStartTime)).div(365 days) == 2) {
            interest = (24 * 1e15);
        } else if ((_now.sub(stakeStartTime)).div(365 days) == 3) {
            interest = (13 * 1e15);
        } else if ((_now.sub(stakeStartTime)).div(365 days) == 4) {
            interest = (11 * 1e15);
        }
    }

     
    function getProofOfStakeReward(address _address) public view returns(uint) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if (_coinAge <= 0) return 0;

        uint interest = 0;

        if ((_now.sub(stakeStartTime)).div(365 days) == 0) {
            interest = (106 * 1e15);
        } else if ((_now.sub(stakeStartTime)).div(365 days) == 1) {
            interest = (49 * 1e15);
        } else if ((_now.sub(stakeStartTime)).div(365 days) == 2) {
            interest = (24 * 1e15);
        } else if ((_now.sub(stakeStartTime)).div(365 days) == 3) {
            interest = (13 * 1e15);
        } else if ((_now.sub(stakeStartTime)).div(365 days) == 4) {
            interest = (11 * 1e1);
        }

        return (_coinAge * interest).div(365 * (10 ** decimals));
    }

    function getCoinAge(address _address, uint _now) internal view returns(uint _coinAge) {
        if (transferIns[_address].length <= 0) return 0;

        for (uint i = 0; i < transferIns[_address].length; i++) {
            if (_now < uint(transferIns[_address][i].time).add(stakeMinAge)) continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if (nCoinSeconds > stakeMaxAge) nCoinSeconds = stakeMaxAge;

            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }


     
    function ownerSetStakeStartTime(uint timestamp) onlyOwner public {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }

     
    function batchTransfer(address[] _recipients, uint[] _values) onlyOwner external returns(bool) {
         
        require(_recipients.length > 0 && _recipients.length == _values.length);
         
        uint total = 0;
        for (uint i = 0; i < _values.length; i++) {
            total = total.add(_values[i]);
        }
         
        require(total <= balances[msg.sender]);
         
        uint64 _now = uint64(now);
        for (uint j = 0; j < _recipients.length; j++) {
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            transferIns[_recipients[j]].push(transferInStruct(uint128(_values[j]), _now));
            emit Transfer(msg.sender, _recipients[j], _values[j]);
        }
         
        balances[msg.sender] = balances[msg.sender].sub(total);
        if (transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        if (balances[msg.sender] > 0) transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]), _now));

        return true;
    }

     
    function dropSet(address[] _recipients, uint[] _values) onlyOwner external returns(bool) {
         
        require(_recipients.length > 0 && _recipients.length == _values.length);

        for (uint j = 0; j < _recipients.length; j++) {
             
            airdrops[_recipients[j]].value = _values[j];
            airdrops[_recipients[j]].claimed = false;
        }

        return true;
    }

     
    function claimAirdrop() external returns(bool) {
         
        require(airdrops[msg.sender].claimed == false);
        require(airdrops[msg.sender].value != 0);

         
        airdrops[msg.sender].claimed = true;
         
        airdrops[msg.sender].value = 0;

         
        address _from = owner;
         
        address _to = msg.sender;
         
        uint _value = airdrops[msg.sender].value;

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        if (transferIns[_from].length > 0) delete transferIns[_from];
        uint64 _now = uint64(now);
        transferIns[_from].push(transferInStruct(uint128(balances[_from]), _now));
        transferIns[_to].push(transferInStruct(uint128(_value), _now));
        return true;

    }

     
     
    function createPayment(address _customer, uint _value) external returns(uint) {

        address _to = address(this);
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        if (transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]), _now));

        payments[escrowCounter] = Payment(msg.sender, _customer, _value, PaymentStatus.Pending, false);
        emit PaymentCreation(escrowCounter, _customer, _value);

        escrowCounter = escrowCounter.add(1);
        return escrowCounter - 1;
    }

     
    function release(uint _orderId) external returns(bool) {
         
        Payment storage payment = payments[_orderId];
         
        require(payment.status == PaymentStatus.Pending);
         
        require(msg.sender == owner || msg.sender == payment.provider);
         
        address _from = address(this);
         
        address _to = payment.customer;
         
        uint _value = payment.value;
         
        uint _fee = _value.mul(escrowFeePercent).div(1000);
         
        _value = _value.sub(_fee);
         
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        balances[_from] = balances[_from].sub(_fee);
        balances[collectionAddress] = balances[collectionAddress].add(_fee);
        emit Transfer(_from, collectionAddress, _fee);
         
        if (transferIns[_from].length > 0) delete transferIns[_from];
         
        uint64 _now = uint64(now);
         
        transferIns[_to].push(transferInStruct(uint128(_value), _now));
         
        transferIns[collectionAddress].push(transferInStruct(uint128(_fee), _now));
         
        payment.status = PaymentStatus.Completed;
         
        emit PaymentCompletion(_orderId, payment.provider, payment.customer, payment.value, payment.status);

        return true;
    }

     
    function refund(uint _orderId) external returns(bool) {
         
        Payment storage payment = payments[_orderId];
         
        require(payment.status == PaymentStatus.Pending);
         
        require(payment.refundApproved);
         
        address _from = address(this);
         
        address _to = payment.provider;
         
        uint _value = payment.value;
         
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        if (transferIns[_from].length > 0) delete transferIns[_from];
         
        uint64 _now = uint64(now);
        transferIns[_to].push(transferInStruct(uint128(_value), _now));
         
        payment.status = PaymentStatus.Refunded;
         
        emit PaymentCompletion(_orderId, payment.provider, payment.customer, payment.value, payment.status);

        return true;
    }

     
    function approveRefund(uint _orderId) external returns(bool) {
         
        Payment storage payment = payments[_orderId];
         
        require(payment.status == PaymentStatus.Pending);
         
        require(msg.sender == owner || msg.sender == payment.customer);
         
        payment.refundApproved = true;

        return true;
    }
     
}