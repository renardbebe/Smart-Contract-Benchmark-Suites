 

pragma solidity 0.4.25;


 
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

contract Ownable {
    mapping(address => bool) owners;

    event OwnerAdded(address indexed newOwner);
    event OwnerDeleted(address indexed owner);

     
    constructor() public {
        owners[msg.sender] = true;
    }

     
    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owners[_newOwner] = true;
        emit OwnerAdded(_newOwner);
    }

    function delOwner(address _owner) external onlyOwner {
        require(owners[_owner]);
        owners[_owner] = false;
        emit OwnerDeleted(_owner);
    }

    function isOwner(address _owner) public view returns (bool) {
        return owners[_owner];
    }

}


contract ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function ownerTransfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}


library SafeERC20 {
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}



 
contract Crowdsale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

     
    ERC20 public token;
    address public wallet;

    uint256 public openingTime;

    uint256 public cap;                  
    uint256 public tokensSold;           
    uint256 public tokenPriceInWei;      

    bool public isFinalized = false;

     
    uint256 public weiRaised;


    struct Stage {
        uint stopDay;        
        uint bonus;          
        uint tokens;         
        uint minPurchase;    
    }

    mapping (uint => Stage) public stages;
    uint public stageCount;
    uint public currentStage;

    mapping (address => uint) public refs;
    uint public buyerRefPercent = 500;
    uint public referrerPercent = 500;
    uint public minWithdrawValue = 200000000000000000;
    uint public globalMinWithdrawValue = 1000 ether;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 tokens, uint256 bonus);
    event Finalized();


     
    modifier onlyWhileOpen {
         
        require(block.timestamp >= openingTime);
        _;
    }


    constructor(address _wallet, ERC20 _token) public {
        require(_wallet != address(0));
        require(_token != address(0));

        wallet = _wallet;
        token = _token;

        cap = 32500000;
        openingTime = now;
        tokenPriceInWei = 1000000000000000;

        currentStage = 1;

        addStage(openingTime + 61    days, 10000, 2500000,  200000000000000000);
        addStage(openingTime + 122   days, 5000,  5000000,  200000000000000000);
        addStage(openingTime + 183   days, 1000,  10000000, 1000000000000000);
         
    }

     
     
     

     
    function () external payable {
        buyTokens(address(0));
    }

    function setTokenPrice(uint _price) onlyOwner public {
        tokenPriceInWei = _price;
    }

    function addStage(uint _stopDay, uint _bonus, uint _tokens, uint _minPurchase) onlyOwner public {
        require(_stopDay > stages[stageCount].stopDay);
        stageCount++;
        stages[stageCount].stopDay = _stopDay;
        stages[stageCount].bonus = _bonus;
        stages[stageCount].tokens = _tokens;
        stages[stageCount].minPurchase = _minPurchase;
    }

    function editStage(uint _stage, uint _stopDay, uint _bonus,  uint _tokens, uint _minPurchase) onlyOwner public {
        stages[_stage].stopDay = _stopDay;
        stages[_stage].bonus = _bonus;
        stages[_stage].tokens = _tokens;
        stages[_stage].minPurchase = _minPurchase;
    }


    function buyTokens(address _ref) public payable {

        uint256 weiAmount = msg.value;

        if (stages[currentStage].stopDay <= now && currentStage < stageCount) {
            _updateCurrentStage();
        }

        _preValidatePurchase(msg.sender, weiAmount);

        uint tokens = 0;
        uint bonusTokens = 0;
        uint totalTokens = 0;
        uint diff = 0;

        (tokens, bonusTokens, totalTokens, diff) = _getTokenAmount(weiAmount);

        _validatePurchase(tokens);

        weiAmount = weiAmount.sub(diff);

        if (_ref != address(0) && _ref != msg.sender) {
            uint refBonus = valueFromPercent(weiAmount, referrerPercent);
            uint buyerBonus = valueFromPercent(weiAmount, buyerRefPercent);

            refs[_ref] = refs[_ref].add(refBonus);
            diff = diff.add(buyerBonus);

            weiAmount = weiAmount.sub(buyerBonus).sub(refBonus);
        }

        if (diff > 0) {
            msg.sender.transfer(diff);
        }

        _processPurchase(msg.sender, totalTokens);
        emit TokenPurchase(msg.sender, msg.sender, msg.value, tokens, bonusTokens);

        _updateState(weiAmount, totalTokens);

        _forwardFunds(weiAmount);
    }

     
     
     

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) onlyWhileOpen internal view{
        require(_beneficiary != address(0));
        require(_weiAmount >= stages[currentStage].minPurchase);
        require(tokensSold < cap);
    }


    function _validatePurchase(uint256 _tokens) internal view {
        require(tokensSold.add(_tokens) <= cap);
    }


     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.safeTransfer(_beneficiary, _tokenAmount.mul(1 ether));
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }


     
    function _getTokenAmount(uint256 _weiAmount) internal returns (uint,uint,uint,uint) {
        uint _tokens;
        uint _tokens_price;

         
        if (currentStage == stageCount && (stages[stageCount].stopDay <= now || stages[currentStage].tokens == 0)) {
            _tokens = _weiAmount.div(tokenPriceInWei);
            _tokens_price = _tokens.mul(tokenPriceInWei);
            uint _diff = _weiAmount.sub(_tokens_price);
            return (_tokens, 0, _tokens, _diff);
        }

        uint _bonus = 0;
        uint _current_tokens = 0;
        uint _current_bonus = 0;

        for (uint i = currentStage; i <= stageCount && _weiAmount >= tokenPriceInWei; i++) {
            if (stages[i].tokens > 0 ) {
                uint _limit = stages[i].tokens.mul(tokenPriceInWei);
                 
                 
                if (_limit > _weiAmount) {
                     
                    _current_tokens = _weiAmount.div(tokenPriceInWei);
                     
                    _tokens_price = _current_tokens.mul(tokenPriceInWei);
                     
                    _weiAmount = _weiAmount.sub(_tokens_price);
                     
                    _tokens = _tokens.add(_current_tokens);
                     
                    stages[i].tokens = stages[i].tokens.sub(_current_tokens);

                    _current_bonus = _current_tokens.mul(stages[i].bonus).div(10000);
                    _bonus = _bonus.add(_current_bonus);

                } else {  
                     
                    _current_tokens = stages[i].tokens;
                    _tokens_price = _current_tokens.mul(tokenPriceInWei);
                    _weiAmount = _weiAmount.sub(_tokens_price);
                    _tokens = _tokens.add(_current_tokens);
                    stages[i].tokens = 0;

                    _current_bonus = _current_tokens.mul(stages[i].bonus).div(10000);
                    _bonus = _bonus.add(_current_bonus);

                    _updateCurrentStage();
                }
            }
        }

         
        if (_weiAmount >= tokenPriceInWei) {
            _current_tokens = _weiAmount.div(tokenPriceInWei);
            _tokens_price = _current_tokens.mul(tokenPriceInWei);
            _weiAmount = _weiAmount.sub(_tokens_price);
            _tokens = _tokens.add(_current_tokens);
        }

        return (_tokens, _bonus, _tokens.add(_bonus), _weiAmount);
    }


    function _updateCurrentStage() internal {
        for (uint i = currentStage; i <= stageCount; i++) {
            if (stages[i].stopDay > now && stages[i].tokens > 0) {
                currentStage = i;
                break;
            }
        }
    }


    function _updateState(uint256 _weiAmount, uint256 _tokens) internal {
        weiRaised = weiRaised.add(_weiAmount);
        tokensSold = tokensSold.add(_tokens);
    }


    function getRefPercent() public {
        require(refs[msg.sender] >= minWithdrawValue);
        require(weiRaised >= globalMinWithdrawValue);
        uint _val = refs[msg.sender];
        refs[msg.sender] = 0;
        msg.sender.transfer(_val);
    }

     
    function _forwardFunds(uint _weiAmount) internal {
        wallet.transfer(_weiAmount);
    }

     
    function capReached() public view returns (bool) {
        return tokensSold >= cap;
    }


     
    function finalize() onlyOwner public {
        require(!isFinalized);
         

        finalization();
        emit Finalized();

        isFinalized = true;
    }

     
    function finalization() internal {
        if (token.balanceOf(this) > 0) {
            token.safeTransfer(wallet, token.balanceOf(this));
        }
    }


     
    function valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }


    function setBuyerRefPercent(uint _buyerRefPercent) onlyOwner public {
        buyerRefPercent = _buyerRefPercent;
    }

    function setReferrerPercent(uint _referrerPercent) onlyOwner public {
        referrerPercent = _referrerPercent;
    }

    function setMinWithdrawValue(uint _minWithdrawValue) onlyOwner public {
        minWithdrawValue = _minWithdrawValue;
    }

    function setGlobalMinWithdrawValue(uint _globalMinWithdrawValue) onlyOwner public {
        globalMinWithdrawValue = _globalMinWithdrawValue;
    }



     
     
     
     
    function claimTokens(address _token, address _to) external onlyOwner {
        require(_to != address(0));
        if (_token == 0x0) {
            _to.transfer(address(this).balance);
            return;
        }

        ERC20 t = ERC20(_token);
        uint balance = t.balanceOf(this);
        t.safeTransfer(_to, balance);
    }

}