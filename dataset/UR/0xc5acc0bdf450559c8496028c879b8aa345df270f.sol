 

pragma solidity 0.4.24;


 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor(address _owner) public {
        owner = _owner;
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



 
contract Validator {
    address public validator;

    event NewValidatorSet(address indexed previousOwner, address indexed newValidator);

     
    constructor() public {
        validator = msg.sender;
    }

     
    modifier onlyValidator() {
        require(msg.sender == validator);
        _;
    }

     
    function setNewValidator(address newValidator) public onlyValidator {
        require(newValidator != address(0));
        emit NewValidatorSet(validator, newValidator);
        validator = newValidator;
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



contract TokenInterface {
    function mint(address _to, uint256 _amount) public returns (bool);
    function finishMinting() public returns (bool);
    function transferOwnership(address newOwner) public;
}


 
contract Crowdsale {
    using SafeMath for uint256;

     
    address public token;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    uint256 public hardCap;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor(uint256 _startTime, uint256 _endTime, uint256 _hardCap, uint256 _rate, address _wallet, address _token) public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        startTime = _startTime;
        endTime = _endTime;
        hardCap = _hardCap;
        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        TokenInterface(token).mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

     
    function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.mul(rate);
    }

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal view returns (bool) {
        require(weiRaised.add(msg.value) <= hardCap);
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

}



 
contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();
 
    constructor(address _owner) public Ownable(_owner) {}

     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

     
    function finalization() internal {}
}







contract Whitelist is Ownable {
    mapping(address => bool) internal investorMap;

     
    event Approved(address indexed investor);

     
    event Disapproved(address indexed investor);

    constructor(address _owner) 
        public 
        Ownable(_owner) 
    {
        
    }

     
    function isInvestorApproved(address _investor) external view returns (bool) {
        require(_investor != address(0));
        return investorMap[_investor];
    }

     
    function approveInvestor(address toApprove) external onlyOwner {
        investorMap[toApprove] = true;
        emit Approved(toApprove);
    }

     
    function approveInvestorsInBulk(address[] toApprove) external onlyOwner {
        for (uint i = 0; i < toApprove.length; i++) {
            investorMap[toApprove[i]] = true;
            emit Approved(toApprove[i]);
        }
    }

     
    function disapproveInvestor(address toDisapprove) external onlyOwner {
        delete investorMap[toDisapprove];
        emit Disapproved(toDisapprove);
    }

     
    function disapproveInvestorsInBulk(address[] toDisapprove) external onlyOwner {
        for (uint i = 0; i < toDisapprove.length; i++) {
            delete investorMap[toDisapprove[i]];
            emit Disapproved(toDisapprove[i]);
        }
    }
}



 
contract CompliantCrowdsaleHardcap is Validator, FinalizableCrowdsale {
    Whitelist public whiteListingContract;

    struct MintStruct {
        address to;
        uint256 tokens;
        uint256 weiAmount;
    }

    mapping (uint => MintStruct) public pendingMints;
    uint256 public currentMintNonce;
    mapping (address => uint) public rejectedMintBalance;

    modifier checkIsInvestorApproved(address _account) {
        require(whiteListingContract.isInvestorApproved(_account));
        _;
    }

    modifier checkIsAddressValid(address _account) {
        require(_account != address(0));
        _;
    }

     
    event MintRejected(
        address indexed to,
        uint256 value,
        uint256 amount,
        uint256 indexed nonce,
        uint256 reason
    );

     
    event ContributionRegistered(
        address beneficiary,
        uint256 tokens,
        uint256 weiAmount,
        uint256 nonce
    );

     
    event RateUpdated(uint256 rate);

     
    event WhiteListingContractSet(address indexed _whiteListingContract);

     
    event Claimed(address indexed account, uint256 amount);

     
    constructor(
        address whitelistAddress,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _hardcap,
        uint256 _rate,
        address _wallet,
        address _token,
        address _owner
    )
        public
        FinalizableCrowdsale(_owner)
        Crowdsale(_startTime, _endTime, _hardcap, _rate, _wallet, _token)
    {
        setWhitelistContract(whitelistAddress);
    }

     
    function setWhitelistContract(address whitelistAddress)
        public 
        onlyValidator 
        checkIsAddressValid(whitelistAddress)
    {
        whiteListingContract = Whitelist(whitelistAddress);
        emit WhiteListingContractSet(whiteListingContract);
    }

     
    function buyTokens(address beneficiary)
        public 
        payable
        checkIsInvestorApproved(beneficiary)
    {
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);

        pendingMints[currentMintNonce] = MintStruct(beneficiary, tokens, weiAmount);
        emit ContributionRegistered(beneficiary, tokens, weiAmount, currentMintNonce);

        currentMintNonce++;
    }

      
    function updateRate(uint256 _rate) public onlyOwner { 
        require(_rate > 0);
        rate = _rate;
        emit RateUpdated(rate);
    }

     
    function approveMint(uint256 nonce)
        external 
        onlyValidator
    {
        require(_approveMint(nonce));
    }

     
    function rejectMint(uint256 nonce, uint256 reason)
        external 
        onlyValidator
    {
        _rejectMint(nonce, reason);
    }

     
    function bulkApproveMints(uint256[] nonces)
        external 
        onlyValidator
    {
        for (uint i = 0; i < nonces.length; i++) {
            require(_approveMint(nonces[i]));
        }        
    }
    
     
    function bulkRejectMints(uint256[] nonces, uint256[] reasons)
        external 
        onlyValidator
    {
        require(nonces.length == reasons.length);
        for (uint i = 0; i < nonces.length; i++) {
            _rejectMint(nonces[i], reasons[i]);
        }
    }

     
    function _approveMint(uint256 nonce)
        private
        checkIsInvestorApproved(pendingMints[nonce].to)
        returns (bool)
    {
         
        weiRaised = weiRaised.add(pendingMints[nonce].weiAmount);

         
        TokenInterface(token).mint(pendingMints[nonce].to, pendingMints[nonce].tokens);
        
        emit TokenPurchase(
            msg.sender,
            pendingMints[nonce].to,
            pendingMints[nonce].weiAmount,
            pendingMints[nonce].tokens
        );

        forwardFunds(pendingMints[nonce].weiAmount);
        delete pendingMints[nonce];

        return true;
    }

     
    function _rejectMint(uint256 nonce, uint256 reason)
        private
        checkIsAddressValid(pendingMints[nonce].to)
    {
        rejectedMintBalance[pendingMints[nonce].to] = rejectedMintBalance[pendingMints[nonce].to].add(pendingMints[nonce].weiAmount);
        
        emit MintRejected(
            pendingMints[nonce].to,
            pendingMints[nonce].tokens,
            pendingMints[nonce].weiAmount,
            nonce,
            reason
        );
        
        delete pendingMints[nonce];
    }

     
    function claim() external {
        require(rejectedMintBalance[msg.sender] > 0);
        uint256 value = rejectedMintBalance[msg.sender];
        rejectedMintBalance[msg.sender] = 0;

        msg.sender.transfer(value);

        emit Claimed(msg.sender, value);
    }

    function finalization() internal {
        TokenInterface(token).finishMinting();
        transferTokenOwnership(owner);
        super.finalization();
    }

     
    function setTokenContract(address newToken)
        external 
        onlyOwner
        checkIsAddressValid(newToken)
    {
        token = newToken;
    }

     
    function transferTokenOwnership(address newOwner)
        public 
        onlyOwner
        checkIsAddressValid(newOwner)
    {
        TokenInterface(token).transferOwnership(newOwner);
    }

    function forwardFunds(uint256 amount) internal {
        wallet.transfer(amount);
    }
}