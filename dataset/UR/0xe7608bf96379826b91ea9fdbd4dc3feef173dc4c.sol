 

pragma solidity 0.4.15;

interface STQToken {
    function mint(address _to, uint256 _amount) external;
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


 
contract STQPreSale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    event FundTransfer(address backer, uint amount, bool isContribution);

    function STQPreSale(address token, address funds) {
        require(address(0) != address(token) && address(0) != address(funds));

        m_token = STQToken(token);
        m_funds = funds;
    }


     

     
    function() payable {
        require(0 == msg.data.length);
        buy();   
    }

     
     
    function buy()
        public
        payable
        nonReentrant
        returns (uint)
    {
        address investor = msg.sender;
        uint256 payment = msg.value;
        require(payment >= c_MinInvestment);
        require(now < 1507766400);

         
        uint stq = payment.mul(c_STQperETH);
        m_token.mint(investor, stq);

         
        m_funds.transfer(payment);
        FundTransfer(investor, payment, true);

        return stq;
    }

     
     
     
     
    function amIOwner() external constant onlyOwner returns (bool) {
        return true;
    }


     

     
    uint public constant c_STQperETH = 150000;

     
    uint public constant c_MinInvestment = 10 finney;

     
    STQToken public m_token;

     
    address public m_funds;
}