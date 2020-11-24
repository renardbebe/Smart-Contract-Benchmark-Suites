 

pragma solidity ^0.4.24;

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
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

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract BlockchainToken is StandardToken, Ownable {

    string public constant name = 'Blockchain Token 2.0';

    string public constant symbol = 'BCT';

    uint32 public constant decimals = 18;

     
    uint public price = 210;

    function setPrice(uint _price) onlyOwner public {
        price = _price;
    }

    uint256 public INITIAL_SUPPLY = 21000000 * 1 ether;

     
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

}

 
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 value);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

     
    function mint(
        address _to,
        uint256 _amount
    )
        public
        hasMintPermission
        canMint
        returns (bool)
    {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function burn(
        address _addr,
        uint256 _value
    )
        public onlyOwner
    {
        _burn(_addr, _value);
    }

    function _burn(
        address _who,
        uint256 _value
    )
        internal
    {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

     
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract WealthBuilderToken is MintableToken {

    string public name = 'Wealth Builder Token';

    string public symbol = 'WBT';

    uint32 public decimals = 18;

     
    uint public rate = 10 ** 7;
     
    uint public mrate = 10 ** 7;

    function setRate(uint _rate) onlyOwner public {
        rate = _rate;
    }

}

contract Data is Ownable {

     
    mapping (address => address) private parent;

     
    mapping (address => uint8) public statuses;

     
    mapping (address => uint) public referralDeposits;

     
    mapping(address => uint256) private balances;

     
    mapping(address => uint256) private investorBalances;

    function parentOf(address _addr) public constant returns (address) {
        return parent[_addr];
    }

    function balanceOf(address _addr) public constant returns (uint256) {
        return balances[_addr] / 1000000;
    }

    function investorBalanceOf(address _addr) public constant returns (uint256) {
        return investorBalances[_addr] / 1000000;
    }

     
    constructor() public {
         
        statuses[msg.sender] = 7;
    }

    function addBalance(address _addr, uint256 amount) onlyOwner public {
        balances[_addr] += amount;
    }

    function subtrBalance(address _addr, uint256 amount) onlyOwner public {
        require(balances[_addr] >= amount);
        balances[_addr] -= amount;
    }

    function addInvestorBalance(address _addr, uint256 amount) onlyOwner public {
        investorBalances[_addr] += amount;
    }

    function subtrInvestorBalance(address _addr, uint256 amount) onlyOwner public {
        require(investorBalances[_addr] >= amount);
        investorBalances[_addr] -= amount;
    }

    function addReferralDeposit(address _addr, uint256 amount) onlyOwner public {
        referralDeposits[_addr] += amount;
    }

    function subtrReferralDeposit(address _addr, uint256 amount) onlyOwner public {
        referralDeposits[_addr] -= amount;
    }

    function setStatus(address _addr, uint8 _status) onlyOwner public {
        statuses[_addr] = _status;
    }

    function setParent(address _addr, address _parent) onlyOwner public {
        parent[_addr] = _parent;
    }

}

contract Declaration {

     
    mapping (uint => uint8) statusThreshold;

     
    mapping (uint8 => mapping (uint16 => uint256)) feeDistribution;

     
    uint[8] thresholds = [
    0, 5000, 35000, 150000, 500000, 2500000, 5000000, 10000000
    ];

    uint[5] referralFees = [50, 30, 20, 10, 5];
    uint[5] serviceFees = [25, 20, 15, 10, 5];


     
    constructor() public {
        setFeeDistributionsAndStatusThresholds();
    }


     
    function setFeeDistributionsAndStatusThresholds() private {
         
        setFeeDistributionAndStatusThreshold(0, [uint16(120), uint16(80), uint16(50), uint16(20), uint16(10)], thresholds[0]);
         
        setFeeDistributionAndStatusThreshold(1, [uint16(160), uint16(100), uint16(60), uint16(30), uint16(20)], thresholds[1]);
         
        setFeeDistributionAndStatusThreshold(2, [uint16(200), uint16(120), uint16(80), uint16(40), uint16(25)], thresholds[2]);
         
        setFeeDistributionAndStatusThreshold(3, [uint16(250), uint16(150), uint16(100), uint16(50), uint16(30)], thresholds[3]);
         
        setFeeDistributionAndStatusThreshold(4, [300, 180, 120, 60, 35], thresholds[4]);
         
        setFeeDistributionAndStatusThreshold(5, [350, 210, 140, 70, 40], thresholds[5]);
         
        setFeeDistributionAndStatusThreshold(6, [400, 240, 160, 80, 45], thresholds[6]);
         
        setFeeDistributionAndStatusThreshold(7, [500, 300, 200, 100, 50], thresholds[7]);
    }


     
    function setFeeDistributionAndStatusThreshold(
        uint8 _st,
        uint16[5] _percentages,
        uint _threshold
    )
        private
    {
        statusThreshold[_threshold] = _st;
        for (uint8 i = 0; i < _percentages.length; i++) {
            feeDistribution[_st][i] = _percentages[i];
        }
    }

}

contract Referral is Declaration, Ownable {

    using SafeMath for uint;

     
    WealthBuilderToken private wbtToken;

     
    BlockchainToken private bctToken;

     
    Data private data;

     
    uint public ethUsdRate;

     
    constructor(
        uint _ethUsdRate,
        address _wbtToken,
        address _bctToken,
        address _data
    )
        public
    {
        ethUsdRate = _ethUsdRate;

         
        wbtToken = WealthBuilderToken(_wbtToken);
        bctToken = BlockchainToken(_bctToken);
        data = Data(_data);
    }

     
    function() payable public {
    }

     
    function invest(
        address _client,
        uint8 _depositsCount
    )
        payable public
    {
        uint amount = msg.value;

         
        if (_depositsCount < 5) {

            uint serviceFee;

            serviceFee = amount * serviceFees[_depositsCount];

            uint referralFee = amount * referralFees[_depositsCount];

             
            distribute(data.parentOf(_client), 0, _depositsCount, amount);

             
            uint active = (amount * 100).sub(referralFee).sub(serviceFee);

            wbtToken.mint(_client, active / 100 * wbtToken.rate() / wbtToken.mrate());

             
            data.addBalance(owner, serviceFee * 10000);
        } else {
            wbtToken.mint(_client, amount * wbtToken.rate() / wbtToken.mrate());
        }
    }

     
    function investBct(
        address _client
    )
        public payable
    {
        uint amount = msg.value;
         
        distribute(data.parentOf(_client), 0, 0, amount);

        bctToken.transfer(_client, amount * ethUsdRate / bctToken.price());
    }


     
    function distribute(
        address _node,
        uint _prevPercentage,
        uint8 _depositsCount,
        uint _amount
    )
        private
    {
        address node = _node;
        uint prevPercentage = _prevPercentage;

         
        while(node != address(0)) {
            uint8 status = data.statuses(node);

             
            uint nodePercentage = feeDistribution[status][_depositsCount];
            uint percentage = nodePercentage.sub(prevPercentage);
            data.addBalance(node, _amount * percentage * 1000);

             
            data.addReferralDeposit(node, _amount * ethUsdRate / 10**18);

             
            updateStatus(node, status);

            node = data.parentOf(node);
            prevPercentage = nodePercentage;
        }
    }


     
    function updateStatus(
        address _node,
        uint8 _status
    )
        private
    {
        uint refDep = data.referralDeposits(_node);

        for (uint i = thresholds.length - 1; i > _status; i--) {
            uint threshold = thresholds[i] * 100;

            if (refDep >= threshold) {
                data.setStatus(_node, statusThreshold[thresholds[i]]);
                break;
            }
        }
    }


     
    function setRate(
        uint _rate
    )
        onlyOwner public
    {
        wbtToken.setRate(_rate);
    }


     
    function setPrice(
        uint _price
    )
        onlyOwner public
    {
        bctToken.setPrice(_price);
    }


     
    function setEthUsdRate(
        uint _ethUsdRate
    )
        onlyOwner public
    {
        ethUsdRate = _ethUsdRate;
    }


     
    function invite(
        address _inviter,
        address _invitee
    )
        public onlyOwner
    {
        data.setParent(_invitee, _inviter);
         
        data.setStatus(_invitee, 0);
    }


     
    function setStatus(
        address _addr,
        uint8 _status
    )
        public onlyOwner
    {
        data.setStatus(_addr, _status);
    }


     
    function withdraw(
        address _addr,
        uint256 _amount,
        bool investor
    )
        public onlyOwner
    {
        uint amount = investor ? data.investorBalanceOf(_addr) : data.balanceOf(_addr);
        require(amount >= _amount && address(this).balance >= _amount);

        if (investor) {
            data.subtrInvestorBalance(_addr, _amount * 1000000);
        } else {
            data.subtrBalance(_addr, _amount * 1000000);
        }

        _addr.transfer(_amount);
    }


     
    function withdrawOwner(
        address _addr,
        uint256 _amount
    )
        public onlyOwner
    {
        require(address(this).balance >= _amount);
        _addr.transfer(_amount);
    }


     
    function transferBctToken(
        address _addr,
        uint _amount
    )
        onlyOwner public
    {
        require(bctToken.balanceOf(this) >= _amount);
        bctToken.transfer(_addr, _amount);
    }


     
    function withdrawWbtToken(
        address _addr,
        uint256 _amount
    )
        onlyOwner public
    {
        wbtToken.burn(_addr, _amount);
        uint256 etherValue = _amount * wbtToken.mrate() / wbtToken.rate();
        _addr.transfer(etherValue);
    }


     
    function transferTokenOwnership(
        address _addr
    )
        onlyOwner public
    {
        wbtToken.transferOwnership(_addr);
    }


     
    function transferDataOwnership(
        address _addr
    )
        onlyOwner public
    {
        data.transferOwnership(_addr);
    }

}