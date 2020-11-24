 

pragma solidity ^0.4.15;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


 

 
 
 
 
 
 
 


 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint256 _amount) returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint256 _amount)
    returns(bool);
}

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
}

 
 
 
contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.1';  


     
     
     
    struct  Checkpoint {

     
    uint128 fromBlock;

     
    uint128 value;
    }

     
     
    MiniMeToken public parentToken;

     
     
    uint256 public parentSnapShotBlock;

     
    uint256 public creationBlock;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;

     
    bool public transfersEnabled;

     
    MiniMeTokenFactory public tokenFactory;

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint256 _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


     
     
     

     
     
     
     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            if (allowed[_from][msg.sender] < _amount) return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint256 _amount
    ) internal returns(bool) {

        if (_amount == 0) {
            return true;
        }

        require(parentSnapShotBlock < block.number);

         
        require((_to != 0) && (_to != address(this)));

         
         
        var previousBalanceFrom = balanceOfAt(_from, block.number);
        if (previousBalanceFrom < _amount) {
            return false;
        }

         
        if (isContract(controller)) {
            require(TokenController(controller).onTransfer(_from, _to, _amount));
        }

         
         
        updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

         
         
        var previousBalanceTo = balanceOfAt(_to, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);

         
        Transfer(_from, _to, _amount);

        return true;
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) returns (bool success) {
        require(transfersEnabled);

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

         
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
        msg.sender,
        _amount,
        this,
        _extraData
        );

        return true;
    }

     
     
    function totalSupply() constant returns (uint) {
        return totalSupplyAt(block.number);
    }

     
     
     

     
     
     
     
    function balanceOfAt(address _owner, uint256 _blockNumber) constant
    returns (uint) {

         
         
         
         
         
        if ((balances[_owner].length == 0)
        || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                 
                return 0;
            }

             
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
    function totalSupplyAt(uint256 _blockNumber) constant returns(uint) {

         
         
         
         
         
        if ((totalSupplyHistory.length == 0)
        || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

             
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

     
     
     

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
    string _cloneTokenName,
    uint8 _cloneDecimalUnits,
    string _cloneTokenSymbol,
    uint256 _snapshotBlock,
    bool _transfersEnabled
    ) returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
        this,
        _snapshotBlock,
        _cloneTokenName,
        _cloneDecimalUnits,
        _cloneTokenSymbol,
        _transfersEnabled
        );

        cloneToken.changeController(msg.sender);

         
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

     
     
     

     
     
     
     
    function generateTokens(address _owner, uint256 _amount
    ) onlyController returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint256 previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint256 _amount
    ) onlyController returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint256 previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

     
     
     

     
     
    function enableTransfers(bool _transfersEnabled) onlyController {
        transfersEnabled = _transfersEnabled;
    }

     
     
     

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint256 _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
        return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint256 min = 0;
        uint256 max = checkpoints.length-1;
        while (max > min) {
            uint256 mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint256 _value
    ) internal  {
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

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint256 size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

     
    function min(uint256 a, uint256 b) internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function ()  payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

     
     
     

     
     
     
     
    function claimTokens(address _token) onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

     
     
     
    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint256 _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );

}

 
 
 

 
 
 
contract MiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        address _parentToken,
        uint256 _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
        );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

contract TokenBurner {
    function burn(address , uint256 )
    returns (bool result) {
        return false;
    }
}

contract FiinuToken is MiniMeToken, Ownable {

    TokenBurner public tokenBurner;

    function FiinuToken(address _tokenFactory)
    MiniMeToken(
        _tokenFactory,
        0x0,                      
        0,                        
        "Fiinu Token",            
        6,                        
        "FNU",                    
        true                     
    )
    {}

    function setTokenBurner(address _tokenBurner) onlyOwner {
        tokenBurner = TokenBurner(_tokenBurner);
    }

     
     
     
    function burn(uint256 _amount) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint256 previousBalanceFrom = balanceOf(msg.sender);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[msg.sender], previousBalanceFrom - _amount);
        assert(tokenBurner.burn(msg.sender, _amount));
        Transfer(msg.sender, 0, _amount);
    }

}

