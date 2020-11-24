 

pragma solidity ^0.4.11;

 
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

 
contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public constant returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract Shareable {

    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    event RequirementChange(uint required);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);

     
    struct PendingState {
        uint256 index;
        uint256 yetNeeded;
        mapping (address => bool) ownersDone;
    }

     
    uint256 public required;

     
    address[] owners;

     
    mapping (address => bool) internal isOwner;

     
    mapping (bytes32 => PendingState) internal pendings;

     
    bytes32[] internal pendingsIndex;

     
    modifier addressNotNull(address _address) {
        require(_address != address(0));
        _;
    }

     
    modifier validRequirement(uint256 _ownersCount, uint _required) {
        require(_required > 1 && _ownersCount >= _required);
        _;
    }

     
    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

     
    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

     
    modifier onlyOwner {
        require(isOwner[msg.sender]);
        _;
    }

     
    modifier onlyManyOwners(bytes32 _operation) {
        if (confirmAndCheck(_operation)) {
            _;
        }
    }

     
    function Shareable(address[] _additionalOwners, uint256 _required)
        validRequirement(_additionalOwners.length + 1, _required)
    {
        owners.push(msg.sender);
        isOwner[msg.sender] = true;

        for (uint i = 0; i < _additionalOwners.length; i++) {
            require(!isOwner[_additionalOwners[i]] && _additionalOwners[i] != address(0));

            owners.push(_additionalOwners[i]);
            isOwner[_additionalOwners[i]] = true;
        }

        required = _required;
    }

     
    function changeRequirement(uint _required)
        external
        validRequirement(owners.length, _required)
        onlyManyOwners(keccak256("change-requirement", _required))
    {
        required = _required;

        RequirementChange(_required);
    }

     
    function addOwner(address _owner)
        external
        addressNotNull(_owner)
        ownerDoesNotExist(_owner)
        onlyManyOwners(keccak256("add-owner", _owner))
    {
        owners.push(_owner);
        isOwner[_owner] = true;

        OwnerAddition(_owner);
    }

     
    function removeOwner(address _owner)
        external
        addressNotNull(_owner)
        ownerExists(_owner)
        onlyManyOwners(keccak256("remove-owner", _owner))
        validRequirement(owners.length - 1, required)
    {
         
        clearPending();

        isOwner[_owner] = false;

        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }

        owners.length -= 1;

        OwnerRemoval(_owner);
    }

     
    function revoke(bytes32 _operation)
        external
        onlyOwner
    {
        var pending = pendings[_operation];

        if (pending.ownersDone[msg.sender]) {
            pending.yetNeeded++;
            pending.ownersDone[msg.sender] = false;

            uint256 count = 0;
            for (uint256 i = 0; i < owners.length; i++) {
                if (hasConfirmed(_operation, owners[i])) {
                    count++;
                }
            }

            if (count <= 0) {
                pendingsIndex[pending.index] = pendingsIndex[pendingsIndex.length - 1];
                pendingsIndex.length--;
                delete pendings[_operation];
            }

            Revoke(msg.sender, _operation);
        }
    }

     
    function hasConfirmed(bytes32 _operation, address _owner)
        constant
        addressNotNull(_owner)
        onlyOwner
        returns (bool)
    {
        return pendings[_operation].ownersDone[_owner];
    }

     
    function confirmAndCheck(bytes32 _operation)
        internal
        onlyOwner
        returns (bool)
    {
        var pending = pendings[_operation];

         
        if (pending.yetNeeded == 0) {
            clearOwnersDone(_operation);
             
            pending.yetNeeded = required;
             
            pendingsIndex.length++;
            pending.index = pendingsIndex.length++;
            pendingsIndex[pending.index] = _operation;
        }

         
        if (!hasConfirmed(_operation, msg.sender)) {
            Confirmation(msg.sender, _operation);

             
            if (pending.yetNeeded <= 1) {
                 
                clearOwnersDone(_operation);
                pendingsIndex[pending.index] = pendingsIndex[pendingsIndex.length - 1];
                pendingsIndex.length--;
                delete pendings[_operation];

                return true;
            } else {
                 
                pending.yetNeeded--;
                pending.ownersDone[msg.sender] = true;
            }
        } else {
            revert();
        }

        return false;
    }

     
    function clearOwnersDone(bytes32 _operation)
        internal
        onlyOwner
    {
        for (uint256 i = 0; i < owners.length; i++) {
            if (pendings[_operation].ownersDone[owners[i]]) {
                pendings[_operation].ownersDone[owners[i]] = false;
            }
        }
    }

     
    function clearPending()
        internal
        onlyOwner
    {
        uint256 length = pendingsIndex.length;

        for (uint256 i = 0; i < length; ++i) {
            clearOwnersDone(pendingsIndex[i]);
            delete pendings[pendingsIndex[i]];
        }

        pendingsIndex.length = 0;
    }
}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue)
        returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue)
        returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
