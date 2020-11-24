 

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity ^0.5.0;




 
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
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

 

pragma solidity ^0.5.0;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

 

pragma solidity ^0.5.0;





 
contract Crowdsale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    IERC20 private _token;

     
    address payable private _wallet;

     
     
     
     
    uint256 private _rate;

     
    uint256 private _weiRaised;

     
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    constructor (uint256 rate, address payable wallet, IERC20 token) public {
        require(rate > 0, "Crowdsale: rate is 0");
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function token() public view returns (IERC20) {
        return _token;
    }

     
    function wallet() public view returns (address payable) {
        return _wallet;
    }

     
    function rate() public view returns (uint256) {
        return _rate;
    }

     
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

     
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
    }

     
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
         
    }

     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

     
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

     
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
         
    }

     
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

     
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}

 

pragma solidity ^0.5.0;



 
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;

     
    event TimedCrowdsaleExtended(uint256 prevClosingTime, uint256 newClosingTime);

     
    modifier onlyWhileOpen {
        require(isOpen(), "TimedCrowdsale: not open");
        _;
    }

     
    constructor (uint256 openingTime, uint256 closingTime) public {
         
        require(openingTime >= block.timestamp, "TimedCrowdsale: opening time is before current time");
         
        require(closingTime > openingTime, "TimedCrowdsale: opening time is not before closing time");

        _openingTime = openingTime;
        _closingTime = closingTime;
    }

     
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

     
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

     
    function isOpen() public view returns (bool) {
         
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

     
    function hasClosed() public view returns (bool) {
         
        return block.timestamp > _closingTime;
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        super._preValidatePurchase(beneficiary, weiAmount);
    }

     
    function _extendTime(uint256 newClosingTime) internal {
        require(!hasClosed(), "TimedCrowdsale: already closed");
         
        require(newClosingTime > _closingTime, "TimedCrowdsale: new closing time is before current closing time");

        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }
}

 

pragma solidity ^0.5.0;



 
contract FinalizableCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    bool private _finalized;

    event CrowdsaleFinalized();

    constructor () internal {
        _finalized = false;
    }

     
    function finalized() public view returns (bool) {
        return _finalized;
    }

     
    function finalize() public {
        require(!_finalized, "FinalizableCrowdsale: already finalized");
        require(hasClosed(), "FinalizableCrowdsale: not closed");

        _finalized = true;

        _finalization();
        emit CrowdsaleFinalized();
    }

     
    function _finalization() internal {
         
    }
}

 

pragma solidity ^0.5.0;

 
contract Secondary {
    address private _primary;

     
    event PrimaryTransferred(
        address recipient
    );

     
    constructor () internal {
        _primary = msg.sender;
        emit PrimaryTransferred(_primary);
    }

     
    modifier onlyPrimary() {
        require(msg.sender == _primary, "Secondary: caller is not the primary account");
        _;
    }

     
    function primary() public view returns (address) {
        return _primary;
    }

     
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0), "Secondary: new primary is the zero address");
        _primary = recipient;
        emit PrimaryTransferred(_primary);
    }
}

 

pragma solidity ^0.5.0;



  
contract Escrow is Secondary {
    using SafeMath for uint256;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

     
    function deposit(address payee) public onlyPrimary payable {
        uint256 amount = msg.value;
        _deposits[payee] = _deposits[payee].add(amount);

        emit Deposited(payee, amount);
    }

     
    function withdraw(address payable payee) public onlyPrimary {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.transfer(payment);

        emit Withdrawn(payee, payment);
    }
}

 

pragma solidity ^0.5.0;


 
contract ConditionalEscrow is Escrow {
     
    function withdrawalAllowed(address payee) public view returns (bool);

    function withdraw(address payable payee) public {
        require(withdrawalAllowed(payee), "ConditionalEscrow: payee is not allowed to withdraw");
        super.withdraw(payee);
    }
}

 

pragma solidity ^0.5.0;


 
contract RefundEscrow is ConditionalEscrow {
    enum State { Active, Refunding, Closed }

    event RefundsClosed();
    event RefundsEnabled();

    State private _state;
    address payable private _beneficiary;

     
    constructor (address payable beneficiary) public {
        require(beneficiary != address(0), "RefundEscrow: beneficiary is the zero address");
        _beneficiary = beneficiary;
        _state = State.Active;
    }

     
    function state() public view returns (State) {
        return _state;
    }

     
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

     
    function deposit(address refundee) public payable {
        require(_state == State.Active, "RefundEscrow: can only deposit while active");
        super.deposit(refundee);
    }

     
    function close() public onlyPrimary {
        require(_state == State.Active, "RefundEscrow: can only close while active");
        _state = State.Closed;
        emit RefundsClosed();
    }

     
    function enableRefunds() public onlyPrimary {
        require(_state == State.Active, "RefundEscrow: can only enable refunds while active");
        _state = State.Refunding;
        emit RefundsEnabled();
    }

     
    function beneficiaryWithdraw() public {
        require(_state == State.Closed, "RefundEscrow: beneficiary can only withdraw while closed");
        _beneficiary.transfer(address(this).balance);
    }

     
    function withdrawalAllowed(address) public view returns (bool) {
        return _state == State.Refunding;
    }
}

 

