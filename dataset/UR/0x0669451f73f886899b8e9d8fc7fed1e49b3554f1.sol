 

pragma solidity 0.4.24;

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
interface IDisputer {
   
  function dispute(address feeReceiver) external;

   
  function approveManagerToSpendDisputeTokens() external;

  function getOwner() external view returns(address);

  function hasDisputed() external view returns(bool);

  function feeReceiver() external view returns(address);

  function getREP() external view returns(IERC20);

  function getDisputeTokenAddress() external view returns(IERC20);
}

 

interface FeeWindow {
  function getStartTime() external view returns(uint256);
  function isOver() external view returns(bool);
}

 

interface Universe {
  function getDisputeRoundDurationInSeconds() external view returns(uint256);

  function isForking() external view returns(bool);

  function isContainerForMarket(address _shadyMarket) external view returns(
    bool
  );
}

 

 
contract ReportingParticipant is IERC20 {
  function redeem(address _redeemer) external returns(bool);
  function getStake() external view returns(uint256);
  function getPayoutDistributionHash() external view returns(bytes32);
  function getFeeWindow() external view returns(FeeWindow);
}

 

interface Market {
  function contribute(
    uint256[] _payoutNumerators,
    bool _invalid,
    uint256 _amount
  ) external returns(bool);

  function getReputationToken() external view returns(IERC20);

  function getUniverse() external view returns(Universe);

  function derivePayoutDistributionHash(
    uint256[] _payoutNumerators,
    bool _invalid
  ) external view returns(bytes32);

  function getCrowdsourcer(
    bytes32 _payoutDistributionHash
  ) external view returns(ReportingParticipant);

  function getNumParticipants() external view returns(uint256);

  function getReportingParticipant(uint256 _index) external view returns(
    ReportingParticipant
  );

  function isFinalized() external view returns(bool);

  function getFeeWindow() external view returns(FeeWindow);

  function getWinningReportingParticipant() external view returns(
    ReportingParticipant
  );

  function isContainerForReportingParticipant(
    ReportingParticipant _shadyReportingParticipant
  ) external view returns(bool);
}

 