contract MintableToken is StandardToken, Shareable {
    event Mint(uint256 iteration, address indexed to, uint256 amount);

     
    uint256 public totalSupplyLimit;

     
    uint256 public numberOfBlocksBetweenSupplies;

     
    uint256 public nextSupplyAfterBlock;

     
    uint256 public currentIteration = 1;

     
    uint256 private prevIterationSupplyLimit = 0;

     
    modifier canMint(uint256 _amount) {
         
        require(block.number >= nextSupplyAfterBlock);

         
        require(totalSupply.add(_amount) <= totalSupplyLimit);

         
        require(_amount <= currentIterationSupplyLimit());

        _;
    }

     
    function MintableToken(
        address _initialSupplyAddress,
        uint256 _initialSupply,
        uint256 _firstIterationSupplyLimit,
        uint256 _totalSupplyLimit,
        uint256 _numberOfBlocksBetweenSupplies,
        address[] _additionalOwners,
        uint256 _required
    )
        Shareable(_additionalOwners, _required)
    {
        require(_initialSupplyAddress != address(0) && _initialSupply > 0);

        prevIterationSupplyLimit = _firstIterationSupplyLimit;
        totalSupplyLimit = _totalSupplyLimit;
        numberOfBlocksBetweenSupplies = _numberOfBlocksBetweenSupplies;
        nextSupplyAfterBlock = block.number.add(_numberOfBlocksBetweenSupplies);

        totalSupply = totalSupply.add(_initialSupply);
        balances[_initialSupplyAddress] = balances[_initialSupplyAddress].add(_initialSupply);
    }

     
    function currentIterationSupplyLimit()
        public
        constant
        returns (uint256 maxSupply)
    {
        if (currentIteration == 1) {
            maxSupply = prevIterationSupplyLimit;
        } else {
            maxSupply = prevIterationSupplyLimit.mul(9881653713).div(10000000000);

            if (maxSupply > (totalSupplyLimit.sub(totalSupply))) {
                maxSupply = totalSupplyLimit.sub(totalSupply);
            }
        }
    }

     
    function mint(address _to, uint256 _amount)
        external
        canMint(_amount)
        onlyManyOwners(keccak256("mint", _to, _amount))
        returns (bool)
    {
        prevIterationSupplyLimit = currentIterationSupplyLimit();
        nextSupplyAfterBlock = block.number.add(numberOfBlocksBetweenSupplies);

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        Mint(currentIteration, _to, _amount);
        Transfer(0x0, _to, _amount);

        currentIteration = currentIteration.add(1);

        clearPending();

        return true;
    }
}

 
contract OTNToken is MintableToken {
     
    string public name = "Open Trading Network";

     
    string public symbol = "OTN";

     
    uint256 public decimals = 18;

     
    function OTNToken(
        address _initialSupplyAddress,
        address[] _additionalOwners
    )
        MintableToken(
            _initialSupplyAddress,
            79000000e18,             
            350000e18,               
            100000000e18,            
            100,                     
            _additionalOwners,       
            2                        
    )
    {

    }

}