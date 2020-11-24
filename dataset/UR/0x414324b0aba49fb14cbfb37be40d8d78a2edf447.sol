 

 

 
pragma solidity 0.5.10;

 

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

 

 
pragma solidity 0.5.10;

 

interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
pragma solidity 0.5.10;



 

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

 

 
pragma solidity 0.5.10;




 

contract ERC20Claimable is ERC20 {

    using SafeMath for uint256;
    using SafeMath for uint32;

     
    struct Claim {
        address claimant;  
        uint256 collateral;  
        uint32 timestamp;   
        address currencyUsed;  
    }

     
    struct PreClaim {
        bytes32 msghash;  
        uint256 timestamp;   
    }

    uint256 public claimPeriod = 180 days;  
    uint256 public preClaimPeriod = 1 days;  
    uint256 public preClaimPeriodEnd = 2 days;  

    mapping(address => Claim) public claims;  
    mapping(address => PreClaim) public preClaims;  
    mapping(address => bool) public claimingDisabled;  

     
    address public customCollateralAddress;
    uint256 public customCollateralRate;

     
    function getCollateralRate(address collateralType) public view returns (uint256) {
        if (collateralType == address(this)) {
            return 1;
        } else if (collateralType == customCollateralAddress) {
            return customCollateralRate;
        } else {
            return 0;
        }
    }

     
    function _setCustomClaimCollateral(address collateral, uint256 rate) internal {
        customCollateralAddress = collateral;
        if (customCollateralAddress == address(0)) {
            customCollateralRate = 0;  
        } else {
            require(rate > 0, "Collateral rate can't be zero");
            customCollateralRate = rate;
        }
        emit CustomClaimCollateralChanged(collateral, rate);
    }

    function getClaimDeleter() public returns (address);

     
    function _setClaimPeriod(uint256 claimPeriodInDays) internal {
        require(claimPeriodInDays > 90, "Claim period must be at least 90 days");  
        uint256 claimPeriodInSeconds = claimPeriodInDays.mul(1 days);
        claimPeriod = claimPeriodInSeconds;
        emit ClaimPeriodChanged(claimPeriod);
    }

    function setClaimable(bool enabled) public {
        claimingDisabled[msg.sender] = !enabled;
    }

     
    function isClaimsEnabled(address target) public view returns (bool) {
        return !claimingDisabled[target];
    }

    event ClaimMade(address indexed lostAddress, address indexed claimant, uint256 balance);
    event ClaimPrepared(address indexed claimer);
    event ClaimCleared(address indexed lostAddress, uint256 collateral);
    event ClaimDeleted(address indexed lostAddress, address indexed claimant, uint256 collateral);
    event ClaimResolved(address indexed lostAddress, address indexed claimant, uint256 collateral);
    event ClaimPeriodChanged(uint256 newClaimPeriodInDays);
    event CustomClaimCollateralChanged(address newCustomCollateralAddress, uint256 newCustomCollareralRate);

   
    function prepareClaim(bytes32 hashedpackage) public {
        preClaims[msg.sender] = PreClaim({
            msghash: hashedpackage,
            timestamp: block.timestamp
        });
        emit ClaimPrepared(msg.sender);
    }

    function validateClaim(address lostAddress, bytes32 nonce) private view {
        PreClaim memory preClaim = preClaims[msg.sender];
        require(preClaim.msghash != 0, "Message hash can't be zero");
        require(preClaim.timestamp.add(preClaimPeriod) <= block.timestamp, "Preclaim period violated. Claimed too early");
        require(preClaim.timestamp.add(preClaimPeriodEnd) >= block.timestamp, "Preclaim period end. Claimed too late");
        require(preClaim.msghash == keccak256(abi.encodePacked(nonce, msg.sender, lostAddress)),"Package could not be validated");
    }

    function declareLost(address collateralType, address lostAddress, bytes32 nonce) public {
        require(lostAddress != address(0), "Can't claim zero address");
        require(isClaimsEnabled(lostAddress), "Claims disabled for this address");
        uint256 collateralRate = getCollateralRate(collateralType);
        require(collateralRate > 0, "Unsupported collateral type");
        address claimant = msg.sender;
        uint256 balance = balanceOf(lostAddress);
        uint256 collateral = balance.mul(collateralRate);
        IERC20 currency = IERC20(collateralType);
        require(balance > 0, "Claimed address holds no shares");
        require(currency.allowance(claimant, address(this)) >= collateral, "Currency allowance insufficient");
        require(currency.balanceOf(claimant) >= collateral, "Currency balance insufficient");
        require(claims[lostAddress].collateral == 0, "Address already claimed");
        validateClaim(lostAddress, nonce);
        require(currency.transferFrom(claimant, address(this), collateral), "Collateral transfer failed");

        claims[lostAddress] = Claim({
            claimant: claimant,
            collateral: collateral,
            timestamp: uint32(block.timestamp),  
            currencyUsed: collateralType
        });

        delete preClaims[claimant];
        emit ClaimMade(lostAddress, claimant, balance);
    }

    function getClaimant(address lostAddress) public view returns (address) {
        return claims[lostAddress].claimant;
    }

    function getCollateral(address lostAddress) public view returns (uint256) {
        return claims[lostAddress].collateral;
    }

    function getCollateralType(address lostAddress) public view returns (address) {
        return claims[lostAddress].currencyUsed;
    }

    function getTimeStamp(address lostAddress) public view returns (uint256) {
        return claims[lostAddress].timestamp;
    }

    function getPreClaimTimeStamp(address claimerAddress) public view returns (uint256) {
        return preClaims[claimerAddress].timestamp;
    }

    function getMsgHash(address claimerAddress) public view returns (bytes32) {
        return preClaims[claimerAddress].msghash;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(super.transfer(recipient, amount), "Transfer failed");
        clearClaim();
        return true;
    }

     
    function clearClaim() public {
        if (claims[msg.sender].collateral != 0) {
            uint256 collateral = claims[msg.sender].collateral;
            IERC20 currency = IERC20(claims[msg.sender].currencyUsed);
            delete claims[msg.sender];
            require(currency.transfer(msg.sender, collateral), "Collateral transfer failed");
            emit ClaimCleared(msg.sender, collateral);
        }
    }

    
    function resolveClaim(address lostAddress) public {
        Claim memory claim = claims[lostAddress];
        uint256 collateral = claim.collateral;
        IERC20 currency = IERC20(claim.currencyUsed);
        require(collateral != 0, "No claim found");
        require(claim.claimant == msg.sender, "Only claimant can resolve claim");
        require(claim.timestamp.add(uint32(claimPeriod)) <= block.timestamp, "Claim period not over yet");
        address claimant = claim.claimant;
        delete claims[lostAddress];
        require(currency.transfer(claimant, collateral), "Collateral transfer failed");
        _transfer(lostAddress, claimant, balanceOf(lostAddress));
        emit ClaimResolved(lostAddress, claimant, collateral);
    }

     
    function deleteClaim(address lostAddress) public {
        require(msg.sender == getClaimDeleter(), "You cannot delete claims");
        Claim memory claim = claims[lostAddress];
        IERC20 currency = IERC20(claim.currencyUsed);
        require(claim.collateral != 0, "No claim found");
        delete claims[lostAddress];
        require(currency.transfer(claim.claimant, claim.collateral), "Collateral transfer failed");
        emit ClaimDeleted(lostAddress, claim.claimant, claim.collateral);
    }

}

 

 
pragma solidity 0.5.10;



 

