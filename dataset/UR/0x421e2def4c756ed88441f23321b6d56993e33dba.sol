 

pragma solidity 0.5.9;

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

 
contract Ownable {
    address payable public owner;
    mapping(address => bool) managers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        owner = msg.sender;
        managers[msg.sender] = true;
        emit OwnershipTransferred(address(0), owner);
    }


     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }


    modifier onlyManager() {
        require(isManager(msg.sender));
        _;
    }
     
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }


    function isManager(address _manager) public view returns (bool) {
        return managers[_manager];
    }


    function addManager(address _manager) external onlyOwner {
        require(_manager != address(0));
        managers[_manager] = true;
    }


    function delManager(address _manager) external onlyOwner {
        require(managers[_manager]);
        managers[_manager] = false;
    }

     
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes calldata _data) external;
}

 
contract Token is Ownable {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               

     
     
     
    struct  Checkpoint {

         
        uint128 fromBlock;

         
        uint128 value;
    }


     
     
    uint public parentSnapShotBlock;

     
    uint public creationBlock;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;

     
     
     
    event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

     
     
     

     
     
     
     
     
    constructor () public {
        name = "Blockchain Partners Coin";
        symbol = "BPC";
        decimals = 18;
        parentSnapShotBlock = block.number;
        creationBlock = block.number;

         
        uint _amount = 21000000 * (10 ** uint256(decimals));
        updateValueAtNow(totalSupplyHistory, _amount);
        updateValueAtNow(balances[msg.sender], _amount);
        emit Transfer(address(0), msg.sender, _amount);
    }


     
    function () external {}

     
     
     

     
     
     
     
    function transfer(address _to, uint256 _amount) external returns (bool success) {
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success) {
         
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] -= _amount;
        doTransfer(_from, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount) internal {

        if (_amount == 0) {
            emit Transfer(_from, _to, _amount);     
            return;
        }

        require(parentSnapShotBlock < block.number);

         
        require((_to != address(0)) && (_to != address(this)));

         
         
        uint previousBalanceFrom = balanceOfAt(_from, block.number);

        require(previousBalanceFrom >= _amount);

         
         
        updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

         
         
        uint previousBalanceTo = balanceOfAt(_to, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);

         
        emit Transfer(_from, _to, _amount);

    }

     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function increaseApproval(address _spender, uint _addedAmount) external returns (bool) {
        require(allowed[msg.sender][_spender] + _addedAmount >= allowed[msg.sender][_spender]);  
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedAmount;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedAmount) external returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedAmount >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedAmount;
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


     
     
     
     
     
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes calldata _extraData) external returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            address(this),
            _extraData
        );

        return true;
    }

     
     
    function totalSupply() public view returns (uint) {
        return totalSupplyAt(block.number);
    }


     
     
     

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint) {

         
         
         
         
         
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            return 0;
             
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
    function totalSupplyAt(uint _blockNumber) public view returns(uint) {

         
         
         
         
         
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            return 0;
             
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

     
     
     

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) view internal returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal  {
        if ((checkpoints.length == 0)
            || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
            newCheckPoint.fromBlock =  uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
    }


     
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }




     
     
     
     
    function generateTokens(address _owner, uint _amount) public onlyOwner returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        emit Transfer(address(0), _owner, _amount);
        return true;
    }

     
     
     

     
     
     
     
    function claimTokens(address _token) external onlyOwner {
        if (_token == address(0)) {
            owner.transfer(address(this).balance);
            return;
        }

        Token token = Token(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }
}


