 

pragma solidity ^0.5.0;

 

 
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
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

 

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

 

 



 
library AssetTokenL {
    using SafeMath for uint256;

 
 
 

    struct Supply {
         
         
         
        mapping (address => Checkpoint[]) balances;

         
        Checkpoint[] totalSupplyHistory;

         
        mapping (address => mapping (address => uint256)) allowed;

         
        uint256 cap;

         
        uint256 goal;

         
        uint256 startTime;

         
        uint256 endTime;

         
        Dividend[] dividends;

         
         
        mapping (address => uint256) dividendsClaimed;

        uint256 tokenActionIndex;  
    }

    struct Availability {
         
         
        bool tokenAlive;

         
        bool transfersEnabled;

         
        bool mintingPhaseFinished;

         
        bool mintingPaused;
    }

    struct Roles {
         
        address pauseControl;

         
        address tokenRescueControl;

         
        address mintControl;
    }

 
 
 

     
    struct Dividend {
        uint256 currentTokenActionIndex;
        uint256 timestamp;
        DividendType dividendType;
        address dividendToken;
        uint256 amount;
        uint256 claimedAmount;
        uint256 totalSupply;
        bool recycled;
        mapping (address => bool) claimed;
    }

     
    enum DividendType { Ether, ERC20 }

     
    struct Checkpoint {

         
        uint128 currentTokenActionIndex;

         
        uint128 value;
    }

 
 
 

     
     
     
     
     
     
    function doTransfer(Supply storage _self, Availability storage  , address _from, address _to, uint256 _amount) public {
         
        require(_to != address(0), "addr0");
        require(_to != address(this), "target self");

         
         
        uint256 previousBalanceFrom = balanceOfNow(_self, _from);
        require(previousBalanceFrom >= _amount, "not enough");

         
         
        updateValueAtNow(_self, _self.balances[_from], previousBalanceFrom.sub(_amount));

         
         
        uint256 previousBalanceTo = balanceOfNow(_self, _to);
        
        updateValueAtNow(_self, _self.balances[_to], previousBalanceTo.add(_amount));

         
        increaseTokenActionIndex(_self);

         
        emit Transfer(_from, _to, _amount);
    }

    function increaseTokenActionIndex(Supply storage _self) private {
        _self.tokenActionIndex = _self.tokenActionIndex.add(1);

        emit TokenActionIndexIncreased(_self.tokenActionIndex, block.number);
    }

     
     
     
     
    function approve(Supply storage _self, address _spender, uint256 _amount) public returns (bool success) {
         
         
         
         
        require((_amount == 0) || (_self.allowed[msg.sender][_spender] == 0), "amount");

        _self.allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
     
     
     
    function increaseApproval(Supply storage _self, address _spender, uint256 _addedValue) public returns (bool) {
        _self.allowed[msg.sender][_spender] = _self.allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, _self.allowed[msg.sender][_spender]);
        return true;
    }

     
     
     
     
     
     
     
     
    function decreaseApproval(Supply storage _self, address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = _self.allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            _self.allowed[msg.sender][_spender] = 0;
        } else {
            _self.allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, _self.allowed[msg.sender][_spender]);
        return true;
    }

     
     
     
     
     
    function transferFrom(Supply storage _supply, Availability storage _availability, address _from, address _to, uint256 _amount) 
    public 
    returns (bool success) 
    {
         
        require(_supply.allowed[_from][msg.sender] >= _amount, "allowance");
        _supply.allowed[_from][msg.sender] = _supply.allowed[_from][msg.sender].sub(_amount);

        doTransfer(_supply, _availability, _from, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function enforcedTransferFrom(
        Supply storage _self, 
        Availability storage _availability, 
        address _from, 
        address _to, 
        uint256 _amount, 
        bool _fullAmountRequired) 
    public 
    returns (bool success) 
    {
        if(_fullAmountRequired && _amount != balanceOfNow(_self, _from))
        {
            revert("Only full amount in case of lost wallet is allowed");
        }

        doTransfer(_self, _availability, _from, _to, _amount);

        emit SelfApprovedTransfer(msg.sender, _from, _to, _amount);

        return true;
    }

 
 
 

     
     
     
     
    function mint(Supply storage _self, address _to, uint256 _amount) public returns (bool) {
        uint256 curTotalSupply = totalSupplyNow(_self);
        uint256 previousBalanceTo = balanceOfNow(_self, _to);

         
        require(curTotalSupply.add(_amount) <= _self.cap, "cap");  

         
        require(_self.startTime <= now, "too soon");
        require(_self.endTime >= now, "too late");

        updateValueAtNow(_self, _self.totalSupplyHistory, curTotalSupply.add(_amount));
        updateValueAtNow(_self, _self.balances[_to], previousBalanceTo.add(_amount));

         
        increaseTokenActionIndex(_self);

        emit MintDetailed(msg.sender, _to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }

 
 
 

     
     
     
     
    function balanceOfAt(Supply storage _self, address _owner, uint256 _specificTransfersAndMintsIndex) public view returns (uint256) {
        return getValueAt(_self.balances[_owner], _specificTransfersAndMintsIndex);
    }

    function balanceOfNow(Supply storage _self, address _owner) public view returns (uint256) {
        return getValueAt(_self.balances[_owner], _self.tokenActionIndex);
    }

     
     
     
    function totalSupplyAt(Supply storage _self, uint256 _specificTransfersAndMintsIndex) public view returns(uint256) {
        return getValueAt(_self.totalSupplyHistory, _specificTransfersAndMintsIndex);
    }

    function totalSupplyNow(Supply storage _self) public view returns(uint256) {
        return getValueAt(_self.totalSupplyHistory, _self.tokenActionIndex);
    }

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint256 _specificTransfersAndMintsIndex) private view returns (uint256) { 
        
         
        if (checkpoints.length == 0 || checkpoints[0].currentTokenActionIndex > _specificTransfersAndMintsIndex) {
            return 0;
        }

         
        if (_specificTransfersAndMintsIndex >= checkpoints[checkpoints.length-1].currentTokenActionIndex) {
            return checkpoints[checkpoints.length-1].value;
        }

         
        uint256 min = 0;
        uint256 max = checkpoints.length-1;
        while (max > min) {
            uint256 mid = (max + min + 1)/2;
            if (checkpoints[mid].currentTokenActionIndex<=_specificTransfersAndMintsIndex) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
    function updateValueAtNow(Supply storage _self, Checkpoint[] storage checkpoints, uint256 _value) private {
        require(_value == uint128(_value), "invalid cast1");
        require(_self.tokenActionIndex == uint128(_self.tokenActionIndex), "invalid cast2");

        checkpoints.push(Checkpoint(
            uint128(_self.tokenActionIndex),
            uint128(_value)
        ));
    }

     
     
    function finishMinting(Availability storage _self) public returns (bool) {
        if(_self.mintingPhaseFinished) {
            return false;
        }

        _self.mintingPhaseFinished = true;
        emit MintFinished(msg.sender);
        return true;
    }

     
     
    function reopenCrowdsale(Availability storage _self) public returns (bool) {
        if(_self.mintingPhaseFinished == false) {
            return false;
        }

        _self.mintingPhaseFinished = false;
        emit Reopened(msg.sender);
        return true;
    }

     
     
     
    function setRoles(Roles storage _self, address _pauseControl, address _tokenRescueControl) public {
        require(_pauseControl != address(0), "addr0");
        require(_tokenRescueControl != address(0), "addr0");
        
        _self.pauseControl = _pauseControl;
        _self.tokenRescueControl = _tokenRescueControl;

        emit RolesChanged(msg.sender, _pauseControl, _tokenRescueControl);
    }

     
    function setMintControl(Roles storage _self, address _mintControl) public {
        require(_mintControl != address(0), "addr0");

        _self.mintControl = _mintControl;

        emit MintControlChanged(msg.sender, _mintControl);
    }

     
    function setTokenAlive(Availability storage _self) public {
        _self.tokenAlive = true;
    }

 
 
 

     
     
    function pauseTransfer(Availability storage _self, bool _transfersEnabled) public
    {
        _self.transfersEnabled = _transfersEnabled;

        if(_transfersEnabled) {
            emit TransferResumed(msg.sender);
        } else {
            emit TransferPaused(msg.sender);
        }
    }

     
     
    function pauseCapitalIncreaseOrDecrease(Availability storage _self, bool _mintingEnabled) public
    {
        _self.mintingPaused = (_mintingEnabled == false);

        if(_mintingEnabled) {
            emit MintingResumed(msg.sender);
        } else {
            emit MintingPaused(msg.sender);
        }
    }

     
    function depositDividend(Supply storage _self, uint256 msgValue)
    public 
    {
        require(msgValue > 0, "amount0");

         
        uint256 currentSupply = totalSupplyNow(_self);

         
        require(currentSupply > 0, "0investors");

         
        uint256 dividendIndex = _self.dividends.length;

         
        _self.dividends.push(
            Dividend(
                _self.tokenActionIndex,  
                block.timestamp,  
                DividendType.Ether,  
                address(0),
                msgValue,  
                0,  
                currentSupply,  
                false  
            )
        );
        emit DividendDeposited(msg.sender, _self.tokenActionIndex, msgValue, currentSupply, dividendIndex);
    }

     
    function depositERC20Dividend(Supply storage _self, address _dividendToken, uint256 _amount, address baseCurrency)
    public
    {
        require(_amount > 0, "amount0");
        require(_dividendToken == baseCurrency, "not baseCurrency");

         
        uint256 currentSupply = totalSupplyNow(_self);

         
        require(currentSupply > 0, "0investors");

         
        uint256 dividendIndex = _self.dividends.length;

         
        _self.dividends.push(
            Dividend(
                _self.tokenActionIndex,  
                block.timestamp,  
                DividendType.ERC20, 
                _dividendToken, 
                _amount,  
                0,  
                currentSupply,  
                false  
            )
        );

         
         
        require(ERC20(_dividendToken).transferFrom(msg.sender, address(this), _amount), "transferFrom");

        emit DividendDeposited(msg.sender, _self.tokenActionIndex, _amount, currentSupply, dividendIndex);
    }

     
     
    function claimDividend(Supply storage _self, uint256 _dividendIndex) public {
         
        Dividend storage dividend = _self.dividends[_dividendIndex];

         
        require(dividend.claimed[msg.sender] == false, "claimed");

          
        require(dividend.recycled == false, "recycled");

         
        uint256 balance = balanceOfAt(_self, msg.sender, dividend.currentTokenActionIndex.sub(1));

         
        uint256 claim = balance.mul(dividend.amount).div(dividend.totalSupply);

         
        dividend.claimed[msg.sender] = true;
        dividend.claimedAmount = SafeMath.add(dividend.claimedAmount, claim);

        claimThis(dividend.dividendType, _dividendIndex, msg.sender, claim, dividend.dividendToken);
    }

     
     
    function claimDividendAll(Supply storage _self) public {
        claimLoopInternal(_self, _self.dividendsClaimed[msg.sender], (_self.dividends.length-1));
    }

     
     
     
     
    function claimInBatches(Supply storage _self, uint256 _startIndex, uint256 _endIndex) public {
        claimLoopInternal(_self, _startIndex, _endIndex);
    }

     
     
     
     
    function claimLoopInternal(Supply storage _self, uint256 _startIndex, uint256 _endIndex) private {
        require(_startIndex <= _endIndex, "start after end");

         
        require(_self.dividendsClaimed[msg.sender] < _self.dividends.length, "all claimed");

        uint256 dividendsClaimedTemp = _self.dividendsClaimed[msg.sender];

         
        for (uint256 i = _startIndex; i <= _endIndex; i++) {
            if (_self.dividends[i].recycled == true) {
                 
                dividendsClaimedTemp = SafeMath.add(i, 1);
            }
            else if (_self.dividends[i].claimed[msg.sender] == false) {
                dividendsClaimedTemp = SafeMath.add(i, 1);
                claimDividend(_self, i);
            }
        }

         
         
         
        if(_startIndex <= _self.dividendsClaimed[msg.sender]) {
            _self.dividendsClaimed[msg.sender] = dividendsClaimedTemp;
        }
    }

     
     
     
     
    function recycleDividend(Supply storage _self, uint256 _dividendIndex, uint256 _recycleLockedTimespan, uint256 _currentSupply) public {
         
        Dividend storage dividend = _self.dividends[_dividendIndex];

         
        require(dividend.recycled == false, "recycled");

         
        require(dividend.timestamp < SafeMath.sub(block.timestamp, _recycleLockedTimespan), "timeUp");

         
        require(dividend.claimed[msg.sender] == false, "claimed");

         
         
         

         
        _self.dividends[_dividendIndex].recycled = true;

         
        uint256 claim = SafeMath.sub(dividend.amount, dividend.claimedAmount);

         
        dividend.claimed[msg.sender] = true;
        dividend.claimedAmount = SafeMath.add(dividend.claimedAmount, claim);

        claimThis(dividend.dividendType, _dividendIndex, msg.sender, claim, dividend.dividendToken);

        emit DividendRecycled(msg.sender, _self.tokenActionIndex, claim, _currentSupply, _dividendIndex);
    }

     
    function claimThis(DividendType _dividendType, uint256 _dividendIndex, address payable _beneficiary, uint256 _claim, address _dividendToken) 
    private 
    {
         
        if (_claim > 0) {
            if (_dividendType == DividendType.Ether) { 
                _beneficiary.transfer(_claim);
            } 
            else if (_dividendType == DividendType.ERC20) { 
                require(ERC20(_dividendToken).transfer(_beneficiary, _claim), "transfer");
            }
            else {
                revert("unknown type");
            }

            emit DividendClaimed(_beneficiary, _dividendIndex, _claim);
        }
    }

     
     
     
    function rescueToken(Availability storage _self, address _foreignTokenAddress, address _to) public
    {
        require(_self.mintingPhaseFinished, "unfinished");
        ERC20(_foreignTokenAddress).transfer(_to, ERC20(_foreignTokenAddress).balanceOf(address(this)));
    }

 
 
 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event SelfApprovedTransfer(address indexed initiator, address indexed from, address indexed to, uint256 value);
    event MintDetailed(address indexed initiator, address indexed to, uint256 amount);
    event MintFinished(address indexed initiator);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TransferPaused(address indexed initiator);
    event TransferResumed(address indexed initiator);
    event MintingPaused(address indexed initiator);
    event MintingResumed(address indexed initiator);
    event Reopened(address indexed initiator);
    event DividendDeposited(address indexed depositor, uint256 transferAndMintIndex, uint256 amount, uint256 totalSupply, uint256 dividendIndex);
    event DividendClaimed(address indexed claimer, uint256 dividendIndex, uint256 claim);
    event DividendRecycled(address indexed recycler, uint256 transferAndMintIndex, uint256 amount, uint256 totalSupply, uint256 dividendIndex);
    event RolesChanged(address indexed initiator, address pauseControl, address tokenRescueControl);
    event MintControlChanged(address indexed initiator, address mintControl);
    event TokenActionIndexIncreased(uint256 tokenActionIndex, uint256 blocknumber);
}

 

contract IBasicAssetTokenFull {
    function checkCanSetMetadata() internal returns (bool);

    function getCap() public view returns (uint256);
    function getGoal() public view returns (uint256);
    function getStart() public view returns (uint256);
    function getEnd() public view returns (uint256);
    function getLimits() public view returns (uint256, uint256, uint256, uint256);
    function setMetaData(
        string calldata _name, 
        string calldata _symbol, 
        address _tokenBaseCurrency, 
        uint256 _cap, 
        uint256 _goal, 
        uint256 _startTime, 
        uint256 _endTime) 
        external;
    
    function getTokenRescueControl() public view returns (address);
    function getPauseControl() public view returns (address);
    function isTransfersPaused() public view returns (bool);

    function setMintControl(address _mintControl) public;
    function setRoles(address _pauseControl, address _tokenRescueControl) public;

    function setTokenAlive() public;
    function isTokenAlive() public view returns (bool);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function approve(address _spender, uint256 _amount) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    function totalSupply() public view returns (uint256);

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool);

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool);

    function finishMinting() public returns (bool);

    function rescueToken(address _foreignTokenAddress, address _to) public;

    function balanceOfAt(address _owner, uint256 _specificTransfersAndMintsIndex) public view returns (uint256);

    function totalSupplyAt(uint256 _specificTransfersAndMintsIndex) public view returns(uint256);

    function enableTransfers(bool _transfersEnabled) public;

    function pauseTransfer(bool _transfersEnabled) public;

    function pauseCapitalIncreaseOrDecrease(bool _mintingEnabled) public;    

    function isMintingPaused() public view returns (bool);

    function mint(address _to, uint256 _amount) public returns (bool);

    function transfer(address _to, uint256 _amount) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);

    function enableTransferInternal(bool _transfersEnabled) internal;

    function reopenCrowdsaleInternal() internal returns (bool);

    function transferFromInternal(address _from, address _to, uint256 _amount) internal returns (bool success);
    function enforcedTransferFromInternal(address _from, address _to, uint256 _value, bool _fullAmountRequired) internal returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event MintDetailed(address indexed initiator, address indexed to, uint256 amount);
    event MintFinished(address indexed initiator);
    event TransferPaused(address indexed initiator);
    event TransferResumed(address indexed initiator);
    event Reopened(address indexed initiator);
    event MetaDataChanged(address indexed initiator, string name, string symbol, address baseCurrency, uint256 cap, uint256 goal, uint256 startTime, uint256 endTime);
    event RolesChanged(address indexed initiator, address _pauseControl, address _tokenRescueControl);
    event MintControlChanged(address indexed initiator, address mintControl);
}

 

 





 
contract BasicAssetToken is IBasicAssetTokenFull, Ownable {

    using SafeMath for uint256;
    using AssetTokenL for AssetTokenL.Supply;
    using AssetTokenL for AssetTokenL.Availability;
    using AssetTokenL for AssetTokenL.Roles;

 
 
 

    string private _name;
    string private _symbol;

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function decimals() public pure returns (uint8) {
        return 0;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    uint16 public constant version = 2000;

     
    address public baseCurrency;

     
    AssetTokenL.Supply supply;

     
    AssetTokenL.Availability availability;

     
    AssetTokenL.Roles roles;

 
 
 

    function isMintingPaused() public view returns (bool) {
        return availability.mintingPaused;
    }

    function isMintingPhaseFinished() public view returns (bool) {
        return availability.mintingPhaseFinished;
    }

    function getPauseControl() public view returns (address) {
        return roles.pauseControl;
    }

    function getTokenRescueControl() public view returns (address) {
        return roles.tokenRescueControl;
    }

    function getMintControl() public view returns (address) {
        return roles.mintControl;
    }

    function isTransfersPaused() public view returns (bool) {
        return !availability.transfersEnabled;
    }

    function isTokenAlive() public view returns (bool) {
        return availability.tokenAlive;
    }

    function getCap() public view returns (uint256) {
        return supply.cap;
    }

    function getGoal() public view returns (uint256) {
        return supply.goal;
    }

    function getStart() public view returns (uint256) {
        return supply.startTime;
    }

    function getEnd() public view returns (uint256) {
        return supply.endTime;
    }

    function getLimits() public view returns (uint256, uint256, uint256, uint256) {
        return (supply.cap, supply.goal, supply.startTime, supply.endTime);
    }

    function getCurrentHistoryIndex() public view returns (uint256) {
        return supply.tokenActionIndex;
    }

 
 
 

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event MintDetailed(address indexed initiator, address indexed to, uint256 amount);
    event MintFinished(address indexed initiator);
    event TransferPaused(address indexed initiator);
    event TransferResumed(address indexed initiator);
    event MintingPaused(address indexed initiator);
    event MintingResumed(address indexed initiator);
    event Reopened(address indexed initiator);
    event MetaDataChanged(address indexed initiator, string name, string symbol, address baseCurrency, uint256 cap, uint256 goal, uint256 startTime, uint256 endTime);
    event RolesChanged(address indexed initiator, address pauseControl, address tokenRescueControl);
    event MintControlChanged(address indexed initiator, address mintControl);
    event TokenActionIndexIncreased(uint256 tokenActionIndex, uint256 blocknumber);

 
 
 
    modifier onlyPauseControl() {
        require(msg.sender == roles.pauseControl, "pauseCtrl");
        _;
    }

     
    function _canDoAnytime() internal view returns (bool) {
        return false;
    }

    modifier onlyOwnerOrOverruled() {
        if(_canDoAnytime() == false) { 
            require(isOwner(), "only owner");
        }
        _;
    }

    modifier canMint() {
        if(_canDoAnytime() == false) { 
            require(canMintLogic(), "canMint");
        }
        _;
    }

    function canMintLogic() private view returns (bool) {
        return msg.sender == roles.mintControl && availability.tokenAlive && !availability.mintingPhaseFinished && !availability.mintingPaused;
    }

     
    function checkCanSetMetadata() internal returns (bool) {
        if(_canDoAnytime() == false) {
            require(isOwner(), "owner only");
            require(!availability.tokenAlive, "alive");
            require(!availability.mintingPhaseFinished, "finished");
        }

        return true;
    }

    modifier canSetMetadata() {
        checkCanSetMetadata();
        _;
    }

    modifier onlyTokenAlive() {
        require(availability.tokenAlive, "not alive");
        _;
    }

    modifier onlyTokenRescueControl() {
        require(msg.sender == roles.tokenRescueControl, "rescueCtrl");
        _;
    }

    modifier canTransfer() {
        require(availability.transfersEnabled, "paused");
        _;
    }

 
 
 

     
     
     
     
     
     
     
     
     
    function setMetaData(
        string calldata _nameParam, 
        string calldata _symbolParam, 
        address _tokenBaseCurrency, 
        uint256 _cap, 
        uint256 _goal, 
        uint256 _startTime, 
        uint256 _endTime) 
        external 
    canSetMetadata 
    {
        require(_cap >= _goal, "cap higher goal");

        _name = _nameParam;
        _symbol = _symbolParam;

        baseCurrency = _tokenBaseCurrency;
        supply.cap = _cap;
        supply.goal = _goal;
        supply.startTime = _startTime;
        supply.endTime = _endTime;

        emit MetaDataChanged(msg.sender, _nameParam, _symbolParam, _tokenBaseCurrency, _cap, _goal, _startTime, _endTime);
    }

     
     
    function setMintControl(address _mintControl) public canSetMetadata {
        roles.setMintControl(_mintControl);
    }

     
     
     
    function setRoles(address _pauseControl, address _tokenRescueControl) public 
    canSetMetadata
    {
        roles.setRoles(_pauseControl, _tokenRescueControl);
    }

    function setTokenAlive() public 
    onlyOwnerOrOverruled
    {
        availability.setTokenAlive();
    }

 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) public canTransfer returns (bool success) {
        supply.doTransfer(availability, msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        return transferFromInternal(_from, _to, _amount);
    }

     
     
     
     
     
     
    function transferFromInternal(address _from, address _to, uint256 _amount) internal canTransfer returns (bool success) {
        return supply.transferFrom(availability, _from, _to, _amount);
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return supply.balanceOfNow(_owner);
    }

     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        return supply.approve(_spender, _amount);
    }

     
     
     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return supply.allowed[_owner][_spender];
    }

     
     
    function totalSupply() public view returns (uint256) {
        return supply.totalSupplyNow();
    }


     
     
     
     
     
     
     
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        return supply.increaseApproval(_spender, _addedValue);
    }

     
     
     
     
     
     
     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        return supply.decreaseApproval(_spender, _subtractedValue);
    }

 
 
 

     
     
     
    function mint(address _to, uint256 _amount) public canMint returns (bool) {
        return supply.mint(_to, _amount);
    }

     
     
    function finishMinting() public onlyOwnerOrOverruled returns (bool) {
        return availability.finishMinting();
    }

 
 
 

     
     
     
    function rescueToken(address _foreignTokenAddress, address _to)
    public
    onlyTokenRescueControl
    {
        availability.rescueToken(_foreignTokenAddress, _to);
    }

 
 
 

     
     
     
     
     
    function balanceOfAt(address _owner, uint256 _specificTransfersAndMintsIndex) public view returns (uint256) {
        return supply.balanceOfAt(_owner, _specificTransfersAndMintsIndex);
    }

     
     
     
    function totalSupplyAt(uint256 _specificTransfersAndMintsIndex) public view returns(uint256) {
        return supply.totalSupplyAt(_specificTransfersAndMintsIndex);
    }

 
 
 

     
    function enableTransferInternal(bool _transfersEnabled) internal {
        availability.pauseTransfer(_transfersEnabled);
    }

     
     
    function enableTransfers(bool _transfersEnabled) public 
    onlyOwnerOrOverruled 
    {
        enableTransferInternal(_transfersEnabled);
    }

 
 
 

     
     
    function pauseTransfer(bool _transfersEnabled) public
    onlyPauseControl
    {
        enableTransferInternal(_transfersEnabled);
    }

     
     
    function pauseCapitalIncreaseOrDecrease(bool _mintingEnabled) public
    onlyPauseControl
    {
        availability.pauseCapitalIncreaseOrDecrease(_mintingEnabled);
    }

     
     
    function reopenCrowdsaleInternal() internal returns (bool) {
        return availability.reopenCrowdsale();
    }

     
     
    function enforcedTransferFromInternal(address _from, address _to, uint256 _value, bool _fullAmountRequired) internal returns (bool) {
        return supply.enforcedTransferFrom(availability, _from, _to, _value, _fullAmountRequired);
    }
}

 