contract Milestones is Ownable {

    enum State { PreIco, IcoOpen, IcoClosed, IcoSuccessful, IcoFailed, BankLicenseSuccessful, BankLicenseFailed }

    event Milestone(string _announcement, State _state);

    State public state = State.PreIco;
    bool public tradingOpen = false;

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    modifier isTradingOpen() {
        require(tradingOpen);
        _;
    }

    function Milestone_OpenTheIco(string _announcement) onlyOwner inState(State.PreIco) {
        state = State.IcoOpen;
        Milestone(_announcement, state);
    }

    function Milestone_CloseTheIco(string _announcement) onlyOwner inState(State.IcoOpen) {
        state = State.IcoClosed;
        Milestone(_announcement, state);
    }

    function Milestone_IcoSuccessful(string _announcement) onlyOwner inState(State.IcoClosed) {
        state = State.IcoSuccessful;
        Milestone(_announcement, state);
    }

    function Milestone_IcoFailed(string _announcement) onlyOwner inState(State.IcoClosed) {
        state = State.IcoFailed;
        Milestone(_announcement, state);
    }

    function Milestone_BankLicenseSuccessful(string _announcement) onlyOwner inState(State.IcoSuccessful) {
        tradingOpen = true;
        state = State.BankLicenseSuccessful;
        Milestone(_announcement, state);
    }

    function Milestone_BankLicenseFailed(string _announcement) onlyOwner inState(State.IcoSuccessful) {
        state = State.BankLicenseFailed;
        Milestone(_announcement, state);
    }

}

contract Investors is Milestones {

    struct WhitelistEntry {
        uint256 max;
        uint256 total;
        bool init;
    }

    mapping(address => bool) internal admins;
    mapping(address => WhitelistEntry) approvedInvestors;

    modifier onlyAdmins() {
        require(admins[msg.sender] == true);
        _;
    }

    function manageInvestors(address _investors_wallet_address, uint256 _max_approved_investment) onlyAdmins {
        if(approvedInvestors[_investors_wallet_address].init){
            approvedInvestors[_investors_wallet_address].max = SafeMath.mul(_max_approved_investment, 10 ** 18);  
             
            if(approvedInvestors[_investors_wallet_address].max == 0 && approvedInvestors[_investors_wallet_address].total == 0)
            delete approvedInvestors[_investors_wallet_address];
        }
        else{
            approvedInvestors[_investors_wallet_address] = WhitelistEntry(SafeMath.mul(_max_approved_investment, 10 ** 18), 0, true);
        }
    }

    function manageAdmins(address _address, bool _add) onlyOwner {
        admins[_address] = _add;
    }

}