contract Acquisition {

    using SafeMath for uint256;

    uint256 public constant VOTING_PERIOD = 60 days;     
    uint256 public constant VALIDITY_PERIOD = 90 days;   

    uint256 public quorum;                               

    address private parent;                              
    address payable public buyer;                        
    uint256 public price;                                
    uint256 public timestamp;                            

    uint256 public noVotes;                              
    uint256 public yesVotes;                             

    enum Vote { NONE, YES, NO }                          
    mapping (address => Vote) private votes;             

    event VotesChanged(uint256 newYesVotes, uint256 newNoVotes);

    constructor (address payable buyer_, uint256 price_, uint256 quorum_) public {
        require(price_ > 0, "Price cannot be zero");
        parent = msg.sender;
        buyer = buyer_;
        price = price_;
        quorum = quorum_;
        timestamp = block.timestamp;
    }

    function isWellFunded(address currency_, uint256 sharesToAcquire) public view returns (bool) {
        IERC20 currency = IERC20(currency_);
        uint256 buyerXCHFBalance = currency.balanceOf(buyer);
        uint256 buyerXCHFAllowance = currency.allowance(buyer, parent);
        uint256 xchfNeeded = sharesToAcquire.mul(price);
        return xchfNeeded <= buyerXCHFBalance && xchfNeeded <= buyerXCHFAllowance;
    }

    function isQuorumReached() public view returns (bool) {
        if (isVotingOpen()) {
             
            return yesVotes.mul(10000).div(IERC20(parent).totalSupply()) >= quorum;
        } else {
             
            return yesVotes.mul(10000).div(yesVotes.add(noVotes)) >= quorum;
        }
    }

    function quorumHasFailed() public view returns (bool) {
        if (isVotingOpen()) {
             
            return (IERC20(parent).totalSupply().sub(noVotes)).mul(10000).div(IERC20(parent).totalSupply()) < quorum;
        } else {
             
            return yesVotes.mul(10000).div(yesVotes.add(noVotes)) < quorum;
        }
    }

    function adjustVotes(address from, address to, uint256 value) public parentOnly() {
        if (isVotingOpen()) {
            Vote fromVoting = votes[from];
            Vote toVoting = votes[to];
            update(fromVoting, toVoting, value);
        }
    }

    function update(Vote previousVote, Vote newVote, uint256 votes_) internal {
        if (previousVote != newVote) {
            if (previousVote == Vote.NO) {
                noVotes = noVotes.sub(votes_);
            } else if (previousVote == Vote.YES) {
                yesVotes = yesVotes.sub(votes_);
            }
            if (newVote == Vote.NO) {
                noVotes = noVotes.add(votes_);
            } else if (newVote == Vote.YES) {
                yesVotes = yesVotes.add(votes_);
            }
            emit VotesChanged(yesVotes, noVotes);
        }
    }

    function isVotingOpen() public view returns (bool) {
        uint256 age = block.timestamp.sub(timestamp);
        return age <= VOTING_PERIOD;
    }

    function hasExpired() public view returns (bool) {
        uint256 age = block.timestamp.sub(timestamp);
        return age > VALIDITY_PERIOD;
    }

    modifier votingOpen() {
        require(isVotingOpen(), "The vote has ended.");
        _;
    }

    function voteYes(address sender, uint256 votes_) public parentOnly() votingOpen() {
        vote(Vote.YES, votes_, sender);
    }

    function voteNo(address sender, uint256 votes_) public parentOnly() votingOpen() {
        vote(Vote.NO, votes_, sender);
    }

    function vote(Vote yesOrNo, uint256 votes_, address voter) internal {
        Vote previousVote = votes[voter];
        Vote newVote = yesOrNo;
        votes[voter] = newVote;
        update(previousVote, newVote, votes_);
    }

    function hasVotedYes(address voter) public view returns (bool) {
        return votes[voter] == Vote.YES;
    }

    function hasVotedNo(address voter) public view returns (bool) {
        return votes[voter] == Vote.NO;
    }

    function kill() public parentOnly() {
         
        selfdestruct(buyer);
    }

    modifier parentOnly () {
        require(msg.sender == parent, "Can only be called by parent contract");
        _;
    }
}

 

 
pragma solidity 0.5.10;

