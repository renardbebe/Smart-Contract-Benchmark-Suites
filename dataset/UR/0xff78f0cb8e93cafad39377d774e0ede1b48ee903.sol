 

pragma solidity 0.5.0;



 
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

 

contract Owned {
    address private _owner;
    address private _newOwner;

    event TransferredOwner(
        address indexed previousOwner,
        address indexed newOwner
    );

   
    constructor() internal {
        _owner = msg.sender;
        emit TransferredOwner(address(0), _owner);
    }

   

    function owner() public view returns(address) {
        return _owner;
    }

   
    modifier onlyOwner() {
        require(isOwner(), "Access is denied");
        _;
    }

   
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

   
    function renounceOwner() public onlyOwner {
        emit TransferredOwner(_owner, address(0));
        _owner = address(0);
    }

   
    function transferOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Empty address");
        _newOwner = newOwner;
    }


    function cancelOwner() public onlyOwner {
        _newOwner = address(0);
    }

    function confirmOwner() public {
        require(msg.sender == _newOwner, "Access is denied");
        emit TransferredOwner(_owner, _newOwner);
        _owner = _newOwner;
    }
}


contract Freezed {
	bool public frozen;

	 
	event Freeze ();
	event Unfreeze ();


    modifier onlyUnfreeze() {
        require(!frozen, "Action temporarily paused");
        _;
    }

	constructor(bool _frozen) public {
		frozen = _frozen;
	}

	function _freezeTransfers () internal {
		if (!frozen) {
			frozen = true;
			emit Freeze();
		}
	}

	function _unfreezeTransfers () internal {
		if (frozen) {
			frozen = false;
			emit Unfreeze();
		}
	}
}


 

contract ERC20Base {



    mapping (address => uint) internal _balanceOf;
    uint internal _totalSupply; 

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );


     

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

     

    function balanceOf(address owner) public view returns(uint) {
        return _balanceOf[owner];
    }



     

    function _transfer(address from, address to, uint256 value) internal {
        _checkRequireERC20(to, value, true, _balanceOf[from]);

         
         
        _balanceOf[from] = SafeMath.sub(_balanceOf[from], value);
        _balanceOf[to] = SafeMath.add(_balanceOf[to], value);
        emit Transfer(from, to, value);
    }


     

    function _mint(address account, uint256 value) internal {
        _checkRequireERC20(account, value, false, 0);
        _totalSupply = SafeMath.add(_totalSupply, value);
        _balanceOf[account] = SafeMath.add(_balanceOf[account], value);
        emit Transfer(address(0), account, value);
    }

     

    function _burn(address account, uint256 value) internal {
        _checkRequireERC20(account, value, true, _balanceOf[account]);

        _totalSupply = SafeMath.sub(_totalSupply, value);
        _balanceOf[account] = SafeMath.sub(_balanceOf[account], value);
        emit Transfer(account, address(0), value);
    }


    function _checkRequireERC20(address addr, uint value, bool checkMax, uint max) internal pure {
        require(addr != address(0), "Empty address");
        require(value > 0, "Empty value");
        if (checkMax) {
            require(value <= max, "Out of value");
        }
    }

}


contract ERC20 is ERC20Base {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _total, address _fOwner) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _mint(_fOwner, _total);
    }


    mapping (address => mapping (address => uint256)) private _allowed;


    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    ); 

     

    function transfer(address to, uint256 value) public {
        _transfer(msg.sender, to, value);
    }

     
    
    function allowance(address owner, address spender) public view returns(uint) {
        return _allowed[owner][spender];
    }


     

    function approve(address spender, uint256 value) public {
        _checkRequireERC20(spender, value, true, _balanceOf[msg.sender]);

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }


     

    function transferFrom(address from, address to, uint256 value) public {
        _checkRequireERC20(to, value, true, _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = SafeMath.sub(_allowed[from][msg.sender], value);
        _transfer(from, to, value);
    }

     

    function increaseAllowance(address spender, uint256 value)  public {
        _checkRequireERC20(spender, value, false, 0);
        require(_balanceOf[msg.sender] >= (_allowed[msg.sender][spender] + value), "Out of value");

        _allowed[msg.sender][spender] = SafeMath.add(_allowed[msg.sender][spender], value);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    }



     

    function decreaseAllowance(address spender, uint256 value) public {
        _checkRequireERC20(spender, value, true, _allowed[msg.sender][spender]);

        _allowed[msg.sender][spender] = SafeMath.sub(_allowed[msg.sender][spender],value);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    }
}


contract MCVToken is ERC20, Owned, Freezed {
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _total, address _fOwner, bool _freeze) 
        public 
        ERC20(_name, _symbol, _decimals, _total, _fOwner) 
        Freezed(_freeze) {
    }


	function freezeTransfers () public onlyOwner {
		_freezeTransfers();
	}

	 
	function unfreezeTransfers () public onlyOwner {
		_unfreezeTransfers();
	}

     

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function transfer(address to, uint256 value) public onlyUnfreeze {
        super.transfer(to, value);
    }



    function transferFrom(address from, address to, uint256 value) public onlyUnfreeze {
        super.transferFrom(from, to, value);
    }

}