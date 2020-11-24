 

 

pragma solidity ^0.5.11;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    function sq(uint256 x) internal pure returns (uint256) {
        return (mul(x,x));
    }
    function pwr(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}

contract Token {
  function balanceOf(address owner) public returns (uint256);
  function transfer(address to, uint256 tokens) public returns (bool);
  function transferFrom(address from, address to, uint256 tokens) public returns(bool);
}

contract DeFi {
  using SafeMath for uint256;

  address public admin = msg.sender;
  address public zeroAddr = address(0);
  address public metContractAddr = 0x686e5ac50D9236A9b7406791256e47feDDB26AbA;
  address public metTokenAddr = 0xa3d58c4E56fedCae3a7c43A725aeE9A71F0ece4e;

  uint256 public delta;
  uint256 public baseRate;

  struct Market {
    uint256 marketOpen;
    uint256 totalLoans;
    uint256 totalPaidLoans;
    uint256 totalCollateral;
    uint256 totalUsedCollateral;
    uint256 totalLoanBlocks;
    uint256 totalPaidLoanBlocks;
    uint256 totalPoolSize;
    uint256 totalPoolWithdrawals;
  }

  struct Lender {
    uint256 balance;
    uint256 checkpoint;
  }

  struct Borrower {
    uint256 totalLoans;
    uint256 checkpoint;
  }

  struct Collateral {
    uint256 balance;
    uint256 checkpoint;
  }

  mapping(address => Market) public markets;
  mapping(address => mapping(address => Lender)) public lenders;
  mapping(address => mapping(address => Borrower)) public borrowers;
  mapping(address => mapping(address => Collateral)) public collateral;

  modifier onlyAdmin() {
      require(msg.sender == admin);
      _;
  }

  constructor(uint256 _delta, uint256 _baseRate) public {
    delta = _delta;
    baseRate = _baseRate;
  }

  function withdrawArbitraryToken(address _token, uint256 _amount) public onlyAdmin() {
    require(_token != metTokenAddr);
     require(Token(_token).transfer(admin, _amount));
  }

  function transferFrom(address _from, address _to, uint256 _amount) private {
    require(Token(metTokenAddr).transferFrom(_from,_to,_amount));
  }

  function transfer(address _to, uint256 _amount) private {
    require(Token(metTokenAddr).transfer(_to,_amount));
  }

  function getMetPrice() public returns(uint256) {
    uint256 ethBalance_ = address(metContractAddr).balance;
    uint256 tokenBalance_ = Token(metTokenAddr).balanceOf(metContractAddr);
    require(tokenBalance_ > 0, "ERROR");
    return ((tokenBalance_.mul(1e18)).div(ethBalance_)).div(1e18);
  }

  function getMarketInterestRate(address _token) public view returns(uint256) {
    uint256 netCollateral_ = markets[_token].totalCollateral.sub(markets[_token].totalUsedCollateral);
    uint256 netPoolSize_ = markets[_token].totalPoolSize.sub(markets[_token].totalPoolWithdrawals);
    uint256 netLoans_ = markets[_token].totalLoans.sub(markets[_token].totalPaidLoans);
    uint256 utilizationRatio_ = (netLoans_.mul(1e18))
                                          .div((netPoolSize_.add(netCollateral_)).add(netLoans_))
                                          .div(1e18);
    return baseRate.add(utilizationRatio_.mul(delta));
  }

  function getTotalInterest(address _token) public view returns(uint256) {
    uint256 netLoans_ = markets[_token].totalLoans.sub(markets[_token].totalPaidLoans);
    uint256 netLoansBlocks_ = markets[_token].totalLoanBlocks.sub(markets[_token].totalPaidLoanBlocks);
    uint256 interestRate_ = getMarketInterestRate(_token);
    uint256 compoundedRate_ = (uint256(1).add(interestRate_.div(2102400))
                                         .pwr(netLoansBlocks_));
    return netLoans_.mul(compoundedRate_);
  }

  function getLenderInterest(address _token, uint256 _amount) public view returns(uint256) {
    uint256 totalInterest_ = getTotalInterest(_token);
    uint256 lenderBalance_ = lenders[msg.sender][_token].balance;
    uint256 netBorrowingBlocks_ = block.number.sub(markets[_token].marketOpen);
    uint256 numOfBlocksLender_ = block.number.sub(lenders[msg.sender][_token].checkpoint);
    uint256 nOfBlocksAdjusted_ = (_amount.mul(numOfBlocksLender_)).div(lenderBalance_);
    uint256 netPoolSize_ = markets[_token].totalPoolSize.sub(markets[_token].totalPoolWithdrawals);
    uint256 netCollateral_ = markets[_token].totalCollateral
                             .sub(markets[_token].totalUsedCollateral);
    uint256 totalPool_ = netPoolSize_.add(netCollateral_);
    uint256 userInterest_ = (totalInterest_.div(netBorrowingBlocks_))
                             .mul(nOfBlocksAdjusted_)
                             .mul(lenderBalance_.div(totalPool_));
    return userInterest_;
  }

  function getCollateralInterest(address _token, uint256 _amount) public view returns(uint256) {
    uint256 totalInterest_ = getTotalInterest(_token);
    uint256 netCollateral_ = markets[_token].totalCollateral
                             .sub(markets[_token].totalUsedCollateral);
    uint256 lenderCollateral_ = collateral[msg.sender][_token].balance;
    uint256 netBorrowingBlocks_ = block.number.sub(markets[_token].marketOpen);
    uint256 numOfBlocksCollateral_ = block.number.sub(collateral[msg.sender][_token].checkpoint);
    uint256 nOfBlocksAdjusted_ = (_amount.mul(numOfBlocksCollateral_)).div(lenderCollateral_);
    uint256 netPoolSize_ = markets[_token].totalPoolSize.sub(markets[_token].totalPoolWithdrawals);
    uint256 totalPool_ = netPoolSize_.add(netCollateral_);
    uint256 userInterest_ = (totalInterest_.div(netBorrowingBlocks_))
                             .mul(nOfBlocksAdjusted_)
                             .mul(lenderCollateral_.div(totalPool_));
    return userInterest_;
  }

  function loansAreCollateralized(address _token) public returns(bool) {
    uint256 metPrice_ = getMetPrice();
    address borrowToken_ = _token == zeroAddr ? metTokenAddr : zeroAddr;
    uint256 amountBorrowed_ = borrowers[msg.sender][_token].totalLoans;
    uint256 outstandingLoans_ = borrowToken_ == metTokenAddr ? amountBorrowed_.div(metPrice_) : amountBorrowed_.mul(metPrice_);
    uint256 totalCollateral_ = getCollateralValue(msg.sender, metTokenAddr);
    return totalCollateral_ > (outstandingLoans_.mul(15e7)).div(1e18);
  }

  function withdrawCollateral(address _token, uint256 _amount) public {
    require(loansAreCollateralized(_token));
    uint256 collateral_ = collateral[msg.sender][_token].balance;
    require(_amount <= collateral_);
    uint256 netCollateral_ = markets[_token].totalCollateral
                             .sub(markets[_token].totalUsedCollateral.add(_amount));
    uint256 netPoolSize_ = markets[_token].totalPoolSize
                           .sub(markets[_token].totalPoolWithdrawals);
    uint256 totalPool_ = netPoolSize_.add(netCollateral_);
    if(totalPool_ == 0) {
      markets[_token].marketOpen = 0;
    }
    uint256 accruedInterest_ = getCollateralInterest(_token, _amount);
    uint256 totalWithdrawal_ = _amount.add(accruedInterest_);
    uint256 checkpoint_ = collateral[msg.sender][_token].checkpoint;
    uint256 numOfBlocksCollateral_ = block.number.sub(checkpoint_);
    uint256 nOfBlocksAdjusted_ = (_amount.mul(numOfBlocksCollateral_)).div(collateral_);
    collateral[msg.sender][_token].balance = collateral_.sub(_amount);
    collateral[msg.sender][_token].checkpoint = checkpoint_.add(nOfBlocksAdjusted_);
    markets[_token].totalUsedCollateral = markets[_token].totalUsedCollateral.add(_amount);
    if(_token == zeroAddr) {
        (bool success, ) = msg.sender.call.value(totalWithdrawal_)("");
        if(!success) {
            revert();
        }
    }
    else {
        transfer(msg.sender, totalWithdrawal_);
    }
  }

  function withdraw(address _token, uint256 _amount) public {
    uint256 balance_ = lenders[msg.sender][_token].balance;
    require(_amount <= balance_);
    uint256 netCollateral_ = markets[_token].totalCollateral
                             .sub(markets[_token].totalUsedCollateral);
    uint256 netPoolSize_ = markets[_token].totalPoolSize
                           .sub(markets[_token].totalPoolWithdrawals.add(_amount));
    if(netPoolSize_.add(netCollateral_) == 0) {
      markets[_token].marketOpen = 0;
    }
    uint256 accruedInterest_ = getLenderInterest(_token, _amount);
    uint256 totalWithdrawal_ = _amount.add(accruedInterest_);
    uint256 checkpoint_ = lenders[msg.sender][_token].checkpoint;
    uint256 numOfBlocksLender_ = block.number.sub(checkpoint_);
    uint256 nOfBlocksAdjusted_ = (_amount.mul(numOfBlocksLender_)).div(balance_);
    lenders[msg.sender][_token].balance = balance_.sub(_amount);
    lenders[msg.sender][_token].checkpoint = checkpoint_.add(nOfBlocksAdjusted_);
    markets[_token].totalPoolWithdrawals = markets[_token].totalPoolWithdrawals.add(_amount);
    if(_token == zeroAddr) {
        (bool success, ) = msg.sender.call.value(totalWithdrawal_)("");
        if(!success) {
            revert();
        }
    }
    else {
        transfer(msg.sender, totalWithdrawal_);
    }
  }

  function initMarketOpen(address _token) private {
    if(markets[_token].marketOpen == 0) {
      markets[_token].marketOpen = block.number;
    }
  }

  function initLenderCheckpoint(address _token) private {
    if(lenders[msg.sender][_token].checkpoint == 0) {
      lenders[msg.sender][_token].checkpoint = block.number;
    }
  }

  function initCollateralCheckpoint(address _token) private {
    if(collateral[msg.sender][_token].checkpoint == 0) {
       collateral[msg.sender][_token].checkpoint = block.number;
     }
 }

   function initBorrowerCheckpoint(address _token) private {
     if(borrowers[msg.sender][_token].checkpoint == 0) {
        borrowers[msg.sender][_token].checkpoint = block.number;
      }
  }

  function addEthToPool() private {
    lenders[msg.sender][zeroAddr].balance = lenders[msg.sender][zeroAddr].balance.add(msg.value);
    markets[zeroAddr].totalPoolSize = markets[zeroAddr].totalPoolSize.add(msg.value);
  }

  function addMetToPool(uint256 _amount) private {
    lenders[msg.sender][metTokenAddr].balance = lenders[msg.sender][metTokenAddr].balance.add(_amount);
    markets[metTokenAddr].totalPoolSize = markets[metTokenAddr].totalPoolSize.add(_amount);
    transferFrom(msg.sender, address(this), _amount);
  }

  function lendEth() public payable {
    initMarketOpen(zeroAddr);
    initLenderCheckpoint(zeroAddr);
    addEthToPool();
  }

  function lendMet(uint256 _amount) public {
    initMarketOpen(metTokenAddr);
    initLenderCheckpoint(metTokenAddr);
    addMetToPool(_amount);
  }

  function addMetLoans(uint256 _amount) private {
   borrowers[msg.sender][metTokenAddr].totalLoans = borrowers[msg.sender][metTokenAddr].totalLoans.add(_amount);
   markets[metTokenAddr].totalLoans = markets[metTokenAddr].totalLoans.add(_amount);
  }

  function addEthLoans() private {
   borrowers[msg.sender][zeroAddr].totalLoans = borrowers[msg.sender][zeroAddr].totalLoans.add(msg.value);
   markets[zeroAddr].totalLoans = markets[zeroAddr].totalLoans.add(msg.value);
  }

  function addEthCollateralToPool() private {
    collateral[msg.sender][zeroAddr].balance = collateral[msg.sender][zeroAddr].balance.add(msg.value);
    markets[zeroAddr].totalCollateral = markets[zeroAddr].totalCollateral.add(msg.value);
  }

  function addMetCollateralToPool(uint256 _amount) private {
    collateral[msg.sender][metTokenAddr].balance = collateral[msg.sender][metTokenAddr].balance.add(_amount);
    markets[metTokenAddr].totalCollateral = markets[metTokenAddr].totalCollateral.add(_amount);
  }

  function addMetCollateral(uint256 _amount) public {
    addMetCollateralToPool(_amount);
    initCollateralCheckpoint(metTokenAddr);
    transferFrom(msg.sender, address(this), _amount);
  }

  function addEthCollateral() public {
    addEthCollateralToPool();
    initCollateralCheckpoint(zeroAddr);
  }

  function borrowEth(uint256 _amount) public {
    uint256 metPrice_ = getMetPrice();
    uint256 collateral_ = borrowers[msg.sender][zeroAddr].totalLoans;
    uint256 interest_ = getCollateralInterest(zeroAddr, collateral_);
    uint256 totalCollateral_ = collateral_.add(interest_);
    uint256 collateralRequirement_ = ((_amount.div(metPrice_)).mul(15e7)).div(1e18);
    require(totalCollateral_ >= collateralRequirement_);
    initBorrowerCheckpoint(zeroAddr);
    addEthLoans();
  }

  function borrowMet(uint256 _amount) public {
    uint256 metPrice_ = getMetPrice();
    uint256 collateral_ = borrowers[msg.sender][metTokenAddr].totalLoans;
    uint256 interest_ = getCollateralInterest(metTokenAddr, collateral_);
    uint256 totalCollateral_ = collateral_.add(interest_);
    uint256 collateralRequirement_ = ((_amount.mul(metPrice_)).mul(15e7)).div(1e18);
    require(totalCollateral_ >= collateralRequirement_);
    initBorrowerCheckpoint(metTokenAddr);
    addMetLoans(_amount);
  }

  function getOwedInterest(address _token) public view returns(uint256) {
    uint256 balance_ = borrowers[msg.sender][_token].totalLoans;
    uint256 numberOfBlocksBorrower_ = block.number.sub(borrowers[msg.sender][_token].checkpoint);
    uint256 interestRate_ = getMarketInterestRate(_token);
    uint256 compoundedRate_ = (uint256(1).add(interestRate_.div(2102400))
                                         .pwr(numberOfBlocksBorrower_));
    return balance_.mul(compoundedRate_);
  }

  function getOwedInterestPartial(address _token, uint256 _amount) public view returns(uint256) {
    uint256 balance_ = borrowers[msg.sender][_token].totalLoans;
    require(_amount <= balance_);
    uint256 checkpoint_ = borrowers[msg.sender][_token].checkpoint;
    uint256 numberOfBlocksBorrower_ = block.number.sub(checkpoint_);
    uint256 nOfBlocksAdjusted_ = (_amount.div(balance_)).mul(numberOfBlocksBorrower_);
    uint256 interestRate_ = getMarketInterestRate(_token);
    uint256 compoundedRate_ = (uint256(1).add(interestRate_.div(2102400))
                                       .pwr(nOfBlocksAdjusted_));
    return _amount.mul(compoundedRate_);
  }

  function updateLoansStatus(address _token, uint256 _amount) private {
    uint256 loanAmount_ = borrowers[msg.sender][_token].totalLoans;
    uint256 netBlocks_ = block.number.sub(borrowers[msg.sender][_token].checkpoint);
    uint256 adjustedNetBlocks_ = (_amount.mul(netBlocks_)).div(loanAmount_);
    markets[_token].totalPaidLoans = markets[_token].totalPaidLoans.add(_amount);
    markets[_token].totalLoanBlocks = markets[_token].totalLoanBlocks.add(adjustedNetBlocks_);
    borrowers[msg.sender][_token].checkpoint = borrowers[msg.sender][_token].checkpoint.add(adjustedNetBlocks_);
  }

  function repayEth(uint256 _amount) public payable {
    uint256 accruedInterest_ = getOwedInterestPartial(zeroAddr, _amount);
    uint256 totalRepayment_ = _amount.add(accruedInterest_);
    require(msg.value == totalRepayment_);
    updateLoansStatus(zeroAddr, _amount);
  }

  function repayMet(uint256 _amount) public {
    uint256 accruedInterest_ = getOwedInterestPartial(metTokenAddr, _amount);
    uint256 totalRepayment_ = _amount.add(accruedInterest_);
    updateLoansStatus(metTokenAddr, _amount);
    transferFrom(msg.sender, address(this), totalRepayment_);
  }

  function updateLiquidatedLoansStatus(address _borrower, address _token) private {
    uint256 balance_ = borrowers[_borrower][_token].totalLoans;
    uint256 collateral_ = collateral[_borrower][_token].balance;
    uint256 netBlocks_ = block.number.sub(borrowers[_borrower][_token].checkpoint);
    borrowers[_borrower][_token].totalLoans = 0;
    collateral[_borrower][_token].balance = 0;
    borrowers[_borrower][_token].checkpoint = 0;
    collateral[_borrower][_token].checkpoint = 0;
    markets[_token].totalPaidLoans = markets[_token].totalPaidLoans.add(balance_);
    markets[_token].totalLoanBlocks = markets[_token].totalLoanBlocks.add(netBlocks_);
    markets[_token].totalUsedCollateral = markets[_token].totalUsedCollateral.add(collateral_);
  }

  function getCollateralValue(address _borrower, address _token) public view returns(uint256) {
    uint256 collateral_ = collateral[_borrower][_token].balance;
    uint256 interest_ = getCollateralInterest(_token, collateral_);
    uint256 totalCollateral_ = collateral_.add(interest_);
    return totalCollateral_;
  }

  function liquidateEth(address _borrower) public {
    uint256 metPrice_ = getMetPrice();
    uint256 amountBorrowed_ = borrowers[_borrower][zeroAddr].totalLoans;
    uint256 totalCollateral_ = getCollateralValue(_borrower, metTokenAddr);
    require(totalCollateral_ < ((amountBorrowed_.mul(metPrice_)).mul(15e7)).div(1e18));
    uint256 fee_ = amountBorrowed_.div(20);
    updateLiquidatedLoansStatus(_borrower, zeroAddr);
    transfer(msg.sender, fee_);
    transfer(_borrower, totalCollateral_.sub(fee_));
  }

  function liquidateMet(address payable _borrower) public {
    uint256 metPrice_ = getMetPrice();
    uint256 amountBorrowed_ = borrowers[_borrower][metTokenAddr].totalLoans;
    uint256 totalCollateral_ = getCollateralValue(_borrower, zeroAddr);
    require(totalCollateral_ < ((amountBorrowed_.div(metPrice_)).mul(15e7)).div(1e18));
    uint256 fee_ = amountBorrowed_.div(20);
    updateLiquidatedLoansStatus(_borrower, metTokenAddr);
    (bool collateralSent, ) = _borrower.call.value(totalCollateral_.sub(fee_))("");
    if(!collateralSent) {
      revert();
    } else {
        (bool feeSent, ) =  msg.sender.call.value(fee_)("");
        if(!feeSent) {
            revert();
        }
    }
  }
}