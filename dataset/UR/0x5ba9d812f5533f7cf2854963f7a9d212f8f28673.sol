 

pragma solidity 0.5.7;
 
 
 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

contract Basket {
    address[] public tokens;
    mapping(address => uint256) public weights;  
    mapping(address => bool) public has;
     
    
     
    
     
     

     
     
    constructor(Basket trustedPrev, address[] memory _tokens, uint256[] memory _weights) public {
        require(_tokens.length == _weights.length, "Basket: unequal array lengths");

         
        tokens = new address[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(!has[_tokens[i]], "duplicate token entries");
            weights[_tokens[i]] = _weights[i];
            has[_tokens[i]] = true;
            tokens[i] = _tokens[i];
        }

         
        if (trustedPrev != Basket(0)) {
            for (uint256 i = 0; i < trustedPrev.size(); i++) {
                address tok = trustedPrev.tokens(i);
                if (!has[tok]) {
                    weights[tok] = trustedPrev.weights(tok);
                    has[tok] = true;
                    tokens.push(tok);
                }
            }
        }
        require(tokens.length <= 10, "Basket: bad length");
    }

    function getTokens() external view returns(address[] memory) {
        return tokens;
    }

    function size() external view returns(uint256) {
        return tokens.length;
    }
}

library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IRSV {
     
    function transfer(address, uint256) external returns(bool);
    function approve(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function totalSupply() external view returns(uint256);
    function balanceOf(address) external view returns(uint256);
    function allowance(address, address) external view returns(uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function decimals() external view returns(uint8);
    function mint(address, uint256) external;
    function burnFrom(address, uint256) external;
}

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

contract Ownable is Context {
    address private _owner;
    address private _nominatedOwner;

    event NewOwnerNominated(address indexed previousOwner, address indexed nominee);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    function nominatedOwner() external view returns (address) {
        return _nominatedOwner;
    }

     
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(_msgSender() == _owner, "caller is not owner");
    }

     
    function nominateNewOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner is 0 address");
        emit NewOwnerNominated(_owner, newOwner);
        _nominatedOwner = newOwner;
    }

     
    function acceptOwnership() external {
        require(_nominatedOwner == _msgSender(), "unauthorized");
        emit OwnershipTransferred(_owner, _nominatedOwner);
        _owner = _nominatedOwner;
    }

     
    function renounceOwnership(string calldata declaration) external onlyOwner {
        string memory requiredDeclaration = "I hereby renounce ownership of this contract forever.";
        require(
            keccak256(abi.encodePacked(declaration)) ==
            keccak256(abi.encodePacked(requiredDeclaration)),
            "declaration incorrect");

        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IProposal {
    function proposer() external returns(address);
    function accept(uint256 time) external;
    function cancel() external;
    function complete(IRSV rsv, Basket oldBasket) external returns(Basket);
    function nominateNewOwner(address newOwner) external;
    function acceptOwnership() external;
}

interface IProposalFactory {
    function createSwapProposal(address,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bool[] calldata toVault
    ) external returns (IProposal);

    function createWeightProposal(address proposer, Basket basket) external returns (IProposal);
}

contract ProposalFactory is IProposalFactory {
    function createSwapProposal(
        address proposer,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bool[] calldata toVault
    )
        external returns (IProposal)
    {
        IProposal proposal = IProposal(new SwapProposal(proposer, tokens, amounts, toVault));
        proposal.nominateNewOwner(msg.sender);
        return proposal;
    }

    function createWeightProposal(address proposer, Basket basket) external returns (IProposal) {
        IProposal proposal = IProposal(new WeightProposal(proposer, basket));
        proposal.nominateNewOwner(msg.sender);
        return proposal;
    }
}

contract Proposal is IProposal, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public time;
    address public proposer;

    enum State { Created, Accepted, Cancelled, Completed }
    State public state;
    
    event ProposalCreated(address indexed proposer);
    event ProposalAccepted(address indexed proposer, uint256 indexed time);
    event ProposalCancelled(address indexed proposer);
    event ProposalCompleted(address indexed proposer, address indexed basket);

    constructor(address _proposer) public {
        proposer = _proposer;
        state = State.Created;
        emit ProposalCreated(proposer);
    }

     
    function accept(uint256 _time) external onlyOwner {
        require(state == State.Created, "proposal not created");
        time = _time;
        state = State.Accepted;
        emit ProposalAccepted(proposer, _time);
    }

     
    function cancel() external onlyOwner {
        require(state != State.Completed);
        state = State.Cancelled;
        emit ProposalCancelled(proposer);
    }

     
     
    function complete(IRSV rsv, Basket oldBasket)
        external onlyOwner returns(Basket)
    {
        require(state == State.Accepted, "proposal must be accepted");
        require(now > time, "wait to execute");
        state = State.Completed;

        Basket b = _newBasket(rsv, oldBasket);
        emit ProposalCompleted(proposer, address(b));
        return b;
    }

     
     
    function _newBasket(IRSV trustedRSV, Basket oldBasket) internal returns(Basket);
}

 
contract WeightProposal is Proposal {
    Basket public trustedBasket;

    constructor(address _proposer, Basket _trustedBasket) Proposal(_proposer) public {
        require(_trustedBasket.size() > 0, "proposal cannot be empty");
        trustedBasket = _trustedBasket;
    }

     
    function _newBasket(IRSV, Basket) internal returns(Basket) {
        return trustedBasket;
    }
}

 

 
contract SwapProposal is Proposal {
    address[] public tokens;
    uint256[] public amounts;  
    bool[] public toVault;

    uint256 constant WEIGHT_SCALE = uint256(10)**18;  

    constructor(address _proposer,
                address[] memory _tokens,
                uint256[] memory _amounts,  
                bool[] memory _toVault )
        Proposal(_proposer) public
    {
        require(_tokens.length > 0, "proposal cannot be empty");
        require(_tokens.length == _amounts.length && _amounts.length == _toVault.length,
                "unequal array lengths");
        tokens = _tokens;
        amounts = _amounts;
        toVault = _toVault;
    }

     
    function _newBasket(IRSV trustedRSV, Basket trustedOldBasket) internal returns(Basket) {

        uint256[] memory weights = new uint256[](tokens.length);
         

        uint256 scaleFactor = WEIGHT_SCALE.mul(uint256(10)**(trustedRSV.decimals()));
         

        uint256 rsvSupply = trustedRSV.totalSupply();
         

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 oldWeight = trustedOldBasket.weights(tokens[i]);
             

            if (toVault[i]) {
                 
                 
                 
                 
                 
                 
                
                weights[i] = oldWeight.add( (amounts[i].sub(1)).mul(scaleFactor).div(rsvSupply) );
                 
            } else {
                weights[i] = oldWeight.sub( amounts[i].mul(scaleFactor).div(rsvSupply) );
                 
            }
        }

        return new Basket(trustedOldBasket, tokens, weights);
         
    }
}