contract FiinuCrowdSale is TokenController, Investors {
    using SafeMath for uint256;

    event Investment(address indexed _investor, uint256 _valueEth, uint256 _valueFnu);
    event RefundAdded(address indexed _refunder, uint256 _valueEth);
    event RefundEnabled(uint256 _valueEth);

    address wallet;
    address public staff_1 = 0x2717FCee32b2896E655Ad82EfF81987A34EFF3E7;
    address public staff_2 = 0x7ee4471C371e581Af42b280CD19Ed7593BD7D15F;
    address public staff_3 = 0xE6BeCcc43b48416CE69B6d03c2e44E2B7b8F77b4;
    address public staff_4 = 0x3369De7Ff98bd5C225a67E09ac81aFa7b5dF3d3d;

    uint256 constant minRaisedWei = 20000 ether;
    uint256 constant targetRaisedWei = 100000 ether;
    uint256 constant maxRaisedWei = 400000 ether;
    uint256 public raisedWei = 0;
    uint256 public refundWei = 0;

    bool public refundOpen = false;

    MiniMeToken public tokenContract;    

    function FiinuCrowdSale(address _wallet, address _tokenAddress) {
        wallet = _wallet;  
        tokenContract = MiniMeToken(_tokenAddress); 
    }

     
     
     

     
     
     

    function proxyPayment(address _owner) payable returns(bool) {
        return false;
    }

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint256 _amount) returns(bool) {
        return tradingOpen;
    }

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint256 _amount)
    returns(bool)
    {
        return true;
    }

    function weiToFNU(uint256 _wei) public constant returns (uint){
        uint256 _return;
         
        if(state == State.PreIco){
            _return = _wei.add(_wei.div(3));
        }
        else {
             
            if(raisedWei < targetRaisedWei){
                _return = _wei;
            } else {
                 
                _return = _wei.mul(targetRaisedWei).div(raisedWei);
            }
        }
         
        return _return.div(10 ** 12);
    }

    function () payable {  

        require(msg.value != 0);  
        require(state == State.PreIco || state == State.IcoOpen);
        require(approvedInvestors[msg.sender].init == true);  
        require(approvedInvestors[msg.sender].max >= approvedInvestors[msg.sender].total.add(msg.value));  
        require(maxRaisedWei >= raisedWei.add(msg.value));  

        uint256 _fnu = weiToFNU(msg.value);
        require(_fnu > 0);

        raisedWei = raisedWei.add(msg.value);
        approvedInvestors[msg.sender].total = approvedInvestors[msg.sender].total.add(msg.value);  
        mint(msg.sender, _fnu);  
        wallet.transfer(msg.value);  
        Investment(msg.sender, msg.value, _fnu);  
    }

    function refund() payable {
        require(msg.value != 0);  
        require(state == State.IcoClosed || state == State.IcoSuccessful || state == State.IcoFailed || state == State.BankLicenseFailed);
        refundWei = refundWei.add(msg.value);
        RefundAdded(msg.sender, msg.value);
    }

    function Milestone_IcoSuccessful(string _announcement) onlyOwner {
        require(raisedWei >= minRaisedWei);
        uint256 _toBeAllocated = tokenContract.totalSupply();
        _toBeAllocated = _toBeAllocated.div(10);
        mint(staff_1, _toBeAllocated.mul(81).div(100));  
        mint(staff_2, _toBeAllocated.mul(9).div(100));  
        mint(staff_3, _toBeAllocated.mul(15).div(1000));   
        mint(staff_4, _toBeAllocated.mul(15).div(1000));  
        mint(owner, _toBeAllocated.mul(7).div(100));  
        super.Milestone_IcoSuccessful(_announcement);
    }

    function Milestone_IcoFailed(string _announcement) onlyOwner {
        require(raisedWei < minRaisedWei);
        super.Milestone_IcoFailed(_announcement);
    }

    function Milestone_BankLicenseFailed(string _announcement) onlyOwner {
         
        burn(staff_1);
        burn(staff_2);
        burn(staff_3);
        burn(staff_4);
        burn(owner);
        super.Milestone_BankLicenseFailed(_announcement);
    }

    function EnableRefund() onlyOwner {
        require(state == State.IcoFailed || state == State.BankLicenseFailed);
        require(refundWei > 0);
        refundOpen = true;
        RefundEnabled(refundWei);
    }

     
    function RequestRefund() public {
        require(refundOpen);
        require(state == State.IcoFailed || state == State.BankLicenseFailed);
        require(tokenContract.balanceOf(msg.sender) > 0);  
         
        uint256 refundAmount = refundWei.mul(approvedInvestors[msg.sender].total).div(raisedWei);
        burn(msg.sender);
        msg.sender.transfer(refundAmount);
    }

     
    function mint(address _to, uint256 _tokens) internal {
        tokenContract.generateTokens(_to, _tokens);
    }

     
    function burn(address _address) internal {
        tokenContract.destroyTokens(_address, tokenContract.balanceOf(_address));
    }
}

contract ProfitSharing is Ownable {
    using SafeMath for uint256;

    event DividendDeposited(address indexed _depositor, uint256 _blockNumber, uint256 _amount, uint256 _totalSupply, uint256 _dividendIndex);
    event DividendClaimed(address indexed _claimer, uint256 _dividendIndex, uint256 _claim);
    event DividendRecycled(address indexed _recycler, uint256 _blockNumber, uint256 _amount, uint256 _totalSupply, uint256 _dividendIndex);

    MiniMeToken public token;

    uint256 public RECYCLE_TIME = 1 years;

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

    function ProfitSharing(address _token) {
        token = MiniMeToken(_token);
    }

    function depositDividend() payable
    onlyOwner
    {
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
        DividendDeposited(msg.sender, blockNumber, msg.value, currentSupply, dividendIndex);
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
            DividendClaimed(msg.sender, _dividendIndex, claim);
        }
    }

    function claimDividendAll() public {
        require(dividendsClaimed[msg.sender] < dividends.length);
        for (uint256 i = dividendsClaimed[msg.sender]; i < dividends.length; i++) {
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
        DividendRecycled(msg.sender, blockNumber, remainingAmount, currentSupply, dividendIndex);
    }

     
    function getNow() internal constant returns (uint256) {
        return now;
    }

}