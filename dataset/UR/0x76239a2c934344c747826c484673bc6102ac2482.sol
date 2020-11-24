 

pragma solidity >=0.4.22 <0.6.0;

interface tokenRecipient
{
	function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}


interface IERC20 
{
	function totalSupply() external view returns (uint256);
	function balanceOf(address who) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
	function approve(address spender, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC223Rtc 
{
	event Transfer(address indexed from, address indexed to, uint256 value,bytes _data);
	event tFallback(address indexed _contract,address indexed _from, uint256 _value,bytes _data);
	event tRetrive(address indexed _contract,address indexed _to, uint256 _value);
	
	
	mapping (address => bool) internal _tokenFull;	
	 
	mapping (address => mapping (address => uint256)) internal _tokenInContract;
	
	 
	function tokenFallback(address _from, uint _value, bytes memory _data) public
	{
        	_tokenFull[msg.sender]=true;
		_tokenInContract[msg.sender][_from]=_value;
		emit tFallback(msg.sender,_from, _value, _data);
	}

	function balanceOfToken(address _contract,address _owner) public view returns(uint256)
	{
		IERC20 cont=IERC20(_contract);
		uint256 tBal = cont.balanceOf(address(this));
		if(_tokenFull[_contract]==true)		 
		{
			uint256 uBal=_tokenInContract[_contract][_owner];	 
			require(tBal >= uBal);
			return(uBal);
		}
		
		return(tBal);
	}

	
	function tokeneRetrive(address _contract, address _to, uint _value) public
	{
		IERC20 cont=IERC20(_contract);
		
		uint256 tBal = cont.balanceOf(address(this));
		require(tBal >= _value);
		
		if(_tokenFull[_contract]==true)		 
		{
			uint256 uBal=_tokenInContract[_contract][msg.sender];	 
			require(uBal >= _value);
			_tokenInContract[_contract][msg.sender]-=_value;
		}
		
		cont.transfer(_to, _value);
		emit tRetrive(_contract, _to, _value);
	}
	
	 
	function isContract(address _addr) internal view returns (bool)
	{
        	uint length;
        	assembly
        	{
			 
			length := extcodesize(_addr)
		}
		return (length>0);
	}
	
	function transfer(address _to, uint _value, bytes memory _data) public returns(bool) 
	{
		if(isContract(_to))
        	{
			ERC223Rtc receiver = ERC223Rtc(_to);
			receiver.tokenFallback(msg.sender, _value, _data);
		}
        	_transfer(msg.sender, _to, _value);
        	emit Transfer(msg.sender, _to, _value, _data);
		return true;        
	}
	
	function _transfer(address _from, address _to, uint _value) internal 
	{
		 
		bytes memory empty;
		emit Transfer(_from, _to, _value,empty);
	}
}

contract FairSocialSystem is IERC20,ERC223Rtc
{
	 
	string	internal _name;
	string	internal _symbol;
	uint8	internal _decimals;
	uint256	internal _totalS;

	
	 
	address	payable internal _mainOwner;
	uint	internal _maxPeriodVolume;		 
	uint	internal _minPeriodVolume;		 
	uint	internal _currentPeriodVolume;
	uint	internal _startPrice;
	uint	internal _currentPrice;
	uint	internal _bonusPrice;


	uint16	internal _perUp;		 
	uint16	internal _perDown;		 
	uint8	internal _bonus;		 
	bool	internal _way;			 


	 
	mapping (address => uint256) internal _balance;
	mapping (address => mapping (address => uint256)) internal _allowed;

	 
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Sell(address indexed owner, uint256 value);
	event Buy (address indexed owner, uint256 value);


	constructor() public 
	{
		_name="Fair Social System";	 
		_symbol="FSS";			 
		_decimals=2;                 	 
		_totalS=13421772800;		 
		_currentPrice=0.00000001 ether;	


		_startPrice=_currentPrice;
		_bonusPrice=_currentPrice<<1;	 
		_maxPeriodVolume=132864000;	 
		_minPeriodVolume=131532800;
		_currentPeriodVolume=0;


		_mainOwner=0x394b570584F2D37D441E669e74563CD164142930;
		_balance[_mainOwner]=(_totalS*5)/100;	 
		_perUp=10380;			 
		_perDown=10276;		 


		emit Transfer(address(this), _mainOwner, _balance[_mainOwner]);
	}

	function _calcPercent(uint mn1,uint mn2) internal pure returns (uint)	 
	{
		uint res=mn1*mn2;
		return res>>20;
	}

	function _initPeriod(bool way) internal
	{                    
		if(way)		 
		{
			_totalS=_totalS-_maxPeriodVolume;
			_maxPeriodVolume=_minPeriodVolume;
			_minPeriodVolume=_minPeriodVolume-_calcPercent(_minPeriodVolume,_perUp);

			_currentPeriodVolume=_minPeriodVolume;
			_currentPrice=_currentPrice-_calcPercent(_currentPrice,_perUp);
		}
		else
		{
			_minPeriodVolume=_maxPeriodVolume;
			_maxPeriodVolume=_maxPeriodVolume+_calcPercent(_maxPeriodVolume,_perDown);
			_totalS=_totalS+_maxPeriodVolume;
			_currentPeriodVolume=0;
			_currentPrice=_currentPrice+_calcPercent(_currentPrice,_perDown);
		}
		if(_currentPrice>_bonusPrice)		 
		{
			_bonusPrice=_bonusPrice<<1;	 
			uint addBal=_totalS/100;
			_balance[_mainOwner]=_balance[_mainOwner]+addBal;
			_totalS=_totalS+addBal;
			emit Transfer(address(this), _mainOwner, addBal);
		}
	}


	function getPrice() public view returns (uint,uint,uint) 
	{
		return (_currentPrice,_startPrice,_bonusPrice);
	}

	function getVolume() public view returns (uint,uint,uint) 
	{
		return (_currentPeriodVolume,_minPeriodVolume,_maxPeriodVolume);
	}

	function restartPrice() public
	{
		require(address(msg.sender)==_mainOwner);
		if(_currentPrice<_startPrice)
		{
			require(_balance[_mainOwner]>100);
			_currentPrice=address(this).balance/_balance[_mainOwner];
			_startPrice=_currentPrice;
			_bonusPrice=_startPrice<<1;
		}
	}


	 
	function () external payable 
	{        
		buy();
	}

	 
	function buy() public payable
	{
		 
		require(!isContract(msg.sender));
		
		uint ethAm=msg.value;
		uint amount=ethAm/_currentPrice;
		uint tAmount=0;	
		uint cAmount=_maxPeriodVolume-_currentPeriodVolume;	 

		while (amount>=cAmount)
		{
			tAmount=tAmount+cAmount;
			ethAm=ethAm-cAmount*_currentPrice;
			_initPeriod(false);	 
			amount=ethAm/_currentPrice;
			cAmount=_maxPeriodVolume;
		}
		if(amount>0)	
		{
			_currentPeriodVolume=_currentPeriodVolume+amount;
			tAmount=tAmount+amount;
		}
		_balance[msg.sender]+=tAmount;
		emit Buy(msg.sender, tAmount);		
		emit Transfer(address(this), msg.sender, tAmount);
	}


	 
	function sell(uint _amount) public
	{
		require(_balance[msg.sender] >= _amount);

		uint ethAm=0;		 
		uint tAmount=_amount;	 
 

		while (tAmount>=_currentPeriodVolume)
		{
			ethAm=ethAm+_currentPeriodVolume*_currentPrice;
			tAmount=tAmount-_currentPeriodVolume;
			_initPeriod(true);	 
		}
		if(tAmount>0)        
		{
			_currentPeriodVolume=_currentPeriodVolume-tAmount;
			ethAm=ethAm+tAmount*_currentPrice;
		}
		
 
 
		_balance[msg.sender] -= _amount;
		msg.sender.transfer(ethAm);
		emit Sell(msg.sender, _amount);
		emit Transfer(msg.sender,address(this),_amount);
	}



	
	 
	function _transfer(address _from, address _to, uint _value) internal 
	{
		 
		require(_to != address(0x0));
		
		
		 
		require(_balance[_from] >= _value);
		 
		require(_balance[_to] + _value > _balance[_to]);
		 
		uint256 previousBalances = _balance[_from] + _balance[_to];
		 
		_balance[_from] -= _value;
		 
		_balance[_to] += _value;
		 
		require(_balance[_from] + _balance[_to] == previousBalances);
	
		emit Transfer(_from, _to, _value);
	}

	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
	{
		require(_allowed[_from][msg.sender] >= _value);
        
		_allowed[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		emit Approval(_from, msg.sender, _allowed[_from][msg.sender]);
		return true;
	}
	
	
	function transfer(address _to, uint256 _value) public returns(bool) 
	{
		if (_to==address(this))		 
		{
			sell(_value);
			return true;
		}

		bytes memory empty;
		if(isContract(_to))
		{
			ERC223Rtc receiver = ERC223Rtc(_to);
			receiver.tokenFallback(msg.sender, _value, empty);
		}
		
		_transfer(msg.sender, _to, _value);
		return true;
	}
	
	
	function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool)
	{
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value))
		{
			spender.receiveApproval(msg.sender, _value, address(this), _extraData);
			return true;
		}
	}


	function approve(address _spender, uint256 _value) public returns(bool)
	{
		require(_spender != address(0));
		_allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function allowance(address owner, address spender) public view returns (uint256)
	{
		return _allowed[owner][spender];
	}

	 
	function balanceOf(address _addr) public view returns(uint256)
	{
		return _balance[_addr];
	}

    	 
	function totalSupply() public view returns(uint256) 
	{
		return _totalS;
	}


	 
	function name() public view returns (string memory)
	{
		return _name;
	}

	 
	function symbol() public view returns (string memory) 
	{
		return _symbol;
	}

	 
	function decimals() public view returns (uint8) 
	{
		return _decimals;
	}
}