contract DividendManager is Ownable {
    using SafeMath for uint;

    event DividendDeposited(address indexed _depositor, uint256 _blockNumber, uint256 _amount, uint256 _totalSupply, uint256 _dividendIndex);
    event DividendClaimed(address indexed _claimer, uint256 _dividendIndex, uint256 _claim);
    event DividendRecycled(address indexed _recycler, uint256 _blockNumber, uint256 _amount, uint256 _totalSupply, uint256 _dividendIndex);

    Token public token;

    uint256 public RECYCLE_TIME = 365 days;

    struct Dividend {
        uint256 blockNumber;
        uint256 timestamp;
        uint256 amount;
        uint256 claimedAmount;
        uint256 totalSupply;
        bool recycled;
        mapping (address => bool) claimed;
    }

    Dividend[] public dividends;

    mapping (address => uint256) dividendsClaimed;

    modifier validDividendIndex(uint256 _dividendIndex) {
        require(_dividendIndex < dividends.length);
        _;
    }

    constructor(address _token) public {
        require(_token != address(0));
        token = Token(_token);
    }

    function depositDividend() payable public {
        uint256 currentSupply = token.totalSupplyAt(block.number);
        uint256 dividendIndex = dividends.length;
        uint256 blockNumber = SafeMath.sub(block.number, 1);
        dividends.push(
            Dividend(
                blockNumber,
                getNow(),
                msg.value,
                0,
                currentSupply,
                false
            )
        );
        emit DividendDeposited(msg.sender, blockNumber, msg.value, currentSupply, dividendIndex);
    }

    function claimDividend(uint256 _dividendIndex) public
    validDividendIndex(_dividendIndex)
    {
        Dividend storage dividend = dividends[_dividendIndex];
        require(dividend.claimed[msg.sender] == false);
        require(dividend.recycled == false);
        uint256 balance = token.balanceOfAt(msg.sender, dividend.blockNumber);
        uint256 claim = balance.mul(dividend.amount).div(dividend.totalSupply);
        dividend.claimed[msg.sender] = true;
        dividend.claimedAmount = SafeMath.add(dividend.claimedAmount, claim);
        if (claim > 0) {
            msg.sender.transfer(claim);
            emit DividendClaimed(msg.sender, _dividendIndex, claim);
        }
    }

    function claimDividendAll() public {
        require(dividendsClaimed[msg.sender] < dividends.length);
        for (uint i = dividendsClaimed[msg.sender]; i < dividends.length; i++) {
            if ((dividends[i].claimed[msg.sender] == false) && (dividends[i].recycled == false)) {
                dividendsClaimed[msg.sender] = SafeMath.add(i, 1);
                claimDividend(i);
            }
        }
    }

    function recycleDividend(uint256 _dividendIndex) public
    onlyOwner
    validDividendIndex(_dividendIndex)
    {
        Dividend storage dividend = dividends[_dividendIndex];
        require(dividend.recycled == false);
        require(dividend.timestamp < SafeMath.sub(getNow(), RECYCLE_TIME));
        dividends[_dividendIndex].recycled = true;
        uint256 currentSupply = token.totalSupplyAt(block.number);
        uint256 remainingAmount = SafeMath.sub(dividend.amount, dividend.claimedAmount);
        uint256 dividendIndex = dividends.length;
        uint256 blockNumber = SafeMath.sub(block.number, 1);
        dividends.push(
            Dividend(
                blockNumber,
                getNow(),
                remainingAmount,
                0,
                currentSupply,
                false
            )
        );
        emit DividendRecycled(msg.sender, blockNumber, remainingAmount, currentSupply, dividendIndex);
    }

     
    function getNow() internal view returns (uint256) {
        return now;
    }

    function dividendsCount() external view returns (uint) {
        return dividends.length;
    }

     
     
     
     
    function claimTokens(address _token) external onlyOwner {
         
         
         
         

        Token claimToken = Token(_token);
        uint balance = claimToken.balanceOf(address(this));
        claimToken.transfer(owner, balance);
    }
}


 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeERC20 {
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}


contract sellTokens is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;
    address payable public wallet;

    uint256 public rate;
    uint256 public minPurchase;

    uint256 public weiRaised;
    uint256 public tokenSold;

    event TokenPurchase(address indexed owner, uint weiAmount, uint tokens);


    constructor(address payable _wallet, uint256 _rate, address _token, uint256 _minPurchase) public {
        require(_token != address(0));
        require(_wallet != address(0));
        require(_rate > 0);

        token = IERC20(_token);
        wallet = _wallet;
        rate = _rate;
        minPurchase = _minPurchase;
    }


    function() payable external {
        buyTokens();
    }


    function buyTokens() payable public {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(weiAmount);

        uint256 tokens = _getTokenAmount(weiAmount);

        if (tokens > token.balanceOf(address(this))) {
            tokens = token.balanceOf(address(this));

            uint price = tokens.div(rate);

            uint _diff =  weiAmount.sub(price);

            if (_diff > 0) {
                msg.sender.transfer(_diff);
                weiAmount = weiAmount.sub(_diff);
            }
        }

        weiRaised = weiRaised.add(weiAmount);
        tokenSold = tokenSold.add(tokens);
        _processPurchase(msg.sender, tokens);

        emit TokenPurchase(msg.sender, weiAmount, tokens);

        _forwardFunds();
    }


    function _preValidatePurchase(uint256 _weiAmount) internal view {
        require(token.balanceOf(address(this)) > 0);
        require(_weiAmount >= minPurchase);
    }


    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate);
    }


    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        token.safeTransfer(_beneficiary, _tokenAmount);
    }


    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }


    function setRate(uint256 _rate) onlyOwner external {
        rate = _rate;
    }


    function setMinPurchase(uint256 _minPurchase) onlyOwner external {
        minPurchase = _minPurchase;
    }

    function withdrawTokens(address _t) onlyOwner external {
        IERC20 _token = IERC20(_t);
        uint balance = _token.balanceOf(address(this));
        _token.safeTransfer(owner, balance);
    }
}


contract CompanyLog is Ownable {
    struct Log {
        uint time;
        uint id;
        uint price;
        string description;
    }

    mapping (uint => Log) public logs;
    uint public lastLogId;

    event NewLog(uint time, uint id, uint price, string description);

    function addLog(uint _time, uint _id, uint _price, string calldata _description) onlyManager external {
        uint256 _logId = lastLogId++;

        logs[_logId] = Log({
            time : _time,
            id : _id,
            price : _price,
            description: _description
            });

        emit NewLog(_time, _id, _price, _description);
    }
}