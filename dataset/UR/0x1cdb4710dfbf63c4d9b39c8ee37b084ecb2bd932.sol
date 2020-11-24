 

pragma solidity ^0.4.19;

contract Ownable {

     
    address public owner = msg.sender;

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
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

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] += _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

}

 
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint value);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply += _amount;
        balances[_to] += _amount;
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function burn(address _addr, uint _amount) onlyOwner public {
        require(_amount > 0 && balances[_addr] >= _amount && totalSupply >= _amount);
        balances[_addr] -= _amount;
        totalSupply -= _amount;
        Burn(_addr, _amount);
        Transfer(_addr, address(0), _amount);
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract WealthBuilderToken is MintableToken {

    string public name = "Wealth Builder Token";

    string public symbol = "WBT";

    uint32 public decimals = 18;

     
    uint public rate = 10**7;
     
    uint public mrate = 10**7;

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

     
    function Data() public {
         
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

    function setStatus(address _addr, uint8 _status) onlyOwner public {
        statuses[_addr] = _status;
    }

    function setParent(address _addr, address _parent) onlyOwner public {
        parent[_addr] = _parent;
    }

}

contract Declaration {

     
    mapping (uint => uint8) statusThreshold;

     
    mapping (uint8 => mapping (uint8 => uint)) feeDistribution;

     
    uint[8] thresholds = [
    0, 5000, 35000, 150000, 500000, 2500000, 5000000, 10000000
    ];

    uint[5] referralFees = [50, 30, 20, 10, 5];
    uint[5] serviceFees = [25, 20, 15, 10, 5];


     
    function Declaration() public {
        setFeeDistributionsAndStatusThresholds();
    }


     
    function setFeeDistributionsAndStatusThresholds() private {
         
        setFeeDistributionAndStatusThreshold(0, [12, 8, 5, 2, 1], thresholds[0]);
         
        setFeeDistributionAndStatusThreshold(1, [16, 10, 6, 3, 2], thresholds[1]);
         
        setFeeDistributionAndStatusThreshold(2, [20, 12, 8, 4, 2], thresholds[2]);
         
        setFeeDistributionAndStatusThreshold(3, [25, 15, 10, 5, 3], thresholds[3]);
         
        setFeeDistributionAndStatusThreshold(4, [30, 18, 12, 6, 3], thresholds[4]);
         
        setFeeDistributionAndStatusThreshold(5, [35, 21, 14, 7, 4], thresholds[5]);
         
        setFeeDistributionAndStatusThreshold(6, [40, 24, 16, 8, 4], thresholds[6]);
         
        setFeeDistributionAndStatusThreshold(7, [50, 30, 20, 10, 5], thresholds[7]);
    }


     
    function setFeeDistributionAndStatusThreshold(
        uint8 _st,
        uint8[5] _percentages,
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

contract Investors is Ownable {

     
     
    address[] public investors;

     
     
    mapping (address => uint) public investorPercentages;


     
    function addInvestors(address[] _investors, uint[] _investorPercentages) onlyOwner public {
        for (uint i = 0; i < _investors.length; i++) {
            investors.push(_investors[i]);
            investorPercentages[_investors[i]] = _investorPercentages[i];
        }
    }


     
    function getInvestorsCount() public constant returns (uint) {
        return investors.length;
    }


     
    function getInvestorsFee() public constant returns (uint8) {
         
        if (now >= 1577836800) {
            return 1;
        }
         
        if (now >= 1546300800) {
            return 5;
        }
        return 10;
    }

}

contract Referral is Declaration, Ownable {

    using SafeMath for uint;

     
    WealthBuilderToken private token;

     
    Data private data;

     
    Investors private investors;

     
    uint public investorsBalance;

     
    uint public ethUsdRate;

     
    function Referral(uint _ethUsdRate, address _token, address _data, address _investors) public {
        ethUsdRate = _ethUsdRate;

         
        token = WealthBuilderToken(_token);
        data = Data(_data);
        investors = Investors(_investors);

        investorsBalance = 0;
    }

     
    function() payable public {
    }

    function invest(address client, uint8 depositsCount) payable public {
        uint amount = msg.value;

         
        if (depositsCount < 5) {

            uint serviceFee;
            uint investorsFee = 0;

            if (depositsCount == 0) {
                uint8 investorsFeePercentage = investors.getInvestorsFee();
                serviceFee = amount * (serviceFees[depositsCount].sub(investorsFeePercentage));
                investorsFee = amount * investorsFeePercentage;
                investorsBalance += investorsFee;
            } else {
                serviceFee = amount * serviceFees[depositsCount];
            }

            uint referralFee = amount * referralFees[depositsCount];

             
            distribute(data.parentOf(client), 0, depositsCount, amount);

             
            uint active = (amount * 100)
            .sub(referralFee)
            .sub(serviceFee)
            .sub(investorsFee);
            token.mint(client, active / 100 * token.rate() / token.mrate());

             
            data.addBalance(owner, serviceFee * 10000);
        } else {
            token.mint(client, amount * token.rate() / token.mrate());
        }
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
            data.addBalance(node, _amount * percentage * 10000);

             
            data.addReferralDeposit(node, _amount * ethUsdRate / 10**18);

             
            updateStatus(node, status);

            node = data.parentOf(node);
            prevPercentage = nodePercentage;
        }
    }


     
    function updateStatus(address _node, uint8 _status) private {
        uint refDep = data.referralDeposits(_node);

        for (uint i = thresholds.length - 1; i > _status; i--) {
            uint threshold = thresholds[i] * 100;

            if (refDep >= threshold) {
                data.setStatus(_node, statusThreshold[threshold]);
                break;
            }
        }
    }


     
    function distributeInvestorsFee(uint start, uint end) onlyOwner public {
        for (uint i = start; i < end; i++) {
            address investor = investors.investors(i);
            uint investorPercentage = investors.investorPercentages(investor);
            data.addInvestorBalance(investor, investorsBalance * investorPercentage);
        }
        if (end == investors.getInvestorsCount()) {
            investorsBalance = 0;
        }
    }


     
    function setRate(uint _rate) onlyOwner public {
        token.setRate(_rate);
    }


     
    function setEthUsdRate(uint _ethUsdRate) onlyOwner public {
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


     
    function setStatus(address _addr, uint8 _status) public onlyOwner {
        data.setStatus(_addr, _status);
    }


     
    function setInvestors(address _addr) public onlyOwner {
        investors = Investors(_addr);
    }


     
    function withdraw(address _addr, uint256 _amount, bool investor) public onlyOwner {
        uint amount = investor ? data.investorBalanceOf(_addr)
        : data.balanceOf(_addr);
        require(amount >= _amount && this.balance >= _amount);

        if (investor) {
            data.subtrInvestorBalance(_addr, _amount * 1000000);
        } else {
            data.subtrBalance(_addr, _amount * 1000000);
        }

        _addr.transfer(_amount);
    }


     
    function withdrawOwner(address _addr, uint256 _amount) public onlyOwner {
        require(this.balance >= _amount);
        _addr.transfer(_amount);
    }


     
    function withdrawToken(address _addr, uint256 _amount) onlyOwner public {
        token.burn(_addr, _amount);
        uint256 etherValue = _amount * token.mrate() / token.rate();
        _addr.transfer(etherValue);
    }


     
    function transferTokenOwnership(address _addr) onlyOwner public {
        token.transferOwnership(_addr);
    }


     
    function transferDataOwnership(address _addr) onlyOwner public {
        data.transferOwnership(_addr);
    }

}

contract PChannel is Ownable {
    
    Referral private refProgram;

     
    uint private depositAmount = 300000;

     
    uint private maxDepositAmount =375000;

     
    mapping (address => uint8) private deposits; 
    
    function PChannel(address _refProgram) public {
        refProgram = Referral(_refProgram);
    }
    
    function() payable public {
        uint8 depositsCount = deposits[msg.sender];
         
         
        if (depositsCount == 15) {
            depositsCount = 0;
            deposits[msg.sender] = 0;
        }

        uint amount = msg.value;
        uint usdAmount = amount * refProgram.ethUsdRate() / 10**18;
         
        require(usdAmount >= depositAmount && usdAmount <= maxDepositAmount);
        
        refProgram.invest.value(amount)(msg.sender, depositsCount);
        deposits[msg.sender]++;
    }

     
    function setRefProgram(address _addr) public onlyOwner {
        refProgram = Referral(_addr);
    }
    
}