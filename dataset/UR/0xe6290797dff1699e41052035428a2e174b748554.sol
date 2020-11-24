 

pragma solidity ^0.5.15;

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
}

contract Token {
  function balanceOf(address owner) public view returns (uint256);
  function transfer(address to, uint256 tokens) public returns (bool);
  function transferFrom(address from, address to, uint256 tokens) public returns(bool);
}

contract DeFi {
  using SafeMath for uint256;

  address public admin = msg.sender;
  address public zeroAddr = address(0);
  address public metContractAddr = 0x077e2A322cCCeD4808c720E09520F85a9A85C257;
  address public metTokenAddr = 0xB786EC13b6Fb2F6406a40B98088A92723EE2F5e0;

  uint256 public price = 2e16;
  uint256 public delta = 2e15;
  uint256 public baseRate = 4e16;

  struct Market {
    uint256 marketOpen;
    uint256 totalLoans;
    uint256 totalLiquidity;
  }

  struct User {
    uint256 debt;
    uint256 balances;
    uint256 checkpoint;
    uint256 synthBalances;
  }

  mapping(address => Market) public markets;
  mapping(address => uint256) public synthSupply;
  mapping(address => mapping(address => User)) public user;

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  constructor() public {
    markets[zeroAddr].marketOpen = block.number;
    markets[zeroAddr].totalLiquidity = 1;
    markets[metTokenAddr].marketOpen = block.number;
    markets[metTokenAddr].totalLiquidity = 1;
  }

  function synthTransfer(address _token, address _from, address _to, uint256 _amount) private {
     user[_from][_token].synthBalances = user[_from][_token].synthBalances.sub(_amount);
     user[_to][_token].synthBalances = user[_to][_token].synthBalances.add(_amount);
  }

  function synthMint(address _token, address _account, uint256 _amount) private {
     synthSupply[_token] = synthSupply[_token].add(_amount);
     user[_account][_token].synthBalances = user[_account][_token].synthBalances.add(_amount);
  }

  function synthBurn(address _token, address _account, uint256 _amount) private {
      synthSupply[_token] = synthSupply[_token].sub(_amount);
      user[_account][_token].synthBalances = user[_account][_token].synthBalances.sub(_amount);
  }

  function transferUnderlyingFromMkt(address _token, address _account, uint256 _amount) private {
      markets[_token].totalLiquidity = markets[_token].totalLiquidity.sub(_amount);
      user[_account][_token].balances = user[_account][_token].balances.add(_amount);
  }

  function transferUnderlyingToMkt(address _token, address _account, uint256 _amount) private {
      user[_account][_token].balances = user[_account][_token].balances.sub(_amount);
      markets[_token].totalLiquidity = markets[_token].totalLiquidity.add(_amount);
  }

  function transferFrom(address _from, address _to, uint256 _amount) private {
    require(Token(metTokenAddr).transferFrom(_from,_to,_amount));
  }

  function transfer(address _to, uint256 _amount) private {
    require(Token(metTokenAddr).transfer(_to,_amount));
  }

  function transferEth(uint256 _amount) private {
    (bool success, ) = msg.sender.call.value(_amount)("");
    if(!success) {
        revert();
    }
  }
  function depositToken(uint256 _amount) public {
    user[msg.sender][metTokenAddr].balances = user[msg.sender][metTokenAddr].balances.add(_amount);
    transferFrom(msg.sender, address(this), _amount);
  }

  function withdrawToken(uint256 _amount) public {
    require(user[msg.sender][metTokenAddr].balances >= _amount);
    user[msg.sender][metTokenAddr].balances = user[msg.sender][metTokenAddr].balances.sub(_amount);
    transfer(msg.sender, _amount);
  }

  function depositEth() public payable {
    user[msg.sender][zeroAddr].balances = user[msg.sender][zeroAddr].balances.add(msg.value);
  }

  function withdrawEth(uint256 _amount) public {
    require(user[msg.sender][zeroAddr].balances >= _amount);
    user[msg.sender][zeroAddr].balances = user[msg.sender][zeroAddr].balances.sub(_amount);
    transferEth(_amount);
  }

  function fracExp(uint256 _k, uint256 _q, uint256 _n) private pure returns (uint256) {
    uint256 s = 0;
    uint256 N = 1;
    uint256 B = 1;
    for (uint i = 0; i < 10; ++i){
      s += _k * N / B / (_q**i);
      N  = N * (_n-i);
      B  = B * (i+1);
    }
    return s;
  }

  function convertToSynth(address _token, uint256 _amount) public view returns(uint256) {
    uint256 exchangeRate_ = getSynthExchangeRate(_token);
    return (_amount.mul(exchangeRate_)).div(1e18);
  }

  function convertFromSynth(address _token, uint256 _amount) public view returns(uint256) {
    uint256 exchangeRate_ = getSynthExchangeRate(_token);
    return (_amount.mul(1e18)).div(exchangeRate_);
  }

  function getMarketInterestRate(address _token) public view returns(uint256) {
    uint256 totalLiquidity_ = markets[_token].totalLiquidity;
    uint256 outstandingLoans_ = markets[_token].totalLoans;
    uint256 utilizationRatio_ = (outstandingLoans_.mul(1e18))
                                .div((totalLiquidity_).add(outstandingLoans_));
    return baseRate.add((utilizationRatio_.mul(delta)).div(1e18));
  }

  function getSynthExchangeRate(address _token) public view returns(uint256) {
    uint256 marketRate_ = getMarketInterestRate(_token);
    uint256 rateAdjusted_ = (uint256(1e18).div(marketRate_.div(2102400)));
    uint256 timeElapsed_ = block.number.sub(markets[_token].marketOpen);
    return fracExp(price, rateAdjusted_, timeElapsed_);
  }

  function exchangeUnderlyingForSynth(address _token, address _user, uint256 _baseAmount, uint256 _synthAmount) private {
    transferUnderlyingToMkt(_token, _user, _baseAmount);
    synthMint(_token, _user, _synthAmount);
  }

  function exchangeSynthForUnderlying(address _token, address _user, uint256 _baseAmount, uint256 _synthAmount) private {
    transferUnderlyingFromMkt(_token, _user, _baseAmount);
    synthBurn(_token, _user, _synthAmount);
  }

  function getSynthToken(address _token, uint256 _amount) public {
    uint256 synthAmount_ = convertToSynth(_token, _amount);
    exchangeUnderlyingForSynth(_token, msg.sender, _amount, synthAmount_);
  }

  function redeemSynthToken(address _token, uint256 _amount) public {
    uint256 baseAmount_ = convertFromSynth(_token, _amount);
    exchangeSynthForUnderlying(_token, msg.sender, baseAmount_, _amount);
  }

  function getMetPrice() public view returns(uint256) {
    uint256 ethBalance_ = address(metContractAddr).balance;
    uint256 tokenBalance_ = Token(metTokenAddr).balanceOf(metContractAddr);
    return ((tokenBalance_.mul(1e18)).div(ethBalance_)).div(1e18);
  }

  function convertEthToMet(uint256 _amount) private view returns(uint256) {
    uint256 price_ = getMetPrice();
    return ((_amount.mul(1e18)).div(price_)).div(1e18);
  }

  function convertMetToEth(uint256 _amount) private view returns(uint256) {
    uint256 price_ = getMetPrice();
    return _amount.mul(price_);
  }

  function refreshCheckpoint(address _token) private {
    if(user[msg.sender][_token].checkpoint == 0) {
      user[msg.sender][_token].checkpoint = block.number;
    }
  }

  function disburseLoans(address _token, address _user, uint256 _amount) private {
    markets[_token].totalLiquidity = markets[_token].totalLiquidity.sub(_amount);
    user[_user][_token].debt = user[_user][_token].debt.add(_amount);
    markets[_token].totalLoans = markets[_token].totalLoans.add(_amount);
  }

  function retrieveLoans(address _token, address _user, uint256 _amount, uint256 _interest) private {
    user[_user][_token].debt = user[_user][_token].debt.sub(_amount.sub(_interest));
    markets[_token].totalLoans = markets[_token].totalLoans.sub(_amount.sub(_interest));
    markets[_token].totalLiquidity = markets[_token].totalLiquidity.add(_amount);
  }

  function borrowEth(uint256 _amount) public {
    uint256 synthBalance_ = user[msg.sender][metTokenAddr].synthBalances;
    uint256 balanceInBase_ = convertFromSynth(metTokenAddr, synthBalance_);
    uint256 balanceInEth_ = convertMetToEth(balanceInBase_);
    if(_amount.mul(2) <= balanceInEth_) {
      refreshCheckpoint(zeroAddr);
      disburseLoans(metTokenAddr, msg.sender, _amount);
      transferEth(_amount);
    }
  }

  function borrowMet(uint256 _amount) public {
    uint256 synthBalance_ = user[msg.sender][zeroAddr].synthBalances;
    uint256 balanceInBase_ = convertFromSynth(zeroAddr, synthBalance_);
    uint256 balanceInMet_ = convertEthToMet(balanceInBase_);
    if(_amount.mul(2) <= balanceInMet_) {
      refreshCheckpoint(metTokenAddr);
      disburseLoans(zeroAddr, msg.sender, _amount);
      transfer(msg.sender, _amount);
    }
  }

  function getAmountOwed(address _borrower, address _token) public view returns(uint256, uint256) {
    uint256 balance_ = user[_borrower][_token].debt;
    uint256 marketRate_ = getMarketInterestRate(_token);
    uint256 blocksElapsed_ = block.number.sub(user[_borrower][_token].checkpoint);
    uint256 amountWithInterest_ = fracExp(balance_, marketRate_, blocksElapsed_);
    return (amountWithInterest_, amountWithInterest_.sub(balance_));
  }

  function repayLoan(address _token, uint256 _amount) public {
    (uint256 amountOwed_, uint256 interest_) = getAmountOwed(msg.sender, _token);
    require(amountOwed_ > 0 && _amount <= amountOwed_);
    retrieveLoans(_token, msg.sender, _amount, interest_);
  }

  function liquidateEth(address _borrower) public {
    uint256 debt_ = user[_borrower][zeroAddr].debt;
    uint256 synthBalance_ = user[_borrower][metTokenAddr].synthBalances;
    uint256 balanceInBase_ = convertFromSynth(metTokenAddr, synthBalance_);
    uint256 balanceInEth_ = convertMetToEth(balanceInBase_);
    require(debt_.mul(2) < balanceInEth_);
    uint256 debtInMet = convertEthToMet(debt_);
    uint256 metDebtInSynth = convertToSynth(metTokenAddr, debtInMet);
    uint256 metFee_ = metDebtInSynth.div(20);
    transferUnderlyingToMkt(metTokenAddr, _borrower, debtInMet);
    synthBurn(metTokenAddr, _borrower, metDebtInSynth.sub(metFee_));
    synthTransfer(metTokenAddr, _borrower, msg.sender, metFee_);
  }

  function liquidateMet(address _borrower) public {
    uint256 debt_ = user[_borrower][metTokenAddr].debt;
    uint256 synthBalance_ = user[_borrower][zeroAddr].synthBalances;
    uint256 balanceInBase_ = convertFromSynth(zeroAddr, synthBalance_);
    uint256 balanceInMet_ = convertEthToMet(balanceInBase_);
    require(debt_.mul(2) < balanceInMet_);
    uint256 debtInEth = convertEthToMet(debt_);
    uint256 ethDebtInSynth = convertToSynth(zeroAddr, debtInEth);
    uint256 ethFee_ = ethDebtInSynth.div(20);
    transferUnderlyingToMkt(zeroAddr, _borrower, debtInEth);
    synthBurn(zeroAddr, _borrower, ethDebtInSynth.sub(ethFee_));
    synthTransfer(zeroAddr, _borrower, msg.sender, ethFee_);
  }

}