interface ICRWDControllerTransfer {
    function transferParticipantsVerification(address _underlyingCurrency, address _from, address _to, uint256 _amount) external returns (bool);
}

 

interface IGlobalIndexControllerLocation {
    function getControllerAddress() external view returns (address);
}

 

contract ICRWDAssetToken is IBasicAssetTokenFull {
    function setGlobalIndexAddress(address _globalIndexAddress) public;
}

 

 






 
contract CRWDAssetToken is BasicAssetToken, ICRWDAssetToken {

    using SafeMath for uint256;

    IGlobalIndexControllerLocation public globalIndex;

    function getControllerAddress() public view returns (address) {
        return globalIndex.getControllerAddress();
    }

     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        ICRWDControllerTransfer(getControllerAddress()).transferParticipantsVerification(baseCurrency, msg.sender, _to, _amount);
        return super.transfer(_to, _amount);
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        ICRWDControllerTransfer(getControllerAddress()).transferParticipantsVerification(baseCurrency, _from, _to, _amount);
        return super.transferFrom(_from, _to, _amount);
    }

     
    function mint(address _to, uint256 _amount) public canMint returns (bool) {
        return super.mint(_to,_amount);
    }

     
    function setGlobalIndexAddress(address _globalIndexAddress) public onlyOwner {
        globalIndex = IGlobalIndexControllerLocation(_globalIndexAddress);
    }
}

 

 


 
contract FeatureCapitalControl is ICRWDAssetToken {
    
 
 
 

     
    address public capitalControl;

 
 
 

    constructor(address _capitalControl) public {
        capitalControl = _capitalControl;
        enableTransferInternal(false);  
    }

 
 
 

     
    function _canDoAnytime() internal view returns (bool) {
        return msg.sender == capitalControl;
    }

    modifier onlyCapitalControl() {
        require(msg.sender == capitalControl, "permission");
        _;
    }

 
 
 

     
     
     
     
    function setCapitalControl(address _capitalControl) public {
        require(checkCanSetMetadata(), "forbidden");

        capitalControl = _capitalControl;
    }

     
     
    function updateCapitalControl(address _capitalControl) public onlyCapitalControl {
        capitalControl = _capitalControl;
    }

 
 
 

     
    function reopenCrowdsale() public onlyCapitalControl returns (bool) {        
        return reopenCrowdsaleInternal();
    }
}

 

 



 
contract FeatureCapitalControlWithForcedTransferFrom is FeatureCapitalControl {

 
 
 

    constructor(address _capitalControl) FeatureCapitalControl(_capitalControl) public { }

 
 
 

    event SelfApprovedTransfer(address indexed initiator, address indexed from, address indexed to, uint256 value);


 
 
 

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
    {
        if (msg.sender == capitalControl) {
            return enforcedTransferFromInternal(_from, _to, _value, true);
        } else {
            return transferFromInternal(_from, _to, _value);
        }
    }

}

 

 
contract AssetTokenT001 is CRWDAssetToken, FeatureCapitalControlWithForcedTransferFrom
{    
    constructor(address _capitalControl) FeatureCapitalControlWithForcedTransferFrom(_capitalControl) public {}
}