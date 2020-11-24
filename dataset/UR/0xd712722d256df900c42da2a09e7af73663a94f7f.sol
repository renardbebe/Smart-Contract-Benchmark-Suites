 

pragma solidity ^0.4.16;

contract SafeMath {

    function safeAdd(uint256 x, uint256 y) view internal returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) view internal returns (uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) view internal returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }

    function safeDiv(uint256 a, uint256 b) view internal returns (uint256) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
}

contract Owner {
	
	 
	mapping ( address => bool ) public ownerAddressMap;
	 
	mapping ( address => uint256 ) public ownerAddressNumberMap;
	 
	mapping ( uint256 => address ) public ownerListMap;
	 
	uint256 public ownerCountInt = 0;
	
	 
	event ContractManagementUpdate( string _type, address _initiator, address _to, bool _newvalue );

	 
	modifier isOwner {
        require( ownerAddressMap[msg.sender]==true );
        _;
    }
	
	 
	function ownerOn( address _onOwnerAddress ) external isOwner returns (bool retrnVal) {
		 
		require( _onOwnerAddress != address(0) );
		 
		if ( ownerAddressNumberMap[ _onOwnerAddress ]>0 )
		{
			 
			if ( !ownerAddressMap[ _onOwnerAddress ] )
			{
				ownerAddressMap[ _onOwnerAddress ] = true;
				ContractManagementUpdate( "Owner", msg.sender, _onOwnerAddress, true );
				retrnVal = true;
			}
			else
			{
				retrnVal = false;
			}
		}
		 
		else
		{
			ownerAddressMap[ _onOwnerAddress ] = true;
			ownerAddressNumberMap[ _onOwnerAddress ] = ownerCountInt;
			ownerListMap[ ownerCountInt ] = _onOwnerAddress;
			ownerCountInt++;
			ContractManagementUpdate( "Owner", msg.sender, _onOwnerAddress, true );
			retrnVal = true;
		}
	}
	
	 
	function ownerOff( address _offOwnerAddress ) external isOwner returns (bool retrnVal) {
		 
		 
		if ( ownerAddressNumberMap[ _offOwnerAddress ]>0 && ownerAddressMap[ _offOwnerAddress ] )
		{
			ownerAddressMap[ _offOwnerAddress ] = false;
			ContractManagementUpdate( "Owner", msg.sender, _offOwnerAddress, false );
			retrnVal = true;
		}
		else
		{
			retrnVal = false;
		}
	}

	 
	function Owner() public {
		 
		ownerAddressMap[ msg.sender ] = true;
		ownerAddressNumberMap[ msg.sender ] = ownerCountInt;
		ownerListMap[ ownerCountInt ] = msg.sender;
		ownerCountInt++;
	}
}

contract SpecialManager is Owner {

	 
	mapping ( address => bool ) public specialManagerAddressMap;
	 
	mapping ( address => uint256 ) public specialManagerAddressNumberMap;
	 
	mapping ( uint256 => address ) public specialManagerListMap;
	 
	uint256 public specialManagerCountInt = 0;
	
	 
	modifier isSpecialManagerOrOwner {
        require( specialManagerAddressMap[msg.sender]==true || ownerAddressMap[msg.sender]==true );
        _;
    }
	
	 
	function specialManagerOn( address _onSpecialManagerAddress ) external isOwner returns (bool retrnVal) {
		 
		require( _onSpecialManagerAddress != address(0) );
		 
		if ( specialManagerAddressNumberMap[ _onSpecialManagerAddress ]>0 )
		{
			 
			if ( !specialManagerAddressMap[ _onSpecialManagerAddress ] )
			{
				specialManagerAddressMap[ _onSpecialManagerAddress ] = true;
				ContractManagementUpdate( "Special Manager", msg.sender, _onSpecialManagerAddress, true );
				retrnVal = true;
			}
			else
			{
				retrnVal = false;
			}
		}
		 
		else
		{
			specialManagerAddressMap[ _onSpecialManagerAddress ] = true;
			specialManagerAddressNumberMap[ _onSpecialManagerAddress ] = specialManagerCountInt;
			specialManagerListMap[ specialManagerCountInt ] = _onSpecialManagerAddress;
			specialManagerCountInt++;
			ContractManagementUpdate( "Special Manager", msg.sender, _onSpecialManagerAddress, true );
			retrnVal = true;
		}
	}
	
	 
	function specialManagerOff( address _offSpecialManagerAddress ) external isOwner returns (bool retrnVal) {
		 
		 
		if ( specialManagerAddressNumberMap[ _offSpecialManagerAddress ]>0 && specialManagerAddressMap[ _offSpecialManagerAddress ] )
		{
			specialManagerAddressMap[ _offSpecialManagerAddress ] = false;
			ContractManagementUpdate( "Special Manager", msg.sender, _offSpecialManagerAddress, false );
			retrnVal = true;
		}
		else
		{
			retrnVal = false;
		}
	}


	 
	function SpecialManager() public {
		 
		specialManagerAddressMap[ msg.sender ] = true;
		specialManagerAddressNumberMap[ msg.sender ] = specialManagerCountInt;
		specialManagerListMap[ specialManagerCountInt ] = msg.sender;
		specialManagerCountInt++;
	}
}

