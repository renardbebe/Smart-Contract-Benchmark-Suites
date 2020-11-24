 

pragma solidity ^0.4.24;


 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender)
    public view returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

    uint256 internal totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        return _a / _b;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

 
contract PausableToken is StandardToken, Pausable {

    function transfer(
        address _to,
        uint256 _value
    )
        public
        whenNotPaused
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        whenNotPaused
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(
        address _spender,
        uint256 _value
    )
        public
        whenNotPaused
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

    function increaseApproval(
        address _spender,
        uint _addedValue
    )
        public
        whenNotPaused
        returns (bool success)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
        public
        whenNotPaused
        returns (bool success)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

 
library Math {
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library ArrayUtils {
    function findUpperBound(uint256[] storage _array, uint256 _element) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = _array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            if (_array[mid] > _element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

         

        if (low > 0 && _array[low - 1] == _element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

contract Whitelist is Ownable {
    struct WhitelistInfo {
        bool inWhitelist;
        uint256 index;   
        uint256 time;    
    }

    mapping (address => WhitelistInfo) public whitelist;
    address[] public whitelistAddresses;

    event AddWhitelist(address indexed operator, uint256 indexInWhitelist);
    event RemoveWhitelist(address indexed operator, uint256 indexInWhitelist);

     
    modifier onlyIfWhitelisted(address _operator) {
        require(inWhitelist(_operator) == true, "not whitelisted.");
        _;
    }

     
    function addAddressToWhitelist(address _operator)
        public
        onlyOwner
        returns(bool)
    {
        WhitelistInfo storage whitelistInfo_ = whitelist[_operator];

        if (inWhitelist(_operator) == false) {
            whitelistAddresses.push(_operator);

            whitelistInfo_.inWhitelist = true;
            whitelistInfo_.time = block.timestamp;
            whitelistInfo_.index = whitelistAddresses.length-1;

            emit AddWhitelist(_operator, whitelistAddresses.length-1);
            return true;
        } else {
            return false;
        }
    }

     
    function addAddressesToWhitelist(address[] _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }

     
    function removeAddressFromWhitelist(address _operator)
        public
        onlyOwner
        returns(bool)
    {
        if (inWhitelist(_operator) == true) {
            uint256 whitelistIndex_ = whitelist[_operator].index;
            removeItemFromWhitelistAddresses(whitelistIndex_);
            whitelist[_operator] = WhitelistInfo(false, 0, 0);

            emit RemoveWhitelist(_operator, whitelistIndex_);
            return true;
        } else {
            return false;
        }
    }

    function removeItemFromWhitelistAddresses(uint256 _index) private {
        address lastWhitelistAddr = whitelistAddresses[whitelistAddresses.length-1];
        WhitelistInfo storage lastWhitelistInfo = whitelist[lastWhitelistAddr];

         
        whitelistAddresses[_index] = whitelistAddresses[whitelistAddresses.length-1];
        lastWhitelistInfo.index = _index;
        delete whitelistAddresses[whitelistAddresses.length-1];
        whitelistAddresses.length--;
    }

     
    function removeAddressesFromWhitelist(address[] _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }

     
    function inWhitelist(address _operator)
        public
        view
        returns(bool)
    {
        return whitelist[_operator].inWhitelist;
    }

    function getWhitelistCount() public view returns(uint256) {
        return whitelistAddresses.length;
    }

    function getAllWhitelist() public view returns(address[]) {
        address[] memory allWhitelist = new address[](whitelistAddresses.length);
        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            allWhitelist[i] = whitelistAddresses[i];
        }
        return allWhitelist;
    }
}

 
contract SnapshotToken is StandardToken {
    using ArrayUtils for uint256[];

     
    uint256 public currSnapshotId;

    mapping (address => uint256[]) internal snapshotIds;
    mapping (address => uint256[]) internal snapshotBalances;

    event Snapshot(uint256 id);

    function transfer(address _to, uint256 _value) public returns (bool) {
        _updateSnapshot(msg.sender);
        _updateSnapshot(_to);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _updateSnapshot(_from);
        _updateSnapshot(_to);
        return super.transferFrom(_from, _to, _value);
    }

    function snapshot() public returns (uint256) {
        currSnapshotId += 1;
        emit Snapshot(currSnapshotId);
        return currSnapshotId;
    }

    function balanceOfAt(address _account, uint256 _snapshotId) public view returns (uint256) {
        require(_snapshotId > 0 && _snapshotId <= currSnapshotId);

        uint256 idx = snapshotIds[_account].findUpperBound(_snapshotId);

        if (idx == snapshotIds[_account].length) {
            return balanceOf(_account);
        } else {
            return snapshotBalances[_account][idx];
        }
    }

    function _updateSnapshot(address _account) internal {
        if (_lastSnapshotId(_account) < currSnapshotId) {
            snapshotIds[_account].push(currSnapshotId);
            snapshotBalances[_account].push(balanceOf(_account));
        }
    }

    function _lastSnapshotId(address _account) internal view returns (uint256) {
        uint256[] storage snapshots = snapshotIds[_account];

        if (snapshots.length == 0) {
            return 0;
        } else {
            return snapshots[snapshots.length - 1];
        }
    }
}


contract BBT is BurnableToken, PausableToken, SnapshotToken, Whitelist {
    string public constant symbol = "BBT";
    string public constant name = "BonBon Token";
    uint8 public constant decimals = 18;
    uint256 private overrideTotalSupply_ = 10 * 1e9 * 1e18;  

    uint256 public circulation;
    uint256 public minedAmount;
    address public teamWallet;
    uint256 public constant gameDistributionRatio = 35;  
    uint256 public constant teamReservedRatio = 15;      

    mapping (uint256 => uint256) private snapshotCirculations_;    

    event Mine(address indexed from, address indexed to, uint256 amount);
    event Release(address indexed from, address indexed to, uint256 amount);
    event SetTeamWallet(address indexed from, address indexed teamWallet);
    event UnlockTeamBBT(address indexed teamWallet, uint256 amount, string source);

     
    modifier hasEnoughUnreleasedBBT(uint256 _amount) {
        require(circulation.add(_amount) <= totalSupply_, "Unreleased BBT not enough.");
        _;
    }

     
    modifier hasTeamWallet() {
        require(teamWallet != address(0), "Team wallet not set.");
        _;
    }

    constructor() public {
        totalSupply_ = overrideTotalSupply_;
    }

     
    function snapshot()
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
        public
        returns(uint256)
    {
        currSnapshotId += 1;
        snapshotCirculations_[currSnapshotId] = circulation;
        emit Snapshot(currSnapshotId);
        return currSnapshotId;
    }

     
    function circulationAt(uint256 _snapshotId)
        public
        view
        returns(uint256)
    {
        require(_snapshotId > 0 && _snapshotId <= currSnapshotId, "invalid snapshot id.");
        return snapshotCirculations_[_snapshotId];
    }

     
    function setTeamWallet(address _address)
        onlyOwner
        whenNotPaused
        public
        returns (bool)
    {
        teamWallet = _address;
        emit SetTeamWallet(msg.sender, _address);
        return true;
    }

     
    function mine(address _to, uint256 _amount)
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
        public
        returns (bool)
    {
         
        if (circulation.add(_amount) > totalSupply_)
            return true;

        if (minedAmount.add(_amount) > (totalSupply_.mul(gameDistributionRatio)).div(100))
            return true;

        releaseBBT(_to, _amount);
        minedAmount = minedAmount.add(_amount);

         
        unlockTeamBBT(getTeamUnlockAmountHelper(_amount), 'mine');

        emit Mine(msg.sender, _to, _amount);
        return true;
    }

     
    function release(address _to, uint256 _amount)
        onlyOwner
        hasEnoughUnreleasedBBT(_amount)
        whenNotPaused
        public
        returns(bool)
    {
        releaseBBT(_to, _amount);
        emit Release(msg.sender, _to, _amount);
        return true;
    }

     
    function releaseAndUnlock(address _to, uint256 _amount)
        onlyOwner
        hasEnoughUnreleasedBBT(_amount)
        whenNotPaused
        public
        returns(bool)
    {
        release(_to, _amount);

         
        unlockTeamBBT(getTeamUnlockAmountHelper(_amount), 'release');

        return true;
    }

    function getTeamUnlockAmountHelper(uint256 _amount)
        private
        pure
        returns(uint256)
    {
        return _amount.mul(teamReservedRatio).div(100 - teamReservedRatio);
    }

    function unlockTeamBBT(uint256 _unlockAmount, string _source)
        hasTeamWallet
        hasEnoughUnreleasedBBT(_unlockAmount)
        private
        returns(bool)
    {
        releaseBBT(teamWallet, _unlockAmount);
        emit UnlockTeamBBT(teamWallet, _unlockAmount, _source);
        return true;
    }

     
    function releaseBBT(address _to, uint256 _amount)
        hasEnoughUnreleasedBBT(_amount)
        private
        returns(bool)
    {
        super._updateSnapshot(msg.sender);
        super._updateSnapshot(_to);

        balances[_to] = balances[_to].add(_amount);
        circulation = circulation.add(_amount);
    }
}