pragma solidity ^0.5.0;




 
contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

     
    uint256 private _goal;

     
    RefundEscrow private _escrow;

     
    constructor (uint256 goal) public {
        require(goal > 0, "RefundableCrowdsale: goal is 0");
        _escrow = new RefundEscrow(wallet());
        _goal = goal;
    }

     
    function goal() public view returns (uint256) {
        return _goal;
    }

     
    function claimRefund(address payable refundee) public {
        require(finalized(), "RefundableCrowdsale: not finalized");
        require(!goalReached(), "RefundableCrowdsale: goal reached");

        _escrow.withdraw(refundee);
    }

     
    function goalReached() public view returns (bool) {
        return weiRaised() >= _goal;
    }

     
    function _finalization() internal {
        if (goalReached()) {
            _escrow.close();
            _escrow.beneficiaryWithdraw();
        } else {
            _escrow.enableRefunds();
        }

        super._finalization();
    }

     
    function _forwardFunds() internal {
        _escrow.deposit.value(msg.value)(msg.sender);
    }
}

 

pragma solidity ^0.5.0;





 
contract PostDeliveryCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    __unstable__TokenVault private _vault;

    constructor() public {
        _vault = new __unstable__TokenVault();
    }

     
    function withdrawTokens(address beneficiary) public {
        require(hasClosed(), "PostDeliveryCrowdsale: not closed");
        uint256 amount = _balances[beneficiary];
        require(amount > 0, "PostDeliveryCrowdsale: beneficiary is not due any tokens");

        _balances[beneficiary] = 0;
        _vault.transfer(token(), beneficiary, amount);
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
        _deliverTokens(address(_vault), tokenAmount);
    }
}

 
 
contract __unstable__TokenVault is Secondary {
    function transfer(IERC20 token, address to, uint256 amount) public onlyPrimary {
        token.transfer(to, amount);
    }
}

 

