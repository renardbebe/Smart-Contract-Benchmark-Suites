 

 
pragma solidity ^0.4.19;

contract SafeMath {

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) pure internal returns (uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) pure internal returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }

    function safeDiv(uint256 a, uint256 b) pure internal returns (uint256) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
}

contract Owner {
	
	 
	string public name = "FoodCoin";
	 
	string public symbol = "FOOD";
	 
	uint256 public decimals = 8;
	 
	string public version = "v1";
	
	 
	address public emissionAddress = address(0);
	 
	address public withdrawAddress = address(0);
	
	 
	mapping ( address => bool ) public ownerAddressMap;
	 
	mapping ( address => uint256 ) public ownerAddressNumberMap;
	 
	mapping ( uint256 => address ) public ownerListMap;
	 
	uint256 public ownerCountInt = 0;

	 
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
			retrnVal = true;
		}
	}
	
	 
	function ownerOff( address _offOwnerAddress ) external isOwner returns (bool retrnVal) {
		 
		 
		if ( ownerAddressNumberMap[ _offOwnerAddress ]>0 && ownerAddressMap[ _offOwnerAddress ] )
		{
			ownerAddressMap[ _offOwnerAddress ] = false;
			retrnVal = true;
		}
		else
		{
			retrnVal = false;
		}
	}
	
	 
	function contractNameUpdate( string _newName, bool updateConfirmation ) external isOwner returns (bool retrnVal) {
		
		if ( updateConfirmation )
		{
			name = _newName;
			retrnVal = true;
		}
		else
		{
			retrnVal = false;
		}
	}
	
	 
	function contractSymbolUpdate( string _newSymbol, bool updateConfirmation ) external isOwner returns (bool retrnVal) {

		if ( updateConfirmation )
		{
			symbol = _newSymbol;
			retrnVal = true;
		}
		else
		{
			retrnVal = false;
		}
	}
	
	 
	function contractDecimalsUpdate( uint256 _newDecimals, bool updateConfirmation ) external isOwner returns (bool retrnVal) {
		
		if ( updateConfirmation && _newDecimals != decimals )
		{
			decimals = _newDecimals;
			retrnVal = true;
		}
		else
		{
			retrnVal = false;
		}
	}
	
	 
	function emissionAddressUpdate( address _newEmissionAddress ) external isOwner {
		emissionAddress = _newEmissionAddress;
	}
	
	 
	function withdrawAddressUpdate( address _newWithdrawAddress ) external isOwner {
		withdrawAddress = _newWithdrawAddress;
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
			retrnVal = true;
		}
	}
	
	 
	function specialManagerOff( address _offSpecialManagerAddress ) external isOwner returns (bool retrnVal) {
		 
		 
		if ( specialManagerAddressNumberMap[ _offSpecialManagerAddress ]>0 && specialManagerAddressMap[ _offSpecialManagerAddress ] )
		{
			specialManagerAddressMap[ _offSpecialManagerAddress ] = false;
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
			retrnVal = true;
		}
	}
	
	 
	function managerOff( address _offManagerAddress ) external isOwner returns (bool retrnVal) {
		 
		 
		if ( managerAddressNumberMap[ _offManagerAddress ]>0 && managerAddressMap[ _offManagerAddress ] )
		{
			managerAddressMap[ _offManagerAddress ] = false;
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
	 
	 
	 
	 
	mapping ( address => uint256 ) public transactionsOnForHolder;
	
	
	 
	 
	 
	bool public balanceOfOn = true;
	 
	 
	 
	 
	mapping ( address => uint256 ) public balanceOfOnForHolder;
	
	
	 
	 
	 
	bool public emissionOn = true;

	 
	uint256 public tokenCreationCap = 0;
	
	 
	 
	mapping ( address => bool ) public verificationAddressMap;
	 
	mapping ( address => uint256 ) public verificationAddressNumberMap;
	 
	mapping ( uint256 => address ) public verificationListMap;
	 
	uint256 public verificationCountInt = 1;
	
	 
	 
	mapping (address => uint256) public verificationHoldersTimestampMap;
	 
	mapping (address => uint256) public verificationHoldersValueMap;
	 
	mapping (address => address) public verificationHoldersVerifierAddressMap;
	 
	mapping (address => uint256) public verificationAddressHoldersListCountMap;
	 
	mapping (address => mapping ( uint256 => address )) public verificationAddressHoldersListNumberMap;
	
	 
	modifier isTransactionsOn( address addressFrom ) {
		
		require( transactionsOnNowVal( addressFrom ) );
		_;
    }
	
	 
	modifier isEmissionOn{
        require( emissionOn );
        _;
    }
	
	 
	function transactionsOnNowVal( address addressFrom ) public view returns( bool )
	{
		return ( transactionsOnForHolder[ addressFrom ]==0 && transactionsOn ) || transactionsOnForHolder[ addressFrom ]==2 ;
	}
	
	 
	function transactionsOnForHolderUpdate( address _to, uint256 _newValue ) external isOwner
	{
		if ( transactionsOnForHolder[ _to ] != _newValue )
		{
			transactionsOnForHolder[ _to ] = _newValue;
		}
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
	
	 
	
	 
	function balanceOfOnUpdate( bool _on ) external isOwner
	{
		balanceOfOn = _on;
	}
	
	 
	function balanceOfOnForHolderUpdate( address _to, uint256 _newValue ) external isOwner
	{
		if ( balanceOfOnForHolder[ _to ] != _newValue )
		{
			balanceOfOnForHolder[ _to ] = _newValue;
		}
	}
	
	
	 
	function verificationAddressOn( address _onVerificationAddress ) external isOwner returns (bool retrnVal) {
		 
		require( _onVerificationAddress != address(0) );
		 
		if ( verificationAddressNumberMap[ _onVerificationAddress ]>0 )
		{
			 
			if ( !verificationAddressMap[ _onVerificationAddress ] )
			{
				verificationAddressMap[ _onVerificationAddress ] = true;
				retrnVal = true;
			}
			else
			{
				retrnVal = false;
			}
		}
		 
		else
		{
			verificationAddressMap[ _onVerificationAddress ] = true;
			verificationAddressNumberMap[ _onVerificationAddress ] = verificationCountInt;
			verificationListMap[ verificationCountInt ] = _onVerificationAddress;
			verificationCountInt++;
			retrnVal = true;
		}
	}
	
	 
	function verificationOff( address _offVerificationAddress ) external isOwner returns (bool retrnVal) {
		 
		if ( verificationAddressNumberMap[ _offVerificationAddress ]>0 && verificationAddressMap[ _offVerificationAddress ] )
		{
			verificationAddressMap[ _offVerificationAddress ] = false;
			retrnVal = true;
		}
		else
		{
			retrnVal = false;
		}
	}
	
	 
	event DescriptionPublished( string _description, address _initiator);
	
	 
	function descriptionUpdate( string _newVal ) external isOwner
	{
		description = _newVal;
		DescriptionPublished( _newVal, msg.sender );
	}
}

 
contract FoodcoinEcosystem is SafeMath, Management {
	
	 
	uint256 public totalSupply = 0;
	
	 
	mapping ( address => uint256 ) balances;
	 
	mapping ( uint256 => address ) public balancesListAddressMap;
	 
	mapping ( address => uint256 ) public balancesListNumberMap;
	 
	mapping ( address => string ) public balancesAddressDescription;
	 
	uint256 balancesCountInt = 1;
	
	 
	mapping ( address => mapping ( address => uint256 ) ) allowed;
	
	
	 
	 
	event Transfer( address indexed from, address indexed to, uint value );
	 
    event Approval( address indexed owner, address indexed spender, uint value );
	
	 
	event FoodTransferEvent( address from, address to, uint256 value, address initiator, uint256 newBalanceFrom, uint256 newBalanceTo );
	 
	event FoodTokenEmissionEvent( address initiator, address to, uint256 value, bool result, uint256 newBalanceTo );
	 
	event FoodWithdrawEvent( address initiator, address to, bool withdrawOk, uint256 withdraw, uint256 withdrawReal, uint256 newBalancesValue );
	
	
	 
	function balanceOf( address _owner ) external view returns ( uint256 )
	{
		 
		if ( ( balanceOfOnForHolder[ _owner ]==0 && balanceOfOn ) || balanceOfOnForHolder[ _owner ]==2 )
		{
			return balances[ _owner ];
		}
		else
		{
			return 0;
		}
	}
	 
	function balanceOfReal( address _owner ) external view returns ( uint256 )
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
	 
	function _transfer( address _from, address _to, uint256 _value ) internal isTransactionsOn( _from ) returns ( bool success )
	{
		 
		if ( _value > 0 && balances[ _from ] >= _value )
		{
			 
			balances[ _from ] -= _value;
			 
			_addClientAddress( _to, _value );
			 
			Transfer( _from, _to, _value );
			FoodTransferEvent( _from, _to, _value, msg.sender, balances[ _from ], balances[ _to ] );
			 
			return true;
		}
		 
		else
		{
			return false;
		}
	}
	 
	function transfer(address _to, uint256 _value) external returns ( bool success )
	{
		 
		if ( verificationAddressNumberMap[ _to ]>0 )
		{
			_verification(msg.sender, _to, _value);
		}
		 
		else
		{
			 
			return _transfer( msg.sender, _to, _value );
		}
	}
	 
	function transferFrom(address _from, address _to, uint256 _value) external isTransactionsOn( _from ) returns ( bool success )
	{
		 
		require( verificationAddressNumberMap[ _to ]==0 );
		 
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
	 
	function approve( address _initiator, uint256 _value ) external isTransactionsOn( msg.sender ) returns ( bool success )
	{
		 
		allowed[ msg.sender ][ _initiator ] = _value;
		 
		Approval( msg.sender, _initiator, _value );
		return true;
	}
	
	 
	function _emission (address _reciever, uint256 _amount) internal isManagerOrOwner isEmissionOn returns ( bool returnVal )
	{
		 
		if ( _reciever != address(0) )
		{
			 
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
				 
				Transfer( emissionAddress, _reciever, amountTmp );
				 
				FoodTokenEmissionEvent( msg.sender, _reciever, _amount, true, balances[ _reciever ] );
			}
			else
			{
				returnVal = false;
				 
				FoodTokenEmissionEvent( msg.sender, _reciever, _amount, false, balances[ _reciever ] );
			}
		}
	}
	 
	function tokenEmission(address _reciever, uint256 _amount) external isManagerOrOwner isEmissionOn returns ( bool returnVal )
	{
		 
		require( _reciever != address(0) );
		 
		returnVal = _emission( _reciever, _amount );
	}
	 
	function tokenEmission5( address _reciever_0, uint256 _amount_0, address _reciever_1, uint256 _amount_1, address _reciever_2, uint256 _amount_2, address _reciever_3, uint256 _amount_3, address _reciever_4, uint256 _amount_4 ) external isManagerOrOwner isEmissionOn
	{
		_emission( _reciever_0, _amount_0 );
		_emission( _reciever_1, _amount_1 );
		_emission( _reciever_2, _amount_2 );
		_emission( _reciever_3, _amount_3 );
		_emission( _reciever_4, _amount_4 );
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
			FoodWithdrawEvent( msg.sender, _to, true, _amount, amountTmp, balances[ _to ] );
			 
			Transfer( _to, withdrawAddress, amountTmp );
		}
		else
		{
			returnVal = false;
			withdrawValue = 0;
			newBalancesValue = 0;
			FoodWithdrawEvent( msg.sender, _to, false, _amount, 0, balances[ _to ] );
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
	
	 
	function _verification( address _from, address _verificationAddress, uint256 _value) internal
	{
		 
		require( verificationAddressMap[ _verificationAddress ] );
		
		 
		if ( verificationHoldersVerifierAddressMap[ _from ] == _verificationAddress )
		{
			 
			uint256 tmpNumberVerification = verificationAddressHoldersListCountMap[ _verificationAddress ];
			verificationAddressHoldersListCountMap[ _verificationAddress ]++;
			 
			verificationAddressHoldersListNumberMap[ _verificationAddress ][ tmpNumberVerification ] = _from;
		}
		
		 
		verificationHoldersTimestampMap[ _from ] = now;
		 
		verificationHoldersValueMap[ _from ] = _value;
		 
		verificationHoldersVerifierAddressMap[ _from ] = _verificationAddress;
	}
}