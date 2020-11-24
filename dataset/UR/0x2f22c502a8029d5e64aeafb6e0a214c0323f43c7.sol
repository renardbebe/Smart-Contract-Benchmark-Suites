 

pragma solidity 0.4.15;



 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



 
contract AnalyticProxy {

    function AnalyticProxy() {
        m_analytics = InvestmentAnalytics(msg.sender);
    }

     
    function() payable {
        m_analytics.iaInvestedBy.value(msg.value)(msg.sender);
    }

    InvestmentAnalytics public m_analytics;
}


 
contract InvestmentAnalytics {
    using SafeMath for uint256;

    function InvestmentAnalytics(){
    }

     
    function createMorePaymentChannelsInternal(uint limit) internal returns (uint) {
        uint paymentChannelsCreated;
        for (uint i = 0; i < limit; i++) {
            uint startingGas = msg.gas;
             

            address paymentChannel = new AnalyticProxy();
            m_validPaymentChannels[paymentChannel] = true;
            m_paymentChannels.push(paymentChannel);
            paymentChannelsCreated++;

             
            uint gasPerChannel = startingGas.sub(msg.gas);
            if (gasPerChannel.add(50000) > msg.gas)
                break;   
        }
        return paymentChannelsCreated;
    }


     
    function iaInvestedBy(address investor) external payable {
        address paymentChannel = msg.sender;
        if (m_validPaymentChannels[paymentChannel]) {
             
            uint value = msg.value;
            m_investmentsByPaymentChannel[paymentChannel] = m_investmentsByPaymentChannel[paymentChannel].add(value);
             
            iaOnInvested(investor, value, true);
        } else {
             
             
            iaOnInvested(msg.sender, msg.value, false);
        }
    }

     
    function iaOnInvested(address investor, uint payment, bool usingPaymentChannel) internal {
    }


    function paymentChannelsCount() external constant returns (uint) {
        return m_paymentChannels.length;
    }

    function readAnalyticsMap() external constant returns (address[], uint[]) {
        address[] memory keys = new address[](m_paymentChannels.length);
        uint[] memory values = new uint[](m_paymentChannels.length);

        for (uint i = 0; i < m_paymentChannels.length; i++) {
            address key = m_paymentChannels[i];
            keys[i] = key;
            values[i] = m_investmentsByPaymentChannel[key];
        }

        return (keys, values);
    }

    function readPaymentChannels() external constant returns (address[]) {
        return m_paymentChannels;
    }


    mapping(address => uint256) public m_investmentsByPaymentChannel;
    mapping(address => bool) m_validPaymentChannels;

    address[] public m_paymentChannels;
}

 
contract ReentrancyGuard {

   
  bool private rentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }

}

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract STQToken {
    function mint(address _to, uint256 _amount) external;
}

 
contract STQPreICO is Ownable, ReentrancyGuard, InvestmentAnalytics {
    using SafeMath for uint256;

    event FundTransfer(address backer, uint amount, bool isContribution);

    function STQPreICO(address token, address funds) {
        require(address(0) != address(token) && address(0) != address(funds));

        m_token = STQToken(token);
        m_funds = funds;
    }


     

     
    function() payable {
        require(0 == msg.data.length);
        buy();   
    }

     
    function buy() public payable {      
        iaOnInvested(msg.sender, msg.value, false);
    }


     

    function createMorePaymentChannels(uint limit) external onlyOwner returns (uint) {
        return createMorePaymentChannelsInternal(limit);
    }

     
     
     
     
    function amIOwner() external constant onlyOwner returns (bool) {
        return true;
    }


     

     
    function iaOnInvested(address investor, uint payment, bool usingPaymentChannel)
        internal
        nonReentrant
    {
        require(payment >= c_MinInvestment);
        require(getCurrentTime() >= c_startTime && getCurrentTime() < c_endTime || msg.sender == owner);

        uint startingInvariant = this.balance.add(m_funds.balance);

         
        uint paymentAllowed = getMaximumFunds().sub(m_totalInvested);
        if (0 == paymentAllowed) {
            investor.transfer(payment);
            return;
        }
        uint change;
        if (paymentAllowed < payment) {
            change = payment.sub(paymentAllowed);
            payment = paymentAllowed;
        }

         
        uint bonusPercent = c_preICOBonusPercent;
        bonusPercent += getLargePaymentBonus(payment);
        if (usingPaymentChannel)
            bonusPercent += c_paymentChannelBonusPercent;

        uint rate = c_STQperETH.mul(100 + bonusPercent).div(100);

         
        uint stq = payment.mul(rate);
        m_token.mint(investor, stq);

         
        m_funds.transfer(payment);
        m_totalInvested = m_totalInvested.add(payment);
        assert(m_totalInvested <= getMaximumFunds());
        FundTransfer(investor, payment, true);

        if (change > 0)
            investor.transfer(change);

        assert(startingInvariant == this.balance.add(m_funds.balance).add(change));
    }

    function getLargePaymentBonus(uint payment) private constant returns (uint) {
        if (payment > 1000 ether) return 10;
        if (payment > 800 ether) return 8;
        if (payment > 500 ether) return 5;
        if (payment > 200 ether) return 2;
        return 0;
    }

     
    function getCurrentTime() internal constant returns (uint) {
        return now;
    }

     
    function getMaximumFunds() internal constant returns (uint) {
        return c_MaximumFunds;
    }


     

     
    uint public constant c_startTime = 1507766400;

     
    uint public constant c_endTime = c_startTime + (1 days);

     
    uint public constant c_MinInvestment = 10 finney;

     
    uint public constant c_MaximumFunds = 8000 ether;


     
    uint public constant c_STQperETH = 100000;

     
    uint public constant c_preICOBonusPercent = 40;

     
    uint public constant c_paymentChannelBonusPercent = 2;


     
    uint public m_totalInvested;

     
    STQToken public m_token;

     
    address public m_funds;
}