pragma solidity ^0.5.0;




 
contract RefundablePostDeliveryCrowdsale is RefundableCrowdsale, PostDeliveryCrowdsale {
    function withdrawTokens(address beneficiary) public {
        require(finalized(), "RefundablePostDeliveryCrowdsale: not finalized");
        require(goalReached(), "RefundablePostDeliveryCrowdsale: goal not reached");

        super.withdrawTokens(beneficiary);
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;



 
 
 
 

interface UniswapExchangeApi{
     
    function getEthToTokenInputPrice(uint256 amountOfEth) external view returns(uint256);
    function tokenToEthSwapInput(uint256 tokens_sold,uint256 min_eth,uint256 deadline) external returns(uint256);

}


interface UniswapFactoryApi{
     
    function getExchange(address _adr) external returns(address);

}

contract GTBExchanger is Ownable{

    address public dai_adr = address(0x006b175474e89094c44da98b954eedeac495271d0f);
    address public rinkeby_dai_adr = address(0x2448eE2641d78CC42D7AD76498917359D961A783);
	address public uniswap;

    UniswapExchangeApi public _daiEx;
    constructor (address _uniswap) public {
		uniswap = _uniswap;

        bool status ;
        bytes memory data ;
         
        (status,data)=uniswap.call.gas(100000)(abi.encodePacked(bytes4(0xe46cdfe6)));
        if(status){
           uint256 local_dai;
           assembly {
                local_dai := mload(add(0x20,data))
           } 
           dai_adr = address(local_dai);
        }
    }

	function changeUniswap(address _a) public onlyOwner{
		uniswap = _a;
		_daiEx = UniswapExchangeApi(UniswapFactoryApi(uniswap).getExchange(dai_adr));
	}

	function init() public{
		require(address(_daiEx)==address(0),"can set exchange only once");
		if(uniswap==address(0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36)){
			dai_adr = rinkeby_dai_adr;
		}
		_daiEx = UniswapExchangeApi(UniswapFactoryApi(uniswap).getExchange(dai_adr));
	} 
	
	function initb() public{
		IERC20(dai_adr).approve(address(_daiEx),uint(2**255));
	} 



    function getDAIAmount(uint256 weiAmount) public view returns(uint256){
        return _daiEx.getEthToTokenInputPrice(weiAmount);
    }

    function exchangeToDAI() external payable returns(uint256){
        address payable daiExAddr = address(uint160(address(_daiEx)));
        bool status ;
        (status,)=daiExAddr.call.gas(75000).value(msg.value)("");
        require(status,'DAI purchase failed');
        uint256 tokAmount = IERC20(dai_adr).balanceOf(address(this));
        require(IERC20(dai_adr).transfer(msg.sender,tokAmount),'transfer failed');
        return tokAmount;
    }

    function exchangeFromDAI(uint256 amount,address payable beneficiary) external{
        require(IERC20(dai_adr).transferFrom(msg.sender,address(this),amount),'transfer failed');
        uint ethValue = _daiEx.tokenToEthSwapInput(amount,1,now+1);
        beneficiary.transfer(ethValue);
    } 

    function() external payable{
        require(msg.sender==address(_daiEx),'WTF3');
    }
}

 

pragma solidity ^0.5.0;


 
 
 
 
 

contract GTBCrowdsale is RefundablePostDeliveryCrowdsale{


    uint256 public priceInDAI;
    uint256 public totalDAI;
    address public admin;
    bool public enabled;
    address public deployer;
    mapping(address => uint256) public daiAmount;

    GTBExchanger public exchanger;

    function goalReached() public view returns (bool) {
        return totalDAI>=goal() && enabled;
    }

    constructor (address payable wallet,
        IERC20 token,
        GTBExchanger _exchanger,
        uint256 amountToSell,
        uint256 startOffset,
        uint256 duration,
        uint256 _priceInDAI) public 
    RefundableCrowdsale(amountToSell)
    TimedCrowdsale(now+startOffset,now+startOffset+duration)
    Crowdsale(1 ,wallet,token)
    {
        exchanger = _exchanger;
        priceInDAI = _priceInDAI;
        totalDAI = 0;
        deployer = msg.sender;
        enabled = false;
    }

    function finalize() public{
        require(msg.sender==admin,"only admin can finalize crowdsale");
        super.finalize();
    }

    function setAdmin(address _admin) public {
        require(msg.sender==deployer, "You cannot change admin");
        admin=_admin;
        IERC20(exchanger.dai_adr()).approve(address(admin),uint256(0)-1);
    }

    function setWithdrawEnabled() public {
        require(msg.sender==admin, "You cannot change Enabled status");
        enabled = true;
        super.finalize();
    }
	
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return getAmountOfTokenFor(weiAmount);
    }

    function getAmountOfTokenFor(uint256 weiAmount) public view returns (uint256) {
        uint256 possibleAmount = exchanger.getDAIAmount(weiAmount);
        return possibleAmount * (10**18) / priceInDAI;
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        uint256 daiAmountToAdd = exchanger.exchangeToDAI.gas(250000).value(msg.value)();
        daiAmount[beneficiary]=daiAmount[beneficiary].add(daiAmountToAdd);
        totalDAI = daiAmountToAdd+totalDAI;
        super._processPurchase(beneficiary,tokenAmount);
    }

    function _forwardFunds() internal {
         
    }

         
         
    function claimRefund(address payable refundee) public {
        require(finalized(), "RefundableCrowdsale: not finalized");
        require(!goalReached(), "RefundableCrowdsale: goal reached");
        
        exchanger.exchangeFromDAI(daiAmount[refundee],refundee);
         
    }
	
	function timeToClose() public view returns(uint256) {
		if(now<closingTime())
			return closingTime()-now;
		else
			return 0;
	}

	function timeToOpen() public view returns(uint256) {
		if(now<openingTime())
			return openingTime()-now;
		else
			return 0;
	}

    function _finalization() internal {
        if (goalReached()) {
            uint256 amountOfTokens = IERC20(exchanger.dai_adr()).balanceOf(address(this));
            IERC20(exchanger.dai_adr()).transfer(wallet(),amountOfTokens);
        } else {
             
            IERC20(exchanger.dai_adr()).approve(address(exchanger),uint256(0)-1);
        }
    }

    function withdrawInBulk(address[] memory baneficiaries) public {
        for(uint256 i=0;i<baneficiaries.length;i++){
            super.withdrawTokens(baneficiaries[i]);
        }
    }

    function refundInBulk(address payable[] memory baneficiaries) public {
        for(uint256 i=0;i<baneficiaries.length;i++){
            claimRefund(baneficiaries[i]);
        }
    }

	function changeUniswao(address _a) public{
        require(msg.sender==admin, "Only Admin can change uniswap address");
        exchanger.changeUniswap(_a);
	}


}