contract Manager is SpecialManager {
	
	 
	mapping ( address => bool ) public managerAddressMap;
	 
	mapping ( address => uint256 ) public managerAddressNumberMap;
	 
	mapping ( uint256 => address ) public managerListMap;
	 
	uint256 public managerCountInt = 0;
	
	 
	modifier isManagerOrOwner {
        require( managerAddressMap[msg.sender]==true || ownerAddressMap[msg.sender]==true );
        _;
    }
	
	 
	function managerOn( address _onManagerAddress ) external isOwner returns (bool retrnVal) {
		 
		require( _onManagerAddress != address(0) );
		 
		if ( managerAddressNumberMap[ _onManagerAddress ]>0 )
		{
			 
			if ( !managerAddressMap[ _onManagerAddress ] )
			{
				managerAddressMap[ _onManagerAddress ] = true;
				ContractManagementUpdate( "Manager", msg.sender, _onManagerAddress, true );
				retrnVal = true;
			}
			else
			{
				retrnVal = false;
			}
		}
		 
		else
		{
			managerAddressMap[ _onManagerAddress ] = true;
			managerAddressNumberMap[ _onManagerAddress ] = managerCountInt;
			managerListMap[ managerCountInt ] = _onManagerAddress;
			managerCountInt++;
			ContractManagementUpdate( "Manager", msg.sender, _onManagerAddress, true );
			retrnVal = true;
		}
	}
	
	 
	function managerOff( address _offManagerAddress ) external isOwner returns (bool retrnVal) {
		 
		 
		if ( managerAddressNumberMap[ _offManagerAddress ]>0 && managerAddressMap[ _offManagerAddress ] )
		{
			managerAddressMap[ _offManagerAddress ] = false;
			ContractManagementUpdate( "Manager", msg.sender, _offManagerAddress, false );
			retrnVal = true;
		}
		else
		{
			retrnVal = false;
		}
	}


	 
	function Manager() public {
		 
		managerAddressMap[ msg.sender ] = true;
		managerAddressNumberMap[ msg.sender ] = managerCountInt;
		managerListMap[ managerCountInt ] = msg.sender;
		managerCountInt++;
	}
}