contract IMigratable {
    function migrationToContract() public returns (address);
}

 

 
pragma solidity 0.5.10;






 

contract ERC20Draggable is ERC20 {

    using SafeMath for uint256;

    IERC20 private wrapped;                         

     
    uint256 public unwrapConversionFactor = 1;

     
    Acquisition public offer;

    IERC20 private currency;

    address public offerFeeRecipient;               

    uint256 public offerFee;              
    uint256 public migrationQuorum;       
    uint256 public acquisitionQuorum;

    uint256 constant MIN_OFFER_INCREMENT = 10500;   
    uint256 constant MIN_HOLDING = 500;             
    uint256 constant MIN_DRAG_ALONG_QUOTA = 3000;   

    bool public active = true;                      

    event OfferCreated(address indexed buyer, uint256 pricePerShare);
    event OfferEnded(address indexed buyer, address sender, bool success, string message);
    event MigrationSucceeded(address newContractAddress);

     
    constructor(
        address wrappedToken,
        uint256 migrationQuorumInBIPS_,
        uint256 acquisitionQuorum_,
        address currencyAddress,
        address offerFeeRecipient_,
        uint offerFee_
    ) public {
        wrapped = IERC20(wrappedToken);
        offerFeeRecipient = offerFeeRecipient_;
        offerFee = offerFee_;
        migrationQuorum = migrationQuorumInBIPS_;
        acquisitionQuorum = acquisitionQuorum_;
        currency = IERC20(currencyAddress);
        IShares(wrappedToken).totalShares();
    }

    function getWrappedContract() public view returns (address) {
        return address(wrapped);
    }

    function getCurrencyContract() public view returns (address) {
        return address(currency);
    }

    function updateCurrency(address newCurrency) public noOfferPending () {
        require(active, "Contract is not active");
        require(IMigratable(getCurrencyContract()).migrationToContract() == newCurrency, "Invalid currency update");
        currency = IERC20(newCurrency);
    }

     
    function wrap(address shareholder, uint256 amount) public noOfferPending() {
        require(active, "Contract not active any more.");
        require(wrapped.balanceOf(msg.sender) >= amount, "Share balance not sufficient");
        require(wrapped.allowance(msg.sender, address(this)) >= amount, "Share allowance not sufficient");
        require(wrapped.transferFrom(msg.sender, address(this), amount), "Share transfer failed");
        _mint(shareholder, amount);
    }

     
    function unwrap(uint256 amount) public {
        require(!active, "As long as the contract is active, you are bound to it");
        _burn(msg.sender, amount);
        require(wrapped.transfer(msg.sender, amount.mul(unwrapConversionFactor)), "Share transfer failed");
    }

     
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
        IBurnable(getWrappedContract()).burn(amount.mul(unwrapConversionFactor));
    }

   
    function initiateAcquisition(uint256 pricePerShare) public {
        require(active, "An accepted offer exists");
        uint256 totalEquity = IShares(getWrappedContract()).totalShares();
        address buyer = msg.sender;

        require(totalSupply() >= totalEquity.mul(MIN_DRAG_ALONG_QUOTA).div(10000), "This contract does not represent enough equity");
        require(balanceOf(buyer) >= totalEquity.mul(MIN_HOLDING).div(10000), "You need to hold at least 5% of the firm to make an offer");

        require(currency.transferFrom(buyer, offerFeeRecipient, offerFee), "Currency transfer failed");

        Acquisition newOffer = new Acquisition(msg.sender, pricePerShare, acquisitionQuorum);
        require(newOffer.isWellFunded(getCurrencyContract(), totalSupply() - balanceOf(buyer)), "Insufficient funding");
        if (offerExists()) {
            require(pricePerShare >= offer.price().mul(MIN_OFFER_INCREMENT).div(10000), "New offers must be at least 5% higher than the pending offer");
            killAcquisition("Offer was replaced by a higher bid");
        }
        offer = newOffer;

        emit OfferCreated(buyer, pricePerShare);
    }

    function voteYes() public offerPending() {
        address voter = msg.sender;
        offer.voteYes(voter, balanceOf(voter));
    }

    function voteNo() public offerPending() {
        address voter = msg.sender;
        offer.voteNo(voter, balanceOf(voter));
    }

    function cancelAcquisition() public offerPending() {
        require(msg.sender == offer.buyer(), "You are not authorized to cancel this acquisition offer");
        killAcquisition("Cancelled by buyer");
    }

    function contestAcquisition() public offerPending() {
        if (offer.hasExpired()) {
            killAcquisition("Offer expired");
        } else if (offer.quorumHasFailed()) {
            killAcquisition("Not enough support");
        } else if (
            !offer.isWellFunded(
                getCurrencyContract(),
                totalSupply().sub(balanceOf(offer.buyer()))
                )
            ) {
            killAcquisition("Offer was not sufficiently funded");
        } else {
            revert("Acquisition contest unsuccessful");
        }
    }

    function killAcquisition(string memory message) internal {
        address buyer = offer.buyer();
        offer.kill();
        offer = Acquisition(address(0));
        emit OfferEnded(
            buyer,
            msg.sender,
            false,
            message
        );
    }

    function completeAcquisition() public offerPending() {
        address buyer = offer.buyer();
        require(msg.sender == buyer, "You are not authorized to complete this acquisition offer");
        require(offer.isQuorumReached(), "Insufficient number of yes votes");
        require(
            offer.isWellFunded(
            getCurrencyContract(),
            totalSupply().sub(balanceOf(buyer))),
            "Offer insufficiently funded"
            );
        invertHoldings(buyer, currency, offer.price());
        emit OfferEnded(
            buyer,
            msg.sender,
            true,
            "Completed successfully"
        );
    }

    function wasAcquired() public view returns (bool) {
        return offerExists() ? !active : false;
    }

    function invertHoldings(address newOwner, IERC20 newBacking, uint256 conversionRate) internal {
        uint256 buyerBalance = balanceOf(newOwner);
        uint256 initialSupply = totalSupply();
        active = false;
        unwrap(buyerBalance);
        uint256 remaining = initialSupply.sub(buyerBalance);
        require(wrapped.transfer(newOwner, remaining), "Wrapped token transfer failed");
        require(newBacking.transferFrom(newOwner, address(this), conversionRate.mul(remaining)), "Backing transfer failed");

        wrapped = newBacking;
        unwrapConversionFactor = conversionRate;
    }

    function migrate() public {
        require(active, "Contract is not active");
        address successor = msg.sender;
        require(balanceOf(successor) >= totalSupply().mul(migrationQuorum).div(10000), "Quorum not reached");

        if (offerExists()) {
            if (!offer.quorumHasFailed()) {
                voteNo();  
                require(offer.quorumHasFailed(), "Quorum has not failed");
            }
            contestAcquisition();
            assert (!offerExists());
        }

        invertHoldings(successor, IERC20(successor), 1);
        emit MigrationSucceeded(successor);
    }

    function _mint(address account, uint256 amount) internal {
        super._mint(account, amount);
        if (offerExists() && active) {
             
            offer.adjustVotes(address(0), account, amount);
        }
    }

    function _transfer(address from, address to, uint256 value) internal {
        super._transfer(from, to, value);
        if (offerExists() && active) {
            offer.adjustVotes(from, to, value);
        }
    }

    function _burn(address account, uint256 amount) internal {
        require(balanceOf(msg.sender) >= amount, "Balance insufficient");
        super._burn(account, amount);
        if (offerExists() && active) {
            offer.adjustVotes(account, address(0), amount);
        }
    }

    function getPendingOffer() public view returns (address) {
        return address(offer);
    }

    function offerExists() public view returns (bool) {
        return getPendingOffer() != address(0);
    }

    modifier offerPending() {
        require(offerExists() && active, "There is no pending offer");
        _;
    }

    modifier noOfferPending() {
        require(!offerExists(), "There is a pending offer");
        _;
    }

}

