 

pragma solidity 0.5.9;

 

 

 
 
 

pragma solidity ^0.5.0;

 
contract Owned {
	modifier only_owner { require (msg.sender == owner, "Only owner"); _; }

	event NewOwner(address indexed old, address indexed current);

	function setOwner(address _new) public only_owner { emit NewOwner(owner, _new); owner = _new; }

	address public owner;
}

 
 
 
 
 
 
contract FrozenToken is Owned {
	event Transfer(address indexed from, address indexed to, uint256 value);

	 
	struct Account {
		uint balance;
		bool liquid;
	}

	 
	constructor(uint _totalSupply, address _owner)
        public
		when_non_zero(_totalSupply)
	{
		totalSupply = _totalSupply;
		owner = _owner;
		accounts[_owner].balance = totalSupply;
		accounts[_owner].liquid = true;
	}

	 
	function balanceOf(address _who) public view returns (uint256) {
		return accounts[_who].balance;
	}

	 
	function makeLiquid(address _to)
		public
		when_liquid(msg.sender)
		returns(bool)
	{
		accounts[_to].liquid = true;
		return true;
	}

	 
	function transfer(address _to, uint256 _value)
		public
		when_owns(msg.sender, _value)
		when_liquid(msg.sender)
		returns(bool)
	{
		emit Transfer(msg.sender, _to, _value);
		accounts[msg.sender].balance -= _value;
		accounts[_to].balance += _value;

		return true;
	}

	 
	function() external {
		assert(false);
	}

	 
	modifier when_owns(address _owner, uint _amount) {
		require (accounts[_owner].balance >= _amount);
		_;
	}

	modifier when_liquid(address who) {
		require (accounts[who].liquid);
		_;
	}

	 
	modifier when_non_zero(uint _value) {
		require (_value > 0);
		_;
	}

	 
	uint public totalSupply;

	 
	mapping (address => Account) accounts;

	 
	string public constant name = "DOT Allocation Indicator";
	string public constant symbol = "DOT";
	uint8 public constant decimals = 3;
}

 

 
 
 
contract Claims is Owned {

    struct Claim {
        uint    index;           
        bytes32 pubKey;          
        bool    hasIndex;        
        uint    vested;          
    }

     
    FrozenToken public allocationIndicator;  

     
    uint public nextIndex;

     
    mapping (address => Claim) public claims;

     
    address[] public claimed;

     
    mapping (address => address) public amended;

     
    event Amended(address indexed original, address indexed amendedTo);
     
    event Claimed(address indexed eth, bytes32 indexed dot, uint indexed idx);
     
    event IndexAssigned(address indexed eth, uint indexed idx);
     
    event Vested(address indexed eth, uint amount);

    constructor(address _owner, address _allocations) public {
        require(_owner != address(0x0), "Must provide an owner address");
        require(_allocations != address(0x0), "Must provide an allocations address");

        owner = _owner;
        allocationIndicator = FrozenToken(_allocations);
    }

     
     
     
     
    function amend(address[] calldata _origs, address[] calldata _amends)
        external
        only_owner
    {
        require(
            _origs.length == _amends.length,
            "Must submit arrays of equal length."
        );

        for (uint i = 0; i < _amends.length; i++) {
            require(!hasClaimed(_origs[i]), "Address has already claimed");
            amended[_origs[i]] = _amends[i];
            emit Amended(_origs[i], _amends[i]);
        }
    }

     
     
     
    function setVesting(address[] calldata _eths, uint[] calldata _vestingAmts)
        external
        only_owner
    {
        require(_eths.length == _vestingAmts.length, "Must submit arrays of equal length");

        for (uint i = 0; i < _eths.length; i++) {
            Claim storage claimData = claims[_eths[i]];
            require(!hasClaimed(_eths[i]), "Account must not be claimed");
            require(claimData.vested == 0, "Account must not be vested already");
            require(_vestingAmts[i] != 0, "Vesting amount must be greater than zero");
            claimData.vested = _vestingAmts[i];
            emit Vested(_eths[i], _vestingAmts[i]);
        }
    }

     
     
     
     
    function assignIndices(address[] calldata _eths)
        external
    {
        for (uint i = 0; i < _eths.length; i++) {
            require(assignNextIndex(_eths[i]), "Assigning the next index failed");
        }
    }

     
     
     
     
     
    function claim(address _eth, bytes32 _pubKey)
        external
        has_allocation(_eth)
        not_claimed(_eth)
    {
        require(_pubKey != bytes32(0), "Failed to provide an Ed25519 or SR25519 public key");
        
        if (amended[_eth] != address(0x0)) {
            require(amended[_eth] == msg.sender, "Address is amended and sender is not the amendment");
        } else {
            require(_eth == msg.sender, "Sender is not the allocation address");
        }

        if (claims[_eth].index == 0 && !claims[_eth].hasIndex) {
            require(assignNextIndex(_eth), "Assigning the next index failed");
        }

        claims[_eth].pubKey = _pubKey;
        claimed.push(_eth);

        emit Claimed(_eth, _pubKey, claims[_eth].index);
    }

     
     
    function claimedLength()
        external view returns (uint)
    {   
        return claimed.length;
    }

     
     
    function hasClaimed(address _eth)
        has_allocation(_eth)
        public view returns (bool)
    {
        return claims[_eth].pubKey != bytes32(0);
    }

     
     
     
    function assignNextIndex(address _eth)
        has_allocation(_eth)
        not_claimed(_eth)
        internal returns (bool)
    {
        require(claims[_eth].index == 0, "Cannot reassign an index.");
        require(!claims[_eth].hasIndex, "Address has already been assigned an index");
        uint idx = nextIndex;
        nextIndex++;
        claims[_eth].index = idx;
        claims[_eth].hasIndex = true;
        emit IndexAssigned(_eth, idx);
        return true;
    }

     
    modifier has_allocation(address _eth) {
        uint bal = allocationIndicator.balanceOf(_eth);
        require(
            bal > 0,
            "Ethereum address has no DOT allocation"
        );
        _;
    }

     
    modifier not_claimed(address _eth) {
        require(
            claims[_eth].pubKey == bytes32(0),
            "Account has already claimed."
        );
        _;
    }
}