contract Management is Manager {
	
	 
	string public description = "";
	
	 
	 
	 
	bool public transactionsOn = false;
	
	 
	 
	 
	bool public emissionOn = true;

	 
	uint256 public tokenCreationCap = 0;
	
	 
	modifier isTransactionsOn{
        require( transactionsOn );
        _;
    }
	
	 
	modifier isEmissionOn{
        require( emissionOn );
        _;
    }
	
	 
	function transactionsStatusUpdate( bool _on ) external isOwner
	{
		transactionsOn = _on;
	}
	
	 
	function emissionStatusUpdate( bool _on ) external isOwner
	{
		emissionOn = _on;
	}
	
	 
	function tokenCreationCapUpdate( uint256 _newVal ) external isOwner
	{
		tokenCreationCap = _newVal;
	}
	
	 
	event DescriptionPublished( string _description, address _initiator);
	
	 
	function descriptionUpdate( string _newVal ) external isOwner
	{
		description = _newVal;
		DescriptionPublished( _newVal, msg.sender );
	}
}

 
contract FoodcoinEcosystem is SafeMath, Management {
	
	 
	string public constant name = "FoodCoin EcoSystem";
	 
	string public constant symbol = "FOOD";
	 
	uint256 public constant decimals = 8;
	 
	uint256 public totalSupply = 0;
	
	 
	mapping ( address => uint256 ) balances;
	 
	mapping ( uint256 => address ) public balancesListAddressMap;
	 
	mapping ( address => uint256 ) public balancesListNumberMap;
	 
	mapping ( address => string ) public balancesAddressDescription;
	 
	uint256 balancesCountInt = 1;
	
	 
	mapping ( address => mapping ( address => uint256 ) ) allowed;
	
	
	 
	event Transfer(address _from, address _to, uint256 _value, address _initiator);
	
	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	 
	event TokenEmissionEvent( address initiatorAddress, uint256 amount, bool emissionOk );
	
	 
	event WithdrawEvent( address initiatorAddress, address toAddress, bool withdrawOk, uint256 withdrawValue, uint256 newBalancesValue );
	
	
	 
	function balanceOf( address _owner ) external view returns ( uint256 )
	{
		return balances[ _owner ];
	}
	 
	function allowance( address _owner, address _initiator ) external view returns ( uint256 remaining )
	{
		return allowed[ _owner ][ _initiator ];
	}
	 
	function balancesQuantity() external view returns ( uint256 )
	{
		return balancesCountInt - 1;
	}
	
	 
	function _addClientAddress( address _balancesAddress, uint256 _amount ) internal
	{
		 
		if ( balancesListNumberMap[ _balancesAddress ] == 0 )
		{
			 
			balancesListAddressMap[ balancesCountInt ] = _balancesAddress;
			balancesListNumberMap[ _balancesAddress ] = balancesCountInt;
			 
			balancesCountInt++;
		}
		 
		balances[ _balancesAddress ] = safeAdd( balances[ _balancesAddress ], _amount );
	}
	 
	function _transfer( address _from, address _to, uint256 _value ) internal isTransactionsOn returns ( bool success )
	{
		 
		if ( _value > 0 && balances[ _from ] >= _value )
		{
			 
			balances[ _from ] -= _value;
			 
			_addClientAddress( _to, _value );
			 
			Transfer( _from, _to, _value, msg.sender );
			 
			return true;
		}
		 
		else
		{
			return false;
		}
	}
	 
	function transfer(address _to, uint256 _value) external isTransactionsOn returns ( bool success )
	{
		return _transfer( msg.sender, _to, _value );
	}
	 
	function transferFrom(address _from, address _to, uint256 _value) external isTransactionsOn returns ( bool success )
	{
		 
		if ( allowed[_from][msg.sender] >= _value )
		{
			 
			if ( _transfer( _from, _to, _value ) )
			{
				 
				allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender], _value);
				return true;
			}
			else
			{
				return false;
			}
		}
		else
		{
			return false;
		}
	}
	 
	function approve( address _initiator, uint256 _value ) external isTransactionsOn returns ( bool success )
	{
		 
		allowed[ msg.sender ][ _initiator ] = _value;
		 
		Approval( msg.sender, _initiator, _value );
		return true;
	}
	
	 
	function tokenEmission(address _reciever, uint256 _amount) external isManagerOrOwner isEmissionOn returns ( bool returnVal )
	{
		 
		require( _reciever != address(0) );
		 
		uint256 checkedSupply = safeAdd( totalSupply, _amount );
		 
		uint256 amountTmp = _amount;
		 
		if ( tokenCreationCap > 0 && tokenCreationCap < checkedSupply )
		{
			amountTmp = 0;
		}
		 
		if ( amountTmp > 0 )
		{
			 
			_addClientAddress( _reciever, amountTmp );
			 
			totalSupply = checkedSupply;
			TokenEmissionEvent( msg.sender, _amount, true);
		}
		else
		{
			returnVal = false;
			TokenEmissionEvent( msg.sender, _amount, false);
		}
	}
	
	 
	function withdraw( address _to, uint256 _amount ) external isSpecialManagerOrOwner returns ( bool returnVal, uint256 withdrawValue, uint256 newBalancesValue )
	{
		 
		if ( balances[ _to ] > 0 )
		{
			 
			uint256 amountTmp = _amount;
			 
			if ( balances[ _to ] < _amount )
			{
				amountTmp = balances[ _to ];
			}
			 
			balances[ _to ] = safeSubtract( balances[ _to ], amountTmp );
			 
			totalSupply = safeSubtract( totalSupply, amountTmp );
			 
			returnVal = true;
			withdrawValue = amountTmp;
			newBalancesValue = balances[ _to ];
			WithdrawEvent( msg.sender, _to, true, amountTmp, balances[ _to ] );
		}
		else
		{
			returnVal = false;
			withdrawValue = 0;
			newBalancesValue = 0;
			WithdrawEvent( msg.sender, _to, false, _amount, balances[ _to ] );
		}
	}
	
	 
	function balancesAddressDescriptionUpdate( string _newDescription ) external returns ( bool returnVal )
	{
		 
		if ( balancesListNumberMap[ msg.sender ] > 0 || ownerAddressMap[msg.sender]==true )
		{
			balancesAddressDescription[ msg.sender ] = _newDescription;
			returnVal = true;
		}
		else
		{
			returnVal = false;
		}
	}
}