 

pragma solidity ^0.4.25;

 
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

 
contract Operated {
    mapping(address => bool) private _ops;

    event OperatorChanged(
        address indexed operator,
        bool active
    );

     
    constructor() internal {
        _ops[msg.sender] = true;
        emit OperatorChanged(msg.sender, true);
    }

     
    modifier onlyOps() {
        require(isOps(), "only operations accounts are allowed to call this function");
        _;
    }

     
    function isOps() public view returns(bool) {
        return _ops[msg.sender];
    }

     
    function setOps(address _account, bool _active) public onlyOps {
        _ops[_account] = _active;
        emit OperatorChanged(_account, _active);
    }
}

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns(address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
contract WhiskyToken is IERC20, Ownable, Operated {
    using SafeMath for uint256;
    using SafeMath for uint64;

     
    string public name = "Whisky Token";
    string public symbol = "WHY";
    uint8 public decimals = 18;
    uint256 public initialSupply = 28100000 * (10 ** uint256(decimals));
    uint256 public totalSupply;

     
    address public crowdSaleContract;

     
    uint64 public assetValue;

     
    uint64 public feeCharge;

     
    bool public freezeTransfer;

     
    bool private tokenAvailable;

     
    uint64 private constant feeChargeMax = 20;

     
    address private feeReceiver;

     
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;
    mapping(address => bool) public frozenAccount;

     
    event Fee(address indexed payer, uint256 fee);
    event FeeCharge(uint64 oldValue, uint64 newValue);
    event AssetValue(uint64 oldValue, uint64 newValue);
    event Burn(address indexed burner, uint256 value);
    event FrozenFunds(address indexed target, bool frozen);
    event FreezeTransfer(bool frozen);

     
    constructor(address _tokenOwner) public {
        transferOwnership(_tokenOwner);
        setOps(_tokenOwner, true);
        crowdSaleContract = msg.sender;
        feeReceiver = _tokenOwner;
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
        assetValue = 0;
        feeCharge = 15;
        freezeTransfer = true;
        tokenAvailable = true;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        if (!tokenAvailable) {
            return 0;
        }
        return balances[_owner];
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "zero address is not allowed");
        require(_value >= 1000, "must transfer more than 1000 sip");
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(!frozenAccount[_from], "sender address is frozen");
        require(!frozenAccount[_to], "receiver address is frozen");

        uint256 transferValue = _value;
        if (msg.sender != owner() && msg.sender != crowdSaleContract) {
            uint256 fee = _value.div(1000).mul(feeCharge);
            transferValue = _value.sub(fee);
            balances[feeReceiver] = balances[feeReceiver].add(fee);
            emit Fee(msg.sender, fee);
            emit Transfer(_from, feeReceiver, fee);
        }

         
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(transferValue);
        if (tokenAvailable) {
            emit Transfer(_from, _to, transferValue);
        }
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender], "requesting more token than allowed");

        _transfer(_from, _to, _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_spender != address(0), "zero address is not allowed");
        require(_value >= 1000, "must approve more than 1000 sip");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_spender != address(0), "zero address is not allowed");
        require(_addedValue >= 1000, "must approve more than 1000 sip");
        
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_spender != address(0), "zero address is not allowed");
        require(_subtractedValue >= 1000, "must approve more than 1000 sip");

        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    } 

     
    function burn(uint256 _value) public {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_value <= balances[msg.sender], "address has not enough token to burn");
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }

     
    function setAssetValue(uint64 _value) public onlyOwner {
        uint64 oldValue = assetValue;
        assetValue = _value;
        emit AssetValue(oldValue, _value);
    }

     
    function setFeeCharge(uint64 _value) public onlyOwner {
        require(_value <= feeChargeMax, "can not increase fee charge over it's limit");
        uint64 oldValue = feeCharge;
        feeCharge = _value;
        emit FeeCharge(oldValue, _value);
    }


     
    function freezeAccount(address _target, bool _freeze) public onlyOwner {
        require(_target != address(0), "zero address is not allowed");

        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }

     
    function setFreezeTransfer(bool _freeze) public onlyOwner {
        freezeTransfer = _freeze;
        emit FreezeTransfer(_freeze);
    }

     
    function setFeeReceiver(address _feeReceiver) public onlyOwner {
        require(_feeReceiver != address(0), "zero address is not allowed");
        feeReceiver = _feeReceiver;
    }

     
    function setTokenAvailable(bool _available) public onlyOwner {
        tokenAvailable = _available;
    }
}

 
contract WhiskyTokenCrowdsale is Ownable, Operated {
    using SafeMath for uint256;
    using SafeMath for uint64;

     
     
    address public beneficiary;

     
     
    uint256 public deadline;

     
     
    uint256 public amountRaisedETH;

     
     
    uint256 public amountRaisedEUR;

     
     
    uint256 public tokenSold;

     
     
    bool public fundingGoalReached;

     
     
    bool public crowdsaleClosed;

     
     
    bool private goalChecked;

     
     
    WhiskyToken public tokenReward;

     
     
    FiatContract public fiat;

     
     
    uint256 private minTokenSellInEuroCents = 200000000;

     
     
    uint256 private minTokenBuyEuroCents = 3000;

     
     
    uint256 private minTokenSell = 2583333 * 1 ether;

     
     
    uint256 private maxTokenSell = 25250000 * 1 ether;

     
     
     
    uint256 private minFounderToken = 308627 * 1 ether;

     
     
     
    uint256 private maxFounderToken = 1405000 * 1 ether;

     
     
     
    uint256 private minRDAToken = 154313 * 1 ether;

     
     
     
    uint256 private maxRDAToken = 1405000 * 1 ether;

     
     
    uint256 private bountyTokenPerPerson = 5 * 1 ether;

     
     
    uint256 private maxBountyToken = 40000 * 1 ether;

     
     
    uint256 public tokenLeftForBounty;

     
     
    Phase private preSalePhase = Phase({
        id: PhaseID.PreSale,
        tokenPrice: 60,
        tokenForSale: 333333 * 1 ether,
        tokenLeft: 333333 * 1 ether
    });

     
     
    Phase private firstPhase = Phase({
        id: PhaseID.First,
        tokenPrice: 80,
        tokenForSale: 2250000 * 1 ether,
        tokenLeft: 2250000 * 1 ether
    });

     
     
    Phase private secondPhase = Phase({
        id: PhaseID.Second,
        tokenPrice: 100,
        tokenForSale: 21000000 * 1 ether,
        tokenLeft: 21000000 * 1 ether
    });

     
     
    Phase private thirdPhase = Phase({
        id: PhaseID.Third,
        tokenPrice: 120,
        tokenForSale: 1666667 * 1 ether,
        tokenLeft: 1666667 * 1 ether
    });

     
     
    Phase private closedPhase = Phase({
        id: PhaseID.Closed,
        tokenPrice: ~uint64(0),
        tokenForSale: 0,
        tokenLeft: 0
    });

     
    Phase public currentPhase;

     
     
     
    struct Phase {
        PhaseID id;
        uint64 tokenPrice;
        uint256 tokenForSale;
        uint256 tokenLeft;
    }

     
    enum PhaseID {
        PreSale,         
        First,           
        Second,          
        Third,           
        Closed           
    }    

     
    mapping(address => Customer) public customer;

     
     
     
    struct Customer {
        Rating rating;
        uint256 amountRaisedEther;
        uint256 amountRaisedEuro;
        uint256 amountReceivedWhiskyToken;
        bool hasReceivedBounty;
    }

     
    enum Rating {
        Unlisted,        
        Whitelisted      
    }

     
    event SaleClosed();
    event GoalReached(address recipient, uint256 tokensSold, uint256 totalAmountRaised);
    event WhitelistUpdated(address indexed _account, uint8 _phase);
    event PhaseEntered(PhaseID phaseID);
    event TokenSold(address indexed customer, uint256 amount);
    event BountyTransfer(address indexed customer, uint256 amount);
    event FounderTokenTransfer(address recipient, uint256 amount);
    event RDATokenTransfer(address recipient, uint256 amount);
    event FundsWithdrawal(address indexed recipient, uint256 amount);

     
    constructor() public {
        setOps(msg.sender, true);
        beneficiary = msg.sender;
        tokenReward = new WhiskyToken(msg.sender);
        fiat = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591);  
        currentPhase = preSalePhase;
        fundingGoalReached = false;
        crowdsaleClosed = false;
        goalChecked = false;
        tokenLeftForBounty = maxBountyToken;
        tokenReward.transfer(msg.sender, currentPhase.tokenForSale);
        currentPhase.tokenLeft = 0;
        tokenSold += currentPhase.tokenForSale;
        amountRaisedEUR = amountRaisedEUR.add((currentPhase.tokenForSale.div(1 ether)).mul(currentPhase.tokenPrice));
    }

     
    function nextPhase() public onlyOwner {
        require(currentPhase.id != PhaseID.Closed, "already reached the closed phase");

        uint8 nextPhaseNum = uint8(currentPhase.id) + 1;

        if (PhaseID(nextPhaseNum) == PhaseID.First) {
            currentPhase = firstPhase;
            deadline = now + 365 * 1 days;
        }
        if (PhaseID(nextPhaseNum) == PhaseID.Second) {
            currentPhase = secondPhase;
        }
        if (PhaseID(nextPhaseNum) == PhaseID.Third) {
            currentPhase = thirdPhase;
        }
        if (PhaseID(nextPhaseNum) == PhaseID.Closed) {
            currentPhase = closedPhase;
        }

        emit PhaseEntered(currentPhase.id);
    }

     
    function updateWhitelist(address _account, uint8 _phase) external onlyOps returns (bool) {
        require(_account != address(0), "zero address is not allowed");
        require(_phase == uint8(Rating.Unlisted) || _phase == uint8(Rating.Whitelisted), "invalid rating");

        Rating rating = Rating(_phase);
        customer[_account].rating = rating;
        emit WhitelistUpdated(_account, _phase);

        if (rating > Rating.Unlisted && !customer[_account].hasReceivedBounty && tokenLeftForBounty > 0) {
            customer[_account].hasReceivedBounty = true;
            customer[_account].amountReceivedWhiskyToken = customer[_account].amountReceivedWhiskyToken.add(bountyTokenPerPerson);
            tokenLeftForBounty = tokenLeftForBounty.sub(bountyTokenPerPerson);
            require(tokenReward.transfer(_account, bountyTokenPerPerson), "token transfer failed");
            emit BountyTransfer(_account, bountyTokenPerPerson);
        }

        return true;
    }

     
    modifier afterDeadline() {
        if ((now >= deadline && currentPhase.id >= PhaseID.First) || currentPhase.id == PhaseID.Closed) {
            _;
        }
    }

     
    function checkGoalReached() public afterDeadline {
        if (!goalChecked) {
            if (_checkFundingGoalReached()) {
                emit GoalReached(beneficiary, tokenSold, amountRaisedETH);
            }
            if (!crowdsaleClosed) {
                crowdsaleClosed = true;
                emit SaleClosed();
            }
            goalChecked = true;
        }
    }

     
    function _checkFundingGoalReached() internal returns (bool) {
        if (!fundingGoalReached) {
            if (amountRaisedEUR >= minTokenSellInEuroCents) {
                fundingGoalReached = true;
            }
        }
        return fundingGoalReached;
    }

     
    function () external payable {
        _buyToken(msg.sender);
    }

     
    function buyToken() external payable {
        _buyToken(msg.sender);
    }

     
    function buyTokenForAddress(address _receiver) external payable {
        require(_receiver != address(0), "zero address is not allowed");
        _buyToken(_receiver);
    }

     
    function buyTokenForAddressWithEuroCent(address _receiver, uint64 _cent) external onlyOps {
        require(!crowdsaleClosed, "crowdsale is closed");
        require(_receiver != address(0), "zero address is not allowed");
        require(currentPhase.id != PhaseID.PreSale, "not allowed to buy token in presale phase");
        require(currentPhase.id != PhaseID.Closed, "not allowed to buy token in closed phase");
        require(customer[_receiver].rating == Rating.Whitelisted, "address is not whitelisted");
        _sendTokenReward(_receiver, _cent);        
        _checkFundingGoalReached();
    }

     
    function _buyToken(address _receiver) internal {
        require(!crowdsaleClosed, "crowdsale is closed");
        require(currentPhase.id != PhaseID.PreSale, "not allowed to buy token in presale phase");
        require(currentPhase.id != PhaseID.Closed, "not allowed to buy token in closed phase");
        require(customer[_receiver].rating == Rating.Whitelisted, "address is not whitelisted");
        _sendTokenReward(_receiver, 0);
        _checkFundingGoalReached();
    }

     
    function _sendTokenReward(address _receiver, uint64 _cent) internal {
         
         
         
        uint256 amountEuroCents;
        uint256 tokenAmount;
        if (msg.value > 0) {
            uint256 amount = msg.value;
            customer[msg.sender].amountRaisedEther = customer[msg.sender].amountRaisedEther.add(amount);
            amountRaisedETH = amountRaisedETH.add(amount);
            amountEuroCents = amount.div(fiat.EUR(0));
            tokenAmount = (amount.div(getTokenPrice())) * 1 ether;
        } else if (_cent > 0) {
            amountEuroCents = _cent;
            tokenAmount = (amountEuroCents.div(currentPhase.tokenPrice)) * 1 ether;
        } else {
            revert("this should never happen");
        }
        
        uint256 sumAmountEuroCents = customer[_receiver].amountRaisedEuro.add(amountEuroCents);
        customer[_receiver].amountRaisedEuro = sumAmountEuroCents;
        amountRaisedEUR = amountRaisedEUR.add(amountEuroCents);

        require(((tokenAmount / 1 ether) * currentPhase.tokenPrice) >= minTokenBuyEuroCents, "must buy token for at least 30 EUR");
        require(tokenAmount <= currentPhase.tokenLeft, "not enough token left in current phase");
        currentPhase.tokenLeft = currentPhase.tokenLeft.sub(tokenAmount);

        customer[_receiver].amountReceivedWhiskyToken = customer[_receiver].amountReceivedWhiskyToken.add(tokenAmount);
        tokenSold = tokenSold.add(tokenAmount);
        require(tokenReward.transfer(_receiver, tokenAmount), "token transfer failed");
        emit TokenSold(_receiver, tokenAmount);
    }

     
    function safeWithdrawal() public afterDeadline {
        require(crowdsaleClosed, "crowdsale must be closed");
        
        if (!fundingGoalReached) {
             
            require(customer[msg.sender].amountRaisedEther > 0, "message sender has not raised any ether to this contract");
            uint256 amount = customer[msg.sender].amountRaisedEther;
            customer[msg.sender].amountRaisedEther = 0;
            msg.sender.transfer(amount);
            emit FundsWithdrawal(msg.sender, amount);
        } else {
             
            require(beneficiary == msg.sender, "message sender is not the beneficiary");
            uint256 ethAmount = address(this).balance;
            beneficiary.transfer(ethAmount);
            emit FundsWithdrawal(beneficiary, ethAmount);

             
            uint256 founderToken = (tokenSold - minTokenSell) * (maxFounderToken - minFounderToken) / (maxTokenSell - minTokenSell) + minFounderToken - (maxBountyToken - tokenLeftForBounty);
            require(tokenReward.transfer(beneficiary, founderToken), "founder token transfer failed");
            emit FounderTokenTransfer(beneficiary, founderToken);

             
            uint256 rdaToken = (tokenSold - minTokenSell) * (maxRDAToken - minRDAToken) / (maxTokenSell - minTokenSell) + minRDAToken;
            require(tokenReward.transfer(beneficiary, rdaToken), "RDA token transfer failed");
            emit RDATokenTransfer(beneficiary, rdaToken);

             
            tokenReward.burn(tokenReward.balanceOf(this));
        }
    }

     
    function earlySafeWithdrawal(uint256 _amount) public onlyOwner {
        require(fundingGoalReached, "funding goal has not been reached");
        require(beneficiary == msg.sender, "message sender is not the beneficiary");
        require(address(this).balance >= _amount, "contract has less ether in balance than requested");

        beneficiary.transfer(_amount);
        emit FundsWithdrawal(beneficiary, _amount);
    }

     
    function getTokenPrice() internal view returns (uint256) {
        return getEtherInEuroCents() * currentPhase.tokenPrice / 100;
    }

     
    function getEtherInEuroCents() internal view returns (uint256) {
        return fiat.EUR(0) * 100;
    }

     
    function setFiatContractAddress(address _fiat) public onlyOwner {
        require(_fiat != address(0), "zero address is not allowed");
        fiat = FiatContract(_fiat);
    }

     
    function setBeneficiary(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0), "zero address is not allowed");
        beneficiary = _beneficiary;
    }
}

 
contract FiatContract {
    function ETH(uint _id) public view returns (uint256);
    function USD(uint _id) public view returns (uint256);
    function EUR(uint _id) public view returns (uint256);
    function GBP(uint _id) public view returns (uint256);
    function updatedAt(uint _id) public view returns (uint);
}