library DisputerParams {
  struct Params {
    Market market;
    uint256 feeWindowId;
    uint256[] payoutNumerators;
    bool invalid;
  }
}

 

 
contract BaseDisputer is IDisputer {
  address public m_owner;
  address public m_feeReceiver = 0;
  DisputerParams.Params public m_params;
  IERC20 public m_rep;
  IERC20 public m_disputeToken;

   
  function dispute(address feeReceiver) external {
    require(m_feeReceiver == 0, "Can only dispute once");
    preDisputeCheck();
    require(feeReceiver != 0, "Must have valid fee receiver");
    m_feeReceiver = feeReceiver;

    IERC20 rep = getREP();
    uint256 initialREPBalance = rep.balanceOf(this);
    IERC20 disputeToken = disputeImpl();
    uint256 finalREPBalance = rep.balanceOf(this);
    m_disputeToken = disputeToken;
    uint256 finalDisputeTokenBalance = disputeToken.balanceOf(this);
    assert(finalREPBalance + finalDisputeTokenBalance >= initialREPBalance);
  }

   
  function approveManagerToSpendDisputeTokens() external {
    IERC20 disputeTokenAddress = getDisputeTokenAddress();
    require(disputeTokenAddress.approve(m_owner, 2 ** 256 - 1));
  }

  function getOwner() external view returns(address) {
    return m_owner;
  }

  function hasDisputed() external view returns(bool) {
    return m_feeReceiver != 0;
  }

  function feeReceiver() external view returns(address) {
    require(m_feeReceiver != 0);
    return m_feeReceiver;
  }

  function getREP() public view returns(IERC20) {
    return m_rep;
  }

  function getDisputeTokenAddress() public view returns(IERC20) {
    require(m_disputeToken != IERC20(address(this)));
    return m_disputeToken;
  }

  function getREPImpl() internal view returns(IERC20);
  function disputeImpl() internal returns(IERC20 disputeToken);
  function preDisputeCheck() internal;

   
   
  function baseInit(
    address owner,
    Market market,
    uint256 feeWindowId,
    uint256[] payoutNumerators,
    bool invalid
  ) internal {
    m_owner = owner;
    m_params = DisputerParams.Params(
      market,
      feeWindowId,
      payoutNumerators,
      invalid
    );
     
     
    m_rep = getREPImpl();
    assert(m_rep.approve(m_owner, 2 ** 256 - 1));

    if (address(market) != 0) {
       
       
       
       
      assert(m_rep.approve(market, 2 ** 256 - 1));
    }

     
     
    m_disputeToken = IERC20(address(this));
  }
}

 

 
contract Disputer is BaseDisputer {
  uint256 public m_windowStart;
  uint256 public m_windowEnd;
  bytes32 public m_payoutDistributionHash;
  uint256 public m_roundNumber;

   
  uint256 public m_cumulativeDisputeStake;
  uint256 public m_cumulativeDisputeStakeInOurOutcome;
  uint256 public m_cumulativeRoundsProcessed;

  constructor(
    address owner,
    Market market,
    uint256 feeWindowId,
    uint256[] payoutNumerators,
    bool invalid
  ) public {
    if (address(market) == 0) {
       
       
      return;
    }

    baseInit(owner, market, feeWindowId, payoutNumerators, invalid);

    Universe universe = market.getUniverse();
    uint256 disputeRoundDuration = universe.getDisputeRoundDurationInSeconds();
    m_windowStart = feeWindowId * disputeRoundDuration;
    m_windowEnd = (feeWindowId + 1) * disputeRoundDuration;

    m_payoutDistributionHash = market.derivePayoutDistributionHash(
      payoutNumerators,
      invalid
    );

    m_roundNumber = inferRoundNumber();

    processCumulativeRounds();
  }

  function inferRoundNumber() public view returns(uint256) {
    Market market = m_params.market;
    Universe universe = market.getUniverse();
    require(!universe.isForking());

    FeeWindow feeWindow = m_params.market.getFeeWindow();
    require(
      address(feeWindow) != 0,
      "magic of choosing round number by timestamp only works during disputing"
    );
     
    uint256 nextParticipant = market.getNumParticipants();
    uint256 disputeRoundDuration = universe.getDisputeRoundDurationInSeconds();
    uint256 nextParticipantFeeWindowStart = feeWindow.getStartTime();
    require(m_windowStart >= nextParticipantFeeWindowStart);
    uint256 feeWindowDifferenceSeconds = m_windowStart - nextParticipantFeeWindowStart;
    require(feeWindowDifferenceSeconds % disputeRoundDuration == 0);
    uint256 feeWindowDifferenceRounds = feeWindowDifferenceSeconds / disputeRoundDuration;
    return nextParticipant + feeWindowDifferenceRounds;
  }

   
  function processCumulativeRounds() public {
    Market market = m_params.market;
    require(!market.isFinalized());
    uint256 numParticipants = market.getNumParticipants();

    while (m_cumulativeRoundsProcessed < numParticipants && m_cumulativeRoundsProcessed < m_roundNumber) {
      ReportingParticipant participant = market.getReportingParticipant(
        m_cumulativeRoundsProcessed
      );
      uint256 stake = participant.getStake();
      m_cumulativeDisputeStake += stake;
      if (participant.getPayoutDistributionHash() == m_payoutDistributionHash) {
        m_cumulativeDisputeStakeInOurOutcome += stake;
      }
      ++m_cumulativeRoundsProcessed;
    }
  }

  function shouldProcessCumulativeRounds() public view returns(bool) {
    Market market = m_params.market;
    require(!market.isFinalized());
    uint256 numParticipants = market.getNumParticipants();
    return m_cumulativeRoundsProcessed < m_roundNumber && m_cumulativeRoundsProcessed < numParticipants;
  }

  function preDisputeCheck() internal {
     
     
    require(block.timestamp > m_windowStart && block.timestamp < m_windowEnd);
  }

   
  function disputeImpl() internal returns(IERC20) {
    if (m_cumulativeRoundsProcessed < m_roundNumber) {
       
       
      processCumulativeRounds();
    }

    Market market = m_params.market;

     
    uint256 roundSizeMinusOne = 2 * m_cumulativeDisputeStake - 3 * m_cumulativeDisputeStakeInOurOutcome - 1;

    ReportingParticipant crowdsourcerBefore = market.getCrowdsourcer(
      m_payoutDistributionHash
    );
    uint256 alreadyContributed = address(
      crowdsourcerBefore
    ) == 0 ? 0 : crowdsourcerBefore.getStake();

    require(alreadyContributed < roundSizeMinusOne, "We are too late");

    uint256 optimalContributionSize = roundSizeMinusOne - alreadyContributed;
    uint256 ourBalance = getREP().balanceOf(this);

    require(
      market.contribute(
        m_params.payoutNumerators,
        m_params.invalid,
        ourBalance > optimalContributionSize ? optimalContributionSize : ourBalance
      )
    );

    if (market.getNumParticipants() == m_roundNumber) {
       
      return market.getCrowdsourcer(m_payoutDistributionHash);
    } else {
       
      ReportingParticipant participant = market.getWinningReportingParticipant(

      );
      require(
        participant.getPayoutDistributionHash() == m_payoutDistributionHash,
        "Wrong winning participant?"
      );
      return IERC20(address(participant));
    }
  }

  function getREPImpl() internal view returns(IERC20) {
    return m_params.market.getReputationToken();
  }
}