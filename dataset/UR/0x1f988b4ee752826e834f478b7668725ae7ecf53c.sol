 

 
 
 
 
 

pragma solidity ^0.4.24;

 
 
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

contract U42 {
	 
	using SafeMath for uint256;

	string public constant name = "U42";
	string public constant symbol = "U42";
	uint8 public constant decimals = 18;
	uint256 public constant initialSupply = 525000000 * (10 ** uint256(decimals));
	uint256 internal totalSupply_ = initialSupply;
	address public contractOwner;

	 
	mapping(address => uint256) balances;

	 
	mapping (address => mapping (address => uint256)) internal allowed;

	 
	struct Service {
		address applicationAddress;
		uint32 serviceId;
		bool isSimple;
		string serviceDescription;
		uint256 tokensPerCredit;
		uint256 maxCreditsPerProvision;
		address updateAddress;
		address receiptAddress;
		bool isRemoved;
		uint256 provisionHead;
	}

	struct Provision {
		uint256 tokensPerCredit;
		uint256 creditsRemaining;
		uint256 applicationReference;
		address userAddress;
		uint256 creditsProvisioned;
	}

	 
	mapping (address => mapping (uint32 => Service)) services;

	 
	mapping (address => mapping (uint32 => mapping (uint256 => Provision))) provisions;

	 
	mapping (address => uint32[]) servicesLists;

	 
	mapping (address => uint32[]) servicesRemovedLists;

	 
	event Transfer (
		address indexed from, 
		address indexed to, 
		uint256 value );

	event TokensBurned (
		address indexed burner, 
		uint256 value );

	event Approval (
		address indexed owner,
		address indexed spender,
		uint256 value );

	event NewService (
		address indexed applicationAddress,
		uint32 serviceId );

	event ServiceChanged (
		address indexed applicationAddress,
		uint32 serviceId );

	event ServiceRemoved (
		address indexed applicationAddress,
		uint32 serviceId );

	event CompleteSimpleProvision (
		address indexed applicationAddress,
		uint32 indexed serviceId,
		address indexed userAddress,
		uint256 multiple,
		uint256 applicationReference );

	event ReferenceConfirmed (
		address indexed applicationAddress,
		uint256 indexed applicationReference, 
		address indexed confirmedBy, 
		uint256 confirmerTokensMinimum );

	event StartProvision (
	    address indexed applicationAddress, 
	    uint32 indexed serviceId, 
	    address indexed userAddress,
	    uint256 provisionId,
	    uint256 serviceCredits,
	    uint256 tokensPerCredit, 
	    uint256 applicationReference );

	event UpdateProvision (
	    address indexed applicationAddress,
	    uint32 indexed serviceId,
	    uint256 indexed provisionId,
	    uint256 creditsRemaining );

	event CompleteProvision (
	    address indexed applicationAddress,
	    uint32 indexed serviceId,
	    uint256 indexed provisionId,
	    uint256 creditsOutstanding );

	event SignalProvisionRefund (
	    address indexed applicationAddress,
	    uint32 indexed serviceId,
	    uint256 indexed provisionId,
	    uint256 tokenValue );

	event TransferBecauseOf (
		address indexed applicationAddress,
	    uint32 indexed serviceId,
	    uint256 indexed provisionId,
	    address from,
	    address to,
	    uint256 value );

	event TransferBecauseOfAggregate (
		address indexed applicationAddress,
	    uint32 indexed serviceId,
	    uint256[] provisionIds,
	    uint256[] tokenAmounts,
	    address from,
	    address to,
	    uint256 value );


	constructor() public {
		 
		balances[msg.sender] = totalSupply_;

		 
		contractOwner=msg.sender;

		 
		emit Transfer(address(0), msg.sender, totalSupply_);
	}

	function listSimpleService ( 
			uint32 _serviceId, 
			string _serviceDescription,
			uint256 _tokensRequired,
			address _updateAddress,
			address _receiptAddress	) 
		public returns (
			bool success ) {

		 
		require(_serviceId != 0);

		 
		require(services[msg.sender][_serviceId].applicationAddress == 0);

		 
		require(_tokensRequired != 0);

		 
		require(_receiptAddress != address(0));

		 
		require(_updateAddress != msg.sender);

		 
		services[msg.sender][_serviceId] = Service(
				msg.sender,
				_serviceId,
				true,
				_serviceDescription,
				_tokensRequired,
				1,
				_updateAddress,
				_receiptAddress,
				false,
				0
			);

		 
		servicesLists[msg.sender].push(_serviceId);

		 
		emit NewService(msg.sender, _serviceId);

		return true;
	}

	function listService ( 
			uint32 _serviceId, 
			string _serviceDescription,
			uint256 _tokensPerCredit,
			uint256 _maxCreditsPerProvision,
			address _updateAddress,
			address _receiptAddress	) 
		public returns (
			bool success ) {

		 
		require(_serviceId != 0);

		 
		require(services[msg.sender][_serviceId].applicationAddress == 0);

		 
		require(_tokensPerCredit != 0);

		 
		require(_receiptAddress != address(0));

		 
		require(_updateAddress != msg.sender);

		 
		services[msg.sender][_serviceId] = Service(
				msg.sender,
				_serviceId,
				false,
				_serviceDescription,
				_tokensPerCredit,
				_maxCreditsPerProvision,
				_updateAddress,
				_receiptAddress,
				false,
				0
			);

		 
		servicesLists[msg.sender].push(_serviceId);

		 
		emit NewService(msg.sender, _serviceId);

		return true;
	}

	function getServicesForApplication ( 
			address _applicationAddress ) 
		public view returns (
			uint32[] serviceIds ) {

		return servicesLists[_applicationAddress];
	}

	function getRemovedServicesForApplication (
			address _applicationAddress ) 
		public view returns (
			uint32[] serviceIds ) {

		return servicesRemovedLists[_applicationAddress];
	}

	function isServiceRemoved (
			address _applicationAddress,
			uint32 _serviceId )
		public view returns (
			bool ) {

		 
		return services[_applicationAddress][_serviceId].isRemoved;
	}

	function getServiceInformation ( 
			address _applicationAddress, 
			uint32 _serviceId )
		public view returns (
			bool exists,
			bool isSimple,
			string serviceDescription,
			uint256 tokensPerCredit,
			uint256 maxCreditsPerProvision,
			address receiptAddress,
			bool isRemoved,
			uint256 provisionHead ) {

		Service storage s=services[_applicationAddress][_serviceId];

		 
		if(s.applicationAddress == 0) {
			 
			exists=false;
			return;

		} else {
			exists=true;
			isSimple=s.isSimple;
			 
			serviceDescription=s.serviceDescription;
			tokensPerCredit=s.tokensPerCredit;
			maxCreditsPerProvision=s.maxCreditsPerProvision;
			receiptAddress=s.receiptAddress;
			isRemoved=s.isRemoved;
			provisionHead=s.provisionHead;

			return;
		}
	}

	function getServiceUpdateAddress (
			address _applicationAddress, 
			uint32 _serviceId ) 
		public view returns (
			address updateAddress ) {

		Service storage s=services[_applicationAddress][_serviceId];

		return s.updateAddress;
	}

	function updateServiceDescription (
			address _targetApplicationAddress, 
			uint32 _serviceId, 
			string _serviceDescription ) 
		public returns (
			bool success ) {

		 
		Service storage s=services[_targetApplicationAddress][_serviceId];

		 
		require(s.applicationAddress != 0);

		 
		require(msg.sender == _targetApplicationAddress || 
			( s.updateAddress != address(0) && msg.sender == s.updateAddress ));

		 
		require(s.isRemoved == false);

		services[_targetApplicationAddress][_serviceId].serviceDescription=_serviceDescription;
		
		emit ServiceChanged(_targetApplicationAddress, _serviceId);

		return true;
	}

	function updateServiceTokensPerCredit (
			address _targetApplicationAddress, 
			uint32 _serviceId, 
			uint256 _tokensPerCredit ) 
		public returns (
			bool success ) {

		 
		Service storage s=services[_targetApplicationAddress][_serviceId];

		 
		require(s.applicationAddress != 0);

		 
		require(msg.sender == _targetApplicationAddress || 
			( s.updateAddress != address(0) && msg.sender == s.updateAddress ));

		 
		require(s.isRemoved == false);

		 
		require(_tokensPerCredit != 0);

		services[_targetApplicationAddress][_serviceId].tokensPerCredit=_tokensPerCredit;
		
		emit ServiceChanged(_targetApplicationAddress, _serviceId);

		return true;		
	}

	function updateServiceMaxCreditsPerProvision (
			address _targetApplicationAddress,
			uint32 _serviceId,
			uint256 _maxCreditsPerProvision )
		public returns (
			bool sucess ) {

		 
		Service storage s=services[_targetApplicationAddress][_serviceId];

		 
		require(s.applicationAddress != 0);

		 
		require(msg.sender == _targetApplicationAddress || 
			( s.updateAddress != address(0) && msg.sender == s.updateAddress ));

		 
		require(s.isRemoved == false);

		 

		 
		services[_targetApplicationAddress][_serviceId].maxCreditsPerProvision=_maxCreditsPerProvision;

		emit ServiceChanged(_targetApplicationAddress, _serviceId);
	
		return true;		
	}

	function changeServiceReceiptAddress(
			uint32 _serviceId, 
			address _receiptAddress ) 
		public returns (
			bool success ) {

		 

		 
		require(services[msg.sender][_serviceId].applicationAddress != 0);

		 
		require(services[msg.sender][_serviceId].isRemoved == false);

		 
		require(_receiptAddress != address(0));

		services[msg.sender][_serviceId].receiptAddress=_receiptAddress;
		
		emit ServiceChanged(msg.sender, _serviceId);

		return true;		
	}

	function changeServiceUpdateAddress (
			uint32 _serviceId,
			address _updateAddress )
		public returns (
			bool success ) {

		 

		 
		require(services[msg.sender][_serviceId].applicationAddress != 0);

		 
		require(services[msg.sender][_serviceId].isRemoved == false);

		 
		 
		services[msg.sender][_serviceId].updateAddress=_updateAddress;

		emit ServiceChanged(msg.sender, _serviceId);

		return true;
	}

	function removeService (
			address _targetApplicationAddress, 
			uint32 _serviceId ) 
		public returns (
			bool success ) {

		 
		require(services[_targetApplicationAddress][_serviceId].applicationAddress != 0);

		 
		require(msg.sender == _targetApplicationAddress || 
			( services[_targetApplicationAddress][_serviceId].updateAddress != address(0) 
			   && msg.sender == services[_targetApplicationAddress][_serviceId].updateAddress 
			  ));

		 
		require(services[_targetApplicationAddress][_serviceId].isRemoved == false);

		 
		servicesRemovedLists[_targetApplicationAddress].push(_serviceId);

		 
		services[_targetApplicationAddress][_serviceId].isRemoved = true;

		emit ServiceRemoved(_targetApplicationAddress, _serviceId);

		return true;
	}

	function transferToSimpleService (
			address _applicationAddress, 
			uint32 _serviceId, 
			uint256 _tokenValue, 
			uint256 _applicationReference, 
			uint256 _multiple ) 
		public returns (
			bool success ) {

		 
		require(_multiple > 0);

		 
		Service storage s=services[_applicationAddress][_serviceId];

		 
		require(s.applicationAddress != 0);

		 
		require(services[_applicationAddress][_serviceId].isRemoved == false);

		 
		require(s.isSimple == true);

		 
		uint256 expectedValue=s.tokensPerCredit.mul(_multiple);

		 
		require(expectedValue == _tokenValue);

		 
		transfer(s.receiptAddress, _tokenValue);

		 
		emit CompleteSimpleProvision(_applicationAddress, _serviceId, msg.sender, _multiple, _applicationReference);

		return true;
	}


	function transferToService (
			address _applicationAddress, 
			uint32 _serviceId, 
			uint256 _tokenValue, 
			uint256 _credits,
			uint256 _applicationReference ) 
		public returns (
			uint256 provisionId ) {

		 
		Service storage s=services[_applicationAddress][_serviceId];

		 
		require(s.applicationAddress != 0);

		 
		require(services[_applicationAddress][_serviceId].isRemoved == false);

		 
		require(s.isSimple == false);

		 
		require(_tokenValue == (_credits.mul(s.tokensPerCredit)));

		 
		require( s.maxCreditsPerProvision == 0 ||
			_credits <= s.maxCreditsPerProvision);

		 
		s.provisionHead++;
		uint256 pid = s.provisionHead;

		 
		provisions[_applicationAddress][_serviceId][pid] = Provision (
				s.tokensPerCredit,
				_credits,
				_applicationReference,
				msg.sender,
				_credits		
			);

		 
		transfer(s.receiptAddress, _tokenValue);

		 
		emit StartProvision(_applicationAddress, _serviceId, msg.sender, pid, _credits, s.tokensPerCredit, _applicationReference);

		 
		return pid;
	}

	function getProvisionCreditsRemaining (
			address _applicationAddress,
			uint32 _serviceId,
		    uint256 _provisionId )
		public view returns (
			uint256 credits) {

		 
		Service storage s=services[_applicationAddress][_serviceId];

		 
		require(s.applicationAddress != 0);

		 
		require(services[_applicationAddress][_serviceId].isRemoved == false);		

		 
		Provision storage p=provisions[_applicationAddress][_serviceId][_provisionId];
		require(p.userAddress != 0);

		 
		return p.creditsRemaining;
	}

	function updateProvision (
		    address _applicationAddress,
		    uint32 _serviceId,
		    uint256 _provisionId,
		    uint256 _creditsRemaining )
		public returns (
			bool success ) {

		 
		require(_creditsRemaining > 0);

		 
		Service storage s=services[_applicationAddress][_serviceId];

		 
		require(s.applicationAddress != 0);

		 
		require(msg.sender == _applicationAddress || 
			( s.updateAddress != address(0) && msg.sender == s.updateAddress ));

		 
		require(s.isRemoved == false);

		 
		Provision storage p=provisions[_applicationAddress][_serviceId][_provisionId];
		require(p.userAddress != 0);

		 
		p.creditsRemaining=_creditsRemaining;
	
		 
		emit UpdateProvision(_applicationAddress, _serviceId, _provisionId, _creditsRemaining);

		return true;		
	}

	function completeProvision (
		    address _applicationAddress,
		    uint32 _serviceId,
		    uint256 _provisionId,
		    uint256 _creditsOutstanding )
		public returns (
			bool success ) {

		 
		Service storage s=services[_applicationAddress][_serviceId];

		 
		require(s.applicationAddress != 0);

		 
		require(msg.sender == _applicationAddress || 
			( s.updateAddress != address(0) && msg.sender == s.updateAddress ));

		 
		require(s.isRemoved == false);

		 
		Provision storage p=provisions[_applicationAddress][_serviceId][_provisionId];
		require(p.userAddress != 0);

		if(_creditsOutstanding > 0) {
			 
			require(_creditsOutstanding <= p.creditsProvisioned);

			emit SignalProvisionRefund(_applicationAddress, _serviceId, _provisionId, _creditsOutstanding.mul(p.tokensPerCredit));
		}

		 
		p.creditsRemaining=0;

		 
		emit CompleteProvision(_applicationAddress, _serviceId, _provisionId, _creditsOutstanding);

		return true;
	}


	function confirmReference (
			address _applicationAddress,
			uint256 _applicationReference,
			uint256 _senderTokensMinimum )
		public returns (
			bool success ) {

		 
		 
		 
		require(balances[msg.sender] > 0);

		 
		require(_senderTokensMinimum == 0 
			|| balances[msg.sender] >= _senderTokensMinimum);

		emit ReferenceConfirmed(_applicationAddress, _applicationReference, msg.sender, _senderTokensMinimum);

		return true;
	}


	function transferBecauseOf (
		    address _to,
		    uint256 _value,
		    address _applicationAddress,
		    uint32 _serviceId,
		    uint256 _provisionId )
		public returns (
			bool success ) {

		 
		Service storage s=services[_applicationAddress][_serviceId];

		 
		require(s.applicationAddress != 0);

		 
		require(s.isRemoved == false);

		 
		if(_provisionId != 0) {
			 
			Provision storage p=provisions[_applicationAddress][_serviceId][_provisionId];
			require(p.userAddress != 0);
		}

		 
		transfer(_to, _value);

		emit TransferBecauseOf(_applicationAddress, _serviceId, _provisionId, msg.sender, _to, _value);

		return true;
	}


	function transferBecauseOfAggregate (
		    address _to,
		    uint256 _value,
		    address _applicationAddress,
		    uint32 _serviceId,
		    uint256[] _provisionIds,
		    uint256[] _tokenAmounts )
		public returns (
			bool success ) {

		 
		Service storage s=services[_applicationAddress][_serviceId];

		 
		require(s.applicationAddress != 0);

		 
		require(s.isRemoved == false);

		 
		transfer(_to, _value);

		emit TransferBecauseOfAggregate(_applicationAddress, _serviceId, _provisionIds, _tokenAmounts, msg.sender, _to, _value);

		return true;
	}

	function ownerBurn ( 
			uint256 _value )
		public returns (
			bool success) {

		 
		require(msg.sender == contractOwner);

		 
		require(_value <= balances[contractOwner]);

		 
		totalSupply_ = totalSupply_.sub(_value);

		 
		balances[contractOwner] = balances[contractOwner].sub(_value);

		 
		emit Transfer(contractOwner, address(0), _value);
		emit TokensBurned(contractOwner, _value);

		return true;

	}
	
	
	function totalSupply ( ) public view returns (
		uint256 ) {

		return totalSupply_;
	}

	function balanceOf (
			address _owner ) 
		public view returns (
			uint256 ) {

		return balances[_owner];
	}

	function transfer (
			address _to, 
			uint256 _value ) 
		public returns (
			bool ) {

		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		emit Transfer(msg.sender, _to, _value);
		return true;
	}

   	 
   	 
   	 
	function approve (
			address _spender, 
			uint256 _value ) 
		public returns (
			bool ) {

		allowed[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function increaseApproval (
			address _spender, 
			uint256 _addedValue ) 
		public returns (
			bool ) {

		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval (
			address _spender,
			uint256 _subtractedValue ) 
		public returns (
			bool ) {

		uint256 oldValue = allowed[msg.sender][_spender];

		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function allowance (
			address _owner, 
			address _spender ) 
		public view returns (
			uint256 remaining ) {

		return allowed[_owner][_spender];
	}

	function transferFrom (
			address _from, 
			address _to, 
			uint256 _value ) 
		public returns (
			bool ) {

		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

}