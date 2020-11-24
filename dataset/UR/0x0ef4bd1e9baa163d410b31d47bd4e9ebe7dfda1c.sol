 

 
pragma solidity ^0.4.24;

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
 
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

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
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

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

 
contract EdxToken is ERC20 {
  using SafeMath for uint256;
	string public name = "Enterprise Decentralized Token";
	string public symbol = "EDX";
	uint8 public decimals = 18;

	struct VestInfo {  
			uint256 vested;
			uint256 remain;
	}
	struct CoinInfo {
		uint256 bsRemain;
		uint256 tmRemain;
		uint256 peRemain;
		uint256 remains;
	}
	struct GrantInfo {
		address holder;
		uint256 remain;
	}
  mapping (address => uint256) private _balances;		  
  mapping (address => VestInfo) private _bs_balance;  
  mapping (address => VestInfo) private _pe_balance;
  mapping (address => VestInfo) private _tm_balance;
  mapping (address => mapping (address => uint256)) private _allowed;

  uint    _releaseTime;
  bool    mainnet;
  uint256 private _totalSupply;
  address _owner;
	GrantInfo _bsholder;
	GrantInfo _peholder;
	GrantInfo _tmholder;
  CoinInfo supplies;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Mint(uint8 mtype,uint256 value);
  event Burn(uint8 mtype,uint256 value);
	event Invest( address indexed account, uint indexed mtype, uint256 vested);
  event Migrate(address indexed account,uint8 indexed mtype,uint256 vested,uint256 remain);

  constructor() public {
		 
		_totalSupply = 450*(10**6)*(10**18);
		_owner = msg.sender;

		supplies.bsRemain = 80*1000000*(10**18);
		supplies.peRemain = 200*1000000*(10**18);
		supplies.tmRemain = 75*1000000*(10**18);
		supplies.remains =  95*1000000*(10**18);
		 
		mainnet = false;
	}
   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
	function getSupplies() public view returns (uint256,uint256,uint256,uint256) {
	    require(msg.sender == _owner);

	    return (supplies.remains,supplies.bsRemain,supplies.peRemain,supplies.tmRemain);

	}
   
  function balanceOf(address owner) public view returns (uint256) {
		uint256 result = 0;
		result = result.add(_balances[owner]).add(_bs_balance[owner].remain).add(_pe_balance[owner].remain).add(_tm_balance[owner].remain);

    return result;
  }
    function  detailedBalance(address account, uint dtype) public view returns(uint256,uint256) {

        if (dtype == 0 || dtype == 1) {
					  uint256 result = balanceOf(account);
						uint256 locked = getBSBalance(account).add(getPEBalance(account)).add(getTMBalance(account));
						if(dtype == 0){
						   return (result,locked);
						}else{
							 return (result,result.sub(locked));
						}

        } else if( dtype ==  2 ) {
            return  (_bs_balance[account].vested,getBSBalance(account));
        }else if (dtype ==  3){
					  return (_pe_balance[account].vested,getPEBalance(account));
		}else if (dtype ==  4){
					  return (_tm_balance[account].vested,getTMBalance(account));
		}else {
		    return (0,0);
		 }

    }
	 
	function grantRole(address account,uint8 mtype,uint256 amount) public{
		require(msg.sender == _owner);

			if(_bsholder.holder == account) {
				_bsholder.holder = address(0);
			}
			if(_peholder.holder == account){
				_peholder.holder = address(0);
			}
			if(_tmholder.holder == account){
					_tmholder.holder = address(0);
			}
		 if(mtype == 2) {
			 require(supplies.bsRemain >= amount);
			 _bsholder.holder = account;
			 _bsholder.remain = amount;

		}else if(mtype == 3){
			require(supplies.peRemain >= amount);
			_peholder.holder = account;
			_peholder.remain = amount;
		}else if(mtype == 4){
			require(supplies.tmRemain >= amount);
			_tmholder.holder = account;
			_tmholder.remain = amount;
		}
	}
	function roleInfo(uint8 mtype)  public view returns(address,uint256) {
		if(mtype == 2) {
			return (_bsholder.holder,_bsholder.remain);
		} else if(mtype == 3) {
			return (_peholder.holder,_peholder.remain);
		}else if(mtype == 4) {
			return (_tmholder.holder,_tmholder.remain);
		}else {
			return (address(0),0);
		}
	}
	function  transferBasestone(address account, uint256 value) public {
		require(msg.sender == _owner);
		_transferBasestone(account,value);

	}
	function  _transferBasestone(address account, uint256 value) internal {

		require(supplies.bsRemain > value);
		supplies.bsRemain = supplies.bsRemain.sub(value);
		_bs_balance[account].vested = _bs_balance[account].vested.add(value);
		_bs_balance[account].remain = _bs_balance[account].remain.add(value);

	}
	function  transferPE(address account, uint256 value) public {
		require(msg.sender == _owner);
		_transferPE(account,value);
	}
	function  _transferPE(address account, uint256 value) internal {
		require(supplies.peRemain > value);
		supplies.peRemain = supplies.peRemain.sub(value);
		_pe_balance[account].vested = _pe_balance[account].vested.add(value);
		_pe_balance[account].remain = _pe_balance[account].remain.add(value);
	}
	function  transferTM(address account, uint256 value) public {
		require(msg.sender == _owner);
		_transferTM(account,value);
	}
	function  _transferTM(address account, uint256 value) internal {
		require(supplies.tmRemain > value);
		supplies.tmRemain = supplies.tmRemain.sub(value);
		_tm_balance[account].vested = _tm_balance[account].vested.add(value);
		_tm_balance[account].remain = _tm_balance[account].remain.add(value);
	}


   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
		if(msg.sender == _owner){
			require(supplies.remains >= value);
			require(to != address(0));
			supplies.remains = supplies.remains.sub(value);
			_balances[to] = _balances[to].add(value);
			emit Transfer(address(0), to, value);
		}else if(msg.sender == _bsholder.holder ){
			require(_bsholder.remain >= value);
			_bsholder.remain = _bsholder.remain.sub(value);
			_transferBasestone(to,value);

		}else if(msg.sender == _peholder.holder) {
			require(_peholder.remain >= value);
			_peholder.remain = _peholder.remain.sub(value);
			_transferPE(to,value);

		}else if(msg.sender == _tmholder.holder){
			require(_tmholder.remain >= value);
			_tmholder.remain = _tmholder.remain.sub(value);
			_transferTM(to,value);

		}else{
    	_transfer(msg.sender, to, value);
		}

    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
    _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
    _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {

		_moveBSBalance(from);
		_movePEBalance(from);
		_moveTMBalance(from);
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }



 
	function release() public {
		require(msg.sender == _owner);
		if(_releaseTime == 0) {
			_releaseTime = now;
		}
	}
	function getBSBalance(address account) public view returns(uint256){
		uint  elasped = now - _releaseTime;
		uint256 shouldRemain = _bs_balance[account].remain;
		if( _releaseTime !=  0 && now > _releaseTime && _bs_balance[account].remain > 0){

			if(elasped < 180 days) {  
				shouldRemain = _bs_balance[account].vested.mul(9).div(10);
			} else if(elasped < 420 days) {
					shouldRemain = _bs_balance[account].vested .mul(6).div(10);
			} else if( elasped < 720 days) {
					shouldRemain = _bs_balance[account].vested .mul(3).div(10);
			}else {
				shouldRemain = 0;
			}

		}
		return shouldRemain;
	}
	 
	function _moveBSBalance(address account) internal {
		uint256 shouldRemain = getBSBalance(account);
		if(_bs_balance[account].remain > shouldRemain) {
			uint256 toMove = _bs_balance[account].remain.sub(shouldRemain);
			_bs_balance[account].remain = shouldRemain;
			_balances[account] = _balances[account].add(toMove);
		}
	}
	function getPEBalance(address account) public view returns(uint256) {
		uint  elasped = now - _releaseTime;
		uint256 shouldRemain = _pe_balance[account].remain;
		if( _releaseTime !=  0 && _pe_balance[account].remain > 0){


			if(elasped < 150 days) {  
				shouldRemain = _pe_balance[account].vested.mul(9).div(10);

			} else if(elasped < 330 days) { 
					shouldRemain = _pe_balance[account].vested .mul(6).div(10);
			} else if( elasped < 540 days) { 
					shouldRemain = _pe_balance[account].vested .mul(3).div(10);
			} else {
					shouldRemain = 0;
			}

		}
		return shouldRemain;
	}
	 
	function _movePEBalance(address account) internal {
		uint256 shouldRemain = getPEBalance(account);
		if(_pe_balance[account].remain > shouldRemain) {
			uint256 toMove = _pe_balance[account].remain.sub(shouldRemain);
			_pe_balance[account].remain = shouldRemain;
			_balances[account] = _balances[account].add(toMove);
		}
	}
	function getTMBalance(address account ) public view returns(uint256){
		uint  elasped = now - _releaseTime;
		uint256 shouldRemain = _tm_balance[account].remain;
		if( _releaseTime !=  0 && _tm_balance[account].remain > 0){
			 
			if(elasped < 90 days) {  
				shouldRemain = _tm_balance[account].vested;
			} else {
					 
					elasped = elasped / 1 days;
					if(elasped <= 1090){
							shouldRemain = _tm_balance[account].vested.mul(1090-elasped).div(1000);
					}else {
							shouldRemain = 0;
					}
			}
		}
		return shouldRemain;
	}
	function _moveTMBalance(address account ) internal {
		uint256 shouldRemain = getTMBalance(account);
		if(_tm_balance[account].remain > shouldRemain) {
			uint256 toMove = _tm_balance[account].remain.sub(shouldRemain);
			_tm_balance[account].remain = shouldRemain;
			_balances[account] = _balances[account].add(toMove);
		}
	}
	 
 function _mint(uint256 value) public {
	 require(msg.sender == _owner);
	 require(mainnet == false);  
	 _totalSupply = _totalSupply.add(value);
	  
	 supplies.remains = supplies.remains.add(value);
	 		emit Mint(1,value);
 }
  
 function _mintBS(uint256 value) public {
	require(msg.sender == _owner);
		require(mainnet == false);  
	_totalSupply = _totalSupply.add(value);
	 
	supplies.bsRemain = supplies.bsRemain.add(value);
			emit Mint(2,value);
 }
  
 function _mintPE(uint256 value) public {
	require(msg.sender == _owner);
		require(mainnet == false);  
	_totalSupply = _totalSupply.add(value);
	 
	supplies.peRemain = supplies.peRemain.add(value);
		emit Mint(3,value);
 }
  
 function _burn(uint256 value) public {
	require(msg.sender == _owner);
	require(mainnet == false);  
	require(supplies.remains >= value);
	_totalSupply = _totalSupply.sub(value);
	supplies.remains = supplies.remains.sub(value);
	emit Burn(0,value);
 }
   
 function _burnTM(uint256 value) public {
	require(msg.sender == _owner);
	require(mainnet == false);  
	require(supplies.remains >= value);
	_totalSupply = _totalSupply.sub(value);
	supplies.tmRemain = supplies.tmRemain.sub(value);
  emit Burn(3,value);
 }
  
 function startupMainnet() public {
     require(msg.sender == _owner);

     mainnet = true;
 }
  
 function migrate() public {
      
     require(mainnet == true);
     require(msg.sender != _owner);
     uint256 value;
     if( _balances[msg.sender] > 0) {
         value = _balances[msg.sender];
         _balances[msg.sender] = 0;
         emit Migrate(msg.sender,0,value,value);
     }
     if( _bs_balance[msg.sender].remain > 0) {
         value = _bs_balance[msg.sender].remain;
         _bs_balance[msg.sender].remain = 0;
         emit Migrate(msg.sender,1,_bs_balance[msg.sender].vested,value);
     }
     if( _pe_balance[msg.sender].remain > 0) {
         value = _pe_balance[msg.sender].remain;
         _pe_balance[msg.sender].remain = 0;
         emit Migrate(msg.sender,2,_pe_balance[msg.sender].vested,value);
     }
     if( _tm_balance[msg.sender].remain > 0){
          value = _tm_balance[msg.sender].remain;
         _tm_balance[msg.sender].remain = 0;
         emit Migrate(msg.sender,3,_pe_balance[msg.sender].vested,value);
     }

 }
  
	function revokeTMBalance(address account) public {
	        require(msg.sender == _owner);
			if(_tm_balance[account].remain > 0  && _tm_balance[account].vested >= _tm_balance[account].remain ){
				_tm_balance[account].vested = _tm_balance[account].vested.sub(_tm_balance[account].remain);
				_tm_balance[account].remain = 0;
				supplies.tmRemain = supplies.tmRemain.add(_tm_balance[account].remain);
			}
	}
}