contract IShares {
    function totalShares() public returns (uint256);
}

contract IBurnable {
    function burn(uint256) public;
}

 

 
pragma solidity 0.5.10;



 

contract DraggableServiceHunterShares is ERC20Claimable, ERC20Draggable {

    string public constant symbol = "DSHS";
    string public constant name = "Draggable ServiceHunter AG Shares";
    string public constant terms = "quitt.ch/investoren";

    uint8 public constant decimals = 0;                   

    uint256 public constant UPDATE_QUORUM = 7500;         
    uint256 public constant ACQUISITION_QUORUM = 7500;    
    uint256 public constant OFFER_FEE = 5000 * 10 ** 18;  

     
    constructor(address wrappedToken, address xchfAddress, address offerFeeRecipient)
        ERC20Draggable(wrappedToken, UPDATE_QUORUM, ACQUISITION_QUORUM, xchfAddress, offerFeeRecipient, OFFER_FEE) public {
        IClaimable(wrappedToken).setClaimable(false);
    }

    function getClaimDeleter() public returns (address) {
        return IClaimable(getWrappedContract()).getClaimDeleter();
    }

    function getCollateralRate(address collateralType) public view returns (uint256) {
        uint256 rate = super.getCollateralRate(collateralType);
        if (rate > 0) {
            return rate;
        } else if (collateralType == getWrappedContract()) {
            return unwrapConversionFactor;
        } else {
             
             
            return IClaimable(getWrappedContract()).getCollateralRate(collateralType).mul(unwrapConversionFactor);
        }
    }

}

contract IClaimable {
    function setClaimable(bool) public;
    function getCollateralRate(address) public view returns (uint256);
    function getClaimDeleter() public returns (address);
}