interface IVault {
    function withdrawTo(address, uint256, address) external;
}

 

 
contract Manager is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

     

     
    address public operator;

     

    Basket public trustedBasket;
    IVault public trustedVault;
    IRSV public trustedRSV;
    IProposalFactory public trustedProposalFactory;

     
    mapping(uint256 => IProposal) public trustedProposals;
    uint256 public proposalsLength;
    uint256 public delay = 24 hours;

     
    bool public issuancePaused;
    bool public emergency;

     
    uint256 public seigniorage;               
    uint256 constant BPS_FACTOR = 10000;      
    uint256 constant WEIGHT_SCALE = 10**18;  

    event ProposalsCleared();

     
    event Issuance(address indexed user, uint256 indexed amount);
    event Redemption(address indexed user, uint256 indexed amount);

     
    event IssuancePausedChanged(bool indexed oldVal, bool indexed newVal);
    event EmergencyChanged(bool indexed oldVal, bool indexed newVal);
    event OperatorChanged(address indexed oldAccount, address indexed newAccount);
    event SeigniorageChanged(uint256 oldVal, uint256 newVal);
    event VaultChanged(address indexed oldVaultAddr, address indexed newVaultAddr);
    event DelayChanged(uint256 oldVal, uint256 newVal);

     
    event WeightsProposed(uint256 indexed id,
        address indexed proposer,
        address[] tokens,
        uint256[] weights);

    event SwapProposed(uint256 indexed id,
        address indexed proposer,
        address[] tokens,
        uint256[] amounts,
        bool[] toVault);

    event ProposalAccepted(uint256 indexed id, address indexed proposer);
    event ProposalCanceled(uint256 indexed id, address indexed proposer, address indexed canceler);
    event ProposalExecuted(uint256 indexed id,
        address indexed proposer,
        address indexed executor,
        address oldBasket,
        address newBasket);

     

     
    constructor(
        address vaultAddr,
        address rsvAddr,
        address proposalFactoryAddr,
        address basketAddr,
        address operatorAddr,
        uint256 _seigniorage) public
    {
        require(_seigniorage <= 1000, "max seigniorage 10%");
        trustedVault = IVault(vaultAddr);
        trustedRSV = IRSV(rsvAddr);
        trustedProposalFactory = IProposalFactory(proposalFactoryAddr);
        trustedBasket = Basket(basketAddr);
        operator = operatorAddr;
        seigniorage = _seigniorage;
        emergency = true;  
    }

     

     
    modifier issuanceNotPaused() {
        require(!issuancePaused, "issuance is paused");
        _;
    }

     
    modifier notEmergency() {
        require(!emergency, "contract is paused");
        _;
    }

     
    modifier onlyOperator() {
        require(_msgSender() == operator, "operator only");
        _;
    }

     
    modifier vaultCollateralized() {
        require(isFullyCollateralized(), "undercollateralized");
        _;
        assert(isFullyCollateralized());
    }

     

     
    function setIssuancePaused(bool val) external onlyOperator {
        emit IssuancePausedChanged(issuancePaused, val);
        issuancePaused = val;
    }

     
    function setEmergency(bool val) external onlyOperator {
        emit EmergencyChanged(emergency, val);
        emergency = val;
    }

     
    function setVault(address newVaultAddress) external onlyOwner {
        emit VaultChanged(address(trustedVault), newVaultAddress);
        trustedVault = IVault(newVaultAddress);
    }

     
    function clearProposals() external onlyOperator {
        proposalsLength = 0;
        emit ProposalsCleared();
    }

     
    function setOperator(address _operator) external onlyOwner {
        emit OperatorChanged(operator, _operator);
        operator = _operator;
    }

     
    function setSeigniorage(uint256 _seigniorage) external onlyOwner {
        require(_seigniorage <= 1000, "max seigniorage 10%");
        emit SeigniorageChanged(seigniorage, _seigniorage);
        seigniorage = _seigniorage;
    }

     
    function setDelay(uint256 _delay) external onlyOwner {
        emit DelayChanged(delay, _delay);
        delay = _delay;
    }

     
     
    function isFullyCollateralized() public view returns(bool) {
        uint256 scaleFactor = WEIGHT_SCALE.mul(uint256(10) ** trustedRSV.decimals());
         

        for (uint256 i = 0; i < trustedBasket.size(); i++) {

            address trustedToken = trustedBasket.tokens(i);
            uint256 weight = trustedBasket.weights(trustedToken);  
            uint256 balance = IERC20(trustedToken).balanceOf(address(trustedVault));  

             
            if (trustedRSV.totalSupply().mul(weight) > balance.mul(scaleFactor)) {
                 
                return false;
            }
        }
        return true;
    }

     
     
     
    function toIssue(uint256 rsvAmount) public view returns (uint256[] memory) {
         
        uint256[] memory amounts = new uint256[](trustedBasket.size());

        uint256 feeRate = uint256(seigniorage.add(BPS_FACTOR));
         
        uint256 effectiveAmount = rsvAmount.mul(feeRate).div(BPS_FACTOR);
         

         
         
        for (uint256 i = 0; i < trustedBasket.size(); i++) {
            address trustedToken = trustedBasket.tokens(i);
            amounts[i] = _weighted(
                effectiveAmount,
                trustedBasket.weights(trustedToken),
                RoundingMode.UP
            );
             
        }

        return amounts;  
    }

     
     
     
    function toRedeem(uint256 rsvAmount) public view returns (uint256[] memory) {
         
        uint256[] memory amounts = new uint256[](trustedBasket.size());

         
         
        for (uint256 i = 0; i < trustedBasket.size(); i++) {
            address trustedToken = trustedBasket.tokens(i);
            amounts[i] = _weighted(
                rsvAmount,
                trustedBasket.weights(trustedToken),
                RoundingMode.DOWN
            );
             
        }

        return amounts;
    }

     
     
    function issue(uint256 rsvAmount) external
        issuanceNotPaused
        notEmergency
        vaultCollateralized
    {
        require(rsvAmount > 0, "cannot issue zero RSV");
        require(trustedBasket.size() > 0, "basket cannot be empty");

         
        uint256[] memory amounts = toIssue(rsvAmount);  
        for (uint256 i = 0; i < trustedBasket.size(); i++) {
            IERC20(trustedBasket.tokens(i)).safeTransferFrom(
                _msgSender(),
                address(trustedVault),
                amounts[i]
            );
             
        }

         
        trustedRSV.mint(_msgSender(), rsvAmount);
         

        emit Issuance(_msgSender(), rsvAmount);
    }

     
     
    function redeem(uint256 rsvAmount) external notEmergency vaultCollateralized {
        require(rsvAmount > 0, "cannot redeem 0 RSV");
        require(trustedBasket.size() > 0, "basket cannot be empty");

         
        trustedRSV.burnFrom(_msgSender(), rsvAmount);
         

         
        uint256[] memory amounts = toRedeem(rsvAmount);  
        for (uint256 i = 0; i < trustedBasket.size(); i++) {
            trustedVault.withdrawTo(trustedBasket.tokens(i), amounts[i], _msgSender());
             
        }

        emit Redemption(_msgSender(), rsvAmount);
    }

     
    function proposeSwap(
        address[] calldata tokens,
        uint256[] calldata amounts,  
        bool[] calldata toVault
    )
    external notEmergency vaultCollateralized returns(uint256)
    {
        require(tokens.length == amounts.length && amounts.length == toVault.length,
            "proposeSwap: unequal lengths");
        uint256 proposalID = proposalsLength++;

        trustedProposals[proposalID] = trustedProposalFactory.createSwapProposal(
            _msgSender(),
            tokens,
            amounts,
            toVault
        );
        trustedProposals[proposalID].acceptOwnership();

        emit SwapProposed(proposalID, _msgSender(), tokens, amounts, toVault);
        return proposalID;
    }


     

    function proposeWeights(address[] calldata tokens, uint256[] calldata weights)
    external notEmergency vaultCollateralized returns(uint256)
    {
        require(tokens.length == weights.length, "proposeWeights: unequal lengths");
        require(tokens.length > 0, "proposeWeights: zero length");

        uint256 proposalID = proposalsLength++;

        trustedProposals[proposalID] = trustedProposalFactory.createWeightProposal(
            _msgSender(),
            new Basket(Basket(0), tokens, weights)
        );
        trustedProposals[proposalID].acceptOwnership();

        emit WeightsProposed(proposalID, _msgSender(), tokens, weights);
        return proposalID;
    }

     
    function acceptProposal(uint256 id) external onlyOperator notEmergency vaultCollateralized {
        require(proposalsLength > id, "proposals length <= id");
        trustedProposals[id].accept(now.add(delay));
        emit ProposalAccepted(id, trustedProposals[id].proposer());
    }

     
     
    function cancelProposal(uint256 id) external notEmergency vaultCollateralized {
        require(
            _msgSender() == trustedProposals[id].proposer() ||
            _msgSender() == owner() ||
            _msgSender() == operator,
            "cannot cancel"
        );
        require(proposalsLength > id, "proposals length <= id");
        trustedProposals[id].cancel();
        emit ProposalCanceled(id, trustedProposals[id].proposer(), _msgSender());
    }

     
    function executeProposal(uint256 id) external onlyOperator notEmergency vaultCollateralized {
        require(proposalsLength > id, "proposals length <= id");
        address proposer = trustedProposals[id].proposer();
        Basket trustedOldBasket = trustedBasket;

         
        trustedBasket = trustedProposals[id].complete(trustedRSV, trustedOldBasket);

         
        for (uint256 i = 0; i < trustedOldBasket.size(); i++) {
            address trustedToken = trustedOldBasket.tokens(i);
            _executeBasketShift(
                trustedOldBasket.weights(trustedToken),
                trustedBasket.weights(trustedToken),
                trustedToken,
                proposer
            );
        }
        for (uint256 i = 0; i < trustedBasket.size(); i++) {
            address trustedToken = trustedBasket.tokens(i);
            if (!trustedOldBasket.has(trustedToken)) {
                _executeBasketShift(
                    trustedOldBasket.weights(trustedToken),
                    trustedBasket.weights(trustedToken),
                    trustedToken,
                    proposer
                );
            }
        }

        emit ProposalExecuted(
            id,
            proposer,
            _msgSender(),
            address(trustedOldBasket),
            address(trustedBasket)
        );
    }


     

     
     
     
    function _executeBasketShift(
        uint256 oldWeight,  
        uint256 newWeight,  
        address trustedToken,
        address proposer
    ) internal {
        if (newWeight > oldWeight) {
             
             
            uint256 transferAmount =_weighted(
                trustedRSV.totalSupply(),
                newWeight.sub(oldWeight),
                RoundingMode.UP
            );
             

            if (transferAmount > 0) {
                IERC20(trustedToken).safeTransferFrom(
                    proposer,
                    address(trustedVault),
                    transferAmount
                );
            }

        } else if (newWeight < oldWeight) {
             
             
            uint256 transferAmount =_weighted(
                trustedRSV.totalSupply(),
                oldWeight.sub(newWeight),
                RoundingMode.DOWN
            );
             
            if (transferAmount > 0) {
                trustedVault.withdrawTo(trustedToken, transferAmount, proposer);
            }
        }
    }

     
     
     
    enum RoundingMode {UP, DOWN}

     
     
    function _weighted(
        uint256 amount,  
        uint256 weight,  
        RoundingMode rnd
    ) internal view returns(uint256)  
    {
        uint256 scaleFactor = WEIGHT_SCALE.mul(uint256(10)**(trustedRSV.decimals()));
         
        uint256 shiftedWeight = amount.mul(weight);
         

         
        if (rnd == RoundingMode.DOWN || shiftedWeight.mod(scaleFactor) == 0) {
            return shiftedWeight.div(scaleFactor);
             
        }
        return shiftedWeight.div(scaleFactor).add